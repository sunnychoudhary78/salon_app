import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class LocationAppBarTitle extends ConsumerWidget {
  const LocationAppBarTitle({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final locationState = ref.watch(selectedLocationProvider);
    final isWarning = locationState.gpsDenied && !locationState.location.isSet;
    final label = locationState.isLoading && !locationState.location.isSet
        ? 'Detecting location...'
        : locationState.location.isSet
        ? locationState.location.displayLabel
        : locationState.gpsDenied
        ? 'Location unavailable'
        : 'Select location';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isWarning
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : colors.glassBorder.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isWarning ? AppColors.warning : colors.accent)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: isWarning ? AppColors.warning : colors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your location',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isWarning
                            ? AppColors.warning
                            : colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
