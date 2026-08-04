import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/accent_palette_switcher.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/settings_tile.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/theme_mode_switcher.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/app_drawer.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/shell_navigation_scope.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.isOwnerMode});

  final bool isOwnerMode;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _customerHomeIndex = 0;
  static const _customerProfileIndex = 1;
  static const _customerBookingsIndex = 2;
  static const _customerNotificationsIndex = 3;

  static const _ownerDashboardIndex = 0;
  static const _ownerSalonsIndex = 1;
  static const _ownerBookingsIndex = 2;
  static const _ownerNotificationsIndex = 3;
  static const _ownerProfileIndex = 4;
  static const _ownerReviewsIndex = 5;

  static const _customerDrawerItems = [
    DrawerNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
      index: _customerHomeIndex,
    ),
    DrawerNavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      index: _customerProfileIndex,
    ),
    DrawerNavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Bookings',
      index: _customerBookingsIndex,
    ),
    DrawerNavItem(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      index: _customerNotificationsIndex,
    ),
    DrawerNavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: RoutePaths.customerSettings,
    ),
  ];

  static const _ownerDrawerItems = [
    DrawerNavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      index: _ownerDashboardIndex,
    ),
    DrawerNavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      index: _ownerProfileIndex,
    ),
    DrawerNavItem(
      icon: Icons.calendar_month_rounded,
      label: 'Bookings',
      index: _ownerBookingsIndex,
    ),
    DrawerNavItem(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      index: _ownerNotificationsIndex,
    ),
    DrawerNavItem(
      icon: Icons.store_rounded,
      label: 'My Salons',
      index: _ownerSalonsIndex,
    ),
    DrawerNavItem(
      icon: Icons.star_rounded,
      label: 'Reviews',
      index: _ownerReviewsIndex,
    ),
    DrawerNavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: RoutePaths.ownerSettings,
    ),
  ];

  static const _customerRoutesByIndex = {
    _customerHomeIndex: RoutePaths.customerHome,
    _customerProfileIndex: RoutePaths.customerProfile,
    _customerBookingsIndex: RoutePaths.customerBookings,
    _customerNotificationsIndex: RoutePaths.customerNotifications,
  };

  static const _ownerRoutesByIndex = {
    _ownerDashboardIndex: RoutePaths.ownerDashboard,
    _ownerSalonsIndex: RoutePaths.ownerSalons,
    _ownerBookingsIndex: RoutePaths.ownerBookings,
    _ownerNotificationsIndex: RoutePaths.ownerNotifications,
    _ownerProfileIndex: RoutePaths.ownerProfile,
    _ownerReviewsIndex: RoutePaths.ownerReviews,
  };

  Future<void> _openContact(BuildContext context) async {
    final launched = await launchEmail(
      AppConfig.supportEmail,
      subject: '${AppConfig.appName} support',
    );
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email us at ${AppConfig.supportEmail}')),
      );
    }
  }

  Future<void> _openUrl(
    BuildContext context, {
    required String url,
    required String fallbackMessage,
  }) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fallbackMessage)));
      return;
    }

    final launched = await launchWebUrl(url);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  void _onDrawerSelect(int index) {
    final route = widget.isOwnerMode
        ? _ownerRoutesByIndex[index]
        : _customerRoutesByIndex[index];
    if (route == null) return;
    context.go(route);
  }

  Map<int, int> _badgeCounts(int unreadCount, int pendingBookings) {
    if (!widget.isOwnerMode) {
      return unreadCount > 0
          ? {_customerNotificationsIndex: unreadCount}
          : const {};
    }
    final counts = <int, int>{};
    if (unreadCount > 0) counts[_ownerNotificationsIndex] = unreadCount;
    if (pendingBookings > 0) counts[_ownerBookingsIndex] = pendingBookings;
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isOwnerMode = widget.isOwnerMode;
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;
    final pendingBookings = isOwnerMode
        ? (ref.watch(ownerDashboardProvider).value?.summary.bookings.pending ??
              0)
        : 0;

    return ShellNavigationScope(
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: const PremiumAppBar(title: 'Settings'),
        drawer: AppDrawer(
          items: isOwnerMode ? _ownerDrawerItems : _customerDrawerItems,
          // No shell tab is active while Settings is open.
          selectedIndex: -1,
          onSelect: _onDrawerSelect,
          headerSubtitle: isOwnerMode ? 'Owner Portal' : 'Customer',
          isOwnerMode: isOwnerMode,
          badgeCounts: _badgeCounts(unreadCount, pendingBookings),
        ),
        body: GradientBackground(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              AppDecorations.scrollBottomPadding(context),
            ),
            children: [
              AnimatedEntrance(
                style: EntranceStyle.slideRight,
                child: GlassCard(child: const ThemeModeSwitcher()),
              ),
              const SizedBox(height: 14),
              const AnimatedEntrance(
                index: 1,
                style: EntranceStyle.slideRight,
                child: GlassCard(child: AccentPaletteSwitcher()),
              ),
              const SizedBox(height: 14),
              if (isOwnerMode) ...[
                AnimatedEntrance(
                  index: 2,
                  style: EntranceStyle.slideRight,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Business portal',
                          subtitle: 'Quick access to owner tools',
                        ),
                        const SizedBox(height: 4),
                        SettingsTile(
                          icon: Icons.store_rounded,
                          title: 'My salons',
                          onTap: () => context.go(RoutePaths.ownerSalons),
                        ),
                        SettingsTile(
                          icon: Icons.calendar_month_rounded,
                          title: 'Bookings',
                          onTap: () => context.go(RoutePaths.ownerBookings),
                        ),
                        SettingsTile(
                          icon: Icons.star_rounded,
                          title: 'Reviews',
                          onTap: () => context.go(RoutePaths.ownerReviews),
                        ),
                        SettingsTile(
                          icon: Icons.dashboard_rounded,
                          title: 'Dashboard',
                          onTap: () => context.go(RoutePaths.ownerDashboard),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              AnimatedEntrance(
                index: isOwnerMode ? 2 : 1,
                style: EntranceStyle.slideRight,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Support',
                        subtitle: 'Get help with your account',
                      ),
                      const SizedBox(height: 4),
                      SettingsTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Contact us',
                        subtitle: AppConfig.supportEmail,
                        onTap: () => _openContact(context),
                      ),
                      SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help centre',
                        subtitle: 'FAQs and booking help',
                        onTap: () => _openContact(context),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedEntrance(
                index: isOwnerMode ? 3 : 2,
                style: EntranceStyle.slideRight,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Legal',
                        subtitle: 'Policies and terms',
                      ),
                      const SizedBox(height: 4),
                      SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy policy',
                        onTap: () => _openUrl(
                          context,
                          url: AppConfig.privacyPolicyUrl,
                          fallbackMessage: 'Privacy policy coming soon',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of service',
                        onTap: () => _openUrl(
                          context,
                          url: AppConfig.termsOfServiceUrl,
                          fallbackMessage: 'Terms of service coming soon',
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedEntrance(
                index: isOwnerMode ? 4 : 3,
                style: EntranceStyle.slideRight,
                child: GlassCard(
                  child: SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    subtitle:
                        '${AppConfig.appName} v${AppConfig.appVersion}${isOwnerMode ? ' · Owner' : ''}',
                    showDivider: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
