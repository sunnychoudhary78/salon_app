import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/shared/widgets/app_drawer.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/shell_navigation_scope.dart';

class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  DateTime? _lastBackPress;

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
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
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

  static const _items = [
    DrawerNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
    DrawerNavItem(icon: Icons.person_rounded, label: 'Profile', index: 1),
    DrawerNavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Bookings',
      index: 2,
    ),
    DrawerNavItem(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      index: 3,
    ),
  ];

  static const _notificationsIndex = 3;

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        drawer: AppDrawer(
          items: _items,
          selectedIndex: widget.navigationShell.currentIndex,
          onSelect: _onSelect,
          headerSubtitle: 'Customer',
          badgeCounts: unreadCount > 0
              ? {_notificationsIndex: unreadCount}
              : const {},
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
    );
  }
}
