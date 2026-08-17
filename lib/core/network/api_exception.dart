class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.details,
    this.code,
    this.data,
  });

  final String message;
  final int? statusCode;
  final List<dynamic>? details;
  final String? code;
  final Map<String, dynamic>? data;

  @override
  String toString() => message;

  static ApiException fromResponse(dynamic data, int? statusCode) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final extra = _asStringKeyMap(map['data']);
      final code = map['code']?.toString() ?? extra?['code']?.toString();
      return ApiException(
        map['message']?.toString() ?? 'Request failed',
        statusCode: statusCode,
        details: map['details'] as List<dynamic>?,
        code: (code == null || code.isEmpty) ? null : code,
        data: extra,
      );
    }
    return ApiException('Request failed', statusCode: statusCode);
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
