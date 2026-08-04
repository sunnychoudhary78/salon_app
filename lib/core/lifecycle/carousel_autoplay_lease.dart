import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Only one salon image carousel may autoplay at a time.
class CarouselAutoplayLease extends Notifier<String?> {
  @override
  String? build() => null;

  bool tryAcquire(String salonId) {
    final current = state;
    if (current == null || current == salonId) {
      state = salonId;
      return true;
    }
    return false;
  }

  void release(String salonId) {
    if (state == salonId) state = null;
  }
}

final carouselAutoplayLeaseProvider =
    NotifierProvider<CarouselAutoplayLease, String?>(CarouselAutoplayLease.new);
