import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/notifications/device_token_service.dart';
import 'package:saloon_booking/core/notifications/local_notification_service.dart';
import 'package:saloon_booking/core/notifications/notification_action_handler.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_router.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';
import 'package:saloon_booking/core/ui/root_scaffold_messenger.dart';
import 'package:saloon_booking/core/utils/role_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_gate_provider.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';

const _registeredTokenKey = 'fcm_registered_token';
const notificationPermissionPrimedKey = 'notification_permission_primed';

class NotificationService with WidgetsBindingObserver {
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
  bool _authRequested = false;
  bool _observerAdded = false;
  bool _deniedSettingsHintShown = false;
  String? _currentToken;
  Future<bool>? _registrationFuture;
  DateTime? _lastRegistrationAttempt;
  Timer? _resumeRegistrationTimer;

  Timer? _refreshDebounce;
  bool _pendingNotificationList = false;
  bool _pendingMyBookings = false;
  bool _pendingOwnerBookings = false;

  bool get supportsPush => supportsMobilePush;

  String get _platformName {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<void> initialize() async {
    if (!supportsPush || _initialized) return;
    _initialized = true;

    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }

    await _localNotifications.initialize(onTap: _router.navigate);

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onOpenedApp(initial);
    } else {
      final launchPayload = await _localNotifications.getLaunchPayload();
      if (launchPayload != null) {
        _router.navigate(launchPayload);
        _read.invalidate(unreadCountProvider);
        _read.invalidate(notificationsProvider);
        _refreshBookingData(launchPayload);
      }
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<bool> onAuthenticated() {
    if (!supportsPush) return Future.value(false);
    _authRequested = true;
    if (_sessionRegistered) return Future.value(true);
    final inFlight = _registrationFuture;
    if (inFlight != null) return inFlight;

    final future = CrashReporting.measureAsync(
      'notification_registration',
      _authenticate,
      slowThreshold: const Duration(seconds: 2),
    );
    _registrationFuture = future;
    return future.whenComplete(() {
      if (identical(_registrationFuture, future)) {
        _registrationFuture = null;
        _lastRegistrationAttempt = DateTime.now();
      }
    });
  }

  Future<bool> _authenticate() async {
    await initialize();

    final granted = await ensureOsPermission();
    if (!granted) {
      if (await _isPermanentlyDenied()) {
        _maybeShowDeniedSettingsHint();
      }
      return false;
    }

    if (Platform.isIOS) {
      await _messaging.getAPNSToken();
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return false;

    final registered = await _registerToken(token);
    _sessionRegistered = registered;
    return registered;
  }

  /// Requests OS notification permission (shared by onboarding + post-login).
  Future<bool> ensureOsPermission() async {
    if (!supportsPush) return false;
    return _requestPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_flushStaleBookingDataIfNeeded());
    if (!_authRequested || _sessionRegistered) return;
    final lastAttempt = _lastRegistrationAttempt;
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < const Duration(seconds: 15)) {
      return;
    }
    _resumeRegistrationTimer?.cancel();
    _resumeRegistrationTimer = Timer(const Duration(seconds: 2), () {
      _resumeRegistrationTimer = null;
      if (_authRequested && !_sessionRegistered) {
        CrashReporting.breadcrumb('notification_registration_resume');
        unawaited(onAuthenticated());
      }
    });
  }

  /// Background FCM cannot invalidate Riverpod; it sets [bookingDataStalePrefsKey].
  Future<void> _flushStaleBookingDataIfNeeded() async {
    try {
      final prefs = await _read.read(sharedPreferencesProvider.future);
      if (prefs.getBool(bookingDataStalePrefsKey) != true) return;
      await prefs.setBool(bookingDataStalePrefsKey, false);

      _read.invalidate(unreadCountProvider);
      _read.invalidate(notificationsProvider);

      final auth = _read.read(authProvider).value;
      if (auth == null) return;

      if (isSalonOwnerAccount(auth)) {
        _read.invalidate(ownerBookingsProvider);
        _read.invalidate(ownerAllBookingsProvider);
        _read.invalidate(ownerDashboardProvider);
        _read.invalidate(ownerEarningsSummaryProvider);
        _read.invalidate(ownerEarningsTransactionsProvider);
        unawaited(_read.read(pendingBookingGateProvider.notifier).refresh());
      } else {
        _read.invalidate(myBookingsProvider);
        _read.invalidate(salonSlotsProvider);
      }
    } catch (e, st) {
      debugPrint('[notifications] stale booking flush failed: $e\n$st');
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
      }
      if (!status.isGranted) {
        return false;
      }
      // Keep FCM permission state in sync (no-op dialog on modern Android).
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      return true;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<bool> _isPermanentlyDenied() async {
    if (Platform.isAndroid) {
      return Permission.notification.isPermanentlyDenied;
    }
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.denied;
  }

  void _maybeShowDeniedSettingsHint() {
    if (_deniedSettingsHintShown) return;
    _deniedSettingsHintShown = true;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text(
          'Notifications are off. Enable them in Settings to get booking alerts.',
        ),
        action: SnackBarAction(
          label: 'Open Settings',
          onPressed: openAppSettings,
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<bool> _registerToken(String token) async {
    try {
      await _deviceTokenService.register(token, platform: _platformName);
      _currentToken = token;
      final prefs = await _read.read(sharedPreferencesProvider.future);
      await prefs.setString(_registeredTokenKey, token);
      return true;
    } catch (e) {
      debugPrint('[notifications] device token registration failed: $e');
      return false;
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final registered = await _registerToken(token);
    if (registered) _sessionRegistered = true;
  }

  void _onForegroundMessage(RemoteMessage message) {
    CrashReporting.breadcrumb('fcm_foreground');
    final payload = NotificationPayload.fromRemoteMessage(message);
    if (!payload.hasDisplayContent) return;

    final shouldShowLocal =
        Platform.isAndroid ||
        message.notification == null ||
        payload.isUrgentBooking;
    if (shouldShowLocal) {
      unawaited(_localNotifications.show(payload));
    }
    if (payload.isUrgentBooking) {
      unawaited(_read.read(pendingBookingGateProvider.notifier).refresh());
    }
    _scheduleRefresh(payload);
  }

  void _onOpenedApp(RemoteMessage message) {
    final payload = NotificationPayload.fromRemoteMessage(message);
    _router.navigate(payload);
    _read.invalidate(unreadCountProvider);
    _read.invalidate(notificationsProvider);
    _refreshBookingData(payload);
  }

  void _scheduleRefresh(NotificationPayload payload) {
    _pendingNotificationList = true;
    if (_isBookingRelated(payload.type)) {
      if (payload.userRole == NotificationUserRoles.salonOwner) {
        _pendingOwnerBookings = true;
      } else {
        _pendingMyBookings = true;
      }
    }
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 500),
      _flushPendingRefresh,
    );
  }

  void _flushPendingRefresh() {
    _read.invalidate(unreadCountProvider);

    if (_pendingNotificationList &&
        _read.read(notificationsScreenActiveProvider)) {
      _read.invalidate(notificationsProvider);
    }
    if (_pendingOwnerBookings) {
      _read.invalidate(ownerBookingsProvider);
      _read.invalidate(ownerAllBookingsProvider);
      _read.invalidate(ownerDashboardProvider);
      _read.invalidate(ownerEarningsSummaryProvider);
      _read.invalidate(ownerEarningsTransactionsProvider);
      unawaited(_read.read(pendingBookingGateProvider.notifier).refresh());
    }
    if (_pendingMyBookings) {
      _read.invalidate(myBookingsProvider);
      _read.invalidate(salonSlotsProvider);
    }

    _pendingNotificationList = false;
    _pendingMyBookings = false;
    _pendingOwnerBookings = false;
  }

  void _refreshBookingData(NotificationPayload payload) {
    if (!isBookingRelatedNotificationType(payload.type)) return;
    if (payload.userRole == NotificationUserRoles.salonOwner) {
      _read.invalidate(ownerBookingsProvider);
      _read.invalidate(ownerAllBookingsProvider);
      _read.invalidate(ownerDashboardProvider);
      _read.invalidate(ownerEarningsSummaryProvider);
      _read.invalidate(ownerEarningsTransactionsProvider);
      if (payload.isUrgentBooking) {
        unawaited(_read.read(pendingBookingGateProvider.notifier).refresh());
      }
    } else {
      _read.invalidate(myBookingsProvider);
      _read.invalidate(salonSlotsProvider);
    }
  }

  bool _isBookingRelated(String type) => isBookingRelatedNotificationType(type);

  Future<void> unregisterCurrentDevice() async {
    if (!supportsPush) return;

    const unregisterTimeout = Duration(seconds: 3);

    try {
      String? token = _currentToken;
      if (token == null || token.isEmpty) {
        final prefs = await _read
            .read(sharedPreferencesProvider.future)
            .timeout(unregisterTimeout);
        token = prefs.getString(_registeredTokenKey);
      }
      if (token == null || token.isEmpty) {
        token = await _messaging.getToken().timeout(unregisterTimeout);
      }
      if (token != null && token.isNotEmpty) {
        try {
          await _deviceTokenService
              .unregister(token)
              .timeout(unregisterTimeout);
        } catch (_) {}
      }
    } catch (_) {
      // Never block logout on FCM / prefs failures.
    }

    _currentToken = null;
    _sessionRegistered = false;
    _authRequested = false;
    _resumeRegistrationTimer?.cancel();
    _resumeRegistrationTimer = null;
    try {
      final prefs = await _read
          .read(sharedPreferencesProvider.future)
          .timeout(unregisterTimeout);
      await prefs.remove(_registeredTokenKey).timeout(unregisterTimeout);
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
    _refreshDebounce?.cancel();
    _resumeRegistrationTimer?.cancel();
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
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
