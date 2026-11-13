import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';
import 'package:saloon_booking/features/ai_stylist/presentation/providers/ai_stylist_provider.dart';

class TryOnPreviewSheet extends ConsumerStatefulWidget {
  const TryOnPreviewSheet({
    super.key,
    required this.analysisId,
    required this.recommendation,
  });

  final String analysisId;
  final HairstyleRecommendation recommendation;

  @override
  ConsumerState<TryOnPreviewSheet> createState() => _TryOnPreviewSheetState();
}

class _TryOnPreviewSheetState extends ConsumerState<TryOnPreviewSheet> {
  static const _colorOptions = [
    ('Natural', ''),
    ('Jet Black', 'natural jet black'),
    ('Dark Brown', 'rich dark espresso brown'),
    ('Caramel', 'warm caramel highlights'),
    ('Ash Grey', 'subtle ash grey'),
  ];

  String _selectedColor = '';
  bool _loading = false;
  String? _error;
  AiTryOnResult? _result;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(aiStylistProvider.notifier).generateTryOn(
            analysisId: widget.analysisId,
            recommendation: widget.recommendation,
            hairColor: _selectedColor.isEmpty ? null : _selectedColor,
          );
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Virtual Try-On: ${widget.recommendation.name}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: colors.surfaceSunken,
                  child: _loading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 14),
                            Text(
                              'Applying hairstyle to your photo...\nThis may take 10-20 seconds.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: colors.accent,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _generate,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _result != null
                              ? CachedNetworkImage(
                                  imageUrl:
                                      resolveImageUrl(_result!.resultImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Try Hair Color Shade',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final (label, value) = _colorOptions[index];
                  final selected = _selectedColor == value;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: _loading
                        ? null
                        : (_) {
                            setState(() => _selectedColor = value);
                            _generate();
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
