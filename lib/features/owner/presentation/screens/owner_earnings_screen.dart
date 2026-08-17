import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/owner_account_alerts_card.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/tap_scale_wrapper.dart';

class OwnerEarningsScreen extends ConsumerWidget {
  const OwnerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(ownerEarningsSummaryProvider);
    final payoutAccount = ref.watch(ownerPayoutAccountProvider).value;
    final payoutNeedsAction = ownerPayoutNeedsAction(payoutAccount);
    final payoutStatus = resolveOwnerPayoutStatus(payoutAccount);
    final colors = context.appColors;

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Earnings',
        subtitle: 'Settlement overview',
      ),
      body: GradientBackground(
        child: RefreshIndicator(
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
                12,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              children: [
                AnimatedEntrance(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.surfaceElevated, colors.accentSoft],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.1),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available to settle',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatMoney(data.pendingTotal),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Online nets minus pay-at-salon fees',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedEntrance(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _EarningsBucketCard(
                          label: 'Settled',
                          amount: data.settledTotal,
                          color: colors.primary,
                          subtitle: 'Paid out to you',
                          icon: Icons.verified_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EarningsBucketCard(
                          label: 'At salon',
                          amount: data.collectedAtSalon,
                          color: colors.accent,
                          subtitle: 'Cash after margin',
                          icon: Icons.storefront_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedEntrance(
                  index: 2,
                  child: _EarningsBucketCard(
                    label: 'Platform fee owed',
                    amount: data.platformFeeOwed,
                    color: AppColors.warning,
                    subtitle: 'Deducted from settlement',
                    icon: Icons.percent_rounded,
                    wide: true,
                  ),
                ),
                const SizedBox(height: 20),
                const AnimatedEntrance(
                  index: 3,
                  child: OwnerPayoutStatusBanner(),
                ),
                const SizedBox(height: 20),
                const AnimatedEntrance(
                  index: 4,
                  child: SectionHeader(
                    title: 'Manage',
                    subtitle: 'Transactions and payout details',
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedEntrance(
                  index: 5,
                  child: _ManageLinkCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'View transactions',
                    subtitle: 'Full earnings history',
                    onTap: () =>
                        context.push(RoutePaths.ownerEarningsTransactions),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedEntrance(
                  index: 6,
                  child: _ManageLinkCard(
                    icon: Icons.account_balance_rounded,
                    title: payoutNeedsAction
                        ? (payoutStatus == OwnerPayoutStatus.missing
                              ? 'Add payout account'
                              : 'Update payout account')
                        : 'Payout account',
                    subtitle: payoutNeedsAction
                        ? 'Required before settlements'
                        : 'Bank details on file',
                    emphasize: payoutNeedsAction,
                    onTap: () => context.push(RoutePaths.ownerPayoutAccount),
                  ),
                ),
              ],
            ),
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
    required this.icon,
    this.wide = false,
  });

  final String label;
  final double amount;
  final Color color;
  final String subtitle;
  final IconData icon;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GlassCard(
      elevated: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(amount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: wide ? 26 : 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageLinkCard extends StatelessWidget {
  const _ManageLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasize = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TapScaleWrapper(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: emphasize ? colors.accentSoft : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: emphasize
                ? colors.accent.withValues(alpha: 0.4)
                : colors.glassBorder,
            width: emphasize ? 1.5 : 1,
          ),
          boxShadow: colors.cardShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
