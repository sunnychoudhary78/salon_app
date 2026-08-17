import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';

/// One pending multi-service request (grouped by booking group id).
class PendingBookingRequest {
  const PendingBookingRequest({
    required this.representativeId,
    required this.groupKey,
    required this.bookingDate,
    required this.bookingTime,
    required this.serviceNames,
    this.customerName,
    this.customerPhotoUrl,
    this.salonName,
    this.amount,
    this.isPremium = false,
  });

  /// Booking id used for accept/reject APIs (any row in the group).
  final String representativeId;
  final String groupKey;
  final String bookingDate;
  final String bookingTime;
  final String serviceNames;
  final String? customerName;
  final String? customerPhotoUrl;
  final String? salonName;
  final double? amount;
  final bool isPremium;

  DateTime? get sortDateTime => parseBookingDateTime(bookingDate, bookingTime);
}

List<PendingBookingRequest> buildPendingBookingQueue(
  List<OwnerBookingModel> pendingItems,
) {
  final groups = <String, List<OwnerBookingModel>>{};
  for (final booking in pendingItems) {
    final key = booking.groupId ?? 'single:${booking.id}';
    groups.putIfAbsent(key, () => <OwnerBookingModel>[]).add(booking);
  }

  final requests = groups.entries.map((entry) {
    final group = entry.value;
    final first = group.first;
    final services = group
        .map((b) => b.serviceName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final amount = group.fold<double>(
      0,
      (sum, b) => sum + (b.premiumAmount ?? 0),
    );
    final hasAmount = group.any((b) => b.premiumAmount != null);

    return PendingBookingRequest(
      representativeId: first.id,
      groupKey: entry.key,
      bookingDate: first.bookingDate,
      bookingTime: first.bookingTime,
      serviceNames: services.isEmpty ? 'Service' : services.join(', '),
      customerName: first.customer?.name,
      customerPhotoUrl: first.customer?.profileImage,
      salonName: first.salonName,
      amount: hasAmount ? amount : null,
      isPremium: ownerGroupIsPremium(group),
    );
  }).toList();

  requests.sort((a, b) {
    final aDt = a.sortDateTime;
    final bDt = b.sortDateTime;
    if (aDt != null && bDt != null) {
      final cmp = aDt.compareTo(bDt);
      if (cmp != 0) return cmp;
    } else if (aDt != null) {
      return -1;
    } else if (bDt != null) {
      return 1;
    }
    return a.representativeId.compareTo(b.representativeId);
  });

  return requests;
}
