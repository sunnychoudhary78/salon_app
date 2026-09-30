import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class BeautySuggestionChips extends StatelessWidget {
  const BeautySuggestionChips({super.key, required this.onSelected});

  static const suggestions = [
    'Wedding look',
    'Hair fall',
    'Beard tidy',
    'Party makeup',
  ];

  static const _icons = <String, IconData>{
    'Wedding look': Icons.diamond_outlined,
    'Hair fall': Icons.spa_outlined,
    'Beard tidy': Icons.content_cut_rounded,
    'Party makeup': Icons.celebration_outlined,
  };

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final suggestion in suggestions)
          Material(
            color: colors.surface,
            shape: StadiumBorder(
              side: BorderSide(color: colors.accent.withValues(alpha: 0.35)),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelected(suggestion),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[suggestion] ?? Icons.auto_awesome_rounded,
                      size: 16,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      suggestion,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}