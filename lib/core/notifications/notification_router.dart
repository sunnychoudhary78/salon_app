import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';
import 'package:saloon_booking/core/routing/app_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';

class NotificationRouter {
  NotificationRouter(this._ref);

  final Ref _ref;

  void navigate(NotificationPayload payload) {
    if (payload.bookingId != null && payload.bookingId!.isNotEmpty) {
      _ref.read(pendingNotificationTargetProvider.notifier).set(
            PendingNotificationTarget(
              bookingId: payload.bookingId!,
              type: payload.type,
            ),
          );
    }

    final router = _ref.read(appRouterProvider);
    final location = _resolveLocation(payload);
    if (location != null) {
      router.go(location);
    }
  }

  String? _resolveLocation(NotificationPayload payload) {
    switch (payload.screen) {
      case NotificationScreens.bookingDetails:
        return RoutePaths.customerBookings;
      case NotificationScreens.promotions:
        return RoutePaths.customerHome;
      case NotificationScreens.ownerBookingDetails:
        return RoutePaths.ownerBookings;
      case NotificationScreens.ownerEarnings:
        return RoutePaths.ownerDashboard;
      default:
        return _fallbackByType(payload.type, payload.userRole);
    }
  }

  String? _fallbackByType(String type, String userRole) {
    if (userRole == NotificationUserRoles.salonOwner) {
      return switch (type) {
        NotificationTypes.newBooking ||
        NotificationTypes.bookingCancelled =>
          RoutePaths.ownerBookings,
        NotificationTypes.paymentReceived => RoutePaths.ownerDashboard,
        _ => null,
      };
    }

    return switch (type) {
      NotificationTypes.bookingConfirmed ||
      NotificationTypes.appointmentReminder ||
      NotificationTypes.bookingCancelled ||
      NotificationTypes.paymentSuccessful =>
        RoutePaths.customerBookings,
      NotificationTypes.promotionalOffer => RoutePaths.customerHome,
      _ => null,
    };
  }
}

class PendingNotificationTarget {
  const PendingNotificationTarget({
    required this.bookingId,
    required this.type,
  });

  final String bookingId;
  final String type;
}

class PendingNotificationTargetNotifier extends Notifier<PendingNotificationTarget?> {
  @override
  PendingNotificationTarget? build() => null;

  void set(PendingNotificationTarget? value) => state = value;

  void clear() => state = null;
}

final pendingNotificationTargetProvider =
    NotifierProvider<PendingNotificationTargetNotifier, PendingNotificationTarget?>(
  PendingNotificationTargetNotifier.new,
);

final notificationRouterProvider = Provider<NotificationRouter>((ref) {
  return NotificationRouter(ref);
});
