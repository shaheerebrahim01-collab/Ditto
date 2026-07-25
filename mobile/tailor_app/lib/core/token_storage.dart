import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Persists *our* JWT (from POST /auth/firebase) — not the Firebase ID
// token. Every authenticated request after login uses this, so the app
// never has to go back to Firebase.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'ditto_access_token';

  final FlutterSecureStorage _storage;

  Future<void> save(String accessToken) => _storage.write(key: _key, value: accessToken);

  Future<String?> read() => _storage.read(key: _key);

  Future<void> clear() => _storage.delete(key: _key);
}
