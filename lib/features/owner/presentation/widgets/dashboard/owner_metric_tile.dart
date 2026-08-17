import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

/// The single metric presentation used across every owner dashboard segment.
///
/// Replaces the three competing patterns the old dashboard shipped: the tinted
/// KPI chip, the finance card's accent-bordered block, and the premium strip's
/// inner chips.
class OwnerMetricTile extends StatelessWidget {
  const OwnerMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Defaults to the theme accent so tiles stay palette-aware.
  final Color? tint;

  /// Optional third line, e.g. "of 40 slots".
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;
    final accent = tint ?? colors.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        child: AnimatedContainer(
          duration: kMicroDuration,
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall?.copyWith(color: colors.textMuted),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall?.copyWith(
                    color: colors.textMuted.withValues(alpha: 0.75),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays metric tiles out in an evenly divided row of equal-height cells.
class OwnerMetricGroup extends StatelessWidget {
  const OwnerMetricGroup({super.key, required this.tiles, this.spacing = 8});

  final List<OwnerMetricTile> tiles;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    // IntrinsicHeight is what lets `stretch` equalise tile heights here: these
    // rows sit in unbounded-height lists, where stretch alone would resolve to
    // an infinite height constraint.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

/// Label/value line used inside the finance and growth cards.
class OwnerMetricLine extends StatelessWidget {
  const OwnerMetricLine({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool muted;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.bodySmall?.copyWith(
              color: muted ? colors.textSecondary : colors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? (muted ? colors.textSecondary : null),
          ),
        ),
      ],
    );
  }
}
