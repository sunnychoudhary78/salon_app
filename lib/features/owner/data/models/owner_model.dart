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
  const OwnerBookingCustomer({this.name, this.phone, this.email});

  final String? name;
  final String? phone;
  final String? email;

  factory OwnerBookingCustomer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OwnerBookingCustomer();
    final user = json['user'] as Map<String, dynamic>?;
    return OwnerBookingCustomer(
      name: user?['name'] as String?,
      phone: user?['phone'] as String?,
      email: user?['email'] as String?,
    );
  }
}

class OwnerBookingModel {
  const OwnerBookingModel({
    required this.id,
    required this.bookingStatus,
    required this.bookingDate,
    required this.bookingTime,
    this.customer,
    this.serviceName,
    this.salonName,
    this.bookingNumber,
    this.bookingType,
    this.premiumAmount,
  });

  final String id;
  final String bookingStatus;
  final String bookingDate;
  final String bookingTime;
  final OwnerBookingCustomer? customer;
  final String? serviceName;
  final String? salonName;
  final String? bookingNumber;
  final String? bookingType;
  final double? premiumAmount;

  bool get isPremium => bookingType == 'PREMIUM';

  factory OwnerBookingModel.fromJson(Map<String, dynamic> json) =>
      OwnerBookingModel(
        id: json['id'].toString(),
        bookingStatus: json['booking_status'] as String,
        bookingDate: json['booking_date']?.toString() ?? '',
        bookingTime: json['booking_time'] as String? ?? '',
        bookingNumber: json['booking_number'] as String?,
        bookingType: json['booking_type'] as String?,
        premiumAmount: json['premium_amount'] == null
            ? null
            : (json['premium_amount'] as num).toDouble(),
        customer: OwnerBookingCustomer.fromJson(
          json['customer'] as Map<String, dynamic>?,
        ),
        serviceName: json['service']?['service_name'] as String?,
        salonName: json['salon']?['salon_name'] as String?,
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
