import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
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
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(width: 4, color: context.appColors.accent),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Earnings',
                    style: theme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Available for settlement',
                style: theme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(earnings.pendingTotal, currency: currency),
                style: theme.headlineMedium?.copyWith(
                  color: context.appColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (payoutNeedsAction) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Set up payout account to withdraw',
                        style: theme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Online nets settle here; pay-at-salon fees reduce this balance',
                  style: theme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: colors.glassBorder),
                const SizedBox(height: 10),
                _BreakdownRow(
                  label: periodLabel,
                  value: formatMoney(revenue.displayGross, currency: currency),
                ),
                const SizedBox(height: 6),
                _BreakdownRow(
                  label: 'Online pending',
                  value: formatMoney(
                    earnings.pending + earnings.inBatch,
                    currency: currency,
                  ),
                ),
                if (earnings.platformFeeOwed > 0) ...[
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: 'Platform fee owed',
                    value:
                        '-${formatMoney(earnings.platformFeeOwed, currency: currency)}',
                  ),
                ],
                if (!compact && earnings.inBatch > 0) ...[
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: 'Processing (in batch)',
                    value: formatMoney(earnings.inBatch, currency: currency),
                  ),
                ],
                const SizedBox(height: 6),
                _BreakdownRow(
                  label: 'Settled',
                  value: formatMoney(earnings.settled, currency: currency),
                  muted: true,
                ),
                const SizedBox(height: 6),
                _BreakdownRow(
                  label: 'Collected at salon',
                  value: formatMoney(
                    earnings.collectedAtSalon,
                    currency: currency,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: muted ? colors.textSecondary : colors.textMuted,
              fontSize: muted ? 12 : null,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? colors.textSecondary : null,
            fontSize: muted ? 13 : null,
          ),
        ),
      ],
    );
  }
}
