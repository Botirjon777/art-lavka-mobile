import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access + refresh tokens in the platform secure store
/// (Keychain / Keystore). Keeps a synchronous cache of the access token so the
/// request interceptor and `currentUserId` don't await on every call.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'artlavka_access_token';
  static const _refreshKey = 'artlavka_refresh_token';

  String? _accessCache;

  /// Synchronously-known access token (populated by [load] / [save]).
  String? get cachedAccessToken => _accessCache;

  /// Warm the cache from secure storage. Call once at startup.
  Future<void> load() async {
    _accessCache = await _storage.read(key: _accessKey);
  }

  Future<void> save({required String access, required String refresh}) async {
    _accessCache = access;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> accessToken() async =>
      _accessCache ??= await _storage.read(key: _accessKey);

  Future<String?> refreshToken() => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    _accessCache = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
