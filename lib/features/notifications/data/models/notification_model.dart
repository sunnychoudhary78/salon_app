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

  String? get bookingId => data['bookingId'] as String?;
  String get screen => data['screen'] as String? ?? '';
  String get userRole => data['userRole'] as String? ?? '';

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
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
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return NotificationsPageResult(
      items: (json['data'] as List<dynamic>? ?? [])
          .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? 0,
      totalPages: meta['total_pages'] as int? ?? 0,
    );
  }
}
