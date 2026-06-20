import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/shared/widgets/app_drawer.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/shell_navigation_scope.dart';

class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  static const _items = [
    DrawerNavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      index: 0,
    ),
    DrawerNavItem(icon: Icons.person_rounded, label: 'Profile', index: 1),
    DrawerNavItem(icon: Icons.store_rounded, label: 'My Salons', index: 2),
    DrawerNavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Bookings',
      index: 3,
    ),
    DrawerNavItem(icon: Icons.star_rounded, label: 'Reviews', index: 4),
    DrawerNavItem(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      index: 5,
    ),
  ];

  static const _notificationsIndex = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(
        items: _items,
        selectedIndex: navigationShell.currentIndex,
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
            child: navigationShell,
          ),
        ),
      ),
    );
  }
}
