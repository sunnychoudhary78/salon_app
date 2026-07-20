import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class HorizontalDateStrip extends StatelessWidget {
  const HorizontalDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.onMoreDates,
    this.dayCount = 14,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onMoreDates;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = DateTime.now();
    final dates = List.generate(
      dayCount,
      (i) => DateTime(today.year, today.month, today.day + i),
    );

    final selected = selectedDate != null
        ? DateTime(
            selectedDate!.year,
            selectedDate!.month,
            selectedDate!.day,
          )
        : null;

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length + (onMoreDates != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (onMoreDates != null && index == dates.length) {
            return _MoreDatesChip(onTap: onMoreDates!);
          }

          final date = dates[index];
          final isSelected = selected != null &&
              date.year == selected.year &&
              date.month == selected.month &&
              date.day == selected.day;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          return _DateChip(
            dayLabel: isToday ? 'Today' : DateFormat.E().format(date),
            dateLabel: DateFormat.d().format(date),
            selected: isSelected,
            colors: colors,
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.dayLabel,
    required this.dateLabel,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String dayLabel;
  final String dateLabel;
  final bool selected;
  final AppThemeExtension colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? colors.accentGradient : null,
            color: selected ? null : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.5)
                  : colors.glassBorder.withValues(alpha: 0.5),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.onAccent : colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.onAccent : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreDatesChip extends StatelessWidget {
  const _MoreDatesChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(height: 4),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
