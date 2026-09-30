import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/beautyassistant/data/models/beauty_chat_models.dart';
import 'package:saloon_booking/features/beautyassistant/presentations/widget/beauty_assistant_style.dart';

class BeautyRecommendationCard extends StatelessWidget {
  const BeautyRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onBrowseSalons,
    required this.index,
  });

  final BeautyRecommendation recommendation;
  final VoidCallback onBrowseSalons;
  final int index;

  void _onTap(BuildContext context) {
    final cta = recommendation.cta;
    switch (cta.type) {
      case RecommendationCtaType.browseSalons:
        onBrowseSalons();
        break;
      case RecommendationCtaType.openSalon:
        if (cta.salonId?.isNotEmpty == true) {
          context.push('${RoutePaths.customerSalons}/${cta.salonId}');
        } else {
          onBrowseSalons();
        }
        break;
      case RecommendationCtaType.book:
        if (cta.salonId?.isNotEmpty == true) {
          context.push('${RoutePaths.customerSalons}/${cta.salonId}/book');
        } else {
          onBrowseSalons();
        }
        break;
      case RecommendationCtaType.none:
        break;
    }
  }

  String get _buttonLabel {
    switch (recommendation.cta.type) {
      case RecommendationCtaType.browseSalons:
      case RecommendationCtaType.openSalon:
      case RecommendationCtaType.book:
        return 'Find salons';
      case RecommendationCtaType.none:
        return 'Suggested';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDisabled = recommendation.cta.type == RecommendationCtaType.none;
    final number = (index + 1).toString().padLeft(2, '0');

    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold accent line on top
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.accent, colors.accent.withValues(alpha: 0.25)],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        number,
                        style: beautySerif(
                          context,
                          size: 20,
                          weight: FontWeight.w500,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: colors.glassBorder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recommendation.serviceName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: beautySerif(
                      context,
                      size: 17,
                      weight: FontWeight.w700,
                      color: colors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      recommendation.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: isDisabled ? null : () => _onTap(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accent,
                        side: BorderSide(
                          color: isDisabled
                              ? colors.glassBorder
                              : colors.accent.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _buttonLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (!isDisabled) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}