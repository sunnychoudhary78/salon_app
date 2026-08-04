import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_dashboard_appointment_ui.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_appointment_tile.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class OwnerNextAppointmentCard extends ConsumerWidget {
  const OwnerNextAppointmentCard({super.key, required this.appointment});

  final OwnerDashboardAppointment? appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointment == null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: context.appColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No more appointments today',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bookingId = appointment!.primaryBookingId;
    return OwnerDashboardAppointmentTile(
      appointment: appointment!,
      emphasizeNext: true,
      onTap: bookingId == null
          ? null
          : () => openOwnerBookingFocus(ref, context, bookingId: bookingId),
    );
  }
}
