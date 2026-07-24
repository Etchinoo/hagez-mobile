import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps Keychain (iOS) / Keystore (Android) for auth token storage.
/// Never store tokens in SharedPreferences — that maps to localStorage-style
/// plaintext storage, which is exactly the XSS-equivalent risk (M12) flagged
/// in the platform's security audit for the web dashboard.
class SecureStorage {
  SecureStorage._();
  static final instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'hagez_access_token';
  static const _refreshTokenKey = 'hagez_refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
