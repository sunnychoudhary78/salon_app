import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';

const adminRoles = {
  'SUPER_ADMIN',
  'ADMIN',
  'SUPPORT_AGENT',
  'MARKETING_MANAGER',
};

const mobileRoles = {'CUSTOMER', 'SALON_OWNER'};

bool isAdminOnly(UserModel user) {
  final names = user.roles.map((r) => r.name).toSet();
  final hasMobile = names.any(mobileRoles.contains);
  final hasAdmin = names.any(adminRoles.contains);
  return hasAdmin && !hasMobile;
}

bool isSalonOwner(UserModel user) =>
    user.roles.any((r) => r.name == 'SALON_OWNER');

bool isCustomer(UserModel user) => user.roles.any((r) => r.name == 'CUSTOMER');

bool isSalonOwnerAccount(AuthState auth) => auth.salonOwner != null;

/// Chose salon owner at signup but has not created the owner profile yet.
bool needsOwnerOnboarding(AuthState auth) =>
    isSalonOwner(auth.user) && auth.salonOwner == null;

String homePathForUser(AuthState auth) {
  if (needsOwnerOnboarding(auth)) return RoutePaths.becomeOwner;
  if (isSalonOwnerAccount(auth)) return RoutePaths.ownerDashboard;
  return RoutePaths.customerHome;
}

bool isApprovedSalonOwner(AuthState auth, {required bool hasApprovedSalons}) =>
    isSalonOwner(auth.user) && auth.salonOwner != null && hasApprovedSalons;

bool hasPendingSalonApplication(AuthState auth) =>
    auth.salonApplication?.isPending ?? false;

bool isOwnerShellRoute(String location) {
  const onboarding = [
    RoutePaths.becomeOwner,
    RoutePaths.applySalon,
    RoutePaths.pendingApproval,
  ];
  if (!location.startsWith('/owner')) return false;
  return !onboarding.any(
    (path) => location == path || location.startsWith('$path/'),
  );
}
