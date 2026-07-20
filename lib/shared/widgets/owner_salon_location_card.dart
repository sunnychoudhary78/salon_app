import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/salon_geocoding.dart';
import 'package:saloon_booking/features/owner/data/models/salon_location_selection.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/owner_salon_location_map_sheet.dart';

class OwnerSalonLocationCard extends StatelessWidget {
  const OwnerSalonLocationCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SalonLocationSelection? value;
  final ValueChanged<SalonLocationSelection?> onChanged;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showOwnerSalonLocationMapSheet(
      context,
      initial: value,
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final confirmed = value?.isConfirmed == true && value!.isComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salon location *',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: 10),
        if (!confirmed)
          GlassCard(
            onTap: () => _openSheet(context),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_location_alt_rounded,
                    color: colors.onAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search & pin on map',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find your salon, adjust the map, and confirm',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textMuted,
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.glass(context, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value!.displayLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (value!.detailLine.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              value!.detailLine,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            formatCoordinatesLabel(
                              value!.latitude,
                              value!.longitude,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openSheet(context),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
