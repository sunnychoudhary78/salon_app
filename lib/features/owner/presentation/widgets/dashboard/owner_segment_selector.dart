import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_dashboard_segment_provider.dart';

/// Sliding segmented control that switches between the three dashboard views.
class OwnerSegmentSelector extends StatelessWidget {
  const OwnerSegmentSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final OwnerDashboardSegment selected;
  final ValueChanged<OwnerDashboardSegment> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const segments = OwnerDashboardSegment.values;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _SegmentTab(
                label: segment.label,
                selected: segment == selected,
                onTap: () {
                  if (segment == selected) return;
                  HapticFeedback.selectionClick();
                  onSelect(segment);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: kMicroDuration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.elevationShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colors.textPrimary : colors.textMuted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
