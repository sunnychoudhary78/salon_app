import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';

const _editFocusFields = {
  'cover_image',
  'gallery_images',
  'description',
  'phone',
  'hours',
  'opening_time',
  'closing_time',
};

String? _normalizeFocusField(String? field) {
  if (field == null || field.isEmpty) return null;
  if (field == 'opening_time' || field == 'closing_time') return 'hours';
  return field;
}

/// Navigates to the screen/section for the first incomplete salon profile gap.
void navigateToProfileCompletenessGap(
  BuildContext context,
  OwnerDashboardProfileCompleteness profileCompleteness,
) {
  final salons = profileCompleteness.salons
      .where((s) => s.completenessPercent < 100)
      .toList();
  if (salons.isEmpty) {
    context.go(RoutePaths.ownerSalons);
    return;
  }
  if (salons.length > 1) {
    context.go(RoutePaths.ownerSalons);
    return;
  }
  navigateToProfileGap(context, salons.first);
}

/// Navigates to the first missing field for a single incomplete salon.
void navigateToProfileGap(
  BuildContext context,
  OwnerDashboardProfileSalon salon, {
  List<String>? missingOverride,
}) {
  final salonId = salon.salonId;
  if (salonId.isEmpty) {
    context.go(RoutePaths.ownerSalons);
    return;
  }

  final missing = missingOverride ?? salon.missing;
  final focus = _normalizeFocusField(missing.isNotEmpty ? missing.first : null);

  if (focus == 'active_services') {
    context.push('${RoutePaths.ownerSalons}/$salonId/services');
    return;
  }

  if (focus != null && _editFocusFields.contains(focus)) {
    context.push(
      '${RoutePaths.ownerSalons}/$salonId/edit?focus=$focus',
    );
    return;
  }

  context.push('${RoutePaths.ownerSalons}/$salonId/edit');
}

/// Variant for attention-center items that only carry salonId + missing.
void navigateToProfileGapFromAttention(
  BuildContext context, {
  required String? salonId,
  List<String>? missing,
}) {
  if (salonId == null || salonId.isEmpty) {
    context.go(RoutePaths.ownerSalons);
    return;
  }

  navigateToProfileGap(
    context,
    OwnerDashboardProfileSalon(
      salonId: salonId,
      salonName: '',
      missing: missing ?? const [],
      completenessPercent: 0,
    ),
    missingOverride: missing,
  );
}
