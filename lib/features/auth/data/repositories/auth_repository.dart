import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (!result.isNewUser && result.authState != null) {
      await _storage.writeToken(result.authState!.token);
    }
    return result;
  }

  Future<AuthState> completeProfile({
    required String signupToken,
    required String name,
    String? email,
  }) async {
    final authState = await _service.completeProfile(
      signupToken: signupToken,
      name: name,
      email: email,
    );
    await _storage.writeToken(authState.token);
    return authState;
  }

  Future<AuthState> login({
    required String email,
    required String password,
  }) async {
    final response = await _service.login(email: email, password: password);
    await _storage.writeToken(response.token);
    final profile = await _service.getProfile();
    return AuthState.fromProfile(response.token, profile);
  }

  Future<AuthState> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _service.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    await _storage.writeToken(response.token);
    final profile = await _service.getProfile();
    return AuthState.fromProfile(response.token, profile);
  }

  Future<AuthState?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final profile = await _service.getProfile();
      return AuthState.fromProfile(token, profile);
    } catch (_) {
      await _storage.deleteToken();
      return null;
    }
  }

  Future<void> logout() => _storage.deleteToken();

  Future<ProfileResponse> getProfile() => _service.getProfile();

  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) =>
      _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  ref.keepAlive();
  return AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
  );
});
