import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pins status bar appearance so scrolling content does not flicker system icons.
class SystemUiScope extends StatelessWidget {
  const SystemUiScope({super.key, required this.child, this.brightness});

  final Widget child;
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final resolved = brightness ?? Theme.of(context).brightness;
    final isDark = resolved == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: child,
    );
  }
}
