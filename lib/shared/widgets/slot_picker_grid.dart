import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

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
  final double? premiumFee;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No operating hours configured for this salon.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) => _SlotChip(
            slot: slot,
            selected: selectedSlotStart == slot.slotStart,
            ownerMode: ownerMode,
            premiumFee: premiumFee,
            onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
          )).toList(),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.ownerMode,
    this.premiumFee,
    this.onTap,
  });

  final SalonSlotModel slot;
  final bool selected;
  final bool ownerMode;
  final double? premiumFee;
  final VoidCallback? onTap;

  bool get _isPremiumEligible =>
      !ownerMode && slot.premiumEligible && slot.status != 'past';

  bool get _isTappable {
    if (onTap == null) return false;
    if (ownerMode) return slot.status != 'past';
    return slot.status == 'available' || _isPremiumEligible;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(slot.status, selected);

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isTappable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ownerMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        _iconFor(slot.status),
                        size: 14,
                        color: colors.foreground,
                      ),
                    ),
                  Text(
                    slot.displayLabel,
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_isPremiumEligible) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 12,
                      color: selected ? AppColors.backgroundDark : AppColors.accent,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Urgent · ₹${(premiumFee ?? 199).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: selected ? AppColors.backgroundDark : AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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

  _SlotColors _colorsFor(String status, bool selected) {
    if (selected) {
      return const _SlotColors(
        background: AppColors.accent,
        foreground: AppColors.backgroundDark,
        border: AppColors.accent,
      );
    }
    return switch (status) {
      'available' => _SlotColors(
        background: AppColors.success.withValues(alpha: 0.15),
        foreground: AppColors.success,
        border: AppColors.success.withValues(alpha: 0.4),
      ),
      'booked' => _SlotColors(
        background: AppColors.error.withValues(alpha: 0.12),
        foreground: AppColors.error,
        border: AppColors.error.withValues(alpha: 0.35),
      ),
      'blocked' => _SlotColors(
        background: AppColors.warning.withValues(alpha: 0.15),
        foreground: AppColors.warning,
        border: AppColors.warning.withValues(alpha: 0.4),
      ),
      'past' => const _SlotColors(
        background: AppColors.surface,
        foreground: AppColors.textMuted,
        border: AppColors.glassBorder,
      ),
      _ => const _SlotColors(
        background: AppColors.surface,
        foreground: AppColors.textMuted,
        border: AppColors.glassBorder,
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
    if (summary == null || summary!.total == 0) return const SizedBox.shrink();

    final (label, color) = switch (summary!.status) {
      'open' => ('Open', AppColors.success),
      'limited' => ('Limited', AppColors.warning),
      'full' => ('Full', AppColors.error),
      _ => ('Slots', AppColors.textMuted),
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
