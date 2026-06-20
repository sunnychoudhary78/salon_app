import 'package:flutter/material.dart';

TimeOfDay? parseSalonTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String formatSalonTimeForApi(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String formatSalonTimeDisplay(String? raw) {
  final time = parseSalonTime(raw);
  if (time == null) return '';
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute $period';
}

int salonTimeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

bool isClosingAfterOpening(TimeOfDay opening, TimeOfDay closing) {
  return salonTimeToMinutes(closing) > salonTimeToMinutes(opening);
}

String formatTimeOfDayLabel(TimeOfDay time) {
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute $period';
}
