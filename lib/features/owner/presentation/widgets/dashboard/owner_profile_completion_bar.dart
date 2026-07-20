import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_profile_completion_nav.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class OwnerProfileCompletionBar extends StatelessWidget {
  const OwnerProfileCompletionBar({
    super.key,
    required this.profileCompleteness,
    this.hideAboveFoldCta = true,
  });

  final OwnerDashboardProfileCompleteness profileCompleteness;
  final bool hideAboveFoldCta;

  @override
  Widget build(BuildContext context) {
    final percent = profileCompleteness.averagePercent;
    if (percent >= 100) return const SizedBox.shrink();

    final colors = context.appColors;
    final showCta = percent < 90;
    final showBarOnly = percent >= 90 && hideAboveFoldCta;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile Completion',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (profileCompleteness.incompleteCount > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${profileCompleteness.incompleteCount} salons need attention',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
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
          if (showCta && !showBarOnly) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => _onCompleteProfile(context),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Complete Profile'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onCompleteProfile(BuildContext context) {
    navigateToProfileCompletenessGap(context, profileCompleteness);
  }
}
