import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/salon_application_status_card.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final dashboard = ref.watch(ownerDashboardProvider);
    final salons = ref.watch(ownerSalonsProvider);
    final application = auth?.salonApplication;
    final showApplicationStatus = application != null &&
        (application.isPending || application.isRejected);

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Dashboard',
        subtitle: auth?.user.name ?? 'Owner Portal',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshProfile();
          await ref.read(hasApprovedSalonsProvider.notifier).refresh();
          ref.invalidate(ownerDashboardProvider);
        },
        child: AsyncValueWidget(
          value: dashboard,
          data: (stats) => ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              AppDecorations.shellBottomInset,
            ),
            children: [
              if (showApplicationStatus) ...[
                AnimatedEntrance(
                  child: SalonApplicationStatusCard(application: application),
                ),
                const SizedBox(height: 20),
              ],
              AnimatedEntrance(
                index: showApplicationStatus ? 1 : 0,
                child: const SectionHeader(
                  title: 'Overview',
                  subtitle: 'Your business at a glance',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedEntrance(
                index: showApplicationStatus ? 2 : 1,
                child: _StatCard(
                  title: 'Salons',
                  value: stats.salonCount.toString(),
                  icon: Icons.store_rounded,
                  color: AppColors.primary,
                  isHero: true,
                ),
              ),
              salons.when(
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  final firstSalon = items.first;
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      AnimatedEntrance(
                        index: showApplicationStatus ? 3 : 2,
                        child: GlassCard(
                          onTap: () => context.push(
                            '${RoutePaths.ownerSalons}/${firstSalon.id}/services',
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.build_rounded,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manage services',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      firstSalon.salonName,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AnimatedEntrance(
                      index: showApplicationStatus ? 4 : 3,
                      child: _StatCard(
                        title: 'Pending',
                        value: stats.pendingBookings.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        compact: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedEntrance(
                      index: showApplicationStatus ? 5 : 4,
                      child: _StatCard(
                        title: 'Accepted',
                        value: stats.acceptedBookings.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        compact: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AnimatedEntrance(
                      index: showApplicationStatus ? 6 : 5,
                      child: _StatCard(
                        title: 'Completed',
                        value: stats.completedBookings.toString(),
                        icon: Icons.done_all_rounded,
                        color: AppColors.primaryLight,
                        compact: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedEntrance(
                      index: showApplicationStatus ? 7 : 6,
                      child: _StatCard(
                        title: 'Reviews',
                        value: stats.totalReviews.toString(),
                        icon: Icons.star_rounded,
                        color: AppColors.accent,
                        compact: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
    this.isHero = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(compact ? 16 : 20),
      shadowColor: color,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconBox(),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : Row(
              children: [
                _iconBox(large: true),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 36,
                                ),
                      ),
                    ],
                  ),
                ),
                if (isHero)
                  Icon(
                    Icons.trending_up_rounded,
                    color: color.withValues(alpha: 0.5),
                    size: 28,
                  ),
              ],
            ),
    );
  }

  Widget _iconBox({bool large = false}) {
    return Container(
      padding: EdgeInsets.all(large ? 14 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: large ? 28 : 22),
    );
  }
}
