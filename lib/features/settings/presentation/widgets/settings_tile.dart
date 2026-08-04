import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.glassFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.glassBorder),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: context.appColors.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textMuted,
                      ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: colors.glassBorder.withValues(alpha: 0.5)),
      ],
    );
  }
}
