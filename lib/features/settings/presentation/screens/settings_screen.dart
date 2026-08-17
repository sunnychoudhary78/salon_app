import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/features/settings/presentation/screens/legal_info_screen.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/accent_palette_switcher.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/settings_tile.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/theme_mode_switcher.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
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
        SnackBar(content: Text('Email us at ${AppConfig.supportEmail}')),
      );
    }
  }

  void _openLegal(BuildContext context, LegalInfoKind kind) {
    LegalInfoScreen.open(context, kind: kind);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Settings',
        showMenu: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                isOwnerMode
                    ? RoutePaths.ownerDashboard
                    : RoutePaths.customerHome,
              );
            }
          },
        ),
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
            if (!isOwnerMode) ...[
              const SizedBox(height: 14),
              const AnimatedEntrance(
                index: 1,
                style: EntranceStyle.slideRight,
                child: GlassCard(child: AccentPaletteSwitcher()),
              ),
            ],
            const SizedBox(height: 14),
            AnimatedEntrance(
              index: isOwnerMode ? 1 : 2,
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
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () => _openLegal(context, LegalInfoKind.help),
                    ),
                    SettingsTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Contact us',
                      subtitle: AppConfig.supportEmail,
                      onTap: () => _openContact(context),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              index: isOwnerMode ? 2 : 3,
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
                      title: 'Privacy Policy',
                      onTap: () => _openLegal(context, LegalInfoKind.privacy),
                    ),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () => _openLegal(context, LegalInfoKind.terms),
                    ),
                    SettingsTile(
                      icon: Icons.assignment_return_outlined,
                      title: 'Cancellation & Refund Policy',
                      onTap: () => _openLegal(context, LegalInfoKind.refund),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              index: isOwnerMode ? 3 : 4,
              style: EntranceStyle.slideRight,
              child: GlassCard(
                child: SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About CATCHY',
                  subtitle:
                      '${AppConfig.appName} v${AppConfig.appVersion}${isOwnerMode ? ' · Owner' : ''}',
                  onTap: () => _openLegal(context, LegalInfoKind.about),
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
