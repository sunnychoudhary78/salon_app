import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
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
    this.showStatus = false,
  });

  final ServiceModel service;
  final VoidCallback? onTap;
  final bool selected;
  final bool multiSelect;
  final bool showBookAffordance;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                  color: selected ? context.appColors.accent : colors.textMuted,
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
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (service.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${service.durationMinutes ?? 30} min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (showStatus) ...[
                        const SizedBox(width: 8),
                        _ServiceStatusPill(
                          label: service.isActive ? 'Active' : 'Inactive',
                          active: service.isActive,
                        ),
                      ],
                    ],
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
                      color: colors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  '₹${service.effectivePrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: hasDiscount
                        ? AppColors.success
                        : context.appColors.accent,
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
                  color: context.appColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.appColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Book',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: context.appColors.accent.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ],
            if (selected && !multiSelect) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, color: context.appColors.accent),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceStatusPill extends StatelessWidget {
  const _ServiceStatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : context.appColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
