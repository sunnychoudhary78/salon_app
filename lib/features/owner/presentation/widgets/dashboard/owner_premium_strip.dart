import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class OwnerPremiumStrip extends StatelessWidget {
  const OwnerPremiumStrip({
    super.key,
    required this.activeCount,
    required this.todayCount,
    required this.unpaidCount,
  });

  final int activeCount;
  final int todayCount;
  final int unpaidCount;

  @override
  Widget build(BuildContext context) {
    if (activeCount == 0 && todayCount == 0 && unpaidCount == 0) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: context.appColors.accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Premium Bookings',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PremiumMetricChip(
                  label: 'Active',
                  value: '$activeCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PremiumMetricChip(label: 'Today', value: '$todayCount'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PremiumMetricChip(
                  label: 'Unpaid',
                  value: '$unpaidCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumMetricChip extends StatelessWidget {
  const _PremiumMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.appColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
