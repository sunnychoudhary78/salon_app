import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_booking_focus_provider.dart';

extension OwnerDashboardAppointmentUi on OwnerDashboardAppointment {
  String get servicesDisplay {
    if (services.isEmpty) return 'Appointment';
    return services
        .map((s) => s.serviceName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  String? get primaryBookingId {
    for (final service in services) {
      final id = service.bookingId;
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  String? get primaryBookingNumber {
    for (final service in services) {
      final number = service.bookingNumber;
      if (number != null && number.isNotEmpty) return number;
    }
    return null;
  }

  String? get paymentHint {
    final summary = paymentSummary;
    if (summary == null) return null;
    if (summary.requiresCashConfirmation) {
      return 'Cash payment needs confirmation';
    }
    final premium = summary.premiumStatus?.toUpperCase();
    if (premium == 'PENDING' || premium == 'UNPAID' || premium == 'FAILED') {
      return 'Premium payment pending';
    }
    final salonFee = summary.salonFeeStatus?.toUpperCase();
    if (salonFee == 'PENDING') {
      final method = summary.method?.toUpperCase();
      if (method == 'PAY_AT_SHOP') return 'Salon fee: pay at shop';
      return 'Salon fee payment pending';
    }
    if (salonFee == 'PAID') return 'Salon fee paid';
    return null;
  }
}

void openOwnerBookingFocus(
  WidgetRef ref,
  BuildContext context, {
  required String bookingId,
  bool openDetail = true,
}) {
  if (bookingId.isEmpty) {
    context.go(RoutePaths.ownerBookings);
    return;
  }
  ref.read(ownerBookingsTodayFilterProvider.notifier).clear();
  ref
      .read(ownerBookingFocusProvider.notifier)
      .set(OwnerBookingFocus(bookingId: bookingId, openDetail: openDetail));
  context.go(RoutePaths.ownerBookings);
}
