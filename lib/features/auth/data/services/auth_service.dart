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
    return OtpVerifyResult(
      isNewUser: false,
      authResponse: auth,
    );
  }

  Future<AuthResponse> completeProfile({
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
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProfileResponse> getProfile() async {
    final response = await _dio.get('${AppConfig.appPrefix}/profile');
    return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  ref.keepAlive();
  return AuthService(ref.watch(dioProvider));
});
