import 'package:flutter/material.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';

class OwnerDashboardSkeleton extends StatelessWidget {
  const OwnerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        const ShimmerBox(width: double.infinity, height: 56, radius: 12),
        const SizedBox(height: 16),
        const ShimmerBox(width: double.infinity, height: 88, radius: 14),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 88, radius: 14),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: ShimmerBox(width: double.infinity, height: 72, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: ShimmerBox(width: double.infinity, height: 72, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: ShimmerBox(width: double.infinity, height: 72, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: ShimmerBox(width: double.infinity, height: 72, radius: 14)),
          ],
        ),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 160, radius: 16),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 72, radius: 14),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 76, radius: 14),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 72, radius: 14),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 72, radius: 14),
        const SizedBox(height: 8),
        const ShimmerBox(width: double.infinity, height: 72, radius: 14),
        const SizedBox(height: 8),
        const ShimmerBox(width: double.infinity, height: 72, radius: 14),
        const SizedBox(height: 16),
        const ShimmerBox(width: double.infinity, height: 180, radius: 16),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 180, radius: 16),
      ],
    );
  }
}
