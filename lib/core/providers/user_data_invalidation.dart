import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/providers/salon_browse_filters_provider.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/payments/presentation/providers/payment_provider.dart';

/// Clears cached async/notifier state tied to the signed-in user. Call before
/// logout or when [userId] changes so lists cannot flash another user's data.
void invalidateAllUserScopedData(Ref ref) {
  _invalidateAllUserScopedData(ref);
}

void invalidateAllUserScopedDataFromWidget(WidgetRef ref) {
  _invalidateAllUserScopedData(ref);
}

void _invalidateAllUserScopedData(dynamic ref) {
  final providers = [
    bannersProvider,
    favoriteSalonsProvider,
    forYouSalonsProvider,
    paginatedSalonsProvider,
    myBookingsProvider,
    premiumConfigProvider,
    notificationsProvider,
    unreadCountProvider,
    ownerDashboardProvider,
    ownerSalonsProvider,
    ownerSalonApplicationsProvider,
    ownerAllBookingsProvider,
    ownerBookingsProvider,
    ownerReviewsProvider,
    hasApprovedSalonsProvider,
    salonBrowseFiltersProvider,
    paymentActionsProvider,
    bookingActionsProvider,
    reviewActionsProvider,
    customerShellTabIndexProvider,
    ownerShellTabIndexProvider,
    pendingSignupProvider,
  ];

  for (final provider in providers) {
    try {
      ref.invalidate(provider);
    } catch (e, stack) {
      CrashReporting.recordError(
        e,
        stack,
        reason: 'invalidateAllUserScopedData: $provider',
      );
    }
  }
}

/// Invalidate user data when the signed-in user id changes (not on first load).
void invalidateOnUserIdChange(
  WidgetRef ref,
  String? previousId,
  String? nextId,
) {
  if (previousId == null || nextId == null || previousId == nextId) return;
  invalidateAllUserScopedDataFromWidget(ref);
}
