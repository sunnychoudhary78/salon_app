class RewardModel {
  const RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.brandName,
    required this.rewardCode,
    this.image,
    this.externalUrl,
    this.rewardType = 'PARTNER_OFFER',
    this.validityDays,
  });

  final String id;
  final String title;
  final String description;
  final String brandName;
  final String rewardCode;
  final String? image;
  final String? externalUrl;
  final String rewardType;
  final int? validityDays;

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      brandName: (json['brand_name'] as String?) ?? 'Exclusive Partner',
      rewardCode: (json['reward_code'] as String?) ?? '',
      image: json['image'] as String?,
      externalUrl: json['external_url'] as String?,
      rewardType: (json['reward_type'] as String?) ?? 'PARTNER_OFFER',
      validityDays: json['validity_days'] != null
          ? int.tryParse(json['validity_days'].toString())
          : null,
    );
  }
}

class CustomerRewardModel {
  const CustomerRewardModel({
    required this.id,
    required this.customerId,
    required this.rewardId,
    required this.status,
    required this.unlockedAt,
    required this.expiresAt,
    this.bookingId,
    this.claimedAt,
    this.reward,
    this.bookingNumber,
    this.salonName,
  });

  final String id;
  final String customerId;
  final String? bookingId;
  final String rewardId;
  final String status;
  final DateTime unlockedAt;
  final DateTime? claimedAt;
  final DateTime expiresAt;
  final RewardModel? reward;
  final String? bookingNumber;
  final String? salonName;

  bool get isUnclaimed => status.toUpperCase() == 'UNCLAIMED';
  bool get isClaimed => status.toUpperCase() == 'CLAIMED';
  bool get isExpired {
    if (status.toUpperCase() == 'EXPIRED') return true;
    return isUnclaimed && DateTime.now().isAfter(expiresAt);
  }

  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  CustomerRewardModel copyWithClaimed({
    String? status,
    DateTime? claimedAt,
    RewardModel? reward,
  }) {
    return CustomerRewardModel(
      id: id,
      customerId: customerId,
      bookingId: bookingId,
      rewardId: rewardId,
      status: status ?? this.status,
      unlockedAt: unlockedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      expiresAt: expiresAt,
      reward: reward ?? this.reward,
      bookingNumber: bookingNumber,
      salonName: salonName,
    );
  }

  factory CustomerRewardModel.fromJson(Map<String, dynamic> json) {
    RewardModel? rewardModel;
    if (json['reward'] != null && json['reward'] is Map<String, dynamic>) {
      rewardModel = RewardModel.fromJson(json['reward'] as Map<String, dynamic>);
    }

    String? bookingNum;
    String? salonNm;
    if (json['booking'] != null && json['booking'] is Map<String, dynamic>) {
      final b = json['booking'] as Map<String, dynamic>;
      bookingNum = b['booking_number'] as String?;
      if (b['salon'] != null && b['salon'] is Map<String, dynamic>) {
        salonNm = (b['salon'] as Map<String, dynamic>)['salon_name'] as String?;
      }
    }

    return CustomerRewardModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString(),
      rewardId: json['reward_id']?.toString() ?? '',
      status: (json['status'] as String?) ?? 'UNCLAIMED',
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      claimedAt: json['claimed_at'] != null
          ? DateTime.tryParse(json['claimed_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 7)),
      reward: rewardModel,
      bookingNumber: bookingNum,
      salonName: salonNm,
    );
  }
}

