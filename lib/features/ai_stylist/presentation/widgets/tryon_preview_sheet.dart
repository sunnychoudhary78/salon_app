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

/// Accurate custom clipper that strictly clips from left (0) to (width * clipFactor).
/// This guarantees the left side reveals the Before image and the right side reveals the After image.
class _BeforeSliderClipper extends CustomClipper<Rect> {
  const _BeforeSliderClipper(this.clipFactor);

  final double clipFactor;

  @override
  Rect getClip(Size size) {
    final w = size.width * clipFactor.clamp(0.0, 1.0);
    return Rect.fromLTWH(0, 0, w, size.height);
  }

  @override
  bool shouldReclip(_BeforeSliderClipper oldClipper) =>
      oldClipper.clipFactor != clipFactor;
}

class TryOnPreviewSheet extends ConsumerStatefulWidget {
  const TryOnPreviewSheet({
    super.key,
    required this.analysisId,
    required this.recommendation,
    this.originalImageUrl,
  });

  final String analysisId;
  final HairstyleRecommendation recommendation;
  final String? originalImageUrl;

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

  // Comparison mode: 0 = Slider, 1 = Before Only, 2 = After Only
  int _compareMode = 0;
  double _sliderValue = 0.5;

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

  void _openFullScreen({required String imageUrl, String? beforeImageUrl}) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => _FullScreenTryOnViewer(
          imageUrl: imageUrl,
          beforeImageUrl: beforeImageUrl,
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

    final result = _result;
    final afterUrl = result != null ? resolveImageUrl(result.resultImageUrl) : null;
    final rawBefore = result?.originalImageUrl ?? widget.originalImageUrl;
    final beforeUrl = (rawBefore != null && rawBefore.isNotEmpty)
        ? resolveImageUrl(rawBefore)
        : null;

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
                                'Applying hairstyle to your photo...\nThis may take 15-25 seconds.',
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
                            : (afterUrl != null)
                                ? _buildComparisonOrSingleImage(
                                    afterUrl: afterUrl,
                                    beforeUrl: beforeUrl,
                                    colors: colors,
                                  )
                                : const SizedBox.shrink(),
                  ),
                ),
              ),
              if (!_loading && afterUrl != null && beforeUrl != null) ...[
                const SizedBox(height: 10),
                _buildModeSelector(colors),
              ],
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

  Widget _buildModeSelector(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildSegmentButton(
            label: '⇄ Slider',
            icon: Icons.compare_arrows_rounded,
            isSelected: _compareMode == 0,
            onTap: () => setState(() => _compareMode = 0),
            colors: colors,
          ),
          _buildSegmentButton(
            label: 'Before',
            icon: Icons.person_outline_rounded,
            isSelected: _compareMode == 1,
            onTap: () => setState(() => _compareMode = 1),
            colors: colors,
          ),
          _buildSegmentButton(
            label: 'After (AI)',
            icon: Icons.auto_awesome_rounded,
            isSelected: _compareMode == 2,
            onTap: () => setState(() => _compareMode = 2),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? colors.accent : colors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonOrSingleImage({
    required String afterUrl,
    required String? beforeUrl,
    required dynamic colors,
  }) {
    if (beforeUrl == null) {
      // Single try-on image fallback with tap to full screen
      return GestureDetector(
        onTap: () => _openFullScreen(imageUrl: afterUrl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: afterUrl,
              fit: BoxFit.cover,
            ),
            _buildFullScreenBadge(),
          ],
        ),
      );
    }

    // Interactive Before / After Split Comparison Slider
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return GestureDetector(
          onTap: () => _openFullScreen(
            imageUrl: afterUrl,
            beforeImageUrl: beforeUrl,
          ),
          onHorizontalDragUpdate: _compareMode == 0
              ? (details) {
                  setState(() {
                    _sliderValue =
                        (details.localPosition.dx / w).clamp(0.01, 0.99);
                  });
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bottom Layer: After (AI Try-on with new hairstyle)
              CachedNetworkImage(
                imageUrl: afterUrl,
                fit: BoxFit.cover,
                width: w,
                height: h,
                placeholder: (_, __) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
              ),

              // Top Layer: Before (Original Scan), strictly clipped to slider width
              if (_compareMode != 2)
                ClipRect(
                  clipper: _BeforeSliderClipper(
                    _compareMode == 1 ? 1.0 : _sliderValue,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: beforeUrl,
                    fit: BoxFit.cover,
                    width: w,
                    height: h,
                  ),
                ),

              // Vertical Divider Line (Visible in Slider mode)
              if (_compareMode == 0)
                Positioned(
                  left: w * _sliderValue - 1.5,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

              // Center Circular Drag Handle (Visible in Slider mode)
              if (_compareMode == 0)
                Positioned(
                  left: w * _sliderValue - 18,
                  top: h / 2 - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // Before Label (Top-Left)
              if (_compareMode != 2)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _buildBadge(
                    label: 'BEFORE',
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),

              // After Label (Top-Right)
              if (_compareMode != 1)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildBadge(
                    label: 'AFTER',
                    color: colors.accent.withValues(alpha: 0.85),
                  ),
                ),

              // Full View Badge (Bottom-Right)
              Positioned(
                right: 10,
                bottom: 10,
                child: _buildFullScreenBadge(),
              ),

              // Drag Hint (Bottom-Left)
              if (_compareMode == 0)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Drag to compare',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFullScreenBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
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
    );
  }
}

class _FullScreenTryOnViewer extends StatefulWidget {
  const _FullScreenTryOnViewer({
    required this.imageUrl,
    this.beforeImageUrl,
    required this.title,
  });

  final String imageUrl;
  final String? beforeImageUrl;
  final String title;

  @override
  State<_FullScreenTryOnViewer> createState() => _FullScreenTryOnViewerState();
}

class _FullScreenTryOnViewerState extends State<_FullScreenTryOnViewer> {
  bool _saving = false;
  bool _saved = false;
  int _compareMode = 0; // 0: slider, 1: before, 2: after
  double _sliderValue = 0.5;

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
    final hasBefore = widget.beforeImageUrl != null && widget.beforeImageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main Comparison / Image Viewer
          Center(
            child: hasBefore
                ? AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;

                        return GestureDetector(
                          onHorizontalDragUpdate: _compareMode == 0
                              ? (details) {
                                  setState(() {
                                    _sliderValue = (details.localPosition.dx / w)
                                        .clamp(0.01, 0.99);
                                  });
                                }
                              : null,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // After image (base)
                              CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                fit: BoxFit.cover,
                                width: w,
                                height: h,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),

                              // Before image (clipped strictly by custom clipper)
                              if (_compareMode != 2)
                                ClipRect(
                                  clipper: _BeforeSliderClipper(
                                    _compareMode == 1 ? 1.0 : _sliderValue,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.beforeImageUrl!,
                                    fit: BoxFit.cover,
                                    width: w,
                                    height: h,
                                  ),
                                ),

                              // Vertical divider bar in slider mode
                              if (_compareMode == 0)
                                Positioned(
                                  left: w * _sliderValue - 1.5,
                                  top: 0,
                                  bottom: 0,
                                  width: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Handle icon in slider mode
                              if (_compareMode == 0)
                                Positioned(
                                  left: w * _sliderValue - 20,
                                  top: h / 2 - 20,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.compare_arrows_rounded,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : InteractiveViewer(
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

          // Top App Bar
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
                    Colors.black.withValues(alpha: 0.78),
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

          // Bottom Controls (Mode Switcher & Badges)
          if (hasBefore)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFullScreenTab(
                          label: '⇄ Wipe Slider',
                          isSelected: _compareMode == 0,
                          onTap: () => setState(() => _compareMode = 0),
                        ),
                        _buildFullScreenTab(
                          label: 'Before',
                          isSelected: _compareMode == 1,
                          onTap: () => setState(() => _compareMode = 1),
                        ),
                        _buildFullScreenTab(
                          label: 'After',
                          isSelected: _compareMode == 2,
                          onTap: () => setState(() => _compareMode = 2),
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

  Widget _buildFullScreenTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
