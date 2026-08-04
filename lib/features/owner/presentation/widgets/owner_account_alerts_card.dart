import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_profile_completion_nav.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_profile_field_labels.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class OwnerAccountAlertsCard extends ConsumerWidget {
  const OwnerAccountAlertsCard({
    super.key,
    this.profileCompleteness,
    this.showVerifiedPayout = false,
  });

  final OwnerDashboardProfileCompleteness? profileCompleteness;
  final bool showVerifiedPayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutAsync = ref.watch(ownerPayoutAccountProvider);
    final profile =
        profileCompleteness ??
        ref.watch(ownerDashboardProvider).value?.summary.profileCompleteness;

    return payoutAsync.when(
      loading: () => profile != null && profile.averagePercent < 100
          ? _ProfileSection(
              profileCompleteness: profile,
              onCompleteProfile: () => _onCompleteProfile(context, profile),
            )
          : const SizedBox.shrink(),
      error: (_, __) => _buildContent(
        context,
        payoutAccount: null,
        profileCompleteness: profile,
      ),
      data: (payout) => _buildContent(
        context,
        payoutAccount: payout,
        profileCompleteness: profile,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required OwnerPayoutAccountModel? payoutAccount,
    required OwnerDashboardProfileCompleteness? profileCompleteness,
  }) {
    final payoutStatus = resolveOwnerPayoutStatus(payoutAccount);
    final payoutNeedsAction = ownerPayoutNeedsAction(payoutAccount);
    final showProfile =
        profileCompleteness != null && profileCompleteness.averagePercent < 100;

    if (!payoutNeedsAction && !showProfile) {
      if (showVerifiedPayout && payoutStatus == OwnerPayoutStatus.verified) {
        return _VerifiedPayoutRow();
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (payoutNeedsAction)
          _PayoutAlertBanner(
            status: payoutStatus,
            onTap: () => context.push(RoutePaths.ownerPayoutAccount),
          ),
        if (payoutNeedsAction && showProfile) const SizedBox(height: 10),
        if (!payoutNeedsAction &&
            showVerifiedPayout &&
            payoutStatus == OwnerPayoutStatus.verified)
          const _VerifiedPayoutRow(),
        if (!payoutNeedsAction &&
            showVerifiedPayout &&
            payoutStatus == OwnerPayoutStatus.verified &&
            showProfile)
          const SizedBox(height: 10),
        if (showProfile)
          _ProfileSection(
            profileCompleteness: profileCompleteness,
            onCompleteProfile: () =>
                _onCompleteProfile(context, profileCompleteness),
          ),
      ],
    );
  }

  void _onCompleteProfile(
    BuildContext context,
    OwnerDashboardProfileCompleteness profileCompleteness,
  ) {
    navigateToProfileCompletenessGap(context, profileCompleteness);
  }
}

class _PayoutAlertBanner extends StatelessWidget {
  const _PayoutAlertBanner({required this.status, required this.onTap});

  final OwnerPayoutStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isRejected = status == OwnerPayoutStatus.rejected;
    final accentColor = isRejected ? AppColors.error : AppColors.warning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(
                isRejected
                    ? Icons.error_outline_rounded
                    : Icons.account_balance_outlined,
                color: accentColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payout account',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownerPayoutStatusMessage(status),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                status == OwnerPayoutStatus.missing ? 'Add' : 'Fix',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedPayoutRow extends StatelessWidget {
  const _VerifiedPayoutRow();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ownerPayoutStatusMessage(OwnerPayoutStatus.verified),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.profileCompleteness,
    required this.onCompleteProfile,
  });

  final OwnerDashboardProfileCompleteness profileCompleteness;
  final VoidCallback onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percent = profileCompleteness.averagePercent;
    final incompleteSalons = profileCompleteness.salons
        .where((s) => s.completenessPercent < 100)
        .toList();
    final missingLabels = aggregateMissingFields(
      incompleteSalons
          .map((s) => (salonName: s.salonName, missing: s.missing))
          .toList(),
    );

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Salon profile completion',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: percent < 90 ? AppColors.warning : null,
                ),
              ),
            ],
          ),
          if (profileCompleteness.incompleteCount > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${profileCompleteness.incompleteCount} salons need attention',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: colors.glassBorder,
            ),
          ),
          if (missingLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Missing',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missingLabels
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: onCompleteProfile,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Complete profile'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact payout banner for earnings and similar screens.
class OwnerPayoutStatusBanner extends ConsumerWidget {
  const OwnerPayoutStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutAsync = ref.watch(ownerPayoutAccountProvider);

    return payoutAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _PayoutAlertBanner(
        status: OwnerPayoutStatus.missing,
        onTap: () => context.push(RoutePaths.ownerPayoutAccount),
      ),
      data: (account) {
        final status = resolveOwnerPayoutStatus(account);
        if (!ownerPayoutNeedsAction(account)) return const SizedBox.shrink();
        return _PayoutAlertBanner(
          status: status,
          onTap: () => context.push(RoutePaths.ownerPayoutAccount),
        );
      },
    );
  }
}
