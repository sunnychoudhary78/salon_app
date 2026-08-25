import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/utils/platform_utils.dart';

/// Cupertino spinner on iOS; Material [CircularProgressIndicator] elsewhere.
class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({
    super.key,
    this.strokeWidth = 2.5,
    this.color,
    this.radius = 12,
  });

  final double strokeWidth;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (isCupertinoPlatform(context)) {
      return CupertinoActivityIndicator(radius: radius, color: color);
    }
    return CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color,
    );
  }
}
