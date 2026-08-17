import 'package:flutter/foundation.dart';

/// Bumped on the main isolate after a notification Accept/Reject finishes
/// so [pendingBookingGateProvider] can refresh and drop resolved bookings.
final ValueNotifier<int> bookingActionCompletedTick = ValueNotifier<int>(0);

void notifyBookingActionCompleted() {
  bookingActionCompletedTick.value++;
}
