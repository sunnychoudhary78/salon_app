import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/payments/data/services/payment_service.dart';
import 'package:saloon_booking/features/payments/data/services/razorpay_checkout.dart';

class PaymentActions extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    ref.keepAlive();
  }

  String _groupId(BookingModel booking) => booking.groupId ?? booking.id;

  Future<void> payOnline({
    required BookingModel booking,
    required String checkoutKind,
  }) async {
    state = const AsyncLoading();
    final groupId = _groupId(booking);
    final result = await AsyncValue.guard(() async {
      final order = await ref.read(paymentServiceProvider).createRazorpayOrder(
            bookingGroupId: groupId,
            checkoutKind: checkoutKind,
          );
      final checkout = await RazorpayCheckout().open(
        payment: order,
        name: booking.salon?.salonName ?? 'CATCHY',
        description: _descriptionForCheckout(checkoutKind, booking),
      );
      try {
        await ref.read(paymentServiceProvider).verifyRazorpayPaymentWithRetry(
              orderId: checkout.orderId,
              paymentId: checkout.paymentId,
              signature: checkout.signature,
            );
      } catch (error) {
        final recovered = await _recoverIfWebhookApplied(
          groupId: groupId,
          checkoutKind: checkoutKind,
        );
        if (recovered) return;
        rethrow;
      }
    });
    state = result;
    ref.invalidate(myBookingsProvider);
    if (result.hasError) throw result.error!;
  }

  String _descriptionForCheckout(String checkoutKind, BookingModel booking) {
    switch (checkoutKind) {
      case 'PREMIUM_ONLY':
        return 'Premium booking fee';
      case 'COMBINED':
        return 'Full booking payment';
      default:
        return booking.salon?.salonName ?? 'Salon visit payment';
    }
  }

  Future<bool> _recoverIfWebhookApplied({
    required String groupId,
    required String checkoutKind,
  }) async {
    const attempts = [1, 2, 3];
    for (final waitSeconds in attempts) {
      await Future<void>.delayed(Duration(seconds: waitSeconds));
      ref.invalidate(myBookingsProvider);
      try {
        final bookings = await ref.read(myBookingsProvider.future);
        final group = bookings
            .where((b) => (b.groupId ?? b.id) == groupId)
            .toList();
        if (group.isNotEmpty && _isCheckoutRecorded(group, checkoutKind)) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  bool _isCheckoutRecorded(List<BookingModel> group, String checkoutKind) {
    final rep = group.firstWhere(
      (b) => b.isPremium,
      orElse: () => group.first,
    );
    if (checkoutKind == 'PREMIUM_ONLY' || checkoutKind == 'COMBINED') {
      if (rep.premiumPaymentStatus != 'PAID') return false;
    }
    if (checkoutKind == 'SALON_FEE' || checkoutKind == 'COMBINED') {
      return rep.salonFeePayment?.isPaid == true ||
          rep.salonFeePayment?.isPayAtShop == true;
    }
    return rep.premiumPaymentStatus == 'PAID';
  }

  Future<void> selectPayAtShop(BookingModel booking) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(paymentServiceProvider).selectPayAtShop(
            bookingGroupId: _groupId(booking),
          ),
    );
    ref.invalidate(myBookingsProvider);
    if (state.hasError) throw state.error!;
  }
}

final paymentActionsProvider = AsyncNotifierProvider<PaymentActions, void>(
  PaymentActions.new,
);
