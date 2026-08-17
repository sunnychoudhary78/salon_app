import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/booking_when_badge.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';

class BookingCard extends StatefulWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.trailing,
    this.serviceNames = const [],
  });

  final BookingModel booking;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// All service names in this request. When more than one is provided the card
  /// shows the combined list instead of the single [booking] service.
  final List<String> serviceNames;

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _detailsExpanded = false;

  BookingModel get booking => widget.booking;

  Future<void> _callSalon(BuildContext context, String phone) async {
    final launched = await launchPhoneCall(phone);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  String? get _salonPhone {
    final phone = booking.salon?.phone?.trim();
    if (phone == null || phone.isEmpty) return null;
    return phone;
  }

  String _paymentStatusLabel() {
    final payment = booking.salonFeePayment;
    if (payment == null) return 'Salon fee: not selected';
    if (payment.isPaid && payment.cashExtraAmount > 0) {
      if (payment.isPayAtShop) {
        return 'Salon fee: paid at shop · extra ${formatMoney(payment.cashExtraAmount)}';
      }
      return 'Salon fee: paid online · extra ${formatMoney(payment.cashExtraAmount)}';
    }
    if (payment.isPayAtShop && payment.isPaid) {
      return 'Salon fee: paid at shop';
    }
    if (payment.isPayAtShop) return 'Salon fee: pay at shop';
    if (payment.isPaid) return 'Salon fee: paid online';
    if (payment.isExpired) return 'Salon fee: payment expired';
    return 'Salon fee: payment pending';
  }

  String _premiumStatusLabel() {
    final payment = booking.premiumPayment;
    if (booking.premiumPaymentStatus == 'PAID') return 'Premium payment: paid';
    if (booking.premiumPaymentExpired || payment?.isExpired == true) {
      return 'Premium payment: expired';
    }
    return 'Premium payment: pending';
  }

  String _formatDateTime() {
    try {
      final parsed = DateTime.parse(booking.bookingDate);
      final dateLabel = DateFormat('EEE, d MMM').format(parsed);
      final time = booking.bookingTime.length >= 5
          ? booking.bookingTime.substring(0, 5)
          : booking.bookingTime;
      return '$dateLabel · $time';
    } catch (_) {
      return '${booking.bookingDate} at ${booking.bookingTime}';
    }
  }

  bool get _showPaymentStatus {
    if (booking.bookingStatus.toUpperCase() == 'ACCEPTED') return true;
    final payment = booking.salonFeePayment;
    return payment != null &&
        payment.isPaid &&
        payment.cashExtraAmount > 0;
  }

  bool get _hasDetailRows {
    return booking.bookingNumber != null ||
        booking.premiumAmount != null ||
        booking.isPremium ||
        booking.service?.price != null ||
        _showPaymentStatus;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GlassCard(
      onTap: widget.onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.salon?.salonName ?? 'Salon',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colors.textPrimary),
                ),
              ),
              StatusBadge(status: booking.bookingStatus),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: context.appColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDateTime(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              BookingWhenBadge(
                date: booking.bookingDate,
                time: booking.bookingTime,
                durationMinutes: booking.service?.durationMinutes ?? 30,
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
                    color: context.appColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color: context.appColors.accent,
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
            text: widget.serviceNames.length > 1
                ? widget.serviceNames.join(', ')
                : (booking.service?.serviceName ?? 'Service'),
          ),
          if (booking.staff != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: 'Preferred: ${booking.staff!.name}',
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
          if (booking.bookingStatus.toUpperCase() == 'ACCEPTED' &&
              booking.salonFeePayAtShop &&
              !booking.salonFeePaid) ...[
            const SizedBox(height: 8),
            Text(
              'Waiting for salon to confirm cash',
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
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          if (_hasDetailRows) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.appColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _detailsExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: context.appColors.accent,
                    ),
                  ],
                ),
              ),
            ),
            if (_detailsExpanded) ...[
              if (booking.bookingNumber != null) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.confirmation_number_outlined,
                  text: '#${booking.bookingNumber}',
                  accent: true,
                ),
              ],
              if (booking.premiumAmount != null) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.bolt_rounded,
                  text: 'Premium: ${formatMoney(booking.premiumAmount!)}',
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
                      'Service: ${formatMoney(booking.service!.effectivePrice!)}',
                  accent: true,
                ),
              ],
              if (_showPaymentStatus) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.account_balance_wallet_outlined,
                  text: _paymentStatusLabel(),
                ),
              ],
            ],
          ],
          if (booking.isConfirmed && _salonPhone != null) ...[
            const SizedBox(height: 6),
            _PhoneRow(
              phone: _salonPhone!,
              onTap: () => _callSalon(context, _salonPhone!),
            ),
          ],
          if (widget.trailing != null) ...[
            const SizedBox(height: 14),
            Divider(color: colors.glassBorder, height: 1),
            const SizedBox(height: 10),
            widget.trailing!,
          ],
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
    final colors = context.appColors;

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: accent ? context.appColors.accent : colors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accent ? context.appColors.accent : colors.textSecondary,
              fontWeight: accent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone, required this.onTap});

  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                phone,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.call_rounded, size: 16, color: context.appColors.accent),
          ],
        ),
      ),
    );
  }
}
