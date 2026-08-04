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
    String? contact,
    String? email,
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
        final paymentId = res.paymentId?.trim();
        final signature = res.signature?.trim();
        final resolvedOrderId = res.orderId?.trim() ?? orderId;
        if (paymentId == null ||
            paymentId.isEmpty ||
            signature == null ||
            signature.isEmpty) {
          completer.completeError('Payment response was incomplete');
        } else {
          completer.complete(
            RazorpayCheckoutResult(
              orderId: resolvedOrderId,
              paymentId: paymentId,
              signature: signature,
            ),
          );
        }
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

    final prefill = <String, dynamic>{
      'name': name,
      if (contact != null && contact.isNotEmpty) 'contact': contact,
      if (email != null && email.isNotEmpty) 'email': email,
    };

    try {
      razorpay.open({
        'key': keyId,
        'amount': payment.amountPaise,
        'currency': payment.currency,
        'name': name,
        'description': description,
        'order_id': orderId,
        'theme': {'color': '#B8860B'},
        'prefill': prefill,
        'method': {
          'upi': true,
          'card': true,
          'netbanking': true,
          'wallet': true,
        },
        'retry': {'enabled': true, 'max_count': 1},
      });
    } catch (error) {
      cleanup();
      if (!completer.isCompleted) completer.completeError(error);
    }

    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () {
        cleanup();
        throw TimeoutException('Payment timed out');
      },
    );
  }
}
