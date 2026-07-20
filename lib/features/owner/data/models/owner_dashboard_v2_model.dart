// V2 deferred UI: reputation strip, customer insights, top_services,
// by_salon cards, utilization donut, premium revenue trends
// (needs summary.premium.revenue_today, performance.premium_trend[]).

class OwnerDashboardV2Model {
  const OwnerDashboardV2Model({
    required this.meta,
    required this.summary,
    required this.attention,
    required this.schedule,
    required this.performance,
  });

  final OwnerDashboardMeta meta;
  final OwnerDashboardSummary summary;
  final OwnerDashboardAttention attention;
  final OwnerDashboardSchedule schedule;
  final OwnerDashboardPerformance performance;

  int get premiumTodayCount => schedule.appointments
      .where((a) => a.hasPremiumService)
      .length;

  int get premiumUnpaidCount {
    for (final section in attention.sections) {
      if (section.type == 'premium_unpaid') return section.count;
    }
    return 0;
  }

  factory OwnerDashboardV2Model.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return OwnerDashboardV2Model(
      meta: OwnerDashboardMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
      summary: OwnerDashboardSummary.fromJson(
        data['summary'] as Map<String, dynamic>? ?? const {},
      ),
      attention: OwnerDashboardAttention.fromJson(
        data['attention'] as Map<String, dynamic>? ?? const {},
      ),
      schedule: OwnerDashboardSchedule.fromJson(
        data['schedule'] as Map<String, dynamic>? ?? const {},
      ),
      performance: OwnerDashboardPerformance.fromJson(
        data['performance'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class OwnerDashboardMeta {
  const OwnerDashboardMeta({
    required this.salonIds,
    required this.salonCount,
    this.scopedSalonId,
    required this.date,
    required this.timezone,
    required this.currency,
    this.generatedAt,
    this.period,
  });

  final List<String> salonIds;
  final int salonCount;
  final String? scopedSalonId;
  final String date;
  final String timezone;
  final String currency;
  final String? generatedAt;
  final OwnerDashboardPeriodInfo? period;

  factory OwnerDashboardMeta.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardMeta(
        salonIds: (json['salon_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        salonCount: json['salon_count'] as int? ?? 0,
        scopedSalonId: json['scoped_salon_id']?.toString(),
        date: json['date']?.toString() ?? '',
        timezone: json['timezone'] as String? ?? 'UTC',
        currency: json['currency'] as String? ?? 'INR',
        generatedAt: json['generated_at']?.toString(),
        period: json['period'] is Map<String, dynamic>
            ? OwnerDashboardPeriodInfo.fromJson(
                json['period'] as Map<String, dynamic>,
              )
            : null,
      );
}

class OwnerDashboardPeriodInfo {
  const OwnerDashboardPeriodInfo({
    required this.key,
    this.from,
    this.to,
    required this.label,
    this.granularity = 'day',
  });

  final String key;
  final String? from;
  final String? to;
  final String label;
  final String granularity;

  factory OwnerDashboardPeriodInfo.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardPeriodInfo(
        key: json['key'] as String? ?? '7d',
        from: json['from']?.toString(),
        to: json['to']?.toString(),
        label: json['label'] as String? ?? 'Last 7 days',
        granularity: json['granularity'] as String? ?? 'day',
      );
}

class OwnerDashboardSummary {
  const OwnerDashboardSummary({
    required this.bookings,
    required this.revenue,
    required this.earnings,
    required this.reputation,
    required this.premiumBookingsCount,
    required this.utilization,
    required this.profileCompleteness,
    required this.notifications,
    required this.bySalon,
  });

  final OwnerDashboardBookingsSummary bookings;
  final OwnerDashboardRevenueSummary revenue;
  final OwnerDashboardEarningsSummary earnings;
  final OwnerDashboardReputationSummary reputation;
  final int premiumBookingsCount;
  final OwnerDashboardUtilization utilization;
  final OwnerDashboardProfileCompleteness profileCompleteness;
  final OwnerDashboardNotifications notifications;
  final List<OwnerDashboardSalonSummary> bySalon;

  factory OwnerDashboardSummary.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardSummary(
        bookings: OwnerDashboardBookingsSummary.fromJson(
          json['bookings'] as Map<String, dynamic>? ?? const {},
        ),
        revenue: OwnerDashboardRevenueSummary.fromJson(
          json['revenue'] as Map<String, dynamic>? ?? const {},
        ),
        earnings: OwnerDashboardEarningsSummary.fromJson(
          json['earnings'] as Map<String, dynamic>? ?? const {},
        ),
        reputation: OwnerDashboardReputationSummary.fromJson(
          json['reputation'] as Map<String, dynamic>? ?? const {},
        ),
        premiumBookingsCount: json['premium_bookings_count'] as int? ?? 0,
        utilization: OwnerDashboardUtilization.fromJson(
          json['utilization'] as Map<String, dynamic>? ?? const {},
        ),
        profileCompleteness: OwnerDashboardProfileCompleteness.fromJson(
          json['profile_completeness'] as Map<String, dynamic>? ?? const {},
        ),
        notifications: OwnerDashboardNotifications.fromJson(
          json['notifications'] as Map<String, dynamic>? ?? const {},
        ),
        bySalon: (json['by_salon'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardSalonSummary.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
      );
}

class OwnerDashboardBookingsSummary {
  const OwnerDashboardBookingsSummary({
    required this.pending,
    required this.upcoming,
    required this.today,
    this.completedInPeriod = 0,
  });

  final int pending;
  final int upcoming;
  final int today;
  final int completedInPeriod;

  factory OwnerDashboardBookingsSummary.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardBookingsSummary(
        pending: json['pending'] as int? ?? 0,
        upcoming: json['upcoming'] as int? ?? 0,
        today: json['today'] as int? ?? 0,
        completedInPeriod: json['completed_in_period'] as int? ?? 0,
      );
}

class OwnerDashboardRevenueSummary {
  const OwnerDashboardRevenueSummary({
    required this.todayGross,
    this.periodGross,
    this.period,
  });

  final double todayGross;
  final double? periodGross;
  final OwnerDashboardPeriodInfo? period;

  double get displayGross => periodGross ?? todayGross;

  factory OwnerDashboardRevenueSummary.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardRevenueSummary(
        todayGross: _toDouble(json['today_gross']),
        periodGross: json['period_gross'] != null
            ? _toDouble(json['period_gross'])
            : null,
        period: json['period'] is Map<String, dynamic>
            ? OwnerDashboardPeriodInfo.fromJson(
                json['period'] as Map<String, dynamic>,
              )
            : null,
      );
}

class OwnerDashboardEarningsSummary {
  const OwnerDashboardEarningsSummary({
    required this.pending,
    required this.inBatch,
    required this.pendingTotal,
    required this.settled,
    this.collectedAtSalon = 0,
    this.platformFeeOwed = 0,
  });

  final double pending;
  final double inBatch;
  final double pendingTotal;
  final double settled;
  final double collectedAtSalon;
  final double platformFeeOwed;

  factory OwnerDashboardEarningsSummary.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardEarningsSummary(
        pending: _toDouble(json['pending']),
        inBatch: _toDouble(json['in_batch']),
        pendingTotal: _toDouble(json['pending_total']),
        settled: _toDouble(json['settled']),
        collectedAtSalon: _toDouble(json['collected_at_salon']),
        platformFeeOwed: _toDouble(json['platform_fee_owed']),
      );
}

class OwnerDashboardReputationSummary {
  const OwnerDashboardReputationSummary({
    this.averageRating,
    required this.reviewCount,
  });

  final double? averageRating;
  final int reviewCount;

  factory OwnerDashboardReputationSummary.fromJson(
    Map<String, dynamic> json,
  ) =>
      OwnerDashboardReputationSummary(
        averageRating: json['average_rating'] == null
            ? null
            : _toDouble(json['average_rating']),
        reviewCount: json['review_count'] as int? ?? 0,
      );
}

class OwnerDashboardUtilization {
  const OwnerDashboardUtilization({
    required this.percent,
    required this.occupiedSlots,
    required this.totalSlots,
    required this.availableSlots,
    required this.status,
  });

  final double percent;
  final int occupiedSlots;
  final int totalSlots;
  final int availableSlots;
  final String status;

  factory OwnerDashboardUtilization.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardUtilization(
        percent: _toDouble(json['percent']),
        occupiedSlots: json['occupied_slots'] as int? ?? 0,
        totalSlots: json['total_slots'] as int? ?? 0,
        availableSlots: json['available_slots'] as int? ?? 0,
        status: json['status'] as String? ?? 'unknown',
      );
}

class OwnerDashboardProfileCompleteness {
  const OwnerDashboardProfileCompleteness({
    required this.averagePercent,
    required this.incompleteCount,
    required this.salons,
  });

  final int averagePercent;
  final int incompleteCount;
  final List<OwnerDashboardProfileSalon> salons;

  factory OwnerDashboardProfileCompleteness.fromJson(
    Map<String, dynamic> json,
  ) =>
      OwnerDashboardProfileCompleteness(
        averagePercent: json['average_percent'] as int? ?? 100,
        incompleteCount: json['incomplete_count'] as int? ?? 0,
        salons: (json['salons'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardProfileSalon.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
      );
}

class OwnerDashboardProfileSalon {
  const OwnerDashboardProfileSalon({
    required this.salonId,
    required this.salonName,
    required this.missing,
    required this.completenessPercent,
  });

  final String salonId;
  final String salonName;
  final List<String> missing;
  final int completenessPercent;

  factory OwnerDashboardProfileSalon.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardProfileSalon(
        salonId: json['salon_id']?.toString() ?? '',
        salonName: json['salon_name'] as String? ?? '',
        missing: (json['missing'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        completenessPercent: json['completeness_percent'] as int? ?? 0,
      );
}

class OwnerDashboardNotifications {
  const OwnerDashboardNotifications({required this.unreadCount});

  final int unreadCount;

  factory OwnerDashboardNotifications.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardNotifications(
        unreadCount: json['unread_count'] as int? ?? 0,
      );
}

class OwnerDashboardSalonSummary {
  const OwnerDashboardSalonSummary({
    required this.salonId,
    required this.salonName,
    required this.todayBookings,
    required this.utilizationPercent,
  });

  final String salonId;
  final String salonName;
  final int todayBookings;
  final double utilizationPercent;

  factory OwnerDashboardSalonSummary.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardSalonSummary(
        salonId: json['salon_id']?.toString() ?? '',
        salonName: json['salon_name'] as String? ?? '',
        todayBookings: json['today_bookings'] as int? ?? 0,
        utilizationPercent: _toDouble(json['utilization_percent']),
      );
}

class OwnerDashboardAttention {
  const OwnerDashboardAttention({
    required this.totalCount,
    required this.sections,
  });

  final int totalCount;
  final List<OwnerDashboardAttentionSection> sections;

  factory OwnerDashboardAttention.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardAttention(
        totalCount: json['total_count'] as int? ?? 0,
        sections: (json['sections'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardAttentionSection.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
      );
}

class OwnerDashboardAttentionSection {
  const OwnerDashboardAttentionSection({
    required this.type,
    required this.count,
    required this.severity,
    required this.items,
  });

  final String type;
  final int count;
  final String severity;
  final List<OwnerDashboardAttentionItem> items;

  factory OwnerDashboardAttentionSection.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardAttentionSection(
        type: json['type'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        severity: json['severity'] as String? ?? 'low',
        items: (json['items'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardAttentionItem.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
      );
}

class OwnerDashboardAttentionItem {
  const OwnerDashboardAttentionItem({
    this.visitId,
    this.bookingId,
    this.bookingNumber,
    this.customerName,
    this.salonName,
    this.bookingDate,
    this.bookingTime,
    this.createdAt,
    this.isPremium = false,
    this.paymentId,
    this.amount,
    this.premiumAmount,
    this.premiumPaymentStatus,
    this.issue,
    this.message,
    this.salonId,
    this.missing,
    this.completenessPercent,
  });

  final String? visitId;
  final String? bookingId;
  final String? bookingNumber;
  final String? customerName;
  final String? salonName;
  final String? bookingDate;
  final String? bookingTime;
  final String? createdAt;
  final bool isPremium;
  final String? paymentId;
  final double? amount;
  final double? premiumAmount;
  final String? premiumPaymentStatus;
  final String? issue;
  final String? message;
  final String? salonId;
  final List<String>? missing;
  final int? completenessPercent;

  factory OwnerDashboardAttentionItem.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardAttentionItem(
        visitId: json['visit_id']?.toString(),
        bookingId: json['booking_id']?.toString(),
        bookingNumber: json['booking_number'] as String?,
        customerName: json['customer_name'] as String?,
        salonName: json['salon_name'] as String?,
        bookingDate: json['booking_date']?.toString(),
        bookingTime: json['booking_time'] as String?,
        createdAt: json['created_at']?.toString(),
        isPremium: json['is_premium'] as bool? ?? false,
        paymentId: json['payment_id']?.toString(),
        amount: json['amount'] == null ? null : _toDouble(json['amount']),
        premiumAmount: json['premium_amount'] == null
            ? null
            : _toDouble(json['premium_amount']),
        premiumPaymentStatus: json['premium_payment_status'] as String?,
        issue: json['issue'] as String?,
        message: json['message'] as String?,
        salonId: json['salon_id']?.toString(),
        missing: (json['missing'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        completenessPercent: json['completeness_percent'] as int?,
      );
}

class OwnerDashboardSchedule {
  const OwnerDashboardSchedule({
    required this.appointments,
    this.next,
    required this.pagination,
  });

  final List<OwnerDashboardAppointment> appointments;
  final OwnerDashboardNextAppointment? next;
  final OwnerDashboardSchedulePagination pagination;

  factory OwnerDashboardSchedule.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardSchedule(
        appointments: (json['appointments'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardAppointment.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
        next: json['next'] == null
            ? null
            : OwnerDashboardNextAppointment.fromJson(
                json['next'] as Map<String, dynamic>,
              ),
        pagination: OwnerDashboardSchedulePagination.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

class OwnerDashboardNextAppointment {
  const OwnerDashboardNextAppointment({
    required this.visitId,
    required this.startsAt,
  });

  final String visitId;
  final String startsAt;

  factory OwnerDashboardNextAppointment.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardNextAppointment(
        visitId: json['visit_id']?.toString() ?? '',
        startsAt: json['starts_at']?.toString() ?? '',
      );
}

class OwnerDashboardSchedulePagination {
  const OwnerDashboardSchedulePagination({
    required this.limit,
    required this.hasMore,
    this.nextCursor,
  });

  final int limit;
  final bool hasMore;
  final String? nextCursor;

  factory OwnerDashboardSchedulePagination.fromJson(
    Map<String, dynamic> json,
  ) =>
      OwnerDashboardSchedulePagination(
        limit: json['limit'] as int? ?? 20,
        hasMore: json['has_more'] as bool? ?? false,
        nextCursor: json['next_cursor']?.toString(),
      );
}

class OwnerDashboardAppointment {
  const OwnerDashboardAppointment({
    required this.visitId,
    required this.bookingDate,
    required this.bookingTime,
    required this.bookingStatus,
    this.salon,
    this.customer,
    required this.services,
    this.paymentSummary,
  });

  final String visitId;
  final String bookingDate;
  final String bookingTime;
  final String bookingStatus;
  final OwnerDashboardAppointmentSalon? salon;
  final OwnerDashboardAppointmentCustomer? customer;
  final List<OwnerDashboardAppointmentService> services;
  final OwnerDashboardPaymentSummary? paymentSummary;

  bool get hasPremiumService =>
      services.any((s) => s.bookingType == 'PREMIUM');

  String? get premiumPaymentStatus {
    for (final s in services) {
      if (s.bookingType == 'PREMIUM' && s.premiumPaymentStatus != null) {
        return s.premiumPaymentStatus;
      }
    }
    return null;
  }

  String get serviceSummary {
    if (services.isEmpty) return 'Appointment';
    if (services.length == 1) return services.first.serviceName ?? 'Service';
    return '${services.first.serviceName ?? 'Service'} +${services.length - 1}';
  }

  factory OwnerDashboardAppointment.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardAppointment(
        visitId: json['visit_id']?.toString() ?? '',
        bookingDate: json['booking_date']?.toString() ?? '',
        bookingTime: json['booking_time'] as String? ?? '',
        bookingStatus: json['booking_status'] as String? ?? '',
        salon: json['salon'] == null
            ? null
            : OwnerDashboardAppointmentSalon.fromJson(
                json['salon'] as Map<String, dynamic>,
              ),
        customer: json['customer'] == null
            ? null
            : OwnerDashboardAppointmentCustomer.fromJson(
                json['customer'] as Map<String, dynamic>,
              ),
        services: (json['services'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardAppointmentService.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
        paymentSummary: json['payment_summary'] == null
            ? null
            : OwnerDashboardPaymentSummary.fromJson(
                json['payment_summary'] as Map<String, dynamic>,
              ),
      );
}

class OwnerDashboardAppointmentSalon {
  const OwnerDashboardAppointmentSalon({this.id, this.salonName});

  final String? id;
  final String? salonName;

  factory OwnerDashboardAppointmentSalon.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardAppointmentSalon(
        id: json['id']?.toString(),
        salonName: json['salon_name'] as String?,
      );
}

class OwnerDashboardAppointmentCustomer {
  const OwnerDashboardAppointmentCustomer({this.id, this.name, this.phone});

  final String? id;
  final String? name;
  final String? phone;

  factory OwnerDashboardAppointmentCustomer.fromJson(
    Map<String, dynamic> json,
  ) =>
      OwnerDashboardAppointmentCustomer(
        id: json['id']?.toString(),
        name: json['name'] as String?,
        phone: json['phone'] as String?,
      );
}

class OwnerDashboardAppointmentService {
  const OwnerDashboardAppointmentService({
    this.bookingId,
    this.bookingNumber,
    this.serviceId,
    this.serviceName,
    this.bookingType,
    this.premiumAmount,
    this.premiumPaymentStatus,
  });

  final String? bookingId;
  final String? bookingNumber;
  final String? serviceId;
  final String? serviceName;
  final String? bookingType;
  final double? premiumAmount;
  final String? premiumPaymentStatus;

  factory OwnerDashboardAppointmentService.fromJson(
    Map<String, dynamic> json,
  ) =>
      OwnerDashboardAppointmentService(
        bookingId: json['booking_id']?.toString(),
        bookingNumber: json['booking_number'] as String?,
        serviceId: json['service_id']?.toString(),
        serviceName: json['service_name'] as String?,
        bookingType: json['booking_type'] as String?,
        premiumAmount: json['premium_amount'] == null
            ? null
            : _toDouble(json['premium_amount']),
        premiumPaymentStatus: json['premium_payment_status'] as String?,
      );
}

class OwnerDashboardPaymentSummary {
  const OwnerDashboardPaymentSummary({
    this.premiumStatus,
    this.salonFeeStatus,
    this.method,
    this.requiresCashConfirmation = false,
    this.checkoutGroupId,
  });

  final String? premiumStatus;
  final String? salonFeeStatus;
  final String? method;
  final bool requiresCashConfirmation;
  final String? checkoutGroupId;

  factory OwnerDashboardPaymentSummary.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardPaymentSummary(
        premiumStatus: json['premium_status'] as String?,
        salonFeeStatus: json['salon_fee_status'] as String?,
        method: json['method'] as String?,
        requiresCashConfirmation:
            json['requires_cash_confirmation'] as bool? ?? false,
        checkoutGroupId: json['checkout_group_id']?.toString(),
      );
}

class OwnerDashboardPerformance {
  const OwnerDashboardPerformance({
    required this.period,
    required this.bookingTrend,
    required this.revenueTrend,
    required this.topServices,
    required this.customers,
    this.cached = false,
  });

  final OwnerDashboardPerformancePeriod period;
  final List<OwnerDashboardTrendPoint> bookingTrend;
  final List<OwnerDashboardRevenueTrendPoint> revenueTrend;
  final List<OwnerDashboardTopService> topServices;
  final OwnerDashboardCustomers customers;
  final bool cached;

  factory OwnerDashboardPerformance.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardPerformance(
        period: OwnerDashboardPerformancePeriod.fromJson(
          json['period'] as Map<String, dynamic>? ?? const {},
        ),
        bookingTrend: (json['booking_trend'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardTrendPoint.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
        revenueTrend: (json['revenue_trend'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardRevenueTrendPoint.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
        topServices: (json['top_services'] as List<dynamic>?)
                ?.map(
                  (e) => OwnerDashboardTopService.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
        customers: OwnerDashboardCustomers.fromJson(
          json['customers'] as Map<String, dynamic>? ?? const {},
        ),
        cached: json['cached'] as bool? ?? false,
      );
}

class OwnerDashboardPerformancePeriod {
  const OwnerDashboardPerformancePeriod({
    this.days,
    this.from,
    required this.to,
    this.key = '7d',
    this.label = 'Last 7 days',
    this.granularity = 'day',
  });

  final int? days;
  final String? from;
  final String to;
  final String key;
  final String label;
  final String granularity;

  bool get isMonthly => granularity == 'month';

  factory OwnerDashboardPerformancePeriod.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardPerformancePeriod(
        days: json['days'] as int?,
        from: json['from']?.toString(),
        to: json['to']?.toString() ?? '',
        key: json['key'] as String? ?? '7d',
        label: json['label'] as String? ?? 'Last 7 days',
        granularity: json['granularity'] as String? ?? 'day',
      );
}

class OwnerDashboardTrendPoint {
  const OwnerDashboardTrendPoint({required this.date, required this.count});

  final String date;
  final int count;

  factory OwnerDashboardTrendPoint.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardTrendPoint(
        date: json['date']?.toString() ?? '',
        count: json['count'] as int? ?? 0,
      );
}

class OwnerDashboardRevenueTrendPoint {
  const OwnerDashboardRevenueTrendPoint({
    required this.date,
    required this.amount,
  });

  final String date;
  final double amount;

  factory OwnerDashboardRevenueTrendPoint.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardRevenueTrendPoint(
        date: json['date']?.toString() ?? '',
        amount: _toDouble(json['amount']),
      );
}

class OwnerDashboardTopService {
  const OwnerDashboardTopService({
    required this.serviceId,
    required this.serviceName,
    required this.bookingCount,
    required this.revenue,
    required this.rank,
  });

  final String serviceId;
  final String serviceName;
  final int bookingCount;
  final double revenue;
  final int rank;

  factory OwnerDashboardTopService.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardTopService(
        serviceId: json['service_id']?.toString() ?? '',
        serviceName: json['service_name'] as String? ?? '',
        bookingCount: json['booking_count'] as int? ?? 0,
        revenue: _toDouble(json['revenue']),
        rank: json['rank'] as int? ?? 0,
      );
}

class OwnerDashboardCustomers {
  const OwnerDashboardCustomers({
    required this.newCustomers,
    required this.returning,
    required this.totalActive,
    required this.newPercent,
  });

  final int newCustomers;
  final int returning;
  final int totalActive;
  final double newPercent;

  factory OwnerDashboardCustomers.fromJson(Map<String, dynamic> json) =>
      OwnerDashboardCustomers(
        newCustomers: json['new'] as int? ?? 0,
        returning: json['returning'] as int? ?? 0,
        totalActive: json['total_active'] as int? ?? 0,
        newPercent: _toDouble(json['new_percent']),
      );
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
