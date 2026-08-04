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
      title:
          titleWidget ??
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: colors.textPrimary),
                )),
      titleSpacing: showDrawerButton || leading != null ? 0 : 16,
      leading:
          leading ??
          (showDrawerButton
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: shellNav.openDrawer,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated.withValues(
                              alpha: 0.72,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.glassBorder.withValues(alpha: 0.65),
                            ),
                          ),
                          child: Icon(
                            Icons.menu_rounded,
                            color: colors.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null),
      actions: actions,
      backgroundColor: colors.navBarBackground,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: colors.glassBorder.withValues(alpha: 0.55)),
      ),
    );
  }
}
