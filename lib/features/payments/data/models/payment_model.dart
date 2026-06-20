class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.paymentType,
    required this.amount,
    required this.amountPaise,
    required this.currency,
    required this.method,
    required this.status,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpayKeyId,
    this.failureReason,
    this.paidAt,
    this.expiresAt,
  });

  final String id;
  final String bookingId;
  final String paymentType;
  final double amount;
  final int amountPaise;
  final String currency;
  final String method;
  final String status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpayKeyId;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime? expiresAt;

  bool get isPending => status == 'PENDING';
  bool get isPaid => status == 'PAID';
  bool get isExpired =>
      status == 'EXPIRED' ||
      (isPending && expiresAt != null && !expiresAt!.isAfter(DateTime.now()));
  bool get isPayAtShop => method == 'PAY_AT_SHOP';

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id'].toString(),
    bookingId: json['booking_id'].toString(),
    paymentType: json['payment_type'] as String? ?? '',
    amount: _parseDouble(json['amount']),
    amountPaise:
        _parseInt(json['amount_paise']) ??
        (_parseDouble(json['amount']) * 100).round(),
    currency: json['currency'] as String? ?? 'INR',
    method: json['method'] as String? ?? 'RAZORPAY',
    status: json['status'] as String? ?? 'PENDING',
    razorpayOrderId: json['razorpay_order_id'] as String?,
    razorpayPaymentId: json['razorpay_payment_id'] as String?,
    razorpayKeyId: json['razorpay_key_id'] as String?,
    failureReason: json['failure_reason'] as String?,
    paidAt: _parseDate(json['paid_at']),
    expiresAt: _parseDate(json['expires_at']),
  );
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
