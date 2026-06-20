import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';

class SalonHoursPickerRow extends StatelessWidget {
  const SalonHoursPickerRow({
    super.key,
    required this.openingTime,
    required this.closingTime,
    required this.onOpeningChanged,
    required this.onClosingChanged,
  });

  final TimeOfDay? openingTime;
  final TimeOfDay? closingTime;
  final ValueChanged<TimeOfDay> onOpeningChanged;
  final ValueChanged<TimeOfDay> onClosingChanged;

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay? initial,
    required ValueChanged<TimeOfDay> onChanged,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.accent,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimePickerTile(
            label: 'Opening time *',
            value: openingTime == null
                ? 'Select time'
                : formatTimeOfDayLabel(openingTime!),
            onTap: () => _pickTime(
              context,
              initial: openingTime,
              onChanged: onOpeningChanged,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TimePickerTile(
            label: 'Closing time *',
            value: closingTime == null
                ? 'Select time'
                : formatTimeOfDayLabel(closingTime!),
            onTap: () => _pickTime(
              context,
              initial: closingTime,
              onChanged: onClosingChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: AppColors.accent.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
