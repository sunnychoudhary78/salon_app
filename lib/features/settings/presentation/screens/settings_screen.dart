import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/settings_tile.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/theme_mode_switcher.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.isOwnerMode});

  final bool isOwnerMode;

  Future<void> _openContact(BuildContext context) async {
    final launched = await launchEmail(
      AppConfig.supportEmail,
      subject: '${AppConfig.appName} support',
    );
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email us at ${AppConfig.supportEmail}'),
        ),
      );
    }
  }

  Future<void> _openUrl(
    BuildContext context, {
    required String url,
    required String fallbackMessage,
  }) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallbackMessage)),
      );
      return;
    }

    final launched = await launchWebUrl(url);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Settings',
        showMenu: false,
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
            child: GlassCard(
              child: const ThemeModeSwitcher(),
            ),
          ),
          const SizedBox(height: 14),
          if (isOwnerMode) ...[
            AnimatedEntrance(
              index: 1,
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
    );
  }
}
