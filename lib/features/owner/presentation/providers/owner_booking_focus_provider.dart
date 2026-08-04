import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Focus a booking on the owner bookings tab (from dashboard taps).
class OwnerBookingFocus {
  const OwnerBookingFocus({
    required this.bookingId,
    this.openDetail = true,
  });

  final String bookingId;
  final bool openDetail;
}

class OwnerBookingFocusNotifier extends Notifier<OwnerBookingFocus?> {
  @override
  OwnerBookingFocus? build() => null;

  void set(OwnerBookingFocus? value) => state = value;

  void clear() => state = null;
}

final ownerBookingFocusProvider =
    NotifierProvider<OwnerBookingFocusNotifier, OwnerBookingFocus?>(
      OwnerBookingFocusNotifier.new,
    );
