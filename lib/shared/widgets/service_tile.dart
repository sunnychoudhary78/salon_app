import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.service,
    this.onTap,
    this.selected = false,
    this.multiSelect = false,
    this.showBookAffordance = false,
  });

  final ServiceModel service;
  final VoidCallback? onTap;
  final bool selected;
  final bool multiSelect;
  final bool showBookAffordance;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = service.hasActiveDiscount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (multiSelect)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${service.category?.name ?? 'General'} · ${service.durationMinutes ?? 30} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    '₹${service.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  '₹${service.effectivePrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: hasDiscount ? AppColors.success : AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (showBookAffordance && !multiSelect) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Book',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.accent.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ],
            if (selected && !multiSelect) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: AppColors.accent),
            ],
          ],
        ),
      ),
    );
  }
}
