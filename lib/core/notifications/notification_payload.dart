import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.screen,
    required this.userRole,
    this.bookingId,
    this.title,
    this.body,
  });

  final String type;
  final String screen;
  final String userRole;
  final String? bookingId;
  final String? title;
  final String? body;

  static bool hasVisibleText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String? _firstNonEmpty(String? a, String? b) {
    if (hasVisibleText(a)) return a!.trim();
    if (hasVisibleText(b)) return b!.trim();
    return null;
  }

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    return NotificationPayload(
      type: data['type']?.toString() ?? '',
      screen: data['screen']?.toString() ?? '',
      userRole: data['userRole']?.toString() ?? '',
      bookingId: _optionalString(data['bookingId']),
      title: _optionalString(data['title']),
      body: _optionalString(data['body']),
    );
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final fromData = NotificationPayload.fromData(message.data);
    final notification = message.notification;
    return NotificationPayload(
      type: fromData.type,
      screen: fromData.screen,
      userRole: fromData.userRole,
      bookingId: fromData.bookingId,
      title: _firstNonEmpty(notification?.title, fromData.title),
      body: _firstNonEmpty(notification?.body, fromData.body),
    );
  }

  bool get hasDisplayContent => hasVisibleText(title) || hasVisibleText(body);

  Map<String, String> toDataMap() {
    return {
      'type': type,
      'screen': screen,
      'userRole': userRole,
      if (bookingId != null) 'bookingId': bookingId!,
      if (title != null) 'title': title!,
      if (body != null) 'body': body!,
    };
  }
}
