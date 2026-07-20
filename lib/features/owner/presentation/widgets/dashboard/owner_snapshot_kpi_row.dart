import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';

class OwnerSnapshotKpiRow extends StatelessWidget {
  const OwnerSnapshotKpiRow({
    super.key,
    required this.bookings,
    required this.utilization,
    required this.premiumBookingsCount,
    required this.reputation,
    this.showCompletedInPeriod = false,
  });

  final OwnerDashboardBookingsSummary bookings;
  final OwnerDashboardUtilization utilization;
  final int premiumBookingsCount;
  final OwnerDashboardReputationSummary reputation;
  final bool showCompletedInPeriod;

  @override
  Widget build(BuildContext context) {
    final rating = reputation.averageRating;
    final ratingLabel = rating != null ? rating.toStringAsFixed(1) : '—';

    return Row(
      children: [
        Expanded(
          child: _KpiChip(
            label: showCompletedInPeriod ? 'Completed' : 'Today',
            value: showCompletedInPeriod
                ? '${bookings.completedInPeriod}'
                : '${bookings.today}',
            icon: showCompletedInPeriod
                ? Icons.check_circle_outline_rounded
                : Icons.calendar_today_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiChip(
            label: 'Util',
            value: '${utilization.percent.toStringAsFixed(0)}%',
            icon: Icons.speed_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiChip(
            label: 'Premium',
            value: '$premiumBookingsCount',
            icon: Icons.bolt_rounded,
            color: AppColors.accent,
            onTap: () => context.go(RoutePaths.ownerBookings),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiChip(
            label: 'Rating',
            value: ratingLabel,
            icon: Icons.star_rounded,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
