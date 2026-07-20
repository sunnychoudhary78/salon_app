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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 22,
                color: isWarning ? AppColors.warning : AppColors.accent,
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
                            color: colors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
