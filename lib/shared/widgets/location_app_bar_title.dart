import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class LocationAppBarTitle extends ConsumerWidget {
  const LocationAppBarTitle({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(selectedLocationProvider);
    final label = locationState.isLoading && !locationState.location.isSet
        ? 'Detecting location...'
        : locationState.location.isSet
            ? locationState.location.displayLabel
            : 'Select location';
    final isWarning =
        locationState.gpsDenied && !locationState.location.isSet;

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
                            color: AppColors.textSecondary,
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
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
