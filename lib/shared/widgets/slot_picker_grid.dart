import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

enum _SlotPeriod { morning, afternoon, evening }

_SlotPeriod _periodForHour(int hour) {
  if (hour < 12) return _SlotPeriod.morning;
  if (hour < 17) return _SlotPeriod.afternoon;
  return _SlotPeriod.evening;
}

extension on _SlotPeriod {
  String get label => switch (this) {
    _SlotPeriod.morning => 'Morning',
    _SlotPeriod.afternoon => 'Afternoon',
    _SlotPeriod.evening => 'Evening',
  };

  IconData get icon => switch (this) {
    _SlotPeriod.morning => Icons.wb_sunny_outlined,
    _SlotPeriod.afternoon => Icons.wb_twilight_outlined,
    _SlotPeriod.evening => Icons.nights_stay_outlined,
  };
}

class SlotPickerGrid extends StatelessWidget {
  const SlotPickerGrid({
    super.key,
    required this.slots,
    this.selectedSlotStart,
    this.onSlotTap,
    this.ownerMode = false,
    this.premiumFee,
  });

  final List<SalonSlotModel> slots;
  final String? selectedSlotStart;
  final void Function(SalonSlotModel slot)? onSlotTap;
  final bool ownerMode;

  /// Kept for call-site compatibility (urgent fee shown in booking chrome).
  // ignore: unused_field
  final double? premiumFee;

  Map<_SlotPeriod, List<SalonSlotModel>> _groupedSlots() {
    final map = <_SlotPeriod, List<SalonSlotModel>>{
      for (final period in _SlotPeriod.values) period: <SalonSlotModel>[],
    };
    for (final slot in slots) {
      map[_periodForHour(slot.startHour)]!.add(slot);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No operating hours configured for this salon.',
          style: TextStyle(color: context.appColors.textMuted),
        ),
      );
    }

    final grouped = _groupedSlots();
    final periods = _SlotPeriod.values
        .where((p) => grouped[p]!.isNotEmpty)
        .toList();
    final listKey = slots.map((s) => s.slotStart).join('|');

    final children = <Widget>[];
    var tileIndex = 0;
    for (var i = 0; i < periods.length; i++) {
      final period = periods[i];
      final periodSlots = grouped[period]!;
      if (i > 0) children.add(const SizedBox(height: 16));
      children.add(_PeriodHeader(period: period, count: periodSlots.length));
      children.add(const SizedBox(height: 10));
      children.add(
        _SlotTileGrid(
          slots: periodSlots,
          selectedSlotStart: selectedSlotStart,
          ownerMode: ownerMode,
          onSlotTap: onSlotTap,
          startIndex: tileIndex,
          animateKeyPrefix: '$listKey|${period.name}',
        ),
      );
      tileIndex += periodSlots.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.period, required this.count});

  final _SlotPeriod period;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Icon(period.icon, size: 16, color: colors.accent),
        const SizedBox(width: 6),
        Text(
          period.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SlotTileGrid extends StatelessWidget {
  const _SlotTileGrid({
    required this.slots,
    required this.selectedSlotStart,
    required this.ownerMode,
    required this.startIndex,
    required this.animateKeyPrefix,
    this.onSlotTap,
  });

  final List<SalonSlotModel> slots;
  final String? selectedSlotStart;
  final bool ownerMode;
  final void Function(SalonSlotModel slot)? onSlotTap;
  final int startIndex;
  final String animateKeyPrefix;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 4 : 3;
        const spacing = 8.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < slots.length; i++)
              SizedBox(
                width: tileWidth,
                child: _SlotChip(
                  slot: slots[i],
                  selected: selectedSlotStart == slots[i].slotStart,
                  ownerMode: ownerMode,
                  onTap: onSlotTap == null ? null : () => onSlotTap!(slots[i]),
                ).appEntrance(
                  context: context,
                  style: EntranceStyle.fadeUp,
                  index: startIndex + i,
                  animateKey: ValueKey('${animateKeyPrefix}_$i'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SlotChip extends StatefulWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.ownerMode,
    this.onTap,
  });

  final SalonSlotModel slot;
  final bool selected;
  final bool ownerMode;
  final VoidCallback? onTap;

  @override
  State<_SlotChip> createState() => _SlotChipState();
}

class _SlotChipState extends State<_SlotChip> {
  int _pulseGeneration = 0;

  @override
  void didUpdateWidget(covariant _SlotChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected) {
      _pulseGeneration++;
    }
  }

  bool get _isPremiumEligible =>
      !widget.ownerMode &&
      widget.slot.premiumEligible &&
      widget.slot.status != 'past';

  bool get _isTappable {
    if (widget.onTap == null) return false;
    if (widget.ownerMode) return widget.slot.status != 'past';
    return widget.slot.status == 'available' || _isPremiumEligible;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = _styleFor(context, widget.slot.status, widget.selected);
    final showUrgentBadge = _isPremiumEligible;
    final isTaken =
        widget.slot.status == 'booked' || widget.slot.status == 'blocked';

    Widget chip = AnimatedContainer(
      duration: kMicroDuration,
      curve: Curves.easeOutCubic,
      height: widget.ownerMode ? 52 : 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: widget.selected ? colors.accentGradient : null,
        color: widget.selected ? null : style.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.selected
              ? colors.accent.withValues(alpha: 0.55)
              : style.border,
          width: widget.selected ? 1.5 : 1,
        ),
        boxShadow: widget.selected
            ? [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.ownerMode) ...[
                  Icon(
                    _iconFor(widget.slot.status),
                    size: 13,
                    color: style.foreground,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    widget.slot.startLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: style.foreground,
                      fontSize: 12.5,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      letterSpacing: -0.1,
                      decoration:
                          !widget.selected && isTaken && !_isPremiumEligible
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: style.foreground.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showUrgentBadge)
            Positioned(
              top: 4,
              right: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? colors.onAccent.withValues(alpha: 0.2)
                      : colors.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 11,
                  color: widget.selected ? colors.onAccent : colors.accent,
                ),
              ),
            ),
        ],
      ),
    );

    if (!animationsDisabled(context) && widget.selected) {
      chip = chip
          .animate(key: ValueKey(_pulseGeneration))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
            duration: kMicroDuration,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.04, 1.04),
            end: const Offset(1, 1),
            duration: kMicroDuration,
            curve: Curves.easeIn,
          );
    }

    return Opacity(
      opacity: widget.slot.status == 'past' ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isTappable
              ? () {
                  HapticFeedback.lightImpact();
                  widget.onTap?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: chip,
        ),
      ),
    );
  }

  IconData _iconFor(String status) => switch (status) {
    'available' => Icons.check_circle_outline,
    'booked' => Icons.event_busy,
    'blocked' => Icons.block,
    'past' => Icons.history,
    _ => Icons.schedule,
  };

  _SlotColors _styleFor(BuildContext context, String status, bool selected) {
    final themeColors = context.appColors;

    if (selected) {
      return _SlotColors(
        background: themeColors.accent,
        foreground: themeColors.onAccent,
        border: themeColors.accent,
      );
    }

    return switch (status) {
      'available' => _SlotColors(
        background: themeColors.surfaceElevated,
        foreground: themeColors.textPrimary,
        border: themeColors.glassBorder.withValues(alpha: 0.7),
      ),
      'booked' || 'blocked' => _SlotColors(
        background: themeColors.surface,
        foreground: themeColors.textSecondary.withValues(alpha: 0.75),
        border: themeColors.glassBorder.withValues(alpha: 0.45),
      ),
      'past' => _SlotColors(
        background: themeColors.surface,
        foreground: themeColors.textSecondary.withValues(alpha: 0.55),
        border: themeColors.glassBorder.withValues(alpha: 0.35),
      ),
      _ => _SlotColors(
        background: themeColors.surface,
        foreground: themeColors.textSecondary.withValues(alpha: 0.7),
        border: themeColors.glassBorder,
      ),
    };
  }
}

class _SlotColors {
  const _SlotColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

class SlotsAvailabilityBadge extends StatelessWidget {
  const SlotsAvailabilityBadge({super.key, required this.summary});

  final SlotsTodaySummary? summary;

  @override
  Widget build(BuildContext context) {
    if (summary == null || !summary!.shouldShowOnCard) {
      return const SizedBox.shrink();
    }

    final (label, color) = switch (summary!.status) {
      'open' => ('Open', AppColors.success),
      'limited' => ('Limited', AppColors.warning),
      'full' => ('Full', AppColors.error),
      _ => ('Slots', context.appColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label · ${summary!.available}/${summary!.total}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SlotsAvailabilityInfoLine extends StatelessWidget {
  const SlotsAvailabilityInfoLine({super.key, required this.summary});

  final SlotsTodaySummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.shouldShowOnCard) return const SizedBox.shrink();

    final label = summary.infoLineLabel;
    if (label.isEmpty) return const SizedBox.shrink();

    final color = switch (summary.status) {
      'open' => AppColors.success,
      'limited' => AppColors.warning,
      'full' => context.appColors.textMuted,
      _ => context.appColors.textSecondary,
    };

    final icon = switch (summary.status) {
      'open' => Icons.event_available_outlined,
      'limited' => Icons.schedule_outlined,
      'full' => Icons.event_busy_outlined,
      _ => Icons.calendar_today_outlined,
    };

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
