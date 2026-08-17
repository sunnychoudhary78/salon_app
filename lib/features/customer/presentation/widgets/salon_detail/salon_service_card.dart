import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/constants/salon_service_icons.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/core/utils/image_decode_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/marquee_text.dart';
import 'package:saloon_booking/shared/widgets/tap_scale_wrapper.dart';

class SalonServiceCard extends StatelessWidget {
  const SalonServiceCard({
    super.key,
    required this.service,
    required this.onBook,
    this.audience = AudienceMode.men,
  });

  final ServiceModel service;
  final VoidCallback onBook;
  final AudienceMode audience;

  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    final hasDiscount = service.hasActiveDiscount;
    final displayPrice = service.effectivePrice;
    final iconAsset = salonServiceIconAsset(
      service.serviceName,
      audience: audience,
    );
    final radius = BorderRadius.circular(16);

    return TapScaleWrapper(
      onTap: onBook,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: radius,
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: iconAsset != null
                    ? Image.asset(
                        iconAsset,
                        fit: BoxFit.contain,
                        cacheWidth: memCachePx(context, 160),
                        cacheHeight: memCachePx(context, 160),
                        errorBuilder: (context, error, stackTrace) =>
                            const _FallbackIcon(),
                      )
                    : const _FallbackIcon(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MarqueeText(
                      text: service.serviceName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              formatMoney(service.price),
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.15,
                                color: _textMuted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.black,
                              ),
                            ),
                          Text(
                            formatMoney(displayPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.appColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.content_cut_rounded,
          color: context.appColors.accent,
          size: 24,
        ),
      ),
    );
  }
}
