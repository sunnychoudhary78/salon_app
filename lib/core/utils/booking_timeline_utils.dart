import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';

enum BookingTimelineGroup { active, past }

enum BookingWhenLabel { today, upcoming, past }

DateTime? parseBookingDateTime(String date, String time) {
  try {
    final datePart = DateTime.parse(date);
    final parts = time.split(':');
    if (parts.length < 2) return datePart;
    return DateTime(
      datePart.year,
      datePart.month,
      datePart.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  } catch (_) {
    return null;
  }
}

bool isBookingSlotEnded({
  required String date,
  required String time,
  int durationMinutes = 30,
}) {
  final start = parseBookingDateTime(date, time);
  if (start == null) return false;
  return DateTime.now().isAfter(
    start.add(Duration(minutes: durationMinutes)),
  );
}

BookingWhenLabel? bookingWhenLabel({
  required String date,
  required String time,
  int durationMinutes = 30,
}) {
  final start = parseBookingDateTime(date, time);
  if (start == null) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final bookingDay = DateTime(start.year, start.month, start.day);
  final end = start.add(Duration(minutes: durationMinutes));

  if (now.isAfter(end)) return BookingWhenLabel.past;
  if (bookingDay == today) return BookingWhenLabel.today;
  if (start.isAfter(now)) return BookingWhenLabel.upcoming;
  return BookingWhenLabel.today;
}

bool isPastBookingStatus(String status) {
  return switch (status.toUpperCase()) {
    'COMPLETED' || 'CANCELLED' || 'REJECTED' => true,
    _ => false,
  };
}

bool isActiveBookingStatus(String status) {
  return switch (status.toUpperCase()) {
    'PENDING' || 'ACCEPTED' => true,
    _ => false,
  };
}

BookingTimelineGroup customerBookingTimeline(BookingModel booking) {
  final status = booking.bookingStatus.toUpperCase();
  if (isPastBookingStatus(status)) return BookingTimelineGroup.past;
  if (status == 'ACCEPTED' && booking.slotEnded) {
    return BookingTimelineGroup.past;
  }
  if (isActiveBookingStatus(status)) return BookingTimelineGroup.active;
  return BookingTimelineGroup.past;
}

BookingTimelineGroup ownerBookingTimeline(OwnerBookingModel booking) {
  if (isPastBookingStatus(booking.bookingStatus)) {
    return BookingTimelineGroup.past;
  }
  if (isActiveBookingStatus(booking.bookingStatus)) {
    return BookingTimelineGroup.active;
  }
  return BookingTimelineGroup.past;
}

List<T> sortBookingsByDateTime<T>({
  required List<T> items,
  required String Function(T item) dateOf,
  required String Function(T item) timeOf,
  bool descending = true,
}) {
  final sorted = List<T>.from(items);
  sorted.sort((a, b) {
    final aDt = parseBookingDateTime(dateOf(a), timeOf(a));
    final bDt = parseBookingDateTime(dateOf(b), timeOf(b));
    if (aDt == null && bDt == null) return 0;
    if (aDt == null) return 1;
    if (bDt == null) return -1;
    return descending ? bDt.compareTo(aDt) : aDt.compareTo(bDt);
  });
  return sorted;
}


List<BookingModel> customerActiveBookings(List<BookingModel> items) {
  return sortBookingsByDateTime(
    items: items
        .where((b) => customerBookingTimeline(b) == BookingTimelineGroup.active)
        .toList(),
    dateOf: (b) => b.bookingDate,
    timeOf: (b) => b.bookingTime,
    descending: false,
  );
}

List<BookingModel> customerPastBookings(List<BookingModel> items) {
  return sortBookingsByDateTime(
    items: items
        .where((b) => customerBookingTimeline(b) == BookingTimelineGroup.past)
        .toList(),
    dateOf: (b) => b.bookingDate,
    timeOf: (b) => b.bookingTime,
  );
}

List<OwnerBookingModel> ownerActiveBookings(List<OwnerBookingModel> items) {
  return sortBookingsByDateTime(
    items: items
        .where((b) => ownerBookingTimeline(b) == BookingTimelineGroup.active)
        .toList(),
    dateOf: (b) => b.bookingDate,
    timeOf: (b) => b.bookingTime,
    descending: false,
  );
}

List<OwnerBookingModel> ownerPastBookings(List<OwnerBookingModel> items) {
  return sortBookingsByDateTime(
    items: items
        .where((b) => ownerBookingTimeline(b) == BookingTimelineGroup.past)
        .toList(),
    dateOf: (b) => b.bookingDate,
    timeOf: (b) => b.bookingTime,
  );
}

List<OwnerBookingModel> ownerPendingBookings(List<OwnerBookingModel> items) {
  return items.where((b) => b.bookingStatus.toUpperCase() == 'PENDING').toList();
}

List<OwnerBookingModel> ownerUpcomingAcceptedBookings(
  List<OwnerBookingModel> items,
) {
  return sortBookingsByDateTime(
    items: items
        .where((b) => b.bookingStatus.toUpperCase() == 'ACCEPTED')
        .toList(),
    dateOf: (b) => b.bookingDate,
    timeOf: (b) => b.bookingTime,
    descending: false,
  );
}
