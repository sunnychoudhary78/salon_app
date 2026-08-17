import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/storage/secure_storage.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/data/services/auth_service.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _authLoggedOutKey = 'auth_logged_out';

class AuthRepository {
  AuthRepository(this._service, this._storage, this._prefsFuture);

  final AuthService _service;
  final SecureStorageService _storage;
  final Future<SharedPreferences> _prefsFuture;

  Future<void> requestOtp({required String phone}) =>
      _service.requestOtp(phone: phone);

  Future<OtpVerifyResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final result = await _service.verifyOtp(phone: phone, otp: otp);
    if (result.isNewUser) return result;

    final auth = result.authResponse;
    if (auth == null) {
      throw StateError('OTP verification succeeded but auth data was missing');
    }

    await _persistSession(auth.token);
    final profile = await _service.getProfile();
    return OtpVerifyResult(
      isNewUser: false,
      authState: AuthState.fromProfile(auth.token, profile),
    );
  }

  Future<AuthState> completeProfile({
    required String signupToken,
    required String name,
    required String gender,
    required String accountType,
    String? email,
  }) async {
    final auth = await _service.completeProfile(
      signupToken: signupToken,
      name: name,
      gender: gender,
      accountType: accountType,
      email: email,
    );
    await _persistSession(auth.token);
    final profile = await _service.getProfile();
    return AuthState.fromProfile(auth.token, profile);
  }

  Future<AuthState?> restoreSession() async {
    CrashReporting.breadcrumb('restore_session_start');
    if (await _isLoggedOut()) {
      await _storage.deleteToken();
      return null;
    }

    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final profile = await _service.getProfile();
      CrashReporting.breadcrumb('restore_session_success');
      return AuthState.fromProfile(token, profile);
    } catch (e, stack) {
      debugPrint('[auth] restoreSession failed: $e');
      CrashReporting.recordError(e, stack, reason: 'restoreSession');
      await _storage.deleteToken();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _setLoggedOut(true);
    } catch (e, stack) {
      debugPrint('[auth] setLoggedOut failed: $e');
      CrashReporting.recordError(e, stack, reason: 'logout_setLoggedOut');
    }
    try {
      await _storage.deleteToken();
    } catch (e, stack) {
      debugPrint('[auth] deleteToken failed: $e');
      CrashReporting.recordError(e, stack, reason: 'logout_deleteToken');
    }
  }

  Future<ProfileResponse> getProfile() => _service.getProfile();

  Future<void> _persistSession(String token) async {
    await _setLoggedOut(false);
    await _storage.writeToken(token);
  }

  Future<bool> _isLoggedOut() async {
    try {
      final prefs = await withStorageTimeout(
        _prefsFuture,
        label: 'isLoggedOut_prefs',
      );
      return prefs.getBool(_authLoggedOutKey) ?? false;
    } catch (e, stack) {
      CrashReporting.recordError(e, stack, reason: 'isLoggedOut');
      return false;
    }
  }

  Future<void> _setLoggedOut(bool value) async {
    final prefs = await withStorageTimeout(
      _prefsFuture,
      label: 'setLoggedOut_prefs',
    );
    await withStorageTimeout(
      prefs.setBool(_authLoggedOutKey, value),
      label: 'setLoggedOut_setBool',
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  ref.keepAlive();
  return AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
    ref.watch(sharedPreferencesProvider.future),
  );
});
