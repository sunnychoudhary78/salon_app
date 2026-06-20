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

  Future<void> payOnline({
    required BookingModel booking,
    required String paymentType,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final order = await ref
          .read(paymentServiceProvider)
          .createRazorpayOrder(bookingId: booking.id, paymentType: paymentType);
      final checkout = await RazorpayCheckout().open(
        payment: order,
        name: booking.salon?.salonName ?? 'CATCHY',
        description: paymentType == 'PREMIUM_FEE'
            ? 'Premium booking fee'
            : booking.service?.serviceName ?? 'Salon service fee',
      );
      await ref
          .read(paymentServiceProvider)
          .verifyRazorpayPayment(
            orderId: checkout.orderId,
            paymentId: checkout.paymentId,
            signature: checkout.signature,
          );
    });
    state = result;
    ref.invalidate(myBookingsProvider);
    if (result.hasError) throw result.error!;
  }

  Future<void> selectPayAtShop(String bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(paymentServiceProvider).selectPayAtShop(bookingId),
    );
    ref.invalidate(myBookingsProvider);
    if (state.hasError) throw state.error!;
  }
}

final paymentActionsProvider = AsyncNotifierProvider<PaymentActions, void>(
  PaymentActions.new,
);
