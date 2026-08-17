import 'package:flutter/widgets.dart';

/// Pixel size for [CachedNetworkImage.memCacheWidth]/Height and [Image.cacheWidth].
///
/// Caps DPR at 2.0 so 3x phones do not decode full-resolution salon photos
/// into 8–10MB bitmaps that fill [ImageCache] and trigger memory-pressure wipes.
int memCachePx(BuildContext context, double logicalPx, {int max = 720}) {
  final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
  return (logicalPx * dpr).round().clamp(1, max);
}
