import 'package:dio/dio.dart';
import 'package:saloon_booking/core/network/api_exception.dart';

const _defaultFallback = 'Something went wrong. Please try again.';
const _noInternet =
    'No internet connection. Please check your network and try again.';
const _timedOut = 'Connection timed out. Please try again.';
const _cancelled = 'Request was cancelled.';
const _requestFailed = 'Request failed. Please try again.';

/// Maps any caught error to a short, user-safe message for UI display.
String userFacingErrorMessage(
  Object error, {
  String fallback = _defaultFallback,
}) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _timedOut;
      case DioExceptionType.connectionError:
        return _noInternet;
      case DioExceptionType.cancel:
        return _cancelled;
      case DioExceptionType.badCertificate:
        return fallback;
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return _safeMessage(_apiMessageFromDio(error), fallback);
    }
  }

  if (error is ApiException) {
    return _safeMessage(error.message, fallback);
  }

  return fallback;
}

/// Short message used when Dio has no response body to parse.
String dioTypeFallbackMessage(DioExceptionType type) {
  switch (type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return _timedOut;
    case DioExceptionType.connectionError:
      return _noInternet;
    case DioExceptionType.cancel:
      return _cancelled;
    case DioExceptionType.badCertificate:
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      return _requestFailed;
  }
}

String _apiMessageFromDio(DioException error) {
  if (error.error is ApiException) {
    return (error.error as ApiException).message;
  }
  final data = error.response?.data;
  if (data != null) {
    return ApiException.fromResponse(data, error.response?.statusCode).message;
  }
  return dioTypeFallbackMessage(error.type);
}

String _safeMessage(String? message, String fallback) {
  final text = message?.trim() ?? '';
  if (text.isEmpty) return fallback;
  if (_looksTechnical(text)) return fallback;
  return text;
}

bool _looksTechnical(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('dioexception') ||
      lower.contains('socketexception') ||
      lower.contains('httpexception') ||
      lower.contains('handshakeexception') ||
      lower.contains('clientexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('network is unreachable') ||
      lower.contains('software caused connection abort') ||
      lower.contains('xmlhttprequest') ||
      lower.contains('instance of ') ||
      lower.contains('stack trace') ||
      lower.contains('package:') ||
      lower.contains('errno =')) {
    return true;
  }

  final trimmed = message.trimLeft();
  if (trimmed.startsWith('{') ||
      trimmed.startsWith('[') ||
      trimmed.startsWith('<')) {
    return true;
  }

  if (message.length > 180) return true;

  return false;
}
