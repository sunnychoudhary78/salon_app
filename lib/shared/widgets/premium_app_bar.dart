import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
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
    final colors = context.appColors;

    return AppBar(
      automaticallyImplyLeading: showDrawerButton || leading != null,
      title: titleWidget ??
          (subtitle != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.textPrimary,
                          ),
                    ),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                )
              : Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
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
      backgroundColor: colors.navBarBackground,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: colors.glassBorder),
      ),
    );
  }
}
