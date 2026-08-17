class OwnerDashboardModel {
  const OwnerDashboardModel({
    required this.salonCount,
    required this.pendingBookings,
    required this.acceptedBookings,
    required this.completedBookings,
    required this.totalReviews,
  });

  final int salonCount;
  final int pendingBookings;
  final int acceptedBookings;
  final int completedBookings;
  final int totalReviews;

  factory OwnerDashboardModel.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardModel(
        salonCount: json['salonCount'] as int? ?? 0,
        pendingBookings: json['pendingBookings'] as int? ?? 0,
        acceptedBookings: json['acceptedBookings'] as int? ?? 0,
        completedBookings: json['completedBookings'] as int? ?? 0,
        totalReviews: json['totalReviews'] as int? ?? 0,
      );
}

class OwnerBookingCustomer {
  const OwnerBookingCustomer({
    this.name,
    this.phone,
    this.email,
    this.profileImage,
  });

  final String? name;
  final String? phone;
  final String? email;
  final String? profileImage;

  factory OwnerBookingCustomer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OwnerBookingCustomer();
    final user = json['user'] as Map<String, dynamic>?;
    return OwnerBookingCustomer(
      name: user?['name'] as String?,
      phone: user?['phone'] as String?,
      email: user?['email'] as String?,
      profileImage: json['profile_image'] as String?,
    );
  }
}

class OwnerBookingModel {
  const OwnerBookingModel({
    required this.id,
    required this.bookingStatus,
    required this.bookingDate,
    required this.bookingTime,
    this.groupId,
    this.customer,
    this.serviceName,
    this.salonName,
    this.staffName,
    this.bookingNumber,
    this.bookingType,
    this.premiumAmount,
    this.premiumPaymentStatus,
    this.premiumPaymentDueAt,
    this.requiresCashConfirmation = false,
    this.canComplete = false,
    this.salonFeePaymentState = 'none',
    this.salonFeeAmount,
    this.cashExtraAmount = 0,
  });

  final String id;
  final String bookingStatus;
  final String bookingDate;
  final String bookingTime;
  final String? groupId;
  final OwnerBookingCustomer? customer;
  final String? serviceName;
  final String? salonName;
  final String? staffName;
  final String? bookingNumber;
  final String? bookingType;
  final double? premiumAmount;
  final String? premiumPaymentStatus;
  final DateTime? premiumPaymentDueAt;
  final bool requiresCashConfirmation;
  final bool canComplete;

  /// none | pending_cash | pending_online | paid
  final String salonFeePaymentState;
  final double? salonFeeAmount;
  final double cashExtraAmount;

  bool get isPremium => bookingType == 'PREMIUM';

  bool get isAccepted => bookingStatus.toUpperCase() == 'ACCEPTED';

  bool get isSalonFeePaid => salonFeePaymentState == 'paid';

  bool get needsPremiumPayment =>
      isPremium &&
      isAccepted &&
      premiumPaymentStatus != 'PAID' &&
      !premiumPaymentExpired;

  bool get premiumPaymentExpired =>
      isPremium &&
      isAccepted &&
      premiumPaymentStatus != 'PAID' &&
      premiumPaymentDueAt != null &&
      !premiumPaymentDueAt!.isAfter(DateTime.now());

  String get paymentWaitingMessage {
    switch (salonFeePaymentState) {
      case 'pending_online':
        return 'Waiting for online payment';
      case 'pending_cash':
        return 'Pay at salon selected';
      case 'paid':
        return 'Payment received';
      default:
        return 'Waiting for customer payment';
    }
  }

  factory OwnerBookingModel.fromJson(Map<String, dynamic> json) {
    final salonFee = json['salon_fee_payment'] as Map<String, dynamic>?;
    final state =
        json['salon_fee_payment_state'] as String? ??
        _inferSalonFeePaymentState(salonFee);
    final requiresCash =
        json['requires_cash_confirmation'] as bool? ?? state == 'pending_cash';
    final canComplete =
        json['can_complete'] as bool? ??
        (state == 'pending_cash' || state == 'paid');
    return OwnerBookingModel(
      id: json['id'].toString(),
      bookingStatus: json['booking_status'] as String,
      bookingDate: json['booking_date']?.toString() ?? '',
      bookingTime: json['booking_time'] as String? ?? '',
      groupId: json['booking_group_id']?.toString(),
      bookingNumber: json['booking_number'] as String?,
      bookingType: json['booking_type'] as String?,
      premiumAmount: _parseDouble(json['premium_amount']),
      premiumPaymentStatus: json['premium_payment_status'] as String?,
      premiumPaymentDueAt: _parseDate(json['premium_payment_due_at']),
      requiresCashConfirmation: requiresCash,
      canComplete: canComplete,
      salonFeePaymentState: state,
      salonFeeAmount: salonFee == null
          ? null
          : (_parseDouble(salonFee['amount']) ?? 0),
      cashExtraAmount: _parseDouble(salonFee?['cash_extra_amount']) ?? 0,
      customer: OwnerBookingCustomer.fromJson(
        json['customer'] as Map<String, dynamic>?,
      ),
      serviceName: json['service']?['service_name'] as String?,
      salonName: json['salon']?['salon_name'] as String?,
      staffName: json['staff']?['name'] as String?,
    );
  }

  static String _inferSalonFeePaymentState(Map<String, dynamic>? salonFee) {
    if (salonFee == null) return 'none';
    final status = salonFee['status']?.toString();
    final method = salonFee['method']?.toString();
    if (status == 'PAID') return 'paid';
    if (status == 'PENDING' && method == 'PAY_AT_SHOP') return 'pending_cash';
    if (status == 'PENDING') return 'pending_online';
    return 'none';
  }
}

/// Urgent/premium fee is stored on one row of a multi-service group.
bool ownerGroupIsPremium(Iterable<OwnerBookingModel> group) =>
    group.any((b) => b.isPremium);

double? ownerGroupPremiumAmount(Iterable<OwnerBookingModel> group) {
  for (final booking in group) {
    if (booking.isPremium) return booking.premiumAmount;
  }
  return null;
}

OwnerBookingModel ownerGroupPremium(Iterable<OwnerBookingModel> group) {
  return group.firstWhere((b) => b.isPremium, orElse: () => group.first);
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

class OwnerEarningsSummaryModel {
  const OwnerEarningsSummaryModel({
    required this.pendingTotal,
    required this.settledTotal,
    this.collectedAtSalon = 0,
    this.pending = 0,
    this.inBatch = 0,
    this.platformFeeOwed = 0,
  });

  final double pendingTotal;
  final double settledTotal;
  final double collectedAtSalon;
  final double pending;
  final double inBatch;
  final double platformFeeOwed;

  factory OwnerEarningsSummaryModel.fromJson(Map<String, dynamic> json) =>
      OwnerEarningsSummaryModel(
        pendingTotal: _parseDouble(json['pending_total']) ?? 0,
        settledTotal: _parseDouble(json['settled_total']) ?? 0,
        collectedAtSalon: _parseDouble(json['collected_at_salon']) ?? 0,
        pending: _parseDouble(json['pending']) ?? 0,
        inBatch: _parseDouble(json['in_batch']) ?? 0,
        platformFeeOwed: _parseDouble(json['platform_fee_owed']) ?? 0,
      );
}

class OwnerEarningsTransactionModel {
  const OwnerEarningsTransactionModel({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.status,
    this.createdAt,
    this.paymentId,
  });

  final String id;
  final String entryType;
  final double amount;
  final String status;
  final String? createdAt;
  final String? paymentId;

  factory OwnerEarningsTransactionModel.fromJson(Map<String, dynamic> json) =>
      OwnerEarningsTransactionModel(
        id: json['id'].toString(),
        entryType: json['entry_type'] as String? ?? '',
        amount: _parseDouble(json['amount']) ?? 0,
        status: json['status'] as String? ?? '',
        createdAt: json['created_at']?.toString(),
        paymentId: json['payment_id']?.toString(),
      );
}

class OwnerPayoutAccountModel {
  const OwnerPayoutAccountModel({
    required this.id,
    required this.accountHolderName,
    required this.ifscCode,
    this.accountNumberMasked,
    this.upiId,
    this.verificationStatus,
  });

  final String id;
  final String accountHolderName;
  final String ifscCode;
  final String? accountNumberMasked;
  final String? upiId;
  final String? verificationStatus;

  factory OwnerPayoutAccountModel.fromJson(Map<String, dynamic> json) =>
      OwnerPayoutAccountModel(
        id: json['id'].toString(),
        accountHolderName: json['account_holder_name'] as String? ?? '',
        ifscCode: json['ifsc_code'] as String? ?? '',
        accountNumberMasked: json['account_number_masked'] as String?,
        upiId: json['upi_id'] as String?,
        verificationStatus: json['verification_status'] as String?,
      );
}

class SalonApplicationModel {
  const SalonApplicationModel({
    required this.id,
    required this.applicationStatus,
    required this.salonName,
    this.applicationType = 'CREATE',
    this.salonId,
    this.description,
    this.rejectionReason,
    this.createdAt,
  });

  final String id;
  final String applicationStatus;
  final String salonName;
  final String applicationType;
  final String? salonId;
  final String? description;
  final String? rejectionReason;
  final String? createdAt;

  bool get isPending => applicationStatus == 'PENDING_APPROVAL';
  bool get isRejected => applicationStatus == 'REJECTED';
  bool get isCreate => applicationType == 'CREATE';
  bool get isUpdate => applicationType == 'UPDATE';
  bool get isDeactivate =>
      applicationType == 'DEACTIVATE' || applicationType == 'CLOSE';
  bool get isActivate => applicationType == 'ACTIVATE';

  factory SalonApplicationModel.fromJson(Map<String, dynamic> json) =>
      SalonApplicationModel(
        id: json['id'] as String,
        applicationStatus: json['application_status'] as String,
        salonName: json['salon_name'] as String,
        applicationType: json['application_type'] as String? ?? 'CREATE',
        salonId: json['salon_id'] as String?,
        description: json['description'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: json['created_at']?.toString(),
      );
}
