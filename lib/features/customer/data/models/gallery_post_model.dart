import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

class GalleryPostModel {
  const GalleryPostModel({
    required this.id,
    required this.salonId,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.staffId,
    this.serviceId,
    this.bookingId,
    this.customerId,
    this.title,
    this.description,
    this.isPublic = true,
    this.customerConsent = 'APPROVED',
    this.likesCount = 0,
    this.isFeatured = false,
    this.isLikedByMe = false,
    this.sortOrder = 0,
    this.staff,
    this.service,
    this.salonName,
    this.customerName,
    this.createdAt,
  });

  final String id;
  final String salonId;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String? staffId;
  final String? serviceId;
  final String? bookingId;
  final String? customerId;
  final String? title;
  final String? description;
  final bool isPublic;
  final String customerConsent;
  final int likesCount;
  final bool isFeatured;
  final bool isLikedByMe;
  final int sortOrder;
  final StaffModel? staff;
  final ServiceModel? service;
  final String? salonName;
  final String? customerName;
  final DateTime? createdAt;

  String? get staffName => staff?.name;
  String? get serviceName => service?.serviceName;

  String get fullBeforeImageUrl => resolveImageUrl(beforeImageUrl);
  String get fullAfterImageUrl => resolveImageUrl(afterImageUrl);

  GalleryPostModel copyWith({
    bool? isLikedByMe,
    int? likesCount,
    String? customerConsent,
  }) {
    return GalleryPostModel(
      id: id,
      salonId: salonId,
      beforeImageUrl: beforeImageUrl,
      afterImageUrl: afterImageUrl,
      staffId: staffId,
      serviceId: serviceId,
      bookingId: bookingId,
      customerId: customerId,
      title: title,
      description: description,
      isPublic: isPublic,
      customerConsent: customerConsent ?? this.customerConsent,
      likesCount: likesCount ?? this.likesCount,
      isFeatured: isFeatured,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      sortOrder: sortOrder,
      staff: staff,
      service: service,
      salonName: salonName,
      customerName: customerName,
      createdAt: createdAt,
    );
  }

  factory GalleryPostModel.fromJson(Map<String, dynamic> json) {
    StaffModel? staff;
    if (json['staff'] is Map<String, dynamic>) {
      staff = StaffModel.fromJson(json['staff'] as Map<String, dynamic>);
    }

    ServiceModel? service;
    if (json['service'] is Map<String, dynamic>) {
      service = ServiceModel.fromJson(json['service'] as Map<String, dynamic>);
    }

    String? salonName;
    if (json['salon'] is Map<String, dynamic>) {
      salonName = json['salon']['salon_name'] as String?;
    }

    String? customerName;
    if (json['customer'] is Map<String, dynamic>) {
      final cust = json['customer'] as Map<String, dynamic>;
      if (cust['user'] is Map<String, dynamic>) {
        customerName = cust['user']['name'] as String?;
      } else {
        customerName = cust['name'] as String?;
      }
    }

    return GalleryPostModel(
      id: json['id'] as String,
      salonId: json['salon_id'] as String,
      beforeImageUrl: json['before_image_url'] as String,
      afterImageUrl: json['after_image_url'] as String,
      staffId: json['staff_id'] as String?,
      serviceId: json['service_id'] as String?,
      bookingId: json['booking_id'] as String?,
      customerId: json['customer_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      customerConsent: json['customer_consent'] as String? ?? 'APPROVED',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      staff: staff,
      service: service,
      salonName: salonName,
      customerName: customerName,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

