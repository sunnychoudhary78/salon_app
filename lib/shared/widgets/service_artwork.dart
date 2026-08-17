import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/constants/salon_service_icons.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/utils/image_decode_utils.dart';

class ServiceArtwork extends StatelessWidget {
  const ServiceArtwork({
    super.key,
    required this.serviceName,
    this.audience = AudienceMode.men,
    this.size = 64,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = 16,
  });

  final String serviceName;
  final AudienceMode audience;
  final double size;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final asset = salonServiceIconAsset(serviceName, audience: audience);

    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: asset == null
          ? const _ServiceArtworkFallback()
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              cacheWidth: memCachePx(context, size),
              cacheHeight: memCachePx(context, size),
              errorBuilder: (context, error, stackTrace) =>
                  const _ServiceArtworkFallback(),
            ),
    );
  }
}

class _ServiceArtworkFallback extends StatelessWidget {
  const _ServiceArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.content_cut_rounded,
        color: context.appColors.accent,
        size: 26,
      ),
    );
  }
}
