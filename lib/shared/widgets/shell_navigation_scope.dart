import 'package:flutter/material.dart';

/// Exposes the shell [Scaffold] drawer to nested tab screens that have their
/// own [Scaffold] (and therefore cannot see [Scaffold.hasDrawer] on the parent).
class ShellNavigationScope extends InheritedWidget {
  const ShellNavigationScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static ShellNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellNavigationScope>();
  }

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}
