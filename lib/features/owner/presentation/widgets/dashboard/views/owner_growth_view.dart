import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_layout.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_metric_tile.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_performance_charts.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

/// Performance view: demand trends, reputation, customers and service mix.
class OwnerGrowthView extends StatelessWidget {
  const OwnerGrowthView({
    super.key,
    required this.dashboard,
    required this.scrollPadding,
  });

  final OwnerDashboardV2Model dashboard;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.summary;
    final performance = dashboard.performance;
    final currency = dashboard.meta.currency;
    final showPerSalon = dashboard.meta.salonCount > 1;
    final hasPremium =
        summary.premiumBookingsCount > 0 ||
        dashboard.premiumTodayCount > 0 ||
        dashboard.premiumUnpaidCount > 0;

    var index = 0;

    return ListView(
      padding: scrollPadding,
      children: [
        AnimatedEntrance(
          index: index++,
          child: OwnerBookingTrendChart(performance: performance),
        ),
        kOwnerSectionSpacer,
        AnimatedEntrance(
          index: index++,
          child: _ReputationCard(reputation: summary.reputation),
        ),
        kOwnerSectionSpacer,
        AnimatedEntrance(
          index: index++,
          child: _CustomerMixCard(customers: performance.customers),
        ),
        if (performance.topServices.isNotEmpty) ...[
          kOwnerSectionSpacer,
          AnimatedEntrance(
            index: index++,
            child: _TopServicesCard(
              services: performance.topServices,
              currency: currency,
            ),
          ),
        ],
        if (hasPremium) ...[
          kOwnerSectionSpacer,
          AnimatedEntrance(
            index: index++,
            child: _PremiumPerformanceCard(
              activeCount: summary.premiumBookingsCount,
              todayCount: dashboard.premiumTodayCount,
              unpaidCount: dashboard.premiumUnpaidCount,
            ),
          ),
        ],
        if (showPerSalon && summary.bySalon.isNotEmpty) ...[
          kOwnerSectionSpacer,
          AnimatedEntrance(
            index: index++,
            child: _BySalonCard(salons: summary.bySalon),
          ),
        ],
      ],
    );
  }
}

class _ReputationCard extends StatelessWidget {
  const _ReputationCard({required this.reputation});

  final OwnerDashboardReputationSummary reputation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;
    final rating = reputation.averageRating;
    final hasRating = rating != null && reputation.reviewCount > 0;

    return GlassCard(
      onTap: () => context.go(RoutePaths.ownerReviews),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: AppColors.starGold),
              const SizedBox(width: 8),
              Text(
                'Reputation',
                style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasRating)
            Text(
              'No reviews yet. Ratings appear once customers review a completed visit.',
              style: theme.bodySmall?.copyWith(color: colors.textSecondary),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: theme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StarRow(rating: rating),
                      const SizedBox(height: 2),
                      Text(
                        '${reputation.reviewCount} review'
                        '${reputation.reviewCount == 1 ? '' : 's'}',
                        style: theme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.starGold;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Icon(
            rating >= star
                ? Icons.star_rounded
                : (rating >= star - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: 14,
            color: accent,
          ),
      ],
    );
  }
}

class _CustomerMixCard extends StatelessWidget {
  const _CustomerMixCard({required this.customers});

  final OwnerDashboardCustomers customers;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;
    final total = customers.totalActive;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                'Customers',
                style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Text(
              'No customer activity in this period yet.',
              style: theme.bodySmall?.copyWith(color: colors.textSecondary),
            )
          else ...[
            _NewReturningBar(
              newCount: customers.newCustomers,
              returningCount: customers.returning,
            ),
            const SizedBox(height: 14),
            OwnerMetricGroup(
              tiles: [
                OwnerMetricTile(
                  label: 'New',
                  value: '${customers.newCustomers}',
                  icon: Icons.person_add_alt_rounded,
                  tint: colors.accent,
                  caption: '${customers.newPercent.toStringAsFixed(0)}% of all',
                ),
                OwnerMetricTile(
                  label: 'Returning',
                  value: '${customers.returning}',
                  icon: Icons.replay_rounded,
                  tint: colors.primary,
                ),
                OwnerMetricTile(
                  label: 'Active',
                  value: '$total',
                  icon: Icons.people_alt_rounded,
                  tint: colors.accent,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NewReturningBar extends StatelessWidget {
  const _NewReturningBar({
    required this.newCount,
    required this.returningCount,
  });

  final int newCount;
  final int returningCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = newCount + returningCount;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (newCount > 0)
              Expanded(
                flex: newCount,
                child: ColoredBox(color: colors.accent),
              ),
            if (returningCount > 0)
              Expanded(
                flex: returningCount,
                child: ColoredBox(color: colors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopServicesCard extends StatelessWidget {
  const _TopServicesCard({required this.services, required this.currency});

  final List<OwnerDashboardTopService> services;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;
    final visible = services.take(5).toList();
    final maxCount = visible
        .map((s) => s.bookingCount)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Top services',
          subtitle: 'Your biggest earners this period',
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visible[i].serviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatMoney(visible[i].revenue, currency: currency),
                          style: theme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxCount == 0
                                  ? 0
                                  : visible[i].bookingCount / maxCount,
                              minHeight: 6,
                              backgroundColor: colors.surfaceSunken,
                              valueColor: AlwaysStoppedAnimation(colors.accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${visible[i].bookingCount}',
                          style: theme.labelSmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumPerformanceCard extends StatelessWidget {
  const _PremiumPerformanceCard({
    required this.activeCount,
    required this.todayCount,
    required this.unpaidCount,
  });

  final int activeCount;
  final int todayCount;
  final int unpaidCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                'Premium bookings',
                style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OwnerMetricGroup(
            tiles: [
              OwnerMetricTile(
                label: 'Active',
                value: '$activeCount',
                icon: Icons.bolt_rounded,
                tint: colors.accent,
              ),
              OwnerMetricTile(
                label: 'Today',
                value: '$todayCount',
                icon: Icons.today_rounded,
                tint: colors.primary,
              ),
              OwnerMetricTile(
                label: 'Unpaid',
                value: '$unpaidCount',
                icon: Icons.money_off_rounded,
                tint: unpaidCount > 0 ? AppColors.warning : colors.primary,
                onTap: unpaidCount > 0
                    ? () => context.go(RoutePaths.ownerBookings)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BySalonCard extends StatelessWidget {
  const _BySalonCard({required this.salons});

  final List<OwnerDashboardSalonSummary> salons;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'By salon',
          subtitle: "Today's load across your locations",
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              for (var i = 0; i < salons.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colors.glassBorder),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salons[i].salonName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${salons[i].todayBookings} booking'
                            '${salons[i].todayBookings == 1 ? '' : 's'} today',
                            style: theme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${salons[i].utilizationPercent.toStringAsFixed(0)}%',
                      style: theme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
