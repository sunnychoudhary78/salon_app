import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'auth_token';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> clearAll() => _storage.deleteAll();
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  ref.keepAlive();
  return SecureStorageService(const FlutterSecureStorage());
});
