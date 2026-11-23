import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/drift/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/sync/hlc.dart';
import '../domain/profile.dart';

const String kProfilePatch = 'profile.patch';
const String kProfileSyncErrorKey = 'profile.sync_error';

/// Local-first profile (SPEC §11): edits go to Drift + outbox immediately; the
/// outbox sends `PATCH /v1/profile` with a stable Idempotency-Key and the edit's
/// HLC so the server applies field-level LWW.
class ProfileRepository {
  ProfileRepository({
    required AppDatabase db,
    required ApiClient api,
    required Hlc hlc,
    required Future<String> Function(String kind, Map<String, dynamic> payload) enqueue,
    required void Function() kick,
  })  : _db = db,
        _api = api,
        _hlc = hlc,
        _enqueue = enqueue,
        _kick = kick;

  final AppDatabase _db;
  final ApiClient _api;
  final Hlc _hlc;
  final Future<String> Function(String kind, Map<String, dynamic> payload) _enqueue;
  final void Function() _kick;

  Stream<LocalProfile?> watch(String accountId) =>
      (_db.select(_db.localProfiles)..where(($LocalProfilesTable t) => t.accountId.equals(accountId))).watchSingleOrNull();

  Stream<int> watchPending() => _db.watchPending(kProfilePatch);

  Stream<String?> watchSyncError() => _db.kvWatch(kProfileSyncErrorKey);

  Future<LocalProfile?> read(String accountId) =>
      (_db.select(_db.localProfiles)..where(($LocalProfilesTable t) => t.accountId.equals(accountId))).getSingleOrNull();

  /// Network refresh → upsert → UI reacts to the Drift stream.
  Future<void> refresh(String accountId) async {
    final Map<String, dynamic>? me = await _api.get('/v1/me');
    final Map<String, dynamic>? p = me?['profile'] as Map<String, dynamic>?;
    final Map<String, dynamic> acc = me!['account'] as Map<String, dynamic>;
    await _db.transaction(() async {
      await (_db.update(_db.localAccounts)..where(($LocalAccountsTable t) => t.id.equals(accountId))).write(
        LocalAccountsCompanion(
          isGuest: Value<bool>(acc['is_guest'] as bool),
          status: Value<String>(acc['status'] as String),
          syncedAt: Value<DateTime>(DateTime.now().toUtc()),
        ),
      );
      if (p != null) await _applyServer(accountId, p);
    });
  }

  /// Saves locally (instant, offline-safe) and queues the write.
  Future<void> saveLocal(String accountId, ProfileDraft next) async {
    await _db.transaction(() async {
      final LocalProfile? cur = await read(accountId);
      final Map<String, String> changed = <String, String>{};
      void diff(String field, String? before, String? after) {
        if (after != null && after != (before ?? '')) changed[field] = after;
      }

      diff('display_name', cur?.displayName, next.displayName);
      diff('username', cur?.username, next.username);
      diff('bio', cur?.bio, next.bio);
      diff('birth_date', cur?.birthDate, next.birthDate);
      if (changed.isEmpty) return;

      final String stamp = _hlc.next();
      final Map<String, dynamic> fieldHlc = cur == null ? <String, dynamic>{} : jsonDecode(cur.fieldHlc) as Map<String, dynamic>;
      for (final String f in changed.keys) {
        fieldHlc[f] = stamp;
      }
      await _db.into(_db.localProfiles).insertOnConflictUpdate(LocalProfilesCompanion(
            accountId: Value<String>(accountId),
            displayName: changed.containsKey('display_name') ? Value<String?>(changed['display_name']) : const Value<String?>.absent(),
            username: changed.containsKey('username') ? Value<String?>(changed['username']) : const Value<String?>.absent(),
            bio: changed.containsKey('bio') ? Value<String?>(changed['bio']) : const Value<String?>.absent(),
            birthDate: changed.containsKey('birth_date') ? Value<String?>(changed['birth_date']) : const Value<String?>.absent(),
            fieldHlc: Value<String>(jsonEncode(fieldHlc)),
            updatedAt: Value<DateTime>(DateTime.now().toUtc()),
          ));
      await _db.kvSet(kProfileSyncErrorKey, '');
      await _enqueue(kProfilePatch, <String, dynamic>{...changed, 'hlc': stamp, 'account_id': accountId});
    });
    _kick();
  }

  /// Outbox sender for [kProfilePatch].
  Future<void> sendPatch(Map<String, dynamic> payload, String idempotencyKey) async {
    final String accountId = payload['account_id'] as String;
    final Map<String, dynamic> body = Map<String, dynamic>.of(payload)..remove('account_id');
    final Map<String, dynamic>? r = await _api.patch('/v1/profile', body: body, idempotencyKey: idempotencyKey);
    await _applyServer(accountId, r!['profile'] as Map<String, dynamic>);
  }

  /// Permanent rejection (e.g. `username_taken`, `validation_failed`): surface
  /// the code and fall back to server truth for the rejected fields.
  Future<void> onRejected(Map<String, dynamic> payload, ApiFailure f) async {
    await _db.kvSet(kProfileSyncErrorKey, f.code);
    final String accountId = payload['account_id'] as String;
    final Map<String, dynamic> fieldHlc = jsonDecode((await read(accountId))?.fieldHlc ?? '{}') as Map<String, dynamic>;
    payload.keys.where((String k) => k != 'hlc' && k != 'account_id').forEach(fieldHlc.remove);
    await (_db.update(_db.localProfiles)..where(($LocalProfilesTable t) => t.accountId.equals(accountId)))
        .write(LocalProfilesCompanion(fieldHlc: Value<String>(jsonEncode(fieldHlc))));
    try {
      await refresh(accountId);
    } on ApiFailure {
      // Offline: the next refresh reconciles.
    }
  }

  /// Field-level LWW against local edits that are newer than the server copy.
  Future<void> _applyServer(String accountId, Map<String, dynamic> p) async {
    final String serverHlc = (p['updated_hlc'] as String?) ?? '0';
    _hlc.observe(serverHlc);
    final LocalProfile? cur = await read(accountId);
    final Map<String, dynamic> fieldHlc = jsonDecode(cur?.fieldHlc ?? '{}') as Map<String, dynamic>;
    bool localWins(String f) {
      final Object? h = fieldHlc[f];
      return h is String && Hlc.compare(h, serverHlc) > 0;
    }

    Value<String?> pick(String f) => localWins(f) ? const Value<String?>.absent() : Value<String?>(p[f] as String?);
    fieldHlc.removeWhere((String f, dynamic _) => !localWins(f));
    await _db.into(_db.localProfiles).insertOnConflictUpdate(LocalProfilesCompanion(
          accountId: Value<String>(accountId),
          displayName: pick('display_name'),
          username: pick('username'),
          bio: pick('bio'),
          birthDate: pick('birth_date'),
          avatarUrl: Value<String?>(p['avatar_url'] as String?),
          fieldHlc: Value<String>(jsonEncode(fieldHlc)),
          serverHlc: Value<String>(serverHlc),
          updatedAt: Value<DateTime>(DateTime.now().toUtc()),
        ));
  }
}
