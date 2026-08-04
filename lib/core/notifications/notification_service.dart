import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/notifications/device_token_service.dart';
import 'package:saloon_booking/core/notifications/local_notification_service.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_router.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';

const _registeredTokenKey = 'fcm_registered_token';

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
  String? _currentToken;
  Future<bool>? _registrationFuture;
  DateTime? _lastRegistrationAttempt;
  Timer? _resumeRegistrationTimer;

  // Coalesce bursts of notifications into a single round of provider
  // invalidations so the UI thread is not flooded when several messages arrive
  // in quick succession.
  Timer? _refreshDebounce;
  bool _pendingNotificationList = false;
  bool _pendingMyBookings = false;
  bool _pendingOwnerBookings = false;

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (!isAndroid || _initialized) return;
    _initialized = true;

    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }

    await _localNotifications.initialize(onTap: _router.navigate);

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
    if (!isAndroid) return Future.value(false);
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

    final granted = await _requestPermission();
    if (!granted) return false;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return false;

    final registered = await _registerToken(token);
    _sessionRegistered = registered;
    return registered;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Recover from an earlier failure (e.g. user just granted notification
    // permission from system settings and returned to the app). Delay this so
    // screen-specific refreshes do not all hit platform channels at once.
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

  Future<bool> _registerToken(String token) async {
    try {
      await _deviceTokenService.register(token);
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
    unawaited(_localNotifications.show(payload));
    _scheduleRefresh(payload);
  }

  void _onOpenedApp(RemoteMessage message) {
    final payload = NotificationPayload.fromRemoteMessage(message);
    _router.navigate(payload);
    // Opening from a notification is a single, user-initiated event (no burst),
    // so refresh immediately.
    _read.invalidate(unreadCountProvider);
    _read.invalidate(notificationsProvider);
    _refreshBookingData(payload);
  }

  /// Records which providers need refreshing and (re)starts a short debounce so
  /// multiple messages collapse into one invalidation pass.
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
    // The unread badge is cheap and always relevant.
    _read.invalidate(unreadCountProvider);

    // Only refetch the (paginated) notifications list when the user is actually
    // viewing it; otherwise the badge is enough.
    if (_pendingNotificationList &&
        _read.read(notificationsScreenActiveProvider)) {
      _read.invalidate(notificationsProvider);
    }
    if (_pendingOwnerBookings) {
      _read.invalidate(ownerBookingsProvider);
      _read.invalidate(ownerAllBookingsProvider);
      _read.invalidate(ownerDashboardProvider);
    }
    if (_pendingMyBookings) {
      _read.invalidate(myBookingsProvider);
      // A booking change can free/occupy a slot, so refresh slot availability.
      _read.invalidate(salonSlotsProvider);
    }

    _pendingNotificationList = false;
    _pendingMyBookings = false;
    _pendingOwnerBookings = false;
  }

  void _refreshBookingData(NotificationPayload payload) {
    if (!_isBookingRelated(payload.type)) return;
    if (payload.userRole == NotificationUserRoles.salonOwner) {
      _read.invalidate(ownerBookingsProvider);
      _read.invalidate(ownerAllBookingsProvider);
      _read.invalidate(ownerDashboardProvider);
    } else {
      _read.invalidate(myBookingsProvider);
      _read.invalidate(salonSlotsProvider);
    }
  }

  bool _isBookingRelated(String type) {
    return type == NotificationTypes.newBooking ||
        type == NotificationTypes.bookingConfirmed ||
        type == NotificationTypes.bookingRejected ||
        type == NotificationTypes.bookingCompleted ||
        type == NotificationTypes.bookingCancelled ||
        type == NotificationTypes.appointmentReminder ||
        type == NotificationTypes.paymentSuccessful ||
        type == NotificationTypes.paymentReceived;
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
    _authRequested = false;
    _resumeRegistrationTimer?.cancel();
    _resumeRegistrationTimer = null;
    final prefs = await _read.read(sharedPreferencesProvider.future);
    await prefs.remove(_registeredTokenKey);
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
