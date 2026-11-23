import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/drift/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/providers.dart';
import 'google_auth_launcher.dart';

const String kLinkScheme = 'hasta';
const String _base = '/v1/auth/identities/google';

/// Gmail link status as the server reports it. `emailMasked` is rendered as-is — never re-masked here.
class GoogleLink {
  const GoogleLink(this.emailMasked);
  final String? emailMasked;
}

/// API contract §1.6. Online-only by design: linking needs Google, so nothing is queued in the outbox.
class IdentityRepository {
  IdentityRepository({required ApiClient api, required AppDatabase db, required GoogleAuthLauncher launcher})
      : _api = api,
        _db = db,
        _launcher = launcher;

  final ApiClient _api;
  final AppDatabase _db;
  final GoogleAuthLauncher _launcher;

  Future<GoogleLink?> current() async {
    final List<dynamic> ids = (await _api.get('/v1/me'))?['identities'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic i in ids) {
      if (i is Map<String, dynamic> && i['provider'] == 'google') return GoogleLink(i['email_masked'] as String?);
    }
    return null;
  }

  /// start → browser → callback `{code, state}` → complete. Throws [AuthCancelled] or [ApiFailure].
  Future<GoogleLink> link() async {
    final Map<String, dynamic> s = (await _api.post('$_base/link:start', body: <String, dynamic>{}, auth: true))!;
    final Uri cb = await _launcher.authenticate(Uri.parse(s['auth_url'] as String), kLinkScheme);
    final Map<String, String> q = cb.queryParameters;
    if (q['error'] == 'access_denied') throw const AuthCancelled();
    if (q['state'] != s['state'] || q['code'] == null) throw const ApiFailure(code: 'link_state_mismatch', status: 400);
    final Map<String, dynamic> r = (await _api.post('$_base/link:complete',
        body: <String, String>{'state': q['state']!, 'code': q['code']!}, auth: true))!;
    final Map<String, dynamic> acc = r['account'] as Map<String, dynamic>;
    await (_db.update(_db.localAccounts)..where(($LocalAccountsTable t) => t.id.equals(acc['id'] as String)))
        .write(LocalAccountsCompanion(isGuest: Value<bool>(acc['is_guest'] as bool)));
    return GoogleLink((r['identity'] as Map<String, dynamic>)['email_masked'] as String?);
  }

  Future<void> unlink() => _api.delete(_base);
}

final Provider<IdentityRepository> identityRepositoryProvider = Provider<IdentityRepository>((Ref ref) => IdentityRepository(
    api: ref.watch(apiClientProvider), db: ref.watch(databaseProvider), launcher: ref.watch(googleAuthLauncherProvider)));
