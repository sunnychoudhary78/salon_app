import 'package:flutter/material.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_action_center.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_layout.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_today_hero_card.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_today_schedule_list.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/salon_application_status_card.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';

/// Operational view: what needs doing right now.
class OwnerTodayView extends StatelessWidget {
  const OwnerTodayView({
    super.key,
    required this.dashboard,
    required this.scrollPadding,
    this.application,
  });

  final OwnerDashboardV2Model dashboard;
  final EdgeInsets scrollPadding;

  /// Set only while a salon application is pending or was rejected.
  final SalonApplicationProfileModel? application;

  @override
  Widget build(BuildContext context) {
    final appointments = dashboard.schedule.appointments;
    final next = appointments.isNotEmpty ? appointments.first : null;
    final hasAttention = dashboard.attention.sections.any(
      (section) => section.count > 0 && section.items.isNotEmpty,
    );

    var index = 0;

    return ListView(
      padding: scrollPadding,
      children: [
        if (application != null) ...[
          AnimatedEntrance(
            index: index++,
            child: SalonApplicationStatusCard(application: application!),
          ),
          kOwnerSectionSpacer,
        ],
        AnimatedEntrance(
          index: index++,
          child: OwnerTodayHeroCard(
            next: next,
            bookings: dashboard.summary.bookings,
            utilization: dashboard.summary.utilization,
            showCompletedInPeriod:
                dashboard.summary.revenue.period?.key != '7d',
          ),
        ),
        if (hasAttention) ...[
          kOwnerSectionSpacer,
          AnimatedEntrance(
            index: index++,
            child: OwnerActionCenter(attention: dashboard.attention),
          ),
        ],
        if (appointments.isNotEmpty) ...[
          kOwnerSectionSpacer,
          AnimatedEntrance(
            index: index++,
            child: OwnerTodayScheduleList(
              appointments: appointments,
              skipFirst: true,
              maxItems: 8,
            ),
          ),
        ],
      ],
    );
  }
}
