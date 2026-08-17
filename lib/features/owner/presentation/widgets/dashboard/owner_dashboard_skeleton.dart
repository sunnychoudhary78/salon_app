import 'package:flutter/material.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_dashboard_segment_provider.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_layout.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';

/// Loading placeholder shaped like the segment that is about to appear.
class OwnerDashboardSkeleton extends StatelessWidget {
  const OwnerDashboardSkeleton({
    super.key,
    required this.segment,
    required this.scrollPadding,
  });

  final OwnerDashboardSegment segment;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: scrollPadding,
      physics: const NeverScrollableScrollPhysics(),
      children: switch (segment) {
        OwnerDashboardSegment.today => const [
          _Block(height: 220),
          kOwnerSectionSpacer,
          _Block(height: 56),
          kOwnerTightSpacer,
          _Block(height: 96),
          kOwnerTightSpacer,
          _Block(height: 96),
        ],
        OwnerDashboardSegment.money => const [
          _Block(height: 190),
          kOwnerSectionSpacer,
          _Block(height: 260),
          kOwnerSectionSpacer,
          _Block(height: 220),
        ],
        OwnerDashboardSegment.growth => const [
          _Block(height: 230),
          kOwnerSectionSpacer,
          _Block(height: 130),
          kOwnerSectionSpacer,
          _Block(height: 200),
        ],
      },
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: double.infinity, height: height, radius: 16);
  }
}
