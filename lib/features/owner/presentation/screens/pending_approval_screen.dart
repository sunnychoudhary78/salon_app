import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/utils/platform_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  Future<void> _checkStatus(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).refreshProfile();
    final approved = await ref
        .read(hasApprovedSalonsProvider.notifier)
        .refresh();
    if (!context.mounted) return;
    if (approved) {
      context.go(RoutePaths.ownerDashboard);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Still pending approval')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final application = auth?.salonApplication;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            PremiumAppBar(
              title: 'Application status',
              showMenu: false,
              leading: IconButton(
                icon: Icon(platformBackIcon(context)),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _checkStatus(context, ref),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    AppDecorations.scrollBottomPadding(context),
                  ),
                  children: [
                    AnimatedEntrance(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.appColors.surfaceElevated,
                              context.appColors.accentSoft,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.35),
                          ),
                          boxShadow: context.appColors.cardShadow(),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.warning.withValues(alpha: 0.25),
                                    AppColors.warning.withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.hourglass_top_rounded,
                                size: 48,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Under review',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              application != null
                                  ? 'Your application for "${application.salonName}" is pending admin approval.'
                                  : 'Your salon application is pending admin approval.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: context.appColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedEntrance(
                      index: 1,
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Application timeline',
                              subtitle: 'Track your approval progress',
                            ),
                            const SizedBox(height: 8),
                            const _TimelineStep(
                              title: 'Application submitted',
                              icon: Icons.check_circle_outline_rounded,
                              done: true,
                              isLast: false,
                            ),
                            const _TimelineStep(
                              title: 'Admin review',
                              icon: Icons.rate_review_outlined,
                              done: false,
                              active: true,
                              isLast: false,
                            ),
                            const _TimelineStep(
                              title: 'Salon goes live',
                              icon: Icons.rocket_launch_outlined,
                              done: false,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedEntrance(
                      index: 2,
                      child: PremiumButton(
                        label: 'Check status',
                        variant: PremiumButtonVariant.accent,
                        onPressed: () => _checkStatus(context, ref),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedEntrance(
                      index: 3,
                      child: PremiumButton(
                        label: 'Back to dashboard',
                        variant: PremiumButtonVariant.ghost,
                        onPressed: () => context.go(RoutePaths.ownerDashboard),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.done,
    required this.isLast,
    this.active = false,
    this.icon = Icons.circle_outlined,
  });

  final String title;
  final bool done;
  final bool active;
  final bool isLast;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.success
        : active
        ? AppColors.warning
        : context.appColors.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: done || active
                      ? LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.35),
                            color.withValues(alpha: 0.12),
                          ],
                        )
                      : null,
                  color: done || active ? null : color.withValues(alpha: 0.1),
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? Icon(Icons.check_rounded, size: 16, color: color)
                    : Icon(icon, size: 14, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: context.appColors.glassBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: active || done
                      ? context.appColors.textPrimary
                      : context.appColors.textMuted,
                  fontWeight: active ? FontWeight.w600 : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
