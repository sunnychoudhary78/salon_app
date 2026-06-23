import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';

class BookingWhenBadge extends StatelessWidget {
  const BookingWhenBadge({
    super.key,
    required this.date,
    required this.time,
    this.durationMinutes = 30,
    this.compact = false,
  });

  final String date;
  final String time;
  final int durationMinutes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = bookingWhenLabel(
      date: date,
      time: time,
      durationMinutes: durationMinutes,
    );
    if (label == null) return const SizedBox.shrink();

    final (text, color, icon) = switch (label) {
      BookingWhenLabel.today => (
          'Today',
          AppColors.accent,
          Icons.today_rounded,
        ),
      BookingWhenLabel.upcoming => (
          'Upcoming',
          AppColors.success,
          Icons.event_rounded,
        ),
      BookingWhenLabel.past => (
          'Past',
          AppColors.textMuted,
          Icons.history_rounded,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
