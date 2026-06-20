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

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    return NotificationPayload(
      type: data['type'] as String? ?? '',
      screen: data['screen'] as String? ?? '',
      userRole: data['userRole'] as String? ?? '',
      bookingId: data['bookingId'] as String?,
      title: data['title'] as String?,
      body: data['body'] as String?,
    );
  }

  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    return NotificationPayload.fromData(message.data).copyWith(
      title: notification?.title,
      body: notification?.body,
    );
  }

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

  NotificationPayload copyWith({
    String? type,
    String? screen,
    String? userRole,
    String? bookingId,
    String? title,
    String? body,
  }) {
    return NotificationPayload(
      type: type ?? this.type,
      screen: screen ?? this.screen,
      userRole: userRole ?? this.userRole,
      bookingId: bookingId ?? this.bookingId,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}
