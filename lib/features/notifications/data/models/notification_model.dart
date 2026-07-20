String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  throw FormatException('Invalid date: $value');
}

Map<String, dynamic> _asDataMap(dynamic value) {
  if (value == null) return {};
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return {};
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  String? get bookingId {
    final value = data['bookingId'];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  String get screen => _asString(data['screen']);
  String get userRole => _asString(data['userRole']);

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _asString(json['id']),
      type: _asString(json['type'], fallback: 'general'),
      title: _asString(json['title']),
      body: _asString(json['body']),
      data: _asDataMap(json['data']),
      readAt: json['read_at'] != null ? _asDateTime(json['read_at']) : null,
      createdAt: _asDateTime(json['created_at']),
    );
  }
}

class NotificationsPageResult {
  const NotificationsPageResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AppNotificationModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory NotificationsPageResult.fromJson(Map<String, dynamic> json) {
    final meta = _asDataMap(json['meta']);
    final rawItems = json['data'];
    final items = <AppNotificationModel>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is! Map) continue;
        try {
          items.add(
            AppNotificationModel.fromJson(Map<String, dynamic>.from(entry)),
          );
        } catch (_) {
          // Skip malformed rows instead of failing the whole inbox.
        }
      }
    }

    return NotificationsPageResult(
      items: items,
      page: _asInt(meta['page'], fallback: 1),
      limit: _asInt(meta['limit'], fallback: 20),
      total: _asInt(meta['total']),
      totalPages: _asInt(meta['total_pages']),
    );
  }
}
