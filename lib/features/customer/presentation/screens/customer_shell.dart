import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/ui/system_ui_scope.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/utils/platform_utils.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
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

  static const _homeIndex = 0;
  static const _profileIndex = 1;
  static const _bookingsIndex = 2;
  static const _notificationsIndex = 3;

  static const _branchRoots = {
    RoutePaths.customerHome,
    RoutePaths.customerProfile,
    RoutePaths.customerBookings,
    RoutePaths.customerNotifications,
  };

  void _onSelect(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    ref.read(customerShellTabIndexProvider.notifier).select(index);
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    final leaf = routerLeafLocation(router);
    final action = resolveShellBack(
      leaf: leaf,
      branchRoots: _branchRoots,
      canPop: router.canPop(),
      atHomeTab: widget.navigationShell.currentIndex == _homeIndex,
    );

    if (action == ShellBackAction.popNested) {
      router.pop();
      return;
    }
    if (action == ShellBackAction.goHome) {
      widget.navigationShell.goBranch(_homeIndex);
      ref.read(customerShellTabIndexProvider.notifier).select(_homeIndex);
      return;
    }
    // Android-only: double-back to exit. iOS uses the home gesture.
    if (!isCupertinoPlatform(context)) {
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
  }

  static const _drawerItems = [
    DrawerNavItem(icon: Icons.home_rounded, label: 'Home', index: _homeIndex),
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
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: RoutePaths.customerSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;
    final currentIndex = widget.navigationShell.currentIndex;

    final publishedTab = ref.read(customerShellTabIndexProvider);
    if (publishedTab != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(customerShellTabIndexProvider.notifier).select(currentIndex);
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
          drawer: AppDrawer(
            items: _drawerItems,
            selectedIndex: currentIndex,
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
      ),
    );
  }
}
