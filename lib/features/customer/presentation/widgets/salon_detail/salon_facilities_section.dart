import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

/// Facility chips from real salon flags only (no invented amenities).
class SalonFacilitiesSection extends StatelessWidget {
  const SalonFacilitiesSection({super.key, required this.salon});

  final SalonModel salon;

  List<String> get _chips {
    final chips = <String>[];
    if (salon.isFeatured) chips.add('Featured');
    if (salon.hasDiscount) chips.add('Offers');
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final chips = _chips;
    if (chips.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Facilities',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in chips)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.appColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    chip,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
