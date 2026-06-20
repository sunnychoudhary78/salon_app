import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';

typedef NotificationTapHandler = void Function(NotificationPayload payload);

class LocalNotificationService {
  LocalNotificationService();

  static const androidChannelId = 'catchy_bookings';
  static const androidChannelName = 'CATCHY Bookings';
  static const androidChannelDescription = 'Booking updates and reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationTapHandler? _onTap;

  Future<void> initialize({required NotificationTapHandler onTap}) async {
    _onTap = onTap;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: androidChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      _onTap?.call(NotificationPayload.fromData(map));
    } catch (_) {}
  }

  Future<void> show(NotificationPayload payload) async {
    final id = payload.bookingId?.hashCode ??
        payload.type.hashCode ^
            DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _plugin.show(
      id: id.abs().remainder(100000),
      title: payload.title ?? 'CATCHY',
      body: payload.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(payload.toDataMap()),
    );
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Navigation is handled when the app resumes via getInitialMessage /
  // onDidReceiveNotificationResponse in the foreground isolate.
}
