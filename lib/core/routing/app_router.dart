import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/unauthorized_trigger.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
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
import 'package:saloon_booking/features/customer/presentation/screens/customer_shell.dart';
import 'package:saloon_booking/features/customer/presentation/screens/salon_detail_screen.dart';
import 'package:saloon_booking/features/customer/presentation/screens/write_review_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/edit_salon_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/salon_owner_wizard_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/manage_services_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_slot_schedule_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_bookings_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_dashboard_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_reviews_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_salons_screen.dart';
import 'package:saloon_booking/features/owner/presentation/screens/owner_shell.dart';
import 'package:saloon_booking/features/owner/presentation/screens/pending_approval_screen.dart';
import 'package:saloon_booking/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:saloon_booking/features/profile/presentation/screens/change_password_screen.dart';
import 'package:saloon_booking/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:saloon_booking/features/profile/presentation/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final authNotifier = _AuthRefreshNotifier(ref);

  ref.listen(authProvider, (_, __) => authNotifier.notify());
  ref.listen(hasApprovedSalonsProvider, (_, __) => authNotifier.notify());
  ref.listen(unauthorizedTriggerProvider, (_, __) => authNotifier.notify());
  ref.listen(onboardingCompletedProvider, (_, __) => authNotifier.notify());

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final onboarding = ref.read(onboardingCompletedProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final isSplash = location == RoutePaths.splash;
      final isOnboarding = location == RoutePaths.onboarding;

      if (auth.isLoading || onboarding.isLoading) {
        return isSplash ? null : RoutePaths.splash;
      }

      final authState = auth.value;
      final isLoggedIn = authState != null;

      if (!isLoggedIn) {
        final hasSeenOnboarding = onboarding.value ?? false;
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
        return _homeForUser(authState);
      }

      if (isSalonOwnerAccount(authState) &&
          location.startsWith('/customer/')) {
        return RoutePaths.ownerDashboard;
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
        builder: (_, state) => OtpVerifyScreen(
          phone: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.completeProfile,
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        redirect: (_, __) => RoutePaths.login,
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
                    builder: (_, __) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (_, __) => const ChangePasswordScreen(),
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
                    builder: (_, state) => WriteReviewScreen(
                      bookingId: state.pathParameters['id']!,
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
        path: '${RoutePaths.customerSalons}/:id',
        builder: (_, state) => SalonDetailScreen(
          salonId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'book',
            builder: (_, state) {
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
              return BookAppointmentScreen(
                salonId: state.pathParameters['id']!,
                initialServiceIds: initialIds,
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
                    builder: (_, state) => EditSalonScreen(
                      salonId: state.pathParameters['salonId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':salonId/services',
                    builder: (_, state) => ManageServicesScreen(
                      salonId: state.pathParameters['salonId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':salonId/schedule',
                    builder: (_, state) => OwnerSlotScheduleScreen(
                      salonId: state.pathParameters['salonId']!,
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
                builder: (_, __) => const NotificationsScreen(isOwnerMode: true),
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
                    builder: (_, __) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (_, __) => const ChangePasswordScreen(),
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
        path: RoutePaths.becomeOwner,
        builder: (_, __) => const SalonOwnerWizardScreen(),
      ),
      GoRoute(
        path: RoutePaths.applySalon,
        redirect: (_, __) => RoutePaths.becomeOwner,
      ),
      GoRoute(
        path: RoutePaths.pendingApproval,
        builder: (_, __) => const PendingApprovalScreen(),
      ),
    ],
  );
});

String _homeForUser(AuthState authState) {
  if (isSalonOwnerAccount(authState)) {
    return RoutePaths.ownerDashboard;
  }
  return RoutePaths.customerHome;
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
    _ref.listen(hasApprovedSalonsProvider, (_, __) => notifyListeners());
    _ref.listen(unauthorizedTriggerProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingCompletedProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  void notify() => notifyListeners();
}
