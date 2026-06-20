import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/api_exception.dart';
import 'package:saloon_booking/core/network/auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  ref.keepAlive();
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-client-type': 'mobile',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        final data = error.response?.data;
        if (data != null) {
          error = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException.fromResponse(data, error.response?.statusCode),
          );
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

extension DioErrorX on DioException {
  ApiException get apiException {
    if (error is ApiException) return error as ApiException;
    final data = response?.data;
    if (data != null) {
      return ApiException.fromResponse(data, response?.statusCode);
    }
    return ApiException(message ?? 'Request failed', statusCode: response?.statusCode);
  }
}
