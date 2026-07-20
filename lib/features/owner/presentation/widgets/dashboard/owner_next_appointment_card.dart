import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/premium_chip.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';

class OwnerNextAppointmentCard extends StatelessWidget {
  const OwnerNextAppointmentCard({
    super.key,
    required this.appointment,
  });

  final OwnerDashboardAppointment? appointment;

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, color: context.appColors.textMuted),
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

    final colors = context.appColors;
    final time = _formatTime(appointment!.bookingTime);
    final customer = appointment!.customer?.name ?? 'Guest';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  appointment!.serviceSummary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (appointment!.hasPremiumService) ...[
            const SizedBox(width: 6),
            const PremiumChip(compact: true),
          ],
          if (appointment!.premiumPaymentStatus != null) ...[
            const SizedBox(width: 4),
            StatusBadge(status: appointment!.premiumPaymentStatus!),
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
