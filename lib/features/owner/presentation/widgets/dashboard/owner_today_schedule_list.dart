import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/premium_chip.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerTodayScheduleList extends ConsumerWidget {
  const OwnerTodayScheduleList({
    super.key,
    required this.appointments,
    this.maxItems = 3,
  });

  final List<OwnerDashboardAppointment> appointments;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) return const SizedBox.shrink();

    final visible = appointments.take(maxItems).toList();
    final hasMore = appointments.length > maxItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Today's schedule",
          subtitle: '${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
          trailing: hasMore
              ? TextButton(
                  onPressed: () {
                    ref.read(ownerBookingsTodayFilterProvider.notifier).enable();
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
            child: _ScheduleRow(appointment: appt),
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.appointment});

  final OwnerDashboardAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final time = _formatTime(appointment.bookingTime);
    final customer = appointment.customer?.name ?? 'Guest';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  appointment.serviceSummary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (appointment.hasPremiumService) const PremiumChip(compact: true),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '—';
    final trimmed = time.length >= 5 ? time.substring(0, 5) : time;
    try {
      final parsed = DateFormat('HH:mm').parse(trimmed);
      return DateFormat.jm().format(parsed);
    } catch (_) {
      return trimmed;
    }
  }
}
