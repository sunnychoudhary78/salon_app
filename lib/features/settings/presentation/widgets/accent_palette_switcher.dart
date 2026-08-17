import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/core/theme/accent_palette_provider.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class AccentPaletteSwitcher extends ConsumerWidget {
  const AccentPaletteSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selected =
        ref.watch(accentPaletteProvider).value ?? AccentPalette.rose;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App accent',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the highlight color used across the app. '
          'Also updates when you switch Men/Women on Home.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final palette in AccentPalette.customerChoices)
              _PaletteOption(
                key: ValueKey('accent-${palette.storageValue}'),
                palette: palette,
                selected: palette == selected,
                onTap: () => ref
                    .read(accentPaletteProvider.notifier)
                    .setPalette(palette),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    super.key,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AccentPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final swatch = palette.tokens.accent;

    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.label} accent',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 74,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.accent : colors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: swatch.withValues(alpha: 0.28),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: palette.tokens.onAccent,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(height: 7),
              Text(
                palette.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.accent : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
