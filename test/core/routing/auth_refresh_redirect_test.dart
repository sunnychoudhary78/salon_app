import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/routing/app_router.dart';
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
    roles: [RoleModel(id: 'r2', name: 'SALON_OWNER')],
  );
  const adminUser = UserModel(
    id: 'u1',
    name: 'Ada',
    roles: [RoleModel(id: 'r3', name: 'ADMIN')],
  );

  const customer = AuthState(token: 't', user: customerUser);
  const customerRenamed = AuthState(
    token: 't',
    user: UserModel(
      id: 'u1',
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      roles: [RoleModel(id: 'r1', name: 'CUSTOMER')],
    ),
  );
  const owner = AuthState(
    token: 't',
    user: ownerUser,
    salonOwner: SalonOwnerProfileModel(id: 'o1', businessName: 'Glow'),
  );
  const incompleteOwner = AuthState(token: 't', user: ownerUser);
  const admin = AuthState(token: 't', user: adminUser);

  test('profile field updates do not require a redirect', () {
    expect(
      authChangeRequiresRedirect(
        const AsyncData(customer),
        const AsyncData(customerRenamed),
      ),
      isFalse,
    );
  });

  test('login, logout and loading changes require a redirect', () {
    expect(
      authChangeRequiresRedirect(
        const AsyncData(null),
        const AsyncData(customer),
      ),
      isTrue,
    );
    expect(
      authChangeRequiresRedirect(
        const AsyncData(customer),
        const AsyncData(null),
      ),
      isTrue,
    );
    expect(
      authChangeRequiresRedirect(
        const AsyncLoading<AuthState?>(),
        const AsyncData(customer),
      ),
      isTrue,
    );
  });

  test('owner or admin identity changes require a redirect', () {
    expect(
      authChangeRequiresRedirect(
        const AsyncData(customer),
        const AsyncData(owner),
      ),
      isTrue,
    );
    expect(
      authChangeRequiresRedirect(
        const AsyncData(customer),
        const AsyncData(admin),
      ),
      isTrue,
    );
    expect(
      authChangeRequiresRedirect(
        const AsyncData(customer),
        const AsyncData(incompleteOwner),
      ),
      isTrue,
    );
  });
}
