import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class LocationErrorHint extends StatelessWidget {
  const LocationErrorHint({
    super.key,
    required this.failure,
    this.showOpenSettings = true,
  });

  final LocationFetchFailure? failure;
  final bool showOpenSettings;

  bool get _shouldShowSettings {
    if (!showOpenSettings) return false;
    return failure == LocationFetchFailure.permissionDenied ||
        failure == LocationFetchFailure.permissionDeniedForever;
  }

  @override
  Widget build(BuildContext context) {
    if (failure == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          locationFailureMessage(failure),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
              ),
        ),
        if (_shouldShowSettings) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: Geolocator.openAppSettings,
            child: const Text('Open settings'),
          ),
        ],
      ],
    );
  }
}
