import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
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
          ref.invalidate(ownerSalonsProvider);
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
              if (stats.pendingBookings > 0)
                AnimatedEntrance(
                  index: showApplicationStatus ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      onTap: () => context.go(RoutePaths.ownerBookings),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${stats.pendingBookings} pending request${stats.pendingBookings == 1 ? '' : 's'}',
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'Tap to review and respond',
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
                ),
              AnimatedEntrance(
                index: showApplicationStatus ? 2 : 1,
                child: const SectionHeader(
                  title: 'Overview',
                  subtitle: 'Your business at a glance',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedEntrance(
                index: showApplicationStatus ? 3 : 2,
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Salons',
                        value: stats.salonCount.toString(),
                        icon: Icons.store_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: stats.pendingBookings.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnimatedEntrance(
                index: showApplicationStatus ? 4 : 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Active',
                        value: stats.acceptedBookings.toString(),
                        icon: Icons.event_available_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Reviews',
                        value: stats.totalReviews.toString(),
                        icon: Icons.star_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              salons.when(
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      AnimatedEntrance(
                        index: showApplicationStatus ? 5 : 4,
                        child: SectionHeader(
                          title: 'Your salons',
                          subtitle: '${items.length} location${items.length == 1 ? '' : 's'}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnimatedEntrance(
                            index: (showApplicationStatus ? 6 : 5) + entry.key,
                            child: _SalonQuickActionCard(salon: entry.value),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalonQuickActionCard extends StatelessWidget {
  const _SalonQuickActionCard({required this.salon});

  final SalonModel salon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            salon.salonName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (salon.city != null) ...[
            const SizedBox(height: 4),
            Text(
              salon.city!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickChip(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => context.push(
                  '${RoutePaths.ownerSalons}/${salon.id}/edit',
                ),
              ),
              _QuickChip(
                icon: Icons.spa_outlined,
                label: 'Services',
                onTap: () => context.push(
                  '${RoutePaths.ownerSalons}/${salon.id}/services',
                ),
              ),
              _QuickChip(
                icon: Icons.schedule_rounded,
                label: 'Schedule',
                onTap: () => context.push(
                  '${RoutePaths.ownerSalons}/${salon.id}/schedule',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
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
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      shadowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
