import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_dashboard_appointment_ui.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/premium_chip.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';

/// Shared dense booking summary used by next + schedule rows.
class OwnerDashboardAppointmentTile extends StatelessWidget {
  const OwnerDashboardAppointmentTile({
    super.key,
    required this.appointment,
    this.emphasizeNext = false,
    this.onTap,
  });

  final OwnerDashboardAppointment appointment;
  final bool emphasizeNext;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final time = _formatTime(appointment.bookingTime);
    final customer = appointment.customer?.name ?? 'Guest';
    final phone = appointment.customer?.phone?.trim();
    final salonName = appointment.salon?.salonName?.trim();
    final bookingNumber = appointment.primaryBookingNumber;
    final paymentHint = appointment.paymentHint;
    final services = appointment.servicesDisplay;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (emphasizeNext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: 52,
              child: Text(
                time,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (appointment.bookingStatus.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      StatusBadge(status: appointment.bookingStatus),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  services.isEmpty ? 'Appointment' : services,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (salonName != null && salonName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    salonName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (bookingNumber != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '#$bookingNumber',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
                if (paymentHint != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    paymentHint,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => launchPhoneCall(phone),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (appointment.hasPremiumService) ...[
            const SizedBox(width: 6),
            const PremiumChip(compact: true),
          ],
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
