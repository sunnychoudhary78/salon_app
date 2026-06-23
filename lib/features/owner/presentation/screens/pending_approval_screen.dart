import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  Future<void> _checkStatus(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).refreshProfile();
    final approved =
        await ref.read(hasApprovedSalonsProvider.notifier).refresh();
    if (!context.mounted) return;
    if (approved) {
      context.go(RoutePaths.ownerDashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still pending approval')),
      );
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
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _checkStatus(context, ref),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    GlassCard(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warning.withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              size: 48,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Under review',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            application != null
                                ? 'Your application for "${application.salonName}" is pending admin approval.'
                                : 'Your salon application is pending admin approval.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application timeline',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 16),
                          const _TimelineStep(
                            title: 'Application submitted',
                            done: true,
                            isLast: false,
                          ),
                          const _TimelineStep(
                            title: 'Admin review',
                            done: false,
                            active: true,
                            isLast: false,
                          ),
                          const _TimelineStep(
                            title: 'Salon goes live',
                            done: false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PremiumButton(
                      label: 'Check status',
                      variant: PremiumButtonVariant.accent,
                      onPressed: () => _checkStatus(context, ref),
                    ),
                    const SizedBox(height: 12),
                    PremiumButton(
                      label: 'Back to dashboard',
                      variant: PremiumButtonVariant.ghost,
                      onPressed: () => context.go(RoutePaths.ownerDashboard),
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
  });

  final String title;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.success
        : active
            ? AppColors.warning
            : AppColors.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? Icon(Icons.check_rounded, size: 14, color: color)
                    : active
                        ? Icon(Icons.more_horiz_rounded, size: 14, color: color)
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.glassBorder,
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
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
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
