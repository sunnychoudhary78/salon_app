import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:saloon_booking/core/notifications/local_notification_service.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';
import 'package:saloon_booking/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final payload = NotificationPayload.fromRemoteMessage(message);
    if (!payload.hasDisplayContent) return;

    if (isBookingRelatedNotificationType(payload.type)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(bookingDataStalePrefsKey, true);
    }

    // iOS already displays APNs alerts when terminated/backgrounded. Only mirror
    // as a local notification on Android (data-only) or when there is no APNs
    // notification block.
    final shouldShowLocal =
        defaultTargetPlatform == TargetPlatform.android ||
        message.notification == null;
    if (!shouldShowLocal) return;

    final local = LocalNotificationService();
    await local.initialize(onTap: (_) {});
    await local.show(payload);
  } catch (e, st) {
    debugPrint('[fcm_background] failed to show notification: $e\n$st');
  }
}
