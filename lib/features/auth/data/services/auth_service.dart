import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';

class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  static const _mobileHeaders = {'x-client-type': 'mobile'};

  Future<void> requestOtp({required String phone}) async {
    await _dio.post(
      '${AppConfig.appPrefix}/auth/otp-request',
      data: {'phone': phone},
      options: Options(headers: _mobileHeaders),
    );
  }

  Future<OtpVerifyResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/auth/otp-verify',
      data: {'phone': phone, 'otp': otp},
      options: Options(headers: _mobileHeaders),
    );
    final data = response.data as Map<String, dynamic>;
    final isNewUser = data['isNewUser'] as bool? ?? false;

    if (isNewUser) {
      return OtpVerifyResult(
        isNewUser: true,
        signupToken: data['signupToken'] as String,
        phone: data['phone'] as String? ?? phone,
      );
    }

    final auth = AuthResponse.fromJson(data);
    final profile = await getProfileWithToken(auth.token);
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
    final response = await _dio.post(
      '${AppConfig.appPrefix}/auth/complete-profile',
      data: {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      },
      options: Options(
        headers: {
          ..._mobileHeaders,
          'Authorization': 'Bearer $signupToken',
        },
      ),
    );
    final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    final profile = await getProfileWithToken(auth.token);
    return AuthState.fromProfile(auth.token, profile);
  }

  Future<ProfileResponse> getProfileWithToken(String token) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '${AppConfig.authPrefix}/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProfileResponse> getProfile() async {
    final response = await _dio.get('${AppConfig.appPrefix}/profile');
    return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '${AppConfig.authPrefix}/change-password',
      data: {
        if (currentPassword != null && currentPassword.isNotEmpty)
          'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': newPassword,
      },
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  ref.keepAlive();
  return AuthService(ref.watch(dioProvider));
});
