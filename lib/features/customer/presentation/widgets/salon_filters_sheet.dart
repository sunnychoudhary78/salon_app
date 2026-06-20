import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/providers/salon_browse_filters_provider.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

Future<void> showSalonFiltersSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _SalonFiltersSheet(),
  );
}

class _SalonFiltersSheet extends ConsumerStatefulWidget {
  const _SalonFiltersSheet();

  @override
  ConsumerState<_SalonFiltersSheet> createState() => _SalonFiltersSheetState();
}

class _SalonFiltersSheetState extends ConsumerState<_SalonFiltersSheet> {
  double? _minRating;
  double? _maxDistanceKm;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final filters = ref.read(salonBrowseFiltersProvider);
      _minRating = filters.minRating;
      _maxDistanceKm = filters.maxDistanceKm;
      _initialized = true;
    }
  }

  bool get _hasGpsLocation {
    final loc = ref.read(selectedLocationProvider).location;
    return loc.isSet &&
        loc.source == LocationSource.gps &&
        loc.latitude != null &&
        loc.longitude != null;
  }

  void _apply() {
    ref.read(salonBrowseFiltersProvider.notifier).applyFilters(
          minRating: _minRating,
          maxDistanceKm: _hasGpsLocation ? _maxDistanceKm : null,
        );
    Navigator.pop(context);
  }

  void _clearAll() {
    ref.read(salonBrowseFiltersProvider.notifier).clearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasGps = _hasGpsLocation;

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
            'Filters',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Refine salons by distance and rating',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Distance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (!hasGps) ...[
            const SizedBox(height: 8),
            Text(
              'Enable GPS location to filter by distance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            _FilterChipRow(
              options: const [
                _FilterOption(label: 'Any', value: null),
                _FilterOption(label: '5 km', value: 5.0),
                _FilterOption(label: '10 km', value: 10.0),
                _FilterOption(label: '25 km', value: 25.0),
              ],
              selected: _maxDistanceKm,
              onSelected: (v) => setState(() => _maxDistanceKm = v),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Rating',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _FilterChipRow(
            options: const [
              _FilterOption(label: 'Any', value: null),
              _FilterOption(label: '3.0+', value: 3.0),
              _FilterOption(label: '4.0+', value: 4.0),
              _FilterOption(label: '4.5+', value: 4.5),
            ],
            selected: _minRating,
            onSelected: (v) => setState(() => _minRating = v),
          ),
          const SizedBox(height: 28),
          PremiumButton(
            label: 'Apply filters',
            variant: PremiumButtonVariant.primary,
            onPressed: _apply,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearAll,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.label, required this.value});

  final String label;
  final double? value;
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_FilterOption> options;
  final double? selected;
  final ValueChanged<double?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option.value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(option.value),
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSelected
                    ? AppColors.accentGradient
                    : LinearGradient(
                        colors: [
                          AppColors.surfaceElevated.withValues(alpha: 0.9),
                          AppColors.surface.withValues(alpha: 0.7),
                        ],
                      ),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.6)
                      : AppColors.glassBorder.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.backgroundDark
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
