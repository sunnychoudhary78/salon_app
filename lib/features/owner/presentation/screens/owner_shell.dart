import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/ui/system_ui_scope.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_gate_provider.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/shared/widgets/app_drawer.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_bottom_nav.dart';
import 'package:saloon_booking/shared/widgets/shell_navigation_scope.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  DateTime? _lastBackPress;
  bool _drawerOpen = false;

  static const _dashboardIndex = 0;
  static const _salonsIndex = 1;
  static const _bookingsIndex = 2;
  static const _notificationsIndex = 3;
  static const _profileIndex = 4;
  static const _reviewsIndex = 5;

  void _onSelect(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    ref.read(ownerShellTabIndexProvider.notifier).select(index);
  }

  static int _navSelectedIndex(int branchIndex) {
    const tabbed = {
      _dashboardIndex,
      _bookingsIndex,
      _salonsIndex,
      _profileIndex,
    };
    return tabbed.contains(branchIndex) ? branchIndex : -1;
  }

  static const _branchRoots = {
    RoutePaths.ownerDashboard,
    RoutePaths.ownerSalons,
    RoutePaths.ownerBookings,
    RoutePaths.ownerNotifications,
    RoutePaths.ownerProfile,
    RoutePaths.ownerReviews,
  };

  /// Nested screens pushed inside a branch (edit salon, manage services/staff,
  /// slot schedule, profile forms) carry their own bottom action bar, so the
  /// nav bar is hidden there rather than stacking two bars.
  ///
  /// Reads the leaf match rather than `RouteMatchList.uri`, which by design
  /// leaves out imperatively pushed routes — and every nested owner screen is
  /// reached with `context.push`.
  static bool _showBottomNav(GoRouterDelegate delegate) {
    final matches = delegate.currentConfiguration;
    if (matches.isEmpty) return false;
    return _branchRoots.contains(matches.last.matchedLocation);
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    final leaf = routerLeafLocation(router);
    final action = resolveShellBack(
      leaf: leaf,
      branchRoots: _branchRoots,
      canPop: router.canPop(),
      atHomeTab: widget.navigationShell.currentIndex == _dashboardIndex,
    );

    if (action == ShellBackAction.popNested) {
      router.pop();
      return;
    }
    if (action == ShellBackAction.goHome) {
      widget.navigationShell.goBranch(_dashboardIndex);
      ref.read(ownerShellTabIndexProvider.notifier).select(_dashboardIndex);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    SystemNavigator.pop();
  }

  /// Overflow destinations only — Home, Bookings, My Salons and Profile live in
  /// the bottom nav.
  static const _drawerItems = [
    DrawerNavItem(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      index: _notificationsIndex,
      section: 'Activity',
    ),
    DrawerNavItem(
      icon: Icons.star_rounded,
      label: 'Reviews',
      index: _reviewsIndex,
      section: 'Activity',
    ),
    DrawerNavItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Earnings',
      route: RoutePaths.ownerEarnings,
      section: 'Business',
    ),
    DrawerNavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: RoutePaths.ownerSettings,
      section: 'Account',
    ),
  ];

  Map<int, int> _badgeCounts(int unreadCount) {
    if (unreadCount <= 0) return const {};
    return {_notificationsIndex: unreadCount};
  }

  List<PremiumBottomNavItem> _navItems(int pendingBookings) => [
    const PremiumBottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      index: _dashboardIndex,
    ),
    PremiumBottomNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Bookings',
      index: _bookingsIndex,
      badgeCount: pendingBookings,
    ),
    const PremiumBottomNavItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'My Salons',
      index: _salonsIndex,
    ),
    const PremiumBottomNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      index: _profileIndex,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;
    // The gate keeps a live PENDING queue for the whole owner session, so the
    // nav badge stays accurate on every tab without an extra fetch.
    final pendingBookings = ref.watch(pendingBookingGateProvider).queue.length;
    // Dashboard and payout data are only needed inside the drawer. Avoid
    // fetching and parsing both on every owner tab just to build the shell.
    final dashboard = _drawerOpen
        ? ref.watch(ownerDashboardProvider).value
        : null;
    final payoutAccount = _drawerOpen
        ? ref.watch(ownerPayoutAccountProvider).value
        : null;
    final profilePercent =
        dashboard?.summary.profileCompleteness.averagePercent ?? 100;
    final attentionHint = _drawerOpen
        ? buildOwnerSetupHint(
            payoutAccount: payoutAccount,
            profilePercent: profilePercent,
          )
        : null;
    final currentIndex = widget.navigationShell.currentIndex;

    final publishedTab = ref.read(ownerShellTabIndexProvider);
    if (publishedTab != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(ownerShellTabIndexProvider.notifier).select(currentIndex);
      });
    }

    // The shell does not rebuild when a route is pushed inside a branch, so the
    // nav bar visibility tracks the router delegate directly. It has to drive
    // the whole Scaffold: an empty `bottomNavigationBar` would still make
    // Scaffold strip the body's bottom inset from nested screens.
    final routerDelegate = GoRouter.of(context).routerDelegate;

    return SystemUiScope(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBack(context);
        },
        child: AnimatedBuilder(
          animation: routerDelegate,
          builder: (context, _) => Scaffold(
            onDrawerChanged: (isOpened) {
              if (_drawerOpen != isOpened) {
                setState(() => _drawerOpen = isOpened);
              }
            },
            drawer: AppDrawer(
              items: _drawerItems,
              selectedIndex: currentIndex,
              onSelect: _onSelect,
              headerSubtitle: 'Owner',
              isOwnerMode: true,
              badgeCounts: _badgeCounts(unreadCount),
              attentionHint: attentionHint,
              onAttentionHintTap: attentionHint != null
                  ? () => _onSelect(_dashboardIndex)
                  : null,
            ),
            body: GradientBackground(
              child: Builder(
                builder: (context) => ShellNavigationScope(
                  openDrawer: () => Scaffold.of(context).openDrawer(),
                  child: widget.navigationShell,
                ),
              ),
            ),
            bottomNavigationBar: _showBottomNav(routerDelegate)
                ? PremiumBottomNav(
                    items: _navItems(pendingBookings),
                    // Notifications and Reviews are drawer destinations with no
                    // tab, so nothing reads as selected while they are open.
                    selectedIndex: _navSelectedIndex(currentIndex),
                    onSelect: _onSelect,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
