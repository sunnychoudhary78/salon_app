import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

class SalonPromoChips extends StatelessWidget {
  const SalonPromoChips({super.key, required this.salon});

  final SalonModel salon;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (salon.isFeatured) {
      chips.add(
        _PromoChip(
          label: 'FEATURED',
          icon: Icons.workspace_premium_rounded,
          gradient: AppColors.accentGradient,
        ),
      );
    }
    if (salon.hasDiscount || salon.discountedServicesCount > 0) {
      final String dealLabel;
      if (salon.maxSavingsPercent > 0) {
        dealLabel = '${salon.maxSavingsPercent}% OFF';
      } else if (salon.discountedServicesCount > 0) {
        dealLabel = salon.discountedServicesCount > 1
            ? '${salon.discountedServicesCount} OFFERS'
            : '1 OFFER';
      } else {
        dealLabel = 'DEAL';
      }
      chips.add(
        _PromoChip(
          label: dealLabel,
          icon: Icons.local_offer_rounded,
          gradient: LinearGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.95),
              AppColors.success.withValues(alpha: 0.75),
            ],
          ),
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.backgroundDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.backgroundDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
