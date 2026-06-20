import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/payments/data/models/payment_model.dart';

class PaymentActionResult {
  const PaymentActionResult({required this.payment, this.booking});

  final PaymentModel payment;
  final BookingModel? booking;
}

class PaymentService {
  PaymentService(this._dio);

  final Dio _dio;

  Future<PaymentModel> createRazorpayOrder({
    required String bookingId,
    required String paymentType,
  }) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/payments/razorpay/order',
      data: {'booking_id': bookingId, 'payment_type': paymentType},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return PaymentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PaymentActionResult> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/payments/razorpay/verify',
      data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return _parseResult(response.data as Map<String, dynamic>);
  }

  Future<PaymentActionResult> selectPayAtShop(String bookingId) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/payments/pay-at-shop',
      data: {'booking_id': bookingId},
    );
    return _parseResult(response.data as Map<String, dynamic>);
  }

  PaymentActionResult _parseResult(Map<String, dynamic> json) {
    return PaymentActionResult(
      payment: PaymentModel.fromJson(json['data'] as Map<String, dynamic>),
      booking: json['booking'] == null
          ? null
          : BookingModel.fromJson(json['booking'] as Map<String, dynamic>),
    );
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  ref.keepAlive();
  return PaymentService(ref.watch(dioProvider));
});
