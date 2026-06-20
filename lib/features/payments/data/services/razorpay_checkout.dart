import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:saloon_booking/features/payments/data/models/payment_model.dart';

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

class RazorpayCheckout {
  Future<RazorpayCheckoutResult> open({
    required PaymentModel payment,
    required String name,
    required String description,
  }) {
    final keyId = payment.razorpayKeyId;
    final orderId = payment.razorpayOrderId;
    if (keyId == null || keyId.isEmpty || orderId == null || orderId.isEmpty) {
      return Future.error('Payment order is not ready');
    }

    final razorpay = Razorpay();
    final completer = Completer<RazorpayCheckoutResult>();

    void cleanup() {
      razorpay.clear();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse res) {
      if (!completer.isCompleted) {
        completer.complete(
          RazorpayCheckoutResult(
            orderId: res.orderId ?? orderId,
            paymentId: res.paymentId ?? '',
            signature: res.signature ?? '',
          ),
        );
      }
      cleanup();
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse res) {
      if (!completer.isCompleted) {
        completer.completeError(res.message ?? 'Payment failed');
      }
      cleanup();
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse res) {
      if (!completer.isCompleted) {
        completer.completeError('External wallet is not supported yet');
      }
      cleanup();
    });

    try {
      razorpay.open({
        'key': keyId,
        'amount': payment.amountPaise,
        'currency': payment.currency,
        'name': name,
        'description': description,
        'order_id': orderId,
        'theme': {'color': '#B8860B'},
      });
    } catch (error) {
      cleanup();
      if (!completer.isCompleted) completer.completeError(error);
    }

    return completer.future;
  }
}
