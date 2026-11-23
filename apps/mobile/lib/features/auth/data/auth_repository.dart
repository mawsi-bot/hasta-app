import 'package:drift/drift.dart';

import '../../../core/config/build_config.dart';
import '../../../core/db/drift/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/security/device_identity.dart';
import '../../../core/security/token_store.dart';
import '../domain/auth_state.dart';

/// Guest-first auth (SPEC §5.3). There is deliberately no Google/Apple sign-in
/// and no OTP/SMS path in v1 — Gmail is only ever *linked* after login.
class AuthRepository {
  AuthRepository({
    required ApiClient api,
    required TokenStore tokens,
    required DeviceIdentity device,
    required AppDatabase db,
  })  : _api = api,
        _tokens = tokens,
        _device = device,
        _db = db;

  final ApiClient _api;
  final TokenStore _tokens;
  final DeviceIdentity _device;
  final AppDatabase _db;

  /// Returns the stored device token, registering the device first if needed.
  Future<String> ensureDeviceToken({bool forceRegister = false}) async {
    if (!forceRegister) {
      final String? existing = await _tokens.read(SecureKey.deviceToken);
      if (existing != null) return existing;
    }
    final Map<String, dynamic>? r = await _api.post('/v1/auth/device/register', body: <String, String>{
      'raw_device_id': await _device.rawDeviceId(),
      'platform': await _device.platform(),
      'app_version': BuildConfig.appVersion,
    });
    final String token = r!['device_token'] as String;
    await _tokens.write(SecureKey.deviceToken, token);
    return token;
  }

  /// One-tap guest: creates a guest account on a fresh device (T40) or resumes
  /// the account already bound to this device (T41).
  Future<AccountSummary> continueAsGuest({String locale = 'my'}) async {
    Future<Map<String, dynamic>?> call(String dt) =>
        _api.post('/v1/auth/guest', body: <String, String>{'device_token': dt, 'locale': locale});
    String dt = await ensureDeviceToken();
    Map<String, dynamic>? r;
    try {
      r = await call(dt);
    } on ApiFailure catch (f) {
      // Device token expired or signed with a rotated secret: re-register once.
      if (f.code != 'unauthenticated' && f.code != 'token_expired') rethrow;
      dt = await ensureDeviceToken(forceRegister: true);
      r = await call(dt);
    }
    return adoptSession(r!);
  }

  /// Persists a session response (`SessionResponse`) locally.
  Future<AccountSummary> adoptSession(Map<String, dynamic> r) async {
    await _tokens.write(SecureKey.accessToken, r['access_token'] as String);
    await _tokens.write(SecureKey.refreshToken, r['refresh_token'] as String);
    final Map<String, dynamic> a = r['account'] as Map<String, dynamic>;
    final AccountSummary s = AccountSummary(id: a['id'] as String, isGuest: a['is_guest'] as bool, status: a['status'] as String);
    final DateTime now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.clearAccountData();
      await _db.into(_db.localAccounts).insert(LocalAccountsCompanion.insert(
            id: s.id,
            isGuest: s.isGuest,
            status: s.status,
            createdAt: DateTime.parse(a['created_at'] as String).toUtc(),
            syncedAt: now,
          ));
      await _db.into(_db.localProfiles).insert(LocalProfilesCompanion.insert(
            accountId: s.id,
            displayName: Value<String?>(a['display_name'] as String?),
            username: Value<String?>(a['username'] as String?),
            updatedAt: now,
          ));
    });
    return s;
  }

  /// Offline restore: a stored refresh token + cached account is enough
  /// to open the app with no network.
  Future<AccountSummary?> restore() async {
    final String? refresh = await _tokens.read(SecureKey.refreshToken);
    if (refresh == null) return null;
    final LocalAccount? a = await _db.select(_db.localAccounts).getSingleOrNull();
    if (a == null) return null;
    return AccountSummary(id: a.id, isGuest: a.isGuest, status: a.status);
  }

  /// Sign out of this device. The device binding is kept, so "Get started"
  /// resumes the same guest account (SPEC §5.3).
  Future<void> signOut() async {
    final String? dt = await _tokens.read(SecureKey.deviceToken);
    try {
      if (dt != null) await _api.post('/v1/auth/logout', body: <String, Object>{'device_token': dt}, auth: true);
    } on ApiFailure {
      // Offline or already revoked: local sign-out still proceeds; the refresh
      // token is discarded so the server session dies at expiry.
    }
    await clearLocalSession();
  }

  Future<void> clearLocalSession() async {
    await _tokens.delete(SecureKey.accessToken);
    await _tokens.delete(SecureKey.refreshToken);
    await _db.clearAccountData();
  }
}
