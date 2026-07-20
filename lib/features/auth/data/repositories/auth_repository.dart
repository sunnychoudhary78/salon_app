import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/storage/secure_storage.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/data/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._service, this._storage);

  final AuthService _service;
  final SecureStorageService _storage;

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

    await _storage.writeToken(auth.token);
    final profile = await _service.getProfile();
    return OtpVerifyResult(
      isNewUser: false,
      authState: AuthState.fromProfile(auth.token, profile),
    );
  }

  Future<AuthState> completeProfile({
    required String signupToken,
    required String name,
    String? email,
  }) async {
    final auth = await _service.completeProfile(
      signupToken: signupToken,
      name: name,
      email: email,
    );
    await _storage.writeToken(auth.token);
    final profile = await _service.getProfile();
    return AuthState.fromProfile(auth.token, profile);
  }

  Future<AuthState?> restoreSession() async {
    CrashReporting.breadcrumb('restore_session_start');
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

  Future<void> logout() => _storage.deleteToken();

  Future<ProfileResponse> getProfile() => _service.getProfile();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  ref.keepAlive();
  return AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
  );
});
