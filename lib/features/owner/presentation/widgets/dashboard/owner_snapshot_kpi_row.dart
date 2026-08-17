import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_metric_tile.dart';

/// Operational snapshot for the Today segment. Reputation and premium counts
/// live in the Growth segment so no metric appears in two places.
class OwnerSnapshotKpiRow extends StatelessWidget {
  const OwnerSnapshotKpiRow({
    super.key,
    required this.bookings,
    required this.utilization,
    this.showCompletedInPeriod = false,
  });

  final OwnerDashboardBookingsSummary bookings;
  final OwnerDashboardUtilization utilization;

  /// When the selected period is wider than the default, the leading tile
  /// reports completed bookings for that period instead of today's count.
  final bool showCompletedInPeriod;

  @override
  Widget build(BuildContext context) {
    final slotCaption = utilization.totalSlots > 0
        ? '${utilization.occupiedSlots}/${utilization.totalSlots} slots'
        : null;

    return OwnerMetricGroup(
      tiles: [
        OwnerMetricTile(
          label: showCompletedInPeriod ? 'Completed' : 'Today',
          value: showCompletedInPeriod
              ? '${bookings.completedInPeriod}'
              : '${bookings.today}',
          icon: showCompletedInPeriod
              ? Icons.task_alt_rounded
              : Icons.wb_sunny_rounded,
          tint: context.appColors.primary,
        ),
        OwnerMetricTile(
          label: 'Upcoming',
          value: '${bookings.upcoming}',
          icon: Icons.upcoming_rounded,
          tint: context.appColors.accent,
        ),
        OwnerMetricTile(
          label: 'Utilisation',
          value: '${utilization.percent.toStringAsFixed(0)}%',
          icon: Icons.donut_large_rounded,
          tint: context.appColors.accent,
          caption: slotCaption,
        ),
      ],
    );
  }
}
