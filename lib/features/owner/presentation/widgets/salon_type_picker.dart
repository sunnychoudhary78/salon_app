import 'package:flutter/material.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class SalonTypePicker extends StatelessWidget {
  const SalonTypePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SalonType? value;
  final ValueChanged<SalonType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salon type *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Who does this salon serve?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final type in SalonType.values) ...[
              if (type != SalonType.values.first) const SizedBox(width: 8),
              Expanded(
                child: _TypeChip(
                  label: switch (type) {
                    SalonType.men => 'Men',
                    SalonType.women => 'Women',
                    SalonType.unisex => 'Unisex',
                  },
                  selected: value == type,
                  onTap: () => onChanged(type),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
      color: selected ? colors.accentSoft : colors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.accent : colors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
