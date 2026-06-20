import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:saloon_booking/core/notifications/local_notification_service.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final payload = NotificationPayload.fromRemoteMessage(message);
  if (payload.title == null && payload.body == null) return;

  final local = LocalNotificationService();
  await local.initialize(onTap: (_) {});
  await local.show(payload);
}
