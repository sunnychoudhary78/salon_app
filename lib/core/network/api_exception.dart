class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final List<dynamic>? details;

  @override
  String toString() => message;

  static ApiException fromResponse(dynamic data, int? statusCode) {
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ?? 'Request failed';
      final details = data['details'] as List<dynamic>?;
      return ApiException(message, statusCode: statusCode, details: details);
    }
    return ApiException('Request failed', statusCode: statusCode);
  }
}
