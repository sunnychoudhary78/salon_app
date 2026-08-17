import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_metric_tile.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class OwnerFinanceCard extends StatelessWidget {
  const OwnerFinanceCard({
    super.key,
    required this.revenue,
    required this.earnings,
    required this.currency,
    this.compact = true,
    this.payoutNeedsAction = false,
    this.periodLabel = "Today's revenue",
  });

  final OwnerDashboardRevenueSummary revenue;
  final OwnerDashboardEarningsSummary earnings;
  final String currency;
  final bool compact;
  final bool payoutNeedsAction;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;
    final isEmpty =
        earnings.pendingTotal == 0 &&
        earnings.settled == 0 &&
        earnings.collectedAtSalon == 0 &&
        earnings.platformFeeOwed == 0 &&
        revenue.displayGross == 0;

    return GlassCard(
      onTap: () => context.push(RoutePaths.ownerEarnings),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 18,
                color: colors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Earnings',
                style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Available for settlement',
            style: theme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(earnings.pendingTotal, currency: currency),
            style: theme.headlineMedium?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (payoutNeedsAction) ...[
            const SizedBox(height: 10),
            _PayoutWarning(),
          ],
          if (isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Online nets settle here; pay-at-salon fees reduce this balance',
              style: theme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: colors.glassBorder),
            const SizedBox(height: 12),
            OwnerMetricLine(
              label: periodLabel,
              value: formatMoney(revenue.displayGross, currency: currency),
            ),
            const SizedBox(height: 8),
            OwnerMetricLine(
              label: 'Online pending',
              value: formatMoney(
                earnings.pending + earnings.inBatch,
                currency: currency,
              ),
            ),
            if (earnings.platformFeeOwed > 0) ...[
              const SizedBox(height: 8),
              OwnerMetricLine(
                label: 'Platform fee owed',
                value:
                    '-${formatMoney(earnings.platformFeeOwed, currency: currency)}',
                valueColor: AppColors.warning,
              ),
            ],
            if (!compact && earnings.inBatch > 0) ...[
              const SizedBox(height: 8),
              OwnerMetricLine(
                label: 'Processing (in batch)',
                value: formatMoney(earnings.inBatch, currency: currency),
              ),
            ],
            const SizedBox(height: 8),
            OwnerMetricLine(
              label: 'Settled',
              value: formatMoney(earnings.settled, currency: currency),
              muted: true,
            ),
            const SizedBox(height: 8),
            OwnerMetricLine(
              label: 'Collected at salon',
              value: formatMoney(earnings.collectedAtSalon, currency: currency),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 15,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Set up your payout account to withdraw',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
