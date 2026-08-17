import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_dashboard_appointment_ui.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_appointment_tile.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerTodayScheduleList extends ConsumerWidget {
  const OwnerTodayScheduleList({
    super.key,
    required this.appointments,
    this.skipFirst = false,
    this.maxItems = 5,
  });

  final List<OwnerDashboardAppointment> appointments;

  /// When true, skips the first appointment (shown in the Next card).
  final bool skipFirst;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = skipFirst ? appointments.skip(1).toList() : appointments;
    if (source.isEmpty) {
      if (appointments.isEmpty) return const SizedBox.shrink();
      // Only the next card exists — still show header with see-all.
      return SectionHeader(
        title: "Today's schedule",
        subtitle:
            '${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
        trailing: TextButton(
          onPressed: () {
            ref.read(ownerBookingsTodayFilterProvider.notifier).enable();
            context.go(RoutePaths.ownerBookings);
          },
          child: const Text('See all'),
        ),
      );
    }

    final visible = source.take(maxItems).toList();
    final remainingAfterPreview =
        appointments.length - (skipFirst ? 1 : 0) - visible.length;
    final hasMore =
        remainingAfterPreview > 0 || appointments.length > visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Today's schedule",
          subtitle:
              '${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
          trailing: hasMore || skipFirst
              ? TextButton(
                  onPressed: () {
                    ref
                        .read(ownerBookingsTodayFilterProvider.notifier)
                        .enable();
                    context.go(RoutePaths.ownerBookings);
                  },
                  child: const Text('See all'),
                )
              : null,
        ),
        const SizedBox(height: 8),
        ...visible.map(
          (appt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OwnerDashboardAppointmentTile(
              appointment: appt,
              onTap: () {
                final bookingId = appt.primaryBookingId;
                if (bookingId == null) return;
                openOwnerBookingFocus(ref, context, bookingId: bookingId);
              },
            ),
          ),
        ),
      ],
    );
  }
}
