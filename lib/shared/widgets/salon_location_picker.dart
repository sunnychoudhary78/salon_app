import 'package:flutter/material.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/salon_geocoding.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class SalonLocationPicker extends StatefulWidget {
  const SalonLocationPicker({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    this.latitude,
    this.longitude,
    this.locationLabel,
    required this.onLocationSet,
    required this.onClear,
  });

  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final void Function(double latitude, double longitude, String label)
      onLocationSet;
  final VoidCallback onClear;

  bool get isSet => latitude != null && longitude != null;

  @override
  State<SalonLocationPicker> createState() => _SalonLocationPickerState();
}

class _SalonLocationPickerState extends State<SalonLocationPicker> {
  final _locationService = UserLocationService();
  bool _loading = false;
  String? _error;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final coords = await _locationService.getCurrentLocation();
      if (!mounted) return;
      if (coords == null) {
        setState(() {
          _loading = false;
          _error = 'Could not get GPS — enable location permission';
        });
        return;
      }

      final label = await resolveSalonLocationLabel(
        coords.latitude,
        coords.longitude,
      );
      if (!mounted) return;
      widget.onLocationSet(coords.latitude, coords.longitude, label);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not get current location';
      });
    }
  }

  Future<void> _findFromAddress() async {
    final address = widget.addressController.text.trim();
    final city = widget.cityController.text.trim();
    final state = widget.stateController.text.trim();

    if (address.isEmpty || city.isEmpty || state.isEmpty) {
      setState(() => _error = 'Fill address, city, and state first');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await geocodeSalonAddress(
      address: address,
      city: city,
      state: state,
    );

    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'Could not find this address — check and try again';
      });
      return;
    }

    widget.onLocationSet(result.latitude, result.longitude, result.label);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isSet = widget.isSet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salon location *',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        if (isSet)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
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
                        widget.locationLabel ??
                            formatCoordinatesLabel(
                              widget.latitude!,
                              widget.longitude!,
                            ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        formatCoordinatesLabel(
                          widget.latitude!,
                          widget.longitude!,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : widget.onClear,
                  child: const Text('Change'),
                ),
              ],
            ),
          )
        else
          Text(
            'Set the exact salon location so customers see distance from them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (!isSet) ...[
          const SizedBox(height: 12),
          PremiumButton(
            label: 'Use current location',
            icon: Icons.my_location_rounded,
            loading: _loading,
            onPressed: _loading ? null : _useCurrentLocation,
          ),
          const SizedBox(height: 10),
          PremiumButton(
            label: 'Find from address',
            icon: Icons.search_rounded,
            variant: PremiumButtonVariant.ghost,
            loading: _loading,
            onPressed: _loading ? null : _findFromAddress,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ],
      ],
    );
  }
}
