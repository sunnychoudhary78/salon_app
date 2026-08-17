import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';

void main() {
  const ownerRoots = {
    RoutePaths.ownerDashboard,
    RoutePaths.ownerProfile,
    RoutePaths.ownerBookings,
  };
  const customerRoots = {
    RoutePaths.customerHome,
    RoutePaths.customerProfile,
    RoutePaths.customerBookings,
  };

  group('isNestedShellLeaf', () {
    test('rejects null, empty, and branch roots', () {
      expect(isNestedShellLeaf(null, ownerRoots), isFalse);
      expect(isNestedShellLeaf('', ownerRoots), isFalse);
      expect(isNestedShellLeaf(RoutePaths.ownerProfile, ownerRoots), isFalse);
      expect(
        isNestedShellLeaf(RoutePaths.customerHome, customerRoots),
        isFalse,
      );
    });

    test('accepts nested children of a branch root', () {
      expect(
        isNestedShellLeaf(RoutePaths.ownerEditProfile, ownerRoots),
        isTrue,
      );
      expect(
        isNestedShellLeaf(RoutePaths.customerEditProfile, customerRoots),
        isTrue,
      );
      expect(
        isNestedShellLeaf('/owner/profile/change-phone/otp', ownerRoots),
        isTrue,
      );
    });

    test('rejects paths that are not under a branch root', () {
      expect(isNestedShellLeaf('/owner/settings', ownerRoots), isFalse);
      expect(isNestedShellLeaf('/auth/login', ownerRoots), isFalse);
    });
  });

  group('resolveShellBack', () {
    test('pops only a nested leaf when the router can pop', () {
      expect(
        resolveShellBack(
          leaf: RoutePaths.ownerEditProfile,
          branchRoots: ownerRoots,
          canPop: true,
          atHomeTab: false,
        ),
        ShellBackAction.popNested,
      );
    });

    test('returns to home from a tab root even if canPop is true', () {
      expect(
        resolveShellBack(
          leaf: RoutePaths.ownerProfile,
          branchRoots: ownerRoots,
          canPop: true,
          atHomeTab: false,
        ),
        ShellBackAction.goHome,
      );
      expect(
        resolveShellBack(
          leaf: RoutePaths.customerProfile,
          branchRoots: customerRoots,
          canPop: true,
          atHomeTab: false,
        ),
        ShellBackAction.goHome,
      );
    });

    test('never pops when the leaf is null or unknown', () {
      expect(
        resolveShellBack(
          leaf: null,
          branchRoots: ownerRoots,
          canPop: true,
          atHomeTab: false,
        ),
        ShellBackAction.goHome,
      );
      expect(
        resolveShellBack(
          leaf: '/owner/settings',
          branchRoots: ownerRoots,
          canPop: true,
          atHomeTab: false,
        ),
        ShellBackAction.goHome,
      );
    });

    test('double-back exit only on the home tab', () {
      expect(
        resolveShellBack(
          leaf: RoutePaths.ownerDashboard,
          branchRoots: ownerRoots,
          canPop: true,
          atHomeTab: true,
        ),
        ShellBackAction.doubleBackExit,
      );
    });
  });
}
