import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

Future<void> showLocationPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet();

  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  final _cityController = TextEditingController();
  bool _gpsLoading = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsLoading = true);
    final ok =
        await ref.read(selectedLocationProvider.notifier).refreshGps();
    if (!mounted) return;
    setState(() => _gpsLoading = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _applyCity() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    await ref.read(selectedLocationProvider.notifier).setManualCity(city);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(selectedLocationProvider);
    final current = locationState.location;
    final isGpsActive =
        current.isSet && current.source == LocationSource.gps;
    final isCityActive =
        current.isSet && current.source == LocationSource.manualCity;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'See salons near you or filter by city',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          _LocationOptionCard(
            icon: Icons.my_location_rounded,
            title: 'Use current location',
            subtitle: isGpsActive ? current.displayLabel : 'Detect via GPS',
            isActive: isGpsActive,
            isLoading: _gpsLoading || locationState.isLoading,
            onTap: _gpsLoading ? null : _useCurrentLocation,
          ),
          if (locationState.gpsDenied) ...[
            const SizedBox(height: 10),
            Text(
              'Location permission is off. Enable it in settings or search by city.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
            ),
            TextButton(
              onPressed: Geolocator.openAppSettings,
              child: const Text('Open settings'),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.glassBorder.withValues(alpha: 0.6),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.glassBorder.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _cityController,
            label: 'Search city',
            hint: 'e.g. Mumbai, Bengaluru',
            prefixIcon: const Icon(Icons.location_city_rounded),
            onChanged: (_) => setState(() {}),
          ),
          if (isCityActive) ...[
            const SizedBox(height: 8),
            Text(
              'Active: ${current.displayLabel}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          PremiumButton(
            label: 'Apply city',
            variant: PremiumButtonVariant.primary,
            onPressed: _cityController.text.trim().isEmpty ? null : _applyCity,
          ),
        ],
      ),
    );
  }
}

class _LocationOptionCard extends StatelessWidget {
  const _LocationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: isActive
                  ? AppColors.accentGradient
                  : LinearGradient(
                      colors: [
                        AppColors.surfaceElevated,
                        AppColors.surface,
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppColors.backgroundDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isActive)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.accent,
              size: 22,
            ),
        ],
      ),
    );
  }
}
