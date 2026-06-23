import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/booking_when_badge.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.trailing,
  });

  final BookingModel booking;
  final VoidCallback? onTap;
  final Widget? trailing;

  Color get _accentColor => switch (booking.bookingStatus.toUpperCase()) {
    'PENDING' => AppColors.warning,
    'ACCEPTED' => AppColors.success,
    'COMPLETED' => AppColors.primaryLight,
    'CANCELLED' => AppColors.textMuted,
    'REJECTED' => AppColors.error,
    _ => AppColors.accent,
  };

  String _paymentStatusLabel() {
    final payment = booking.salonFeePayment;
    if (payment == null) return 'Salon fee: not selected';
    if (payment.isPaid) return 'Salon fee: paid online';
    if (payment.isPayAtShop) return 'Salon fee: pay at shop';
    if (payment.isExpired) return 'Salon fee: payment expired';
    return 'Salon fee: payment pending';
  }

  String _premiumStatusLabel() {
    final payment = booking.premiumPayment;
    if (booking.premiumPaymentStatus == 'PAID') return 'Premium payment: paid';
    if (payment?.isExpired == true) return 'Premium payment: expired';
    return 'Premium payment: pending';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      shadowColor: _accentColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_accentColor, _accentColor.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.salon?.salonName ?? 'Salon',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    StatusBadge(status: booking.bookingStatus),
                    const SizedBox(width: 6),
                    BookingWhenBadge(
                      date: booking.bookingDate,
                      time: booking.bookingTime,
                      durationMinutes:
                          booking.service?.durationMinutes ?? 30,
                      compact: true,
                    ),
                    if (booking.isPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.spa_outlined,
                  text: booking.service?.serviceName ?? 'Service',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: '${booking.bookingDate} at ${booking.bookingTime}',
                ),
                if (booking.bookingNumber != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    text: '#${booking.bookingNumber}',
                    accent: true,
                  ),
                ],
                if (booking.bookingStatus.toUpperCase() == 'PENDING') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Awaiting salon confirmation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (booking.bookingStatus.toUpperCase() == 'REJECTED' &&
                    booking.rejectionReason != null &&
                    booking.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Declined: ${booking.rejectionReason}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ],
                if (booking.premiumAmount != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.bolt_rounded,
                    text:
                        'Premium: ₹${booking.premiumAmount!.toStringAsFixed(0)}',
                    accent: true,
                  ),
                ],
                if (booking.isPremium) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.lock_clock_rounded,
                    text: _premiumStatusLabel(),
                    accent: booking.premiumPaymentStatus == 'PAID',
                  ),
                ],
                if (booking.service?.price != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    text:
                        'Service: ₹${booking.service!.effectivePrice!.toStringAsFixed(2)}',
                    accent: true,
                  ),
                ],
                if (booking.bookingStatus.toUpperCase() == 'ACCEPTED') ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    text: _paymentStatusLabel(),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.glassBorder, height: 1),
                  const SizedBox(height: 10),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.accent = false});

  final IconData icon;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: accent ? AppColors.accent : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accent ? AppColors.accent : AppColors.textSecondary,
              fontWeight: accent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
