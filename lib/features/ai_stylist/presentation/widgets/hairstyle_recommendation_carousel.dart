import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';

class HairstyleRecommendationCarousel extends StatelessWidget {
  const HairstyleRecommendationCarousel({
    super.key,
    required this.recommendations,
    this.analysisId,
    this.onTryOnTap,
  });

  final List<HairstyleRecommendation> recommendations;
  final String? analysisId;
  final void Function(HairstyleRecommendation rec)? onTryOnTap;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 425,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 10, right: 8),
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return _HairstyleCard(
            rec: rec,
            rank: index + 1,
            onTryOnTap: onTryOnTap == null ? null : () => onTryOnTap!(rec),
          );
        },
      ),
    );
  }
}

class _HairstyleCard extends StatelessWidget {
  const _HairstyleCard({
    required this.rec,
    required this.rank,
    this.onTryOnTap,
  });

  final HairstyleRecommendation rec;
  final int rank;
  final VoidCallback? onTryOnTap;

  void _showZoomDialog(BuildContext context) {
    final colors = context.appColors;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#$rank ${rec.name}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (rec.imageUrl != null && rec.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: resolveImageUrl(rec.imageUrl!),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: colors.surfaceSunken,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.surfaceSunken,
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 48,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (rec.barberInstructions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.content_cut_rounded,
                              size: 14, color: colors.accent),
                          const SizedBox(width: 6),
                          Text(
                            'Show this to your barber',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: rec.barberInstructions),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Barber instructions copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Icon(Icons.copy_rounded,
                                size: 14, color: colors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rec.barberInstructions,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onTryOnTap != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onTryOnTap!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text(
                    'Try On My Photo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasImage = rec.imageUrl != null && rec.imageUrl!.isNotEmpty;

    return Container(
      width: 276,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hairstyle Lookbook Photo / Visual Preview
          GestureDetector(
            onTap: () => _showZoomDialog(context),
            child: Stack(
              children: [
                Container(
                  height: 138,
                  width: double.infinity,
                  color: colors.surfaceSunken,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: resolveImageUrl(rec.imageUrl!),
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                          placeholder: (context, url) => Container(
                            color: colors.surfaceSunken,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _PlaceholderBanner(
                            name: rec.name,
                            colors: colors,
                          ),
                        )
                      : _PlaceholderBanner(
                          name: rec.name,
                          colors: colors,
                        ),
                ),
                // Match badge overlay on the top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: colors.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '#$rank • ${rec.matchScore}% Match',
                      style: TextStyle(
                        color: colors.onAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Zoom icon on top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rec.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceSunken,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${rec.maintenanceLevel} Care',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rec.whyItSuits.isNotEmpty)
                            Text(
                              rec.whyItSuits,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          if (rec.barberInstructions.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: colors.surfaceSunken,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.glassBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.content_cut_rounded,
                                        size: 12,
                                        color: colors.accent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Show this to your barber',
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                                text: rec.barberInstructions),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Barber guide copied!'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 12,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rec.barberInstructions,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 10,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (rec.beardPairing.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Beard: ${rec.beardPairing}',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (onTryOnTap != null)
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: onTryOnTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.onAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                        label: const Text(
                          'Try On My Photo',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        rec.matchedServiceNames.isNotEmpty
                            ? rec.matchedServiceNames.join(' • ')
                            : 'Custom Haircut & Styling',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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

class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner({
    required this.name,
    required this.colors,
  });

  final String name;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceElevated,
            colors.surfaceSunken,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.face_retouching_natural_rounded,
              size: 38,
              color: colors.accent.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 4),
            Text(
              'Face-Matched Style',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
