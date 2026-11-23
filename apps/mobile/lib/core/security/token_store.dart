import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys held in the platform keystore. Never logged (SKILL prohibition).
enum SecureKey { deviceToken, accessToken, refreshToken }

abstract interface class TokenStore {
  Future<String?> read(SecureKey key);
  Future<void> write(SecureKey key, String value);
  Future<void> delete(SecureKey key);
}

/// Android Keystore-backed EncryptedSharedPreferences / iOS Keychain.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _s = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  final FlutterSecureStorage _s;

  @override
  Future<String?> read(SecureKey key) => _s.read(key: key.name);

  @override
  Future<void> write(SecureKey key, String value) => _s.write(key: key.name, value: value);

  @override
  Future<void> delete(SecureKey key) => _s.delete(key: key.name);
}

/// In-memory store for tests.
class MemoryTokenStore implements TokenStore {
  final Map<SecureKey, String> values = <SecureKey, String>{};

  @override
  Future<String?> read(SecureKey key) async => values[key];

  @override
  Future<void> write(SecureKey key, String value) async => values[key] = value;

  @override
  Future<void> delete(SecureKey key) async => values.remove(key);
}
