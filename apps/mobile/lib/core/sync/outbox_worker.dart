import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../connectivity/connectivity.dart';
import '../db/drift/app_database.dart';
import '../ids/uuid_v7.dart';
import '../network/api_failure.dart';

/// Sends one outbox entry. Must use [idempotencyKey] for the HTTP write.
typedef OutboxSender = Future<void> Function(Map<String, dynamic> payload, String idempotencyKey);

/// Called when the server permanently rejects an entry (4xx other than 401/408/429).
typedef OutboxRejected = Future<void> Function(Map<String, dynamic> payload, ApiFailure failure);

class OutboxHandler {
  const OutboxHandler({required this.send, required this.onRejected});
  final OutboxSender send;
  final OutboxRejected onRejected;
}

/// Durable, ordered write queue (SPEC §11.2). Entries survive restarts; each
/// keeps the same Idempotency-Key across retries, so a replay after a lost
/// response is applied once.
class OutboxWorker {
  OutboxWorker({
    required AppDatabase db,
    required ConnectivitySignal connectivity,
    required Map<String, OutboxHandler> handlers,
    DateTime Function()? now,
  })  : _db = db,
        _connectivity = connectivity,
        _handlers = handlers,
        _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final ConnectivitySignal _connectivity;
  final Map<String, OutboxHandler> _handlers;
  final DateTime Function() _now;

  StreamSubscription<bool>? _sub;
  bool _running = false;
  bool _again = false;

  static const int maxBackoffSeconds = 300;

  void start() {
    _sub ??= _connectivity.watch().listen((bool online) {
      if (online) unawaited(drain());
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Enqueue inside the caller's transaction when possible.
  Future<String> enqueue(String kind, Map<String, dynamic> payload) async {
    final String id = uuidV7();
    await _db.into(_db.outboxEntries).insert(OutboxEntriesCompanion.insert(
          id: id,
          kind: kind,
          payload: jsonEncode(payload),
          idempotencyKey: uuidV7(),
          nextAttemptAt: _now(),
          createdAt: _now(),
        ));
    return id;
  }

  Future<int> pendingCount([String? kind]) async {
    final SimpleSelectStatement<$OutboxEntriesTable, OutboxEntry> q = _db.select(_db.outboxEntries)
      ..where(($OutboxEntriesTable t) => t.status.equals('pending'));
    if (kind != null) q.where(($OutboxEntriesTable t) => t.kind.equals(kind));
    return (await q.get()).length;
  }

  /// Drains due entries in creation order. Stops at the first transient failure
  /// so ordering is preserved.
  Future<void> drain() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        if (!await _connectivity.isOnline()) return;
        final List<OutboxEntry> due = await (_db.select(_db.outboxEntries)
              ..where(($OutboxEntriesTable t) =>
                  t.status.equals('pending') & t.nextAttemptAt.isSmallerOrEqualValue(_now()))
              ..orderBy(<OrderClauseGenerator<$OutboxEntriesTable>>[
                ($OutboxEntriesTable t) => OrderingTerm.asc(t.createdAt),
                ($OutboxEntriesTable t) => OrderingTerm.asc(t.id),
              ]))
            .get();
        for (final OutboxEntry e in due) {
          final bool keepGoing = await _process(e);
          if (!keepGoing) return;
        }
      } while (_again);
    } finally {
      _running = false;
    }
  }

  Future<bool> _process(OutboxEntry e) async {
    final OutboxHandler? h = _handlers[e.kind];
    final Map<String, dynamic> payload = jsonDecode(e.payload) as Map<String, dynamic>;
    if (h == null) {
      await _markFailed(e, 'unknown_kind');
      return true;
    }
    try {
      await h.send(payload, e.idempotencyKey);
      await (_db.delete(_db.outboxEntries)..where(($OutboxEntriesTable t) => t.id.equals(e.id))).go();
      return true;
    } on ApiFailure catch (f) {
      if (_isTransient(f)) {
        final int attempts = e.attempts + 1;
        final int wait = f.retryAfterSeconds ?? min(maxBackoffSeconds, pow(2, attempts).toInt());
        await (_db.update(_db.outboxEntries)..where(($OutboxEntriesTable t) => t.id.equals(e.id))).write(
          OutboxEntriesCompanion(
            attempts: Value<int>(attempts),
            nextAttemptAt: Value<DateTime>(_now().add(Duration(seconds: wait))),
            lastErrorCode: Value<String?>(f.code),
          ),
        );
        return false;
      }
      await _markFailed(e, f.code);
      await h.onRejected(payload, f);
      return true;
    }
  }

  static bool _isTransient(ApiFailure f) {
    final int s = f.status ?? 0;
    return f.isOffline || s >= 500 || s == 401 || s == 408 || s == 429 || f.code == 'idempotency_conflict';
  }

  Future<void> _markFailed(OutboxEntry e, String code) =>
      (_db.update(_db.outboxEntries)..where(($OutboxEntriesTable t) => t.id.equals(e.id))).write(
        OutboxEntriesCompanion(status: const Value<String>('failed'), lastErrorCode: Value<String?>(code)),
      );
}
