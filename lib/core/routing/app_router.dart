import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/splash_gate_provider.dart';
import 'package:saloon_booking/core/network/unauthorized_trigger.dart';
import 'package:saloon_booking/core/routing/app_page_transitions.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/ui/root_scaffold_messenger.dart';
import 'package:saloon_booking/core/utils/role_utils.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/auth/presentation/screens/admin_blocked_screen.dart';
import 'package:saloon_booking/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:saloon_booking/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:saloon_booking/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:saloon_booking/features/auth/presentation/screens/splash_screen.dart';
import 'package:saloon_booking/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:saloon_booking/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:saloon_booking/features/customer/presentation/screens/book_appointment_screen.dart';
import 'package:saloon_booking/features/customer/presentation/screens/customer_bookings_screen.dart';
import 'package:saloon_booking/features/customer/presentation/screens/customer_home_screen.dart';
import 'package:saloon_booking/features/beautyassistant/presentations/screen/beauty_assistant_screen.dart';
import 'package:saloon_booking/features/customer/presentation/screens/customer_shell.dart';
import 'package:saloon_booking/features/customer/presentation/screens/salon_detail_screen.dart';
import 'package:saloon_booking/features/customer/presentation/screens/write_review_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/edit_salon_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/salon_owner_wizard_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/manage_services_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/manage_staff_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_slot_schedule_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_bookings_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_dashboard_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_earnings_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_earnings_transactions_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_payout_account_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_reviews_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_salons_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_shell.dart';
import 'package:saloon_booking/features/owner/presentation/screens/pending_approval_screen.dart';
import 'package:saloon_booking/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:saloon_booking/features/profile/presentation/screens/change_phone_otp_screen.dart';
import 'package:saloon_booking/features/profile/presentation/screens/change_phone_screen.dart';
import 'package:saloon_booking/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:saloon_booking/features/profile/presentation/screens/profile_screen.dart';
import 'package:saloon_booking/features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  // _AuthRefreshNotifier already listens to these providers internally; avoid
  // duplicate listeners here (which made GoRouter re-evaluate redirects twice
  // per auth/approval/onboarding change).
  final authNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final onboarding = ref.read(onboardingCompletedProvider);
      final splashTimedOut = ref.read(splashGateProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final isSplash = location == RoutePaths.splash;
      final isOnboarding = location == RoutePaths.onboarding;

      final authLoading = auth.isLoading && !splashTimedOut;
      final onboardingLoading = onboarding.isLoading && !splashTimedOut;

      if (authLoading || onboardingLoading) {
        // Keep auth/onboarding screens visible while their local actions run.
        if (isSplash || isAuthRoute || isOnboarding) return null;
        // Stay on the current route when reloading an existing session.
        if (auth.hasValue) return null;
        return RoutePaths.splash;
      }

      final authState = splashTimedOut && auth.isLoading ? null : auth.value;
      final isLoggedIn = authState != null;

      if (!isLoggedIn) {
        final hasSeenOnboarding = splashTimedOut && onboarding.isLoading
            ? false
            : (onboarding.value ?? false);
        if (!hasSeenOnboarding && !isOnboarding) {
          return RoutePaths.onboarding;
        }
        if (isAuthRoute || isOnboarding) return null;
        return RoutePaths.login;
      }

      if (isAdminOnly(authState.user)) {
        if (location != RoutePaths.adminBlocked) return RoutePaths.adminBlocked;
        return null;
      }

      if (isAuthRoute || isSplash) {
        return homePathForUser(authState);
      }

      if (needsOwnerOnboarding(authState)) {
        if (location == RoutePaths.becomeOwner) return null;
        return RoutePaths.becomeOwner;
      }

      if (!isSalonOwner(authState.user) && location == RoutePaths.becomeOwner) {
        return RoutePaths.customerHome;
      }

      if (isSalonOwner(authState.user) && location.startsWith('/customer/')) {
        return homePathForUser(authState);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.otpVerify,
        builder: (_, state) =>
            OtpVerifyScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: RoutePaths.completeProfile,
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminBlocked,
        builder: (_, __) => const AdminBlockedScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerHome,
                builder: (_, __) => const CustomerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerProfile,
                builder: (_, __) => const ProfileScreen(isOwnerMode: false),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: fadeSlideBuilder(
                      (_, __) => const EditProfileScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'change-phone',
                    pageBuilder: fadeSlideBuilder(
                      (_, __) => const ChangePhoneScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'otp',
                        pageBuilder: (context, state) => fadeSlidePage<void>(
                          key: state.pageKey,
                          child: ChangePhoneOtpScreen(
                            phone: state.extra as String? ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerBookings,
                builder: (_, __) => const CustomerBookingsScreen(),
                routes: [
                  GoRoute(
                    path: ':id/review',
                    pageBuilder: (context, state) => fadeSlidePage<void>(
                      key: state.pageKey,
                      child: WriteReviewScreen(
                        bookingId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerNotifications,
                builder: (_, __) => const NotificationsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.customerBeautyAssistant,
        pageBuilder: fadeSlideBuilder((_, __) => const BeautyAssistantScreen()),
      ),
      GoRoute(
        path: RoutePaths.customerSettings,
        pageBuilder: fadeSlideBuilder(
          (_, __) => const SettingsScreen(isOwnerMode: false),
        ),
      ),
      GoRoute(
        path: '${RoutePaths.customerSalons}/:id',
        pageBuilder: (context, state) => fadeSlidePage<void>(
          key: state.pageKey,
          child: SalonDetailScreen(salonId: state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'book',
            pageBuilder: (context, state) {
              final query = state.uri.queryParameters;
              final initialIds = <String>{};
              final singleId = query['serviceId'];
              if (singleId != null && singleId.isNotEmpty) {
                initialIds.add(singleId);
              }
              final multipleIds = query['serviceIds'];
              if (multipleIds != null && multipleIds.isNotEmpty) {
                initialIds.addAll(
                  multipleIds.split(',').where((id) => id.isNotEmpty),
                );
              }
              return fadeSlidePage<void>(
                key: state.pageKey,
                child: BookAppointmentScreen(
                  salonId: state.pathParameters['id']!,
                  initialServiceIds: initialIds,
                  initialStaffId: query['staffId'],
                ),
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            OwnerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerDashboard,
                builder: (_, __) => const OwnerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerSalons,
                builder: (_, __) => const OwnerSalonsScreen(),
                routes: [
                  GoRoute(
                    path: ':salonId/edit',
                    pageBuilder: (context, state) => fadeSlidePage<void>(
                      key: state.pageKey,
                      child: EditSalonScreen(
                        salonId: state.pathParameters['salonId']!,
                        focusField: state.uri.queryParameters['focus'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':salonId/services',
                    pageBuilder: (context, state) => fadeSlidePage<void>(
                      key: state.pageKey,
                      child: ManageServicesScreen(
                        salonId: state.pathParameters['salonId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':salonId/staff',
                    pageBuilder: (context, state) => fadeSlidePage<void>(
                      key: state.pageKey,
                      child: ManageStaffScreen(
                        salonId: state.pathParameters['salonId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':salonId/schedule',
                    pageBuilder: (context, state) => fadeSlidePage<void>(
                      key: state.pageKey,
                      child: OwnerSlotScheduleScreen(
                        salonId: state.pathParameters['salonId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerBookings,
                builder: (_, __) => const OwnerBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerNotifications,
                builder: (_, __) =>
                    const NotificationsScreen(isOwnerMode: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerProfile,
                builder: (_, __) => const ProfileScreen(isOwnerMode: true),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: fadeSlideBuilder(
                      (_, __) => const EditProfileScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'change-phone',
                    pageBuilder: fadeSlideBuilder(
                      (_, __) => const ChangePhoneScreen(isOwnerMode: true),
                    ),
                    routes: [
                      GoRoute(
                        path: 'otp',
                        pageBuilder: (context, state) => fadeSlidePage<void>(
                          key: state.pageKey,
                          child: ChangePhoneOtpScreen(
                            phone: state.extra as String? ?? '',
                            isOwnerMode: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerReviews,
                builder: (_, __) => const OwnerReviewsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.ownerSettings,
        pageBuilder: fadeSlideBuilder(
          (_, __) => const SettingsScreen(isOwnerMode: true),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerEarnings,
        pageBuilder: fadeSlideBuilder((_, __) => const OwnerEarningsScreen()),
      ),
      GoRoute(
        path: RoutePaths.ownerEarningsTransactions,
        pageBuilder: fadeSlideBuilder(
          (_, __) => const OwnerEarningsTransactionsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.ownerPayoutAccount,
        pageBuilder: fadeSlideBuilder(
          (_, __) => const OwnerPayoutAccountScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.becomeOwner,
        pageBuilder: modalUpBuilder((_, __) => const SalonOwnerWizardScreen()),
      ),
      GoRoute(
        path: RoutePaths.applySalon,
        redirect: (_, __) => RoutePaths.becomeOwner,
      ),
      GoRoute(
        path: RoutePaths.pendingApproval,
        pageBuilder: fadeSlideBuilder((_, __) => const PendingApprovalScreen()),
      ),
    ],
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      if (previous == null || authChangeRequiresRedirect(previous, next)) {
        notifyListeners();
      }
    });
    _ref.listen(unauthorizedTriggerProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingCompletedProvider, (_, __) => notifyListeners());
    _ref.listen(splashGateProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

/// Whether an auth provider update should re-run GoRouter redirects.
///
/// Profile field edits (name, photo, email) must not rebuild the route stack;
/// login, logout, loading, and role/owner identity changes still must.
@visibleForTesting
bool authChangeRequiresRedirect(
  AsyncValue<AuthState?> previous,
  AsyncValue<AuthState?> next,
) {
  if (previous.isLoading != next.isLoading) return true;
  if (previous.hasError != next.hasError) return true;

  final prevAuth = previous.value;
  final nextAuth = next.value;
  if ((prevAuth == null) != (nextAuth == null)) return true;
  if (prevAuth == null || nextAuth == null) return false;

  if (isAdminOnly(prevAuth.user) != isAdminOnly(nextAuth.user)) return true;
  if (isSalonOwner(prevAuth.user) != isSalonOwner(nextAuth.user)) return true;
  if (isSalonOwnerAccount(prevAuth) != isSalonOwnerAccount(nextAuth)) {
    return true;
  }
  return false;
}
