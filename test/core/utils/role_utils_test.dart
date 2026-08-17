import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/utils/role_utils.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';

void main() {
  const customerUser = UserModel(
    id: 'u1',
    name: 'Ada',
    roles: [RoleModel(id: 'r1', name: 'CUSTOMER')],
  );
  const ownerUser = UserModel(
    id: 'u1',
    name: 'Ada',
    roles: [
      RoleModel(id: 'r1', name: 'CUSTOMER'),
      RoleModel(id: 'r2', name: 'SALON_OWNER'),
    ],
  );

  const customer = AuthState(token: 't', user: customerUser);
  const incompleteOwner = AuthState(token: 't', user: ownerUser);
  const owner = AuthState(
    token: 't',
    user: ownerUser,
    salonOwner: SalonOwnerProfileModel(id: 'o1', businessName: 'Glow'),
  );

  test('needsOwnerOnboarding is true only with SALON_OWNER and no profile', () {
    expect(needsOwnerOnboarding(customer), isFalse);
    expect(needsOwnerOnboarding(incompleteOwner), isTrue);
    expect(needsOwnerOnboarding(owner), isFalse);
  });

  test('homePathForUser sends incomplete owners to the salon wizard', () {
    expect(homePathForUser(customer), RoutePaths.customerHome);
    expect(homePathForUser(incompleteOwner), RoutePaths.becomeOwner);
    expect(homePathForUser(owner), RoutePaths.ownerDashboard);
  });
}
