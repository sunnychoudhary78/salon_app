import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
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
    DrawerNavItem(icon: Icons.store_rounded, label: 'My Salons', index: _salonsIndex),
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
    DrawerNavItem(icon: Icons.person_rounded, label: 'Profile', index: _profileIndex),
    DrawerNavItem(icon: Icons.star_rounded, label: 'Reviews', index: _reviewsIndex),
  ];

  static const _bottomNavItems = [
    PremiumBottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      index: _dashboardIndex,
    ),
    PremiumBottomNavItem(
      icon: Icons.store_outlined,
      activeIcon: Icons.store_rounded,
      label: 'Salons',
      index: _salonsIndex,
    ),
    PremiumBottomNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Bookings',
      index: _bookingsIndex,
    ),
    PremiumBottomNavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts',
      index: _notificationsIndex,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;
    final currentIndex = widget.navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        drawer: AppDrawer(
          items: _drawerItems,
          selectedIndex: currentIndex,
          onSelect: _onSelect,
          headerSubtitle: 'Owner Portal',
          isOwnerMode: true,
          badgeCounts: unreadCount > 0
              ? {_notificationsIndex: unreadCount}
              : const {},
        ),
        body: GradientBackground(
          child: Builder(
            builder: (context) => ShellNavigationScope(
              openDrawer: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDecorations.shellBottomInset,
                ),
                child: widget.navigationShell,
              ),
            ),
          ),
        ),
        bottomNavigationBar: PremiumBottomNav(
          items: _bottomNavItems,
          selectedIndex: currentIndex <= _notificationsIndex ? currentIndex : -1,
          onSelect: _onSelect,
        ),
      ),
    );
  }
}
