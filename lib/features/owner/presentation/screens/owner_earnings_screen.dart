import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/owner_account_alerts_card.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerEarningsScreen extends ConsumerWidget {
  const OwnerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(ownerEarningsSummaryProvider);
    final payoutAccount = ref.watch(ownerPayoutAccountProvider).value;
    final payoutNeedsAction = ownerPayoutNeedsAction(payoutAccount);
    final payoutStatus = resolveOwnerPayoutStatus(payoutAccount);

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Earnings',
        subtitle: 'Settlement overview',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownerEarningsSummaryProvider);
          ref.invalidate(ownerPayoutAccountProvider);
          await ref.read(ownerEarningsSummaryProvider.future);
        },
        child: AsyncValueWidget(
          value: summary,
          data: (data) => ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              AppDecorations.scrollBottomPadding(context),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _EarningsBucketCard(
                      label: 'Available to settle',
                      amount: data.pendingTotal,
                      color: AppColors.warning,
                      subtitle: 'Online nets minus pay-at-salon fees',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EarningsBucketCard(
                      label: 'Settled',
                      amount: data.settledTotal,
                      color: AppColors.success,
                      subtitle: 'Paid out to you',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EarningsBucketCard(
                      label: 'Collected at salon',
                      amount: data.collectedAtSalon,
                      color: AppColors.accent,
                      subtitle: 'Cash after platform margin',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EarningsBucketCard(
                      label: 'Platform fee owed',
                      amount: data.platformFeeOwed,
                      color: AppColors.error,
                      subtitle: 'Deducted from settlement',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const OwnerPayoutStatusBanner(),
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Manage',
                subtitle: 'Transactions and payout details',
              ),
              const SizedBox(height: 12),
              PremiumButton(
                label: 'View transactions',
                icon: Icons.receipt_long_outlined,
                onPressed: () => context.push(RoutePaths.ownerEarningsTransactions),
              ),
              const SizedBox(height: 10),
              PremiumButton(
                label: payoutNeedsAction
                    ? (payoutStatus == OwnerPayoutStatus.missing
                        ? 'Add payout account'
                        : 'Update payout account')
                    : 'Payout account',
                icon: Icons.account_balance_outlined,
                variant: payoutNeedsAction
                    ? PremiumButtonVariant.primary
                    : PremiumButtonVariant.ghost,
                onPressed: () => context.push(RoutePaths.ownerPayoutAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsBucketCard extends StatelessWidget {
  const _EarningsBucketCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.subtitle,
  });

  final String label;
  final double amount;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      shadowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appColors.textMuted,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
