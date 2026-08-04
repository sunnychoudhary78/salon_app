import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/ui/system_ui_scope.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/shared/widgets/app_drawer.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
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

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    if (widget.navigationShell.currentIndex != _dashboardIndex) {
      widget.navigationShell.goBranch(_dashboardIndex);
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

  static const _drawerItems = [
    DrawerNavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      index: _dashboardIndex,
    ),
    DrawerNavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      index: _profileIndex,
    ),
    DrawerNavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Bookings',
      index: _bookingsIndex,
    ),
    DrawerNavItem(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      index: _notificationsIndex,
    ),
    DrawerNavItem(
      icon: Icons.store_rounded,
      label: 'My Salons',
      index: _salonsIndex,
    ),
    DrawerNavItem(
      icon: Icons.star_rounded,
      label: 'Reviews',
      index: _reviewsIndex,
    ),
    DrawerNavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: RoutePaths.ownerSettings,
    ),
  ];

  Map<int, int> _badgeCounts(int unreadCount, int pendingBookings) {
    final counts = <int, int>{};
    if (unreadCount > 0) counts[_notificationsIndex] = unreadCount;
    if (pendingBookings > 0) counts[_bookingsIndex] = pendingBookings;
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;
    // Dashboard and payout data are only needed inside the drawer. Avoid
    // fetching and parsing both on every owner tab just to build the shell.
    final dashboard = _drawerOpen
        ? ref.watch(ownerDashboardProvider).value
        : null;
    final payoutAccount = _drawerOpen
        ? ref.watch(ownerPayoutAccountProvider).value
        : null;
    final pendingBookings = dashboard?.summary.bookings.pending ?? 0;
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

    return SystemUiScope(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBack(context);
        },
        child: Scaffold(
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
            badgeCounts: _badgeCounts(unreadCount, pendingBookings),
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
        ),
      ),
    );
  }
}
