import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_layout.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_finance_card.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_metric_tile.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_performance_charts.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

/// Finance view: what came in, what is owed, and where to act on it.
class OwnerMoneyView extends StatelessWidget {
  const OwnerMoneyView({
    super.key,
    required this.dashboard,
    required this.scrollPadding,
    required this.payoutNeedsAction,
  });

  final OwnerDashboardV2Model dashboard;
  final EdgeInsets scrollPadding;
  final bool payoutNeedsAction;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.summary;
    final currency = dashboard.meta.currency;
    final periodLabel = summary.revenue.period?.label;

    return ListView(
      padding: scrollPadding,
      children: [
        AnimatedEntrance(
          index: 0,
          child: _RevenueHero(
            revenue: summary.revenue,
            bookings: summary.bookings,
            currency: currency,
          ),
        ),
        kOwnerSectionSpacer,
        AnimatedEntrance(
          index: 1,
          child: OwnerFinanceCard(
            revenue: summary.revenue,
            earnings: summary.earnings,
            currency: currency,
            compact: false,
            payoutNeedsAction: payoutNeedsAction,
            periodLabel: periodLabel == null || periodLabel.isEmpty
                ? 'Period revenue'
                : '$periodLabel revenue',
          ),
        ),
        kOwnerSectionSpacer,
        AnimatedEntrance(
          index: 2,
          child: OwnerRevenueTrendChart(
            performance: dashboard.performance,
            currency: currency,
          ),
        ),
        kOwnerSectionSpacer,
        const AnimatedEntrance(index: 3, child: _MoneyShortcuts()),
      ],
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({
    required this.revenue,
    required this.bookings,
    required this.currency,
  });

  final OwnerDashboardRevenueSummary revenue;
  final OwnerDashboardBookingsSummary bookings;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;
    final periodLabel = revenue.period?.label;
    final periodGross = revenue.periodGross;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodLabel == null || periodLabel.isEmpty
                ? 'Revenue'
                : '$periodLabel revenue',
            style: theme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(
                periodGross ?? revenue.todayGross,
                currency: currency,
              ),
              style: theme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OwnerMetricGroup(
            tiles: [
              OwnerMetricTile(
                label: 'Today',
                value: formatMoney(revenue.todayGross, currency: currency),
                icon: Icons.today_rounded,
                tint: colors.accent,
              ),
              OwnerMetricTile(
                label: 'Completed',
                value: '${bookings.completedInPeriod}',
                icon: Icons.check_circle_outline_rounded,
                tint: colors.primary,
                caption: 'this period',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyShortcuts extends StatelessWidget {
  const _MoneyShortcuts();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Manage money',
          subtitle: 'Settlements and payout details',
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ShortcutRow(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Earnings',
                subtitle: 'Balance and settlement history',
                onTap: () => context.push(RoutePaths.ownerEarnings),
              ),
              const _ShortcutDivider(),
              _ShortcutRow(
                icon: Icons.receipt_long_rounded,
                title: 'Transactions',
                subtitle: 'Every payment, newest first',
                onTap: () => context.push(RoutePaths.ownerEarningsTransactions),
              ),
              const _ShortcutDivider(),
              _ShortcutRow(
                icon: Icons.account_balance_rounded,
                title: 'Payout account',
                subtitle: 'Where settlements are sent',
                onTap: () => context.push(RoutePaths.ownerPayoutAccount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutDivider extends StatelessWidget {
  const _ShortcutDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, color: context.appColors.glassBorder),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusControl),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, size: 18, color: colors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.bodySmall?.copyWith(color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
