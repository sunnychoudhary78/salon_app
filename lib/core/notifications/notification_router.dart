import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';
import 'package:saloon_booking/core/routing/app_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/customer/data/services/gallery_service.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_gate_provider.dart';

class NotificationRouter {
  NotificationRouter(this._ref);

  final Ref _ref;

  void navigate(NotificationPayload payload) {
    if (payload.bookingId != null && payload.bookingId!.isNotEmpty) {
      _ref
          .read(pendingNotificationTargetProvider.notifier)
          .set(
            PendingNotificationTarget(
              bookingId: payload.bookingId!,
              type: payload.type,
              userRole: payload.userRole,
            ),
          );
    }

    if (payload.isUrgentBooking) {
      // ignore: discarded_futures
      _ref.read(pendingBookingGateProvider.notifier).refresh();
    }

    if (payload.screen == NotificationScreens.customerTransformations ||
        payload.type == NotificationTypes.transformationUploaded) {
      _ref.invalidate(myTransformationsProvider);
    }

    final router = _ref.read(appRouterProvider);
    final location = _resolveLocation(payload);
    if (location != null) {
      router.go(location);
    }
  }

  String? _resolveLocation(NotificationPayload payload) {
    if (payload.route != null && payload.route!.isNotEmpty) {
      return payload.route;
    }

    switch (payload.screen) {
      case NotificationScreens.bookingDetails:
        return RoutePaths.customerBookings;
      case NotificationScreens.promotions:
        return RoutePaths.customerHome;
      case NotificationScreens.ownerBookingDetails:
        return RoutePaths.ownerBookings;
      case NotificationScreens.ownerEarnings:
        return RoutePaths.ownerEarnings;
      case NotificationScreens.ownerDashboard:
        return RoutePaths.ownerDashboard;
      case NotificationScreens.ownerReviews:
        return RoutePaths.ownerReviews;
      case NotificationScreens.customerTransformations:
        return RoutePaths.customerTransformations;
      default:
        return _fallbackByType(payload.type, payload.userRole);
    }
  }

  String? _fallbackByType(String type, String userRole) {
    if (userRole == NotificationUserRoles.salonOwner) {
      return switch (type) {
        NotificationTypes.newBooking ||
        NotificationTypes.bookingCancelled ||
        NotificationTypes.payAtShopSelected => RoutePaths.ownerBookings,
        NotificationTypes.paymentReceived => RoutePaths.ownerEarnings,
        NotificationTypes.salonApplicationSubmitted ||
        NotificationTypes.salonApplicationApproved ||
        NotificationTypes.salonApplicationRejected => RoutePaths.ownerDashboard,
        NotificationTypes.newReview => RoutePaths.ownerReviews,
        _ => null,
      };
    }

    return switch (type) {
      NotificationTypes.bookingConfirmed ||
      NotificationTypes.bookingRejected ||
      NotificationTypes.bookingCompleted ||
      NotificationTypes.appointmentReminder ||
      NotificationTypes.bookingCancelled ||
      NotificationTypes.paymentSuccessful => RoutePaths.customerBookings,
      NotificationTypes.rewardUnlocked => RoutePaths.customerRewards,
      NotificationTypes.promotionalOffer => RoutePaths.customerHome,
      NotificationTypes.transformationUploaded => RoutePaths.customerTransformations,
      _ => null,
    };
  }
}

class PendingNotificationTarget {
  const PendingNotificationTarget({
    required this.bookingId,
    required this.type,
    this.userRole = '',
  });

  final String bookingId;
  final String type;
  final String userRole;
}

class PendingNotificationTargetNotifier
    extends Notifier<PendingNotificationTarget?> {
  @override
  PendingNotificationTarget? build() => null;

  void set(PendingNotificationTarget? value) => state = value;

  void clear() => state = null;
}

final pendingNotificationTargetProvider =
    NotifierProvider<
      PendingNotificationTargetNotifier,
      PendingNotificationTarget?
    >(PendingNotificationTargetNotifier.new);

final notificationRouterProvider = Provider<NotificationRouter>((ref) {
  return NotificationRouter(ref);
});
