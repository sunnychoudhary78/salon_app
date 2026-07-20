import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';

const _tokenKey = 'auth_token';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  // In-memory cache so the auth token doesn't trigger a platform-channel read
  // on every outgoing HTTP request (a source of perceived UI stalls).
  String? _cachedToken;
  bool _tokenLoaded = false;

  Future<String?> readToken() async {
    if (_tokenLoaded) return _cachedToken;
    try {
      _cachedToken = await withStorageTimeout(
        _storage.read(key: _tokenKey),
        label: 'readToken',
        onTimeout: () => null,
      );
    } catch (e, stack) {
      CrashReporting.recordError(e, stack, reason: 'readToken');
      _cachedToken = null;
    }
    _tokenLoaded = true;
    return _cachedToken;
  }

  Future<void> writeToken(String token) async {
    await withStorageTimeout(
      _storage.write(key: _tokenKey, value: token),
      label: 'writeToken',
    );
    _cachedToken = token;
    _tokenLoaded = true;
  }

  Future<void> deleteToken() async {
    try {
      await withStorageTimeout(
        _storage.delete(key: _tokenKey),
        label: 'deleteToken',
      );
    } catch (e, stack) {
      CrashReporting.recordError(e, stack, reason: 'deleteToken');
    }
    _cachedToken = null;
    _tokenLoaded = true;
  }

  Future<void> clearAll() async {
    try {
      await withStorageTimeout(
        _storage.deleteAll(),
        label: 'clearAll',
      );
    } catch (e, stack) {
      CrashReporting.recordError(e, stack, reason: 'clearAll');
    }
    _cachedToken = null;
    _tokenLoaded = true;
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  ref.keepAlive();
  return SecureStorageService(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});
