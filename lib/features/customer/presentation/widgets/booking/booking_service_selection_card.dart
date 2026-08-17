import 'package:flutter/material.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/service_artwork.dart';
import 'package:saloon_booking/shared/widgets/tap_scale_wrapper.dart';

class BookingServiceSelectionCard extends StatelessWidget {
  const BookingServiceSelectionCard({
    super.key,
    required this.service,
    required this.selected,
    required this.onTap,
    this.audience = AudienceMode.men,
  });

  final ServiceModel service;
  final bool selected;
  final VoidCallback onTap;
  final AudienceMode audience;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasDiscount = service.hasActiveDiscount;
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${service.serviceName}, '
          '${service.durationMinutes ?? 30} minutes, '
          '${formatMoney(service.effectivePrice)}',
      child: TapScaleWrapper(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? colors.accentSoft : colors.surfaceElevated,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? colors.accent
                  : colors.glassBorder.withValues(alpha: 0.75),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? colors.cardShadow(
                    color: colors.glowAccent.withValues(alpha: 0.18),
                  )
                : colors.cardShadow(),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceArtwork(
                serviceName: service.serviceName,
                audience: audience,
                size: 78,
                padding: const EdgeInsets.all(9),
                borderRadius: 15,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            service.serviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            key: ValueKey(selected),
                            color: selected ? colors.accent : colors.textMuted,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    if (service.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceSunken,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.durationMinutes ?? 30} min',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (hasDiscount) ...[
                          Text(
                            formatMoney(service.price),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          formatMoney(service.effectivePrice),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: hasDiscount
                                    ? AppColors.success
                                    : colors.accent,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
