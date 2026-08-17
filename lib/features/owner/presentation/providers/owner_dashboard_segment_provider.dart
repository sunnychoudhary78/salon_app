import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three owner dashboard views. Replaces the single long scroll that
/// stacked operations, finance and performance on top of each other.
enum OwnerDashboardSegment {
  today('Today'),
  money('Money'),
  growth('Growth');

  const OwnerDashboardSegment(this.label);

  final String label;
}

/// Which segment the dashboard is showing. Held outside the screen so
/// notification taps and deep links can land on a specific view.
class OwnerDashboardSegmentNotifier extends Notifier<OwnerDashboardSegment> {
  @override
  OwnerDashboardSegment build() => OwnerDashboardSegment.today;

  void select(OwnerDashboardSegment segment) => state = segment;
}

final ownerDashboardSegmentProvider =
    NotifierProvider<OwnerDashboardSegmentNotifier, OwnerDashboardSegment>(
      OwnerDashboardSegmentNotifier.new,
    );
