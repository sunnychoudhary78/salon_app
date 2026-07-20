import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/session_expired_notifier.dart';
import 'package:saloon_booking/core/network/unauthorized_trigger.dart';
import 'package:saloon_booking/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;
  bool _handlingUnauthorized = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _ref.read(secureStorageProvider).readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      if (_handlingUnauthorized) {
        handler.next(err);
        return;
      }

      final token = await _ref.read(secureStorageProvider).readToken();
      if (token == null || token.isEmpty) {
        handler.next(err);
        return;
      }

      _handlingUnauthorized = true;
      try {
        await _ref.read(secureStorageProvider).deleteToken();
        _ref.read(sessionExpiredProvider.notifier).notify();
        _ref.read(unauthorizedTriggerProvider.notifier).trigger();
      } finally {
        _handlingUnauthorized = false;
      }
    }
    handler.next(err);
  }
}
