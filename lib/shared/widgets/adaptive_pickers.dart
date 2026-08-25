import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/platform_utils.dart';

DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
  if (value.isBefore(min)) return min;
  if (value.isAfter(max)) return max;
  return value;
}

/// Platform-adaptive date picker: Cupertino wheel on iOS, Material elsewhere.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final first = DateUtils.dateOnly(firstDate);
  final last = DateUtils.dateOnly(lastDate);
  final initial = _clampDate(DateUtils.dateOnly(initialDate), first, last);

  if (!isCupertinoPlatform(context)) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
  }

  var selected = initial;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return Container(
        height: 280 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.of(ctx).pop(selected),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Platform-adaptive time picker: Cupertino wheel on iOS, Material elsewhere.
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  if (!isCupertinoPlatform(context)) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: context.appColors.accent),
          ),
          child: child!,
        );
      },
    );
  }

  final now = DateTime.now();
  var selected = DateTime(
    now.year,
    now.month,
    now.day,
    initialTime.hour,
    initialTime.minute,
  );

  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return Container(
        height: 280 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.of(ctx).pop(
                      TimeOfDay(hour: selected.hour, minute: selected.minute),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: selected,
                use24hFormat: MediaQuery.alwaysUse24HourFormatOf(ctx),
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
          ],
        ),
      );
    },
  );
}
