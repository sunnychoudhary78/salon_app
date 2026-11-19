import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/gallery_image_saver.dart';
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
  bool _saving = false;
  bool _saved = false;
  String? _saveMessage;
  bool _saveMessageIsError = false;
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
      _saved = false;
      _saveMessage = null;
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

  Future<void> _saveToGallery() async {
    final result = _result;
    if (result == null || _saving) return;

    HapticFeedback.lightImpact();
    setState(() {
      _saving = true;
      _saveMessage = null;
      _saveMessageIsError = false;
    });

    try {
      final imageUrl = resolveImageUrl(result.resultImageUrl);
      final ok = await GalleryImageSaver.saveNetworkImage(
        imageUrl: imageUrl,
        nameHint: widget.recommendation.name,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = ok;
        _saveMessage = ok
            ? 'Photo saved to your gallery!'
            : 'Could not save photo to gallery.';
        _saveMessageIsError = !ok;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = false;
        _saveMessage = 'Failed to save photo. Please try again.';
        _saveMessageIsError = true;
      });
    }
  }

  void _openFullScreen(String imageUrl) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => _FullScreenTryOnViewer(
          imageUrl: imageUrl,
          title: widget.recommendation.name,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canDownload = !_loading && _error == null && _result != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Virtual Try-On: ${widget.recommendation.name}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (canDownload) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: _saved ? 'Saved to Gallery' : 'Save to Gallery',
                      child: Material(
                        color: _saved
                            ? AppColors.success.withValues(alpha: 0.14)
                            : colors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _saving ? null : _saveToGallery,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: _saving
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.accent,
                                      ),
                                    )
                                  : Icon(
                                      _saved
                                          ? Icons.check_rounded
                                          : Icons.download_rounded,
                                      size: 20,
                                      color: _saved
                                          ? AppColors.success
                                          : colors.accent,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_saveMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _saveMessageIsError
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _saveMessageIsError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_rounded,
                        size: 16,
                        color: _saveMessageIsError
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _saveMessage!,
                          style: TextStyle(
                            color: _saveMessageIsError
                                ? AppColors.error
                                : AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                                ? GestureDetector(
                                    onTap: () => _openFullScreen(
                                      resolveImageUrl(_result!.resultImageUrl),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: resolveImageUrl(
                                            _result!.resultImageUrl,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          right: 10,
                                          bottom: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.62),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.fullscreen_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Full view',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
      ),
    );
  }
}

class _FullScreenTryOnViewer extends StatefulWidget {
  const _FullScreenTryOnViewer({
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  State<_FullScreenTryOnViewer> createState() => _FullScreenTryOnViewerState();
}

class _FullScreenTryOnViewerState extends State<_FullScreenTryOnViewer> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saving) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    try {
      final ok = await GalleryImageSaver.saveNetworkImage(
        imageUrl: widget.imageUrl,
        nameHint: widget.title,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = ok;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Photo saved to your gallery!'
                : 'Could not save photo to gallery.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save photo. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Close',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _saving ? null : _save,
                        tooltip:
                            _saved ? 'Saved to Gallery' : 'Save to Gallery',
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _saved
                                    ? Icons.check_rounded
                                    : Icons.download_rounded,
                                color: _saved
                                    ? AppColors.success
                                    : Colors.white,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
