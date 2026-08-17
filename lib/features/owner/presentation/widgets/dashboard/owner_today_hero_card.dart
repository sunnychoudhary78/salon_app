import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_dashboard_appointment_ui.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_snapshot_kpi_row.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/premium_chip.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

/// Single "today at a glance" unit: what is coming up next plus the three
/// operational counters. Replaces the separate next-appointment card and
/// free-floating KPI row the old dashboard stacked on top of each other.
class OwnerTodayHeroCard extends ConsumerWidget {
  const OwnerTodayHeroCard({
    super.key,
    required this.next,
    required this.bookings,
    required this.utilization,
    this.showCompletedInPeriod = false,
  });

  final OwnerDashboardAppointment? next;
  final OwnerDashboardBookingsSummary bookings;
  final OwnerDashboardUtilization utilization;
  final bool showCompletedInPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointment = next;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appointment == null)
            const _NoUpcomingToday()
          else
            _NextUp(
              appointment: appointment,
              onOpen: () {
                final bookingId = appointment.primaryBookingId;
                if (bookingId == null) return;
                openOwnerBookingFocus(ref, context, bookingId: bookingId);
              },
            ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.appColors.glassBorder),
          const SizedBox(height: 14),
          OwnerSnapshotKpiRow(
            bookings: bookings,
            utilization: utilization,
            showCompletedInPeriod: showCompletedInPeriod,
          ),
        ],
      ),
    );
  }
}

class _NextUp extends StatelessWidget {
  const _NextUp({required this.appointment, required this.onOpen});

  final OwnerDashboardAppointment appointment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;
    final customer = appointment.customer?.name ?? 'Guest';
    final phone = appointment.customer?.phone?.trim();
    final salonName = appointment.salon?.salonName?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'NEXT UP',
              style: theme.labelSmall?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            if (appointment.hasPremiumService) const PremiumChip(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppColors.radiusControl),
                border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                appointment.displayTime,
                style: theme.titleSmall?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    appointment.servicesDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (salonName != null && salonName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            salonName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (appointment.paymentHint != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.warning,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  appointment.paymentHint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            if (phone != null && phone.isNotEmpty)
              Expanded(
                child: _HeroAction(
                  icon: Icons.phone_rounded,
                  label: 'Call',
                  onTap: () => launchPhoneCall(phone),
                ),
              ),
            if (phone != null && phone.isNotEmpty) const SizedBox(width: 8),
            Expanded(
              child: _HeroAction(
                icon: Icons.receipt_long_rounded,
                label: 'Details',
                onTap: onOpen,
                filled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = filled ? colors.onAccent : colors.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled
                ? colors.accent
                : colors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
            border: Border.all(
              color: colors.accent.withValues(alpha: filled ? 1 : 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoUpcomingToday extends StatelessWidget {
  const _NoUpcomingToday();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.event_available_rounded,
            size: 20,
            color: colors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nothing left today',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'No more appointments on the books for today.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
