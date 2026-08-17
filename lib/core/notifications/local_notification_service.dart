import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saloon_booking/core/notifications/notification_action_handler.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/features/owner/presentation/providers/booking_action_completed_signal.dart';

typedef NotificationTapHandler = void Function(NotificationPayload payload);

class LocalNotificationService {
  LocalNotificationService();

  static const androidChannelId = 'catchy_bookings';
  static const androidChannelName = 'CATCHY Bookings';
  static const androidChannelDescription = 'Booking updates and reminders';

  static const androidUrgentChannelId = 'catchy_urgent_bookings_v5';
  static const androidUrgentChannelName = 'CATCHY Urgent Bookings';
  static const androidUrgentChannelDescription =
      'New booking requests that need Accept or Reject';

  static const androidAcceptActionId = bookingAcceptActionId;
  static const androidRejectActionId = bookingRejectActionId;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationTapHandler? _onTap;
  bool _initialized = false;
  bool _urgentChannelHasCustomSound = true;

  Future<void> initialize({
    required NotificationTapHandler onTap,
    bool forBackgroundAction = false,
  }) async {
    if (_initialized && !forBackgroundAction) {
      _onTap = onTap;
      return;
    }
    _onTap = onTap;

    const acceptAction = AndroidNotificationAction(
      androidAcceptActionId,
      'Accept',
      showsUserInterface: true,
      cancelNotification: true,
    );
    const rejectAction = AndroidNotificationAction(
      androidRejectActionId,
      'Reject',
      showsUserInterface: true,
      cancelNotification: true,
    );

    final darwinCategories = <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        bookingRequestCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            bookingAcceptActionId,
            'Accept',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            bookingRejectActionId,
            'Reject',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),
    ];

    final initSettings = InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ),
      iOS: DarwinInitializationSettings(
        // Permission is requested only via NotificationService / FCM.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: darwinCategories,
      ),
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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
      await _createUrgentChannel(androidPlugin);
      // Accept/Reject are attached per notification in [show].
      // Keep action constants referenced for analyzer clarity.
      assert(acceptAction.id == androidAcceptActionId);
      assert(rejectAction.id == androidRejectActionId);
    }

    _initialized = true;
  }

  Future<void> _createUrgentChannel(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) return;

    final vibration = Int64List.fromList(const [
      0,
      500,
      200,
      500,
      200,
      500,
      200,
      800,
      300,
      500,
      200,
      500,
    ]);

    try {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          androidUrgentChannelId,
          androidUrgentChannelName,
          description: androidUrgentChannelDescription,
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('booking_urgent'),
          enableVibration: true,
          vibrationPattern: vibration,
        ),
      );
      _urgentChannelHasCustomSound = true;
    } catch (e, st) {
      debugPrint(
        '[local_notifications] urgent channel with sound failed: $e\n$st',
      );
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          androidUrgentChannelId,
          androidUrgentChannelName,
          description: androidUrgentChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibration,
        ),
      );
      _urgentChannelHasCustomSound = false;
    }
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    if (actionId == bookingAcceptActionId ||
        actionId == bookingRejectActionId) {
      await handleNotificationAction(response);
      notifyBookingActionCompleted();
      return;
    }

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      _onTap?.call(NotificationPayload.fromData(map));
    } catch (_) {}
  }

  /// Returns the payload of a local notification that launched the app from a
  /// terminated state, if any. Needed because data-only FCM messages are
  /// rendered as local notifications and are not surfaced by
  /// FirebaseMessaging.getInitialMessage().
  Future<NotificationPayload?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;

    final response = details.notificationResponse;
    if (response == null) return null;

    final actionId = response.actionId;
    if (actionId == bookingAcceptActionId ||
        actionId == bookingRejectActionId) {
      await handleNotificationAction(response);
      notifyBookingActionCompleted();
      return null;
    }

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return NotificationPayload.fromData(map);
    } catch (_) {
      return null;
    }
  }

  int _notificationId(NotificationPayload payload) {
    final id =
        payload.bookingGroupId?.hashCode ??
        payload.bookingId?.hashCode ??
        payload.type.hashCode ^
            DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return id.abs().remainder(100000);
  }

  Future<void> cancelByPayload(NotificationPayload payload) async {
    await _plugin.cancel(id: _notificationId(payload));
  }

  Future<void> showActionResult({
    required bool success,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: androidChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> show(NotificationPayload payload) async {
    final urgent = payload.isUrgentBooking;
    final preferCustomSound = urgent && _urgentChannelHasCustomSound;

    try {
      await _showInternal(
        payload,
        urgent: urgent,
        useCustomSound: preferCustomSound,
      );
    } catch (e, st) {
      debugPrint('[local_notifications] show failed: $e\n$st');
      if (!urgent) rethrow;
      // Keep Accept/Reject; only drop custom sound.
      try {
        await _showInternal(
          payload,
          urgent: true,
          useCustomSound: false,
        );
      } catch (fallbackError, fallbackSt) {
        debugPrint(
          '[local_notifications] urgent fallback (no custom sound) failed: '
          '$fallbackError\n$fallbackSt',
        );
        rethrow;
      }
    }
  }

  Future<void> _showInternal(
    NotificationPayload payload, {
    required bool urgent,
    bool useCustomSound = true,
  }) async {
    final id = _notificationId(payload);
    final withActions = payload.hasAcceptRejectActions;
    final playCustomSound = urgent && useCustomSound;

    final List<AndroidNotificationAction>? androidActions = withActions
        ? const <AndroidNotificationAction>[
            AndroidNotificationAction(
              androidAcceptActionId,
              'Accept',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              androidRejectActionId,
              'Reject',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ]
        : null;

    final androidDetails = urgent
        ? AndroidNotificationDetails(
            androidUrgentChannelId,
            androidUrgentChannelName,
            channelDescription: androidUrgentChannelDescription,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.message,
            playSound: true,
            sound: playCustomSound
                ? const RawResourceAndroidNotificationSound('booking_urgent')
                : null,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(const [
              0,
              500,
              200,
              500,
              200,
              500,
              200,
              800,
              300,
              500,
              200,
              500,
            ]),
            actions: androidActions,
          )
        : AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: playCustomSound ? 'booking_urgent.wav' : null,
      interruptionLevel: urgent
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
      categoryIdentifier: withActions ? bookingRequestCategoryId : null,
    );

    await _plugin.show(
      id: id,
      title: payload.title ?? 'CATCHY',
      body: payload.displayBody,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload.encode(),
    );
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Plugin callback is sync; keep isolate alive until the API call finishes.
  // ignore: discarded_futures
  _notificationTapBackground(response);
}

Future<void> _notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await handleNotificationAction(response);
}
