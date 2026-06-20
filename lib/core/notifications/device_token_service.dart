import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';

class DeviceTokenService {
  DeviceTokenService(this._dio);

  final Dio _dio;

  Future<void> register(String token) async {
    await _dio.post(
      '${AppConfig.appPrefix}/device-token',
      data: {
        'token': token,
        'platform': 'android',
      },
    );
  }

  Future<void> unregister(String token) async {
    await _dio.delete(
      '${AppConfig.appPrefix}/device-token',
      data: {'token': token},
    );
  }
}

final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService(ref.watch(dioProvider));
});
