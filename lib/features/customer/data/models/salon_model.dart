import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/utils/json_parse_utils.dart';
import 'package:saloon_booking/features/payments/data/models/payment_model.dart';

double _parseDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
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

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.serviceName,
    required this.price,
    this.durationMinutes,
    this.description,
    this.discountPrice,
    this.status,
    this.serviceFor = SalonType.unisex,
  });

  final String id;
  final String serviceName;
  final double price;
  final int? durationMinutes;
  final String? description;
  final double? discountPrice;
  final String? status;
  final SalonType serviceFor;

  double get effectivePrice =>
      discountPrice != null && discountPrice! > 0 && discountPrice! < price
      ? discountPrice!
      : price;

  bool get hasActiveDiscount => effectivePrice < price;

  bool get isActive => status == null || status == 'ACTIVE';

  String get serviceForLabel => serviceFor.serviceAudienceLabel;

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'].toString(),
    serviceName: requireString(json, 'service_name'),
    price: _parseDouble(json['price']),
    durationMinutes: _parseInt(json['duration_minutes']),
    description: json['description'] as String?,
    discountPrice: json['discount_price'] == null
        ? null
        : _parseDouble(json['discount_price']),
    status: json['status'] as String?,
    serviceFor: SalonType.parse(json['service_for'] as String?),
  );

  Map<String, dynamic> toCreateJson({
    String? description,
    int? durationMinutes,
    double? discountPrice,
    String? status,
    SalonType? serviceFor,
  }) => {
    'service_name': serviceName,
    'price': price,
    'description': ?description,
    'duration_minutes': ?durationMinutes,
    'discount_price': ?discountPrice,
    'status': ?status,
    'service_for': (serviceFor ?? this.serviceFor).apiValue,
  };
}

class StaffModel {
  const StaffModel({
    required this.id,
    required this.name,
    this.profileImage,
    this.status,
    this.sortOrder = 0,
    this.averageRating,
    this.reviewCount = 0,
  });

  final String id;
  final String name;
  final String? profileImage;
  final String? status;
  final int sortOrder;
  final double? averageRating;
  final int reviewCount;

  bool get isActive => status == null || status == 'ACTIVE';

  /// Higher rating first; unrated last. Ties: reviewCount, sortOrder, name.
  static List<StaffModel> sortByRating(List<StaffModel> staff) {
    if (staff.length <= 1) return List<StaffModel>.from(staff);
    final sorted = List<StaffModel>.from(staff);
    sorted.sort((a, b) {
      final aRated = a.averageRating != null && a.reviewCount > 0;
      final bRated = b.averageRating != null && b.reviewCount > 0;
      if (aRated != bRated) return aRated ? -1 : 1;
      if (aRated && bRated) {
        final ratingDiff = b.averageRating!.compareTo(a.averageRating!);
        if (ratingDiff != 0) return ratingDiff;
        final countDiff = b.reviewCount.compareTo(a.reviewCount);
        if (countDiff != 0) return countDiff;
      }
      final sortDiff = a.sortOrder.compareTo(b.sortOrder);
      if (sortDiff != 0) return sortDiff;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
    id: json['id'].toString(),
    name: requireString(json, 'name'),
    profileImage: json['profile_image'] as String?,
    status: json['status'] as String?,
    sortOrder: _parseInt(json['sort_order']) ?? 0,
    averageRating: json['average_rating'] == null
        ? null
        : _parseDouble(json['average_rating']),
    reviewCount: _parseInt(json['review_count']) ?? 0,
  );
}

class SlotsTodaySummary {
  const SlotsTodaySummary({
    required this.total,
    required this.available,
    required this.status,
  });

  final int total;
  final int available;
  final String status;

  factory SlotsTodaySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SlotsTodaySummary(total: 0, available: 0, status: 'unknown');
    }
    return SlotsTodaySummary(
      total: json['total'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
    );
  }

  bool get shouldShowOnCard => status != 'unknown' && total > 0;

  String get infoLineLabel => switch (status) {
    'open' => '$available slot${available == 1 ? '' : 's'} open today',
    'limited' => 'Limited slots today',
    'full' => 'Fully booked today',
    _ => '',
  };
}

class PremiumConfigModel {
  const PremiumConfigModel({
    required this.enabled,
    required this.fee,
    required this.currency,
    this.paymentWindowMinutes = 15,
  });

  final bool enabled;
  final double fee;
  final String currency;
  final int paymentWindowMinutes;

  factory PremiumConfigModel.fromJson(Map<String, dynamic> json) {
    final rawWindow = json['payment_window_minutes'];
    final parsedWindow = rawWindow is int
        ? rawWindow
        : int.tryParse(rawWindow?.toString() ?? '') ?? 15;
    final window = parsedWindow < 1
        ? 15
        : (parsedWindow > 120 ? 120 : parsedWindow);
    return PremiumConfigModel(
      enabled: json['enabled'] as bool? ?? true,
      fee: _parseDouble(json['fee'], fallback: 199),
      currency: json['currency'] as String? ?? 'INR',
      paymentWindowMinutes: window,
    );
  }
}

class SalonSlotModel {
  const SalonSlotModel({
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    required this.premiumEligible,
    this.booking,
    this.blockNote,
  });

  final String slotStart;
  final String slotEnd;
  final String status;
  final bool premiumEligible;
  final Map<String, dynamic>? booking;
  final String? blockNote;

  String get displayLabel {
    final start = _formatTime(slotStart);
    final end = _formatTime(slotEnd);
    return '$start – $end';
  }

  /// Start time only, e.g. `1:00 PM` — denser slot chips.
  String get startLabel => _formatTime(slotStart);

  /// Hour component of [slotStart] (0–23), or 0 if unparsable.
  int get startHour {
    final parts = slotStart.split(':');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts[0]) ?? 0;
  }

  static String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  factory SalonSlotModel.fromJson(Map<String, dynamic> json) => SalonSlotModel(
    slotStart: requireString(json, 'slot_start'),
    slotEnd: requireString(json, 'slot_end'),
    status: requireString(json, 'status'),
    premiumEligible: json['premium_eligible'] as bool? ?? false,
    booking: json['booking'] as Map<String, dynamic>?,
    blockNote: json['block_note'] as String?,
  );
}

class SalonSlotsResponse {
  const SalonSlotsResponse({
    required this.date,
    this.openingTime,
    this.closingTime,
    required this.slots,
    required this.premiumConfig,
  });

  final String date;
  final String? openingTime;
  final String? closingTime;
  final List<SalonSlotModel> slots;
  final PremiumConfigModel premiumConfig;

  factory SalonSlotsResponse.fromJson(Map<String, dynamic> json) =>
      SalonSlotsResponse(
        date: json['date']?.toString() ?? '',
        openingTime: json['opening_time'] as String?,
        closingTime: json['closing_time'] as String?,
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((e) => SalonSlotModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        premiumConfig: PremiumConfigModel.fromJson(
          (json['premium_config'] as Map<String, dynamic>?) ?? {},
        ),
      );
}

class SalonModel {
  const SalonModel({
    required this.id,
    required this.salonName,
    this.salonType = SalonType.unisex,
    this.description,
    this.address,
    this.formattedAddress,
    this.locality,
    this.city,
    this.state,
    this.postalCode,
    this.coverImage,
    this.galleryImages = const [],
    this.previewImages = const [],
    this.phone,
    this.openingTime,
    this.closingTime,
    this.status,
    this.isActive = true,
    this.services = const [],
    this.slotsToday,
    this.isFeatured = false,
    this.hasDiscount = false,
    this.discountedServicesCount = 0,
    this.maxSavingsPercent = 0,
    this.hasServices = false,
    this.averageRating,
    this.reviewCount = 0,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.premiumBookingFee,
    this.staff = const [],
    this.isFavorite = false,
  });

  final String id;
  final String salonName;
  final SalonType salonType;
  final String? description;
  final String? address;
  final String? formattedAddress;
  final String? locality;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? coverImage;
  final List<String> galleryImages;
  final List<String> previewImages;
  final String? phone;
  final String? openingTime;
  final String? closingTime;
  final String? status;
  final bool isActive;
  final List<ServiceModel> services;
  final List<StaffModel> staff;
  final SlotsTodaySummary? slotsToday;
  final bool isFeatured;
  final bool hasDiscount;
  final int discountedServicesCount;
  final int maxSavingsPercent;
  final bool hasServices;
  final double? averageRating;
  final int reviewCount;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final double? premiumBookingFee;
  final bool isFavorite;

  bool get isActiveForCustomers => status == 'ACTIVE' && isActive;

  /// Title-case label matching web/admin salon status enum.
  String get statusLabel {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'SUSPENDED':
        return 'Suspended';
      case 'CLOSED':
        return 'Closed';
      default:
        return isActive ? 'Active' : 'Inactive';
    }
  }

  String? get displayCoverImage =>
      coverImage ?? (galleryImages.isNotEmpty ? galleryImages.first : null);

  List<String> get allDisplayImages {
    final seen = <String>{};
    return [
      if (coverImage != null && coverImage!.isNotEmpty && seen.add(coverImage!))
        coverImage!,
      for (final image in galleryImages)
        if (image.isNotEmpty && seen.add(image)) image,
    ];
  }

  List<String> get carouselImages {
    if (previewImages.isNotEmpty) return previewImages;
    return allDisplayImages;
  }

  static String? _parseImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['medium'] as String? ??
          value['full'] as String? ??
          value['thumb'] as String?;
    }
    if (value is Map) {
      return value['medium']?.toString() ??
          value['full']?.toString() ??
          value['thumb']?.toString();
    }
    return null;
  }

  static List<String> _parseImageUrlList(List<dynamic>? raw) {
    return (raw ?? [])
        .map(_parseImageUrl)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
  }

  factory SalonModel.fromJson(Map<String, dynamic> json) => SalonModel(
    id: json['id'].toString(),
    salonName: requireString(json, 'salon_name'),
    salonType: SalonType.parse(json['salon_type'] as String?),
    description: json['description'] as String?,
    address: (json['street'] as String? ?? json['address'] as String?),
    formattedAddress: json['formatted_address'] as String?,
    locality: json['locality'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    postalCode: json['postal_code'] as String?,
    coverImage: _parseImageUrl(json['cover_image']),
    galleryImages: _parseImageUrlList(json['gallery_images'] as List<dynamic>?),
    previewImages: _parseImageUrlList(json['preview_images'] as List<dynamic>?),
    phone: json['phone'] as String?,
    openingTime: json['opening_time'] as String?,
    closingTime: json['closing_time'] as String?,
    status: json['status'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    isFeatured: json['is_featured'] as bool? ?? false,
    hasDiscount: json['has_discount'] as bool? ?? false,
    discountedServicesCount: _parseInt(json['discounted_services_count']) ?? 0,
    maxSavingsPercent: _parseInt(json['max_savings_percent']) ?? 0,
    hasServices:
        json['has_services'] as bool? ??
        ((json['services'] as List<dynamic>? ?? []).isNotEmpty),
    averageRating: json['average_rating'] == null
        ? null
        : _parseDouble(json['average_rating']),
    reviewCount: _parseInt(json['review_count']) ?? 0,
    latitude: json['latitude'] == null ? null : _parseDouble(json['latitude']),
    longitude: json['longitude'] == null
        ? null
        : _parseDouble(json['longitude']),
    distanceKm: json['distance_km'] == null
        ? null
        : _parseDouble(json['distance_km']),
    premiumBookingFee: json['premium_booking_fee'] == null
        ? null
        : _parseDouble(json['premium_booking_fee']),
    services: (json['services'] as List<dynamic>? ?? [])
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    staff: StaffModel.sortByRating(
      (json['staff'] as List<dynamic>? ?? [])
          .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    slotsToday: json['slots_today'] != null
        ? SlotsTodaySummary.fromJson(
            json['slots_today'] as Map<String, dynamic>,
          )
        : null,
    isFavorite: json['is_favorite'] as bool? ?? false,
  );
}

class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkType,
    this.linkTarget,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? linkType;
  final String? linkTarget;

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    id: json['id'] as String,
    title: json['title'] as String,
    imageUrl: json['image_url'] as String?,
    linkType: json['link_type'] as String?,
    linkTarget: json['link_target'] as String?,
  );
}

class BookingSalonRef {
  const BookingSalonRef({
    required this.id,
    required this.salonName,
    this.phone,
  });

  final String id;
  final String salonName;
  final String? phone;

  factory BookingSalonRef.fromJson(Map<String, dynamic> json) =>
      BookingSalonRef(
        id: json['id'] as String,
        salonName: requireString(json, 'salon_name'),
        phone: json['phone'] as String?,
      );
}

class BookingServiceRef {
  const BookingServiceRef({
    required this.serviceName,
    this.price,
    this.discountPrice,
    this.durationMinutes,
  });

  final String serviceName;
  final double? price;
  final double? discountPrice;
  final int? durationMinutes;

  double? get effectivePrice {
    final priceValue = price;
    final discountValue = discountPrice;
    if (priceValue == null) return null;
    if (discountValue != null &&
        discountValue > 0 &&
        discountValue < priceValue) {
      return discountValue;
    }
    return priceValue;
  }

  factory BookingServiceRef.fromJson(Map<String, dynamic> json) =>
      BookingServiceRef(
        serviceName: requireString(json, 'service_name'),
        price: json['price'] == null ? null : _parseDouble(json['price']),
        discountPrice: json['discount_price'] == null
            ? null
            : _parseDouble(json['discount_price']),
        durationMinutes: _parseInt(json['duration_minutes']),
      );
}

class BookingStaffRef {
  const BookingStaffRef({
    required this.id,
    required this.name,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;

  factory BookingStaffRef.fromJson(Map<String, dynamic> json) =>
      BookingStaffRef(
        id: json['id'].toString(),
        name: requireString(json, 'name'),
        profileImage: json['profile_image'] as String?,
      );
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.bookingStatus,
    required this.bookingDate,
    required this.bookingTime,
    this.groupId,
    this.bookingNumber,
    this.bookingType,
    this.premiumAmount,
    this.salon,
    this.service,
    this.staff,
    this.notes,
    this.rejectionReason,
    this.premiumPaymentStatus,
    this.premiumPaymentDueAt,
    this.payments = const [],
    this.premiumPayment,
    this.salonFeePayment,
    this.hasReview = false,
    this.canReview = false,
    this.slotEnded = false,
  });

  final String id;
  final String bookingStatus;
  final String bookingDate;
  final String bookingTime;
  final String? groupId;
  final String? bookingNumber;
  final String? bookingType;
  final double? premiumAmount;
  final BookingSalonRef? salon;
  final BookingServiceRef? service;
  final BookingStaffRef? staff;
  final String? notes;
  final String? rejectionReason;
  final String? premiumPaymentStatus;
  final DateTime? premiumPaymentDueAt;
  final List<PaymentModel> payments;
  final PaymentModel? premiumPayment;
  final PaymentModel? salonFeePayment;
  final bool hasReview;
  final bool canReview;
  final bool slotEnded;

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: json['id'].toString(),
    bookingStatus: json['booking_status'] as String,
    bookingDate: json['booking_date']?.toString() ?? '',
    bookingTime: json['booking_time'] as String? ?? '',
    groupId: json['booking_group_id']?.toString(),
    bookingNumber: json['booking_number'] as String?,
    bookingType: json['booking_type'] as String?,
    premiumAmount: json['premium_amount'] == null
        ? null
        : _parseDouble(json['premium_amount']),
    notes: json['notes'] as String?,
    rejectionReason: json['rejection_reason'] as String?,
    premiumPaymentStatus: json['premium_payment_status'] as String?,
    premiumPaymentDueAt: _parseDate(json['premium_payment_due_at']),
    payments: (json['payments'] as List<dynamic>? ?? [])
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    premiumPayment: json['premium_payment'] == null
        ? null
        : PaymentModel.fromJson(
            json['premium_payment'] as Map<String, dynamic>,
          ),
    salonFeePayment: json['salon_fee_payment'] == null
        ? null
        : PaymentModel.fromJson(
            json['salon_fee_payment'] as Map<String, dynamic>,
          ),
    salon: json['salon'] != null
        ? BookingSalonRef.fromJson(json['salon'] as Map<String, dynamic>)
        : null,
    service: json['service'] != null
        ? BookingServiceRef.fromJson(json['service'] as Map<String, dynamic>)
        : null,
    staff: json['staff'] != null
        ? BookingStaffRef.fromJson(json['staff'] as Map<String, dynamic>)
        : null,
    hasReview: json['has_review'] as bool? ?? json['review'] != null,
    canReview: json['can_review'] as bool? ?? false,
    slotEnded: json['slot_ended'] as bool? ?? false,
  );

  bool get canCancel =>
      bookingStatus == 'PENDING' || bookingStatus == 'ACCEPTED';

  bool get isPremium => bookingType == 'PREMIUM';
  bool get isAccepted => bookingStatus == 'ACCEPTED';
  bool get isConfirmed =>
      bookingStatus == 'ACCEPTED' || bookingStatus == 'COMPLETED';
  bool get isPremiumPaid => !isPremium || premiumPaymentStatus == 'PAID';
  bool get needsPremiumPayment =>
      isAccepted &&
      isPremium &&
      premiumPaymentStatus != 'PAID' &&
      !premiumPaymentExpired;
  bool get premiumPaymentExpired =>
      isAccepted &&
      isPremium &&
      premiumPaymentStatus != 'PAID' &&
      premiumPaymentDueAt != null &&
      !premiumPaymentDueAt!.isAfter(DateTime.now());
  bool get salonFeePaid => salonFeePayment?.isPaid == true;
  bool get salonFeePayAtShop => salonFeePayment?.isPayAtShop == true;
  bool get canChooseSalonPayment =>
      isAccepted && isPremiumPaid && !salonFeePaid && !salonFeePayAtShop;
}

class CouponModel {
  const CouponModel({
    required this.code,
    required this.discountType,
    required this.discountValue,
  });

  final String code;
  final String discountType;
  final double discountValue;

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
    code: json['code'] as String,
    discountType: json['discount_type'] as String,
    discountValue: _parseDouble(json['discount_value']),
  );
}

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.rating,
    this.staffRating,
    this.staffName,
    this.review,
    this.customerName,
    this.salonName,
    this.status,
    this.createdAt,
  });

  final String id;
  final int rating;
  final int? staffRating;
  final String? staffName;
  final String? review;
  final String? customerName;
  final String? salonName;
  final String? status;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'].toString(),
    rating: _parseInt(json['rating']) ?? 0,
    staffRating: _parseInt(json['staff_rating']),
    staffName: json['staff_name'] as String? ??
        json['booking']?['staff']?['name'] as String?,
    review: json['review'] as String?,
    customerName:
        json['customer_name'] as String? ??
        json['customer']?['user']?['name'] as String?,
    salonName: json['salon']?['salon_name'] as String?,
    status: json['status'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );
}

class SalonReviewsResult {
  const SalonReviewsResult({
    required this.reviews,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<ReviewModel> reviews;
  final int total;
  final int limit;
  final int offset;
}

List<T> parseDataList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final list = (json as Map<String, dynamic>)['data'] as List<dynamic>;
  return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}

class BrowseSalonsResult {
  const BrowseSalonsResult({
    required this.salons,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  final List<SalonModel> salons;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  factory BrowseSalonsResult.fromJson(
    Map<String, dynamic> json,
    SalonModel Function(Map<String, dynamic>) fromJsonSalon,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final salons = parseDataList(json, fromJsonSalon);
    final limit = meta['limit'] as int? ?? salons.length;
    final offset = meta['offset'] as int? ?? 0;
    final total = meta['total'] as int? ?? salons.length;
    final hasMore =
        meta['has_more'] as bool? ?? (offset + salons.length < total);
    return BrowseSalonsResult(
      salons: salons,
      total: total,
      limit: limit,
      offset: offset,
      hasMore: hasMore,
    );
  }
}
