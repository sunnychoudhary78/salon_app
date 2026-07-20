import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
}) {
  final colors = context.appColors;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: showDragHandle,
    isScrollControlled: isScrollControlled,
    backgroundColor: isDark ? colors.surfaceElevated : colors.surface,
    barrierColor: isDark
        ? Colors.black.withValues(alpha: 0.5)
        : const Color(0xFF141210).withValues(alpha: 0.4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppColors.radiusSheet),
      ),
    ),
    builder: (ctx) => GlassBottomSheetSurface(child: builder(ctx)),
  );
}

class GlassBottomSheetSurface extends StatelessWidget {
  const GlassBottomSheetSurface({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceElevated : colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppColors.radiusSheet),
        ),
        border: Border(
          top: BorderSide(color: colors.glassBorder),
        ),
      ),
      child: child,
    );
  }
}
