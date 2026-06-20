import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/shared/widgets/shell_navigation_scope.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.showMenu = true,
    this.leading,
  }) : assert(
          titleWidget != null || title != null,
          'Provide either title or titleWidget',
        );

  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showMenu;
  final Widget? leading;

  @override
  Size get preferredSize => Size.fromHeight(
        titleWidget != null
            ? kToolbarHeight + 12
            : subtitle != null
                ? kToolbarHeight + 8
                : kToolbarHeight,
      );

  @override
  Widget build(BuildContext context) {
    final shellNav = ShellNavigationScope.maybeOf(context);
    final showDrawerButton = showMenu && leading == null && shellNav != null;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.55),
            border: Border(
              bottom: BorderSide(
                color: AppColors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: showDrawerButton || leading != null,
            title: titleWidget ??
                (subtitle != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      )
                    : Text(
                        title!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      )),
            titleSpacing: showDrawerButton || leading != null ? 0 : 16,
            leading: leading ??
                (showDrawerButton
                    ? IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: shellNav.openDrawer,
                        tooltip: 'Open menu',
                      )
                    : null),
            actions: actions,
            backgroundColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.0),
                      AppColors.accent.withValues(alpha: 0.6),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
