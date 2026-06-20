import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saloon_booking/core/notifications/device_token_service.dart';
import 'package:saloon_booking/core/notifications/local_notification_service.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_router.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';

const _registeredTokenKey = 'fcm_registered_token';

class NotificationService {
  NotificationService(
    this._deviceTokenService,
    this._localNotifications,
    this._router,
    this._read,
  );

  final DeviceTokenService _deviceTokenService;
  final LocalNotificationService _localNotifications;
  final NotificationRouter _router;
  final Ref _read;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  bool _initialized = false;
  bool _sessionRegistered = false;
  String? _currentToken;

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (!isAndroid || _initialized) return;
    _initialized = true;

    await _localNotifications.initialize(onTap: _router.navigate);

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onOpenedApp(initial);
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> onAuthenticated() async {
    if (!isAndroid || _sessionRegistered) return;
    await initialize();

    final granted = await _requestPermission();
    if (!granted) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _registerToken(token);
    _sessionRegistered = true;
  }

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
    }
    return true;
  }

  Future<void> _registerToken(String token) async {
    try {
      await _deviceTokenService.register(token);
      _currentToken = token;
      final prefs = await _read.read(sharedPreferencesProvider.future);
      await prefs.setString(_registeredTokenKey, token);
    } catch (_) {}
  }

  Future<void> _onTokenRefresh(String token) async {
    await _registerToken(token);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final payload = NotificationPayload.fromRemoteMessage(message);
    if (payload.title == null && payload.body == null) return;
    unawaited(_localNotifications.show(payload));
    _read.invalidate(unreadCountProvider);
    _read.invalidate(notificationsProvider);
  }

  void _onOpenedApp(RemoteMessage message) {
    _router.navigate(NotificationPayload.fromRemoteMessage(message));
    _read.invalidate(unreadCountProvider);
    _read.invalidate(notificationsProvider);
  }

  Future<void> unregisterCurrentDevice() async {
    if (!isAndroid) return;

    String? token = _currentToken;
    if (token == null || token.isEmpty) {
      final prefs = await _read.read(sharedPreferencesProvider.future);
      token = prefs.getString(_registeredTokenKey);
    }
    if (token == null || token.isEmpty) {
      token = await _messaging.getToken();
    }
    if (token == null || token.isEmpty) return;

    try {
      await _deviceTokenService.unregister(token);
    } catch (_) {}

    _currentToken = null;
    _sessionRegistered = false;
    final prefs = await _read.read(sharedPreferencesProvider.future);
    await prefs.remove(_registeredTokenKey);
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(
    ref.watch(deviceTokenServiceProvider),
    ref.watch(localNotificationServiceProvider),
    ref.watch(notificationRouterProvider),
    ref,
  );
  ref.onDispose(service.dispose);
  return service;
});
