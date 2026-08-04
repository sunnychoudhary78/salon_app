import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

class SalonWhyChooseItem {
  const SalonWhyChooseItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

double? minServicePrice(SalonModel salon) {
  if (salon.services.isEmpty) return null;
  return salon.services
      .map((s) => s.effectivePrice)
      .reduce((a, b) => a < b ? a : b);
}

int avgServiceDurationMinutes(SalonModel salon) {
  if (salon.services.isEmpty) return 30;
  final durations = salon.services.map((s) => s.durationMinutes ?? 30).toList();
  final sum = durations.fold<int>(0, (a, b) => a + b);
  return (sum / durations.length).round();
}

String salonLocationLine(SalonModel salon) {
  final parts = [
    if (salon.locality != null && salon.locality!.isNotEmpty) salon.locality,
    if (salon.city != null) salon.city,
    if (salon.state != null) salon.state,
    if (salon.postalCode != null && salon.postalCode!.isNotEmpty)
      salon.postalCode,
  ];
  final locationLine = parts.join(', ');
  if (salon.formattedAddress?.isNotEmpty == true) {
    return salon.formattedAddress!;
  }
  if (salon.address?.isNotEmpty == true) {
    return '${salon.address}\n$locationLine';
  }
  return locationLine;
}

String salonShortLocation(SalonModel salon) {
  final city = salon.city;
  final locality = salon.locality;
  if (locality != null && locality.isNotEmpty && city != null) {
    return '$locality, $city';
  }
  return city ?? locality ?? salon.state ?? 'Location';
}

String? salonHoursLabel(SalonModel salon) {
  if (salon.openingTime == null || salon.closingTime == null) return null;
  return '${formatSalonTimeDisplay(salon.openingTime)} – ${formatSalonTimeDisplay(salon.closingTime)}';
}

bool salonIsVerified(SalonModel salon) =>
    salon.status == 'ACTIVE' && salon.isActive;

bool salonIsOpenNow(SalonModel salon) =>
    isSalonOpenNow(salon.openingTime, salon.closingTime);

List<SalonWhyChooseItem> whyChooseItems(SalonModel salon) {
  final items = <SalonWhyChooseItem>[];
  if (salon.staff.isNotEmpty) {
    items.add(
      const SalonWhyChooseItem(
        icon: Icons.groups_rounded,
        title: 'Experienced Staff',
        subtitle: 'Skilled stylists ready to serve you',
      ),
    );
  }
  if (salon.isFeatured) {
    items.add(
      const SalonWhyChooseItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Featured Salon',
        subtitle: 'Handpicked premium experience',
      ),
    );
  }
  if (salon.hasDiscount) {
    items.add(
      const SalonWhyChooseItem(
        icon: Icons.local_offer_rounded,
        title: 'Great Offers',
        subtitle: 'Exclusive discounts available',
      ),
    );
  }
  final rating = salon.averageRating ?? 0;
  if (rating >= 4.0 && salon.reviewCount >= 5) {
    items.add(
      const SalonWhyChooseItem(
        icon: Icons.star_rounded,
        title: 'Highly Rated',
        subtitle: 'Loved by customers',
      ),
    );
  }
  return items;
}

List<SalonModel> similarSalons(
  List<SalonModel> all,
  String currentSalonId, {
  int limit = 8,
}) {
  final others = all.where((s) => s.id != currentSalonId).toList()
    ..sort((a, b) {
      final da = a.distanceKm;
      final db = b.distanceKm;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
  return others.take(limit).toList();
}

String formatDistanceKm(double? km) {
  if (km == null) return '—';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

BoxDecoration premiumCardDecoration(BuildContext context) {
  final colors = context.appColors;
  return BoxDecoration(
    color: colors.surfaceElevated,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: colors.glassBorder.withValues(alpha: 0.4)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

BoxDecoration compactSalonDetailCardDecoration(BuildContext context) {
  final colors = context.appColors;
  return BoxDecoration(
    color: colors.surfaceElevated,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colors.glassBorder.withValues(alpha: 0.45)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
