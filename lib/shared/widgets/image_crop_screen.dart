import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

enum ImageCropShape { circle, landscape }

/// Opens the crop screen and returns the cropped file, or null if cancelled.
Future<XFile?> cropPickedImage(
  BuildContext context,
  XFile source,
  ImageCropShape shape,
) {
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute(
      builder: (_) => ImageCropScreen(imagePath: source.path, shape: shape),
    ),
  );
}

/// Crops each file in order. Cancelled photos are skipped; the rest continue.
Future<List<XFile>> cropPickedImages(
  BuildContext context,
  List<XFile> sources,
  ImageCropShape shape,
) async {
  final cropped = <XFile>[];
  for (final source in sources) {
    if (!context.mounted) break;
    final result = await cropPickedImage(context, source, shape);
    if (result != null) cropped.add(result);
  }
  return cropped;
}

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imagePath,
    required this.shape,
  });

  final String imagePath;
  final ImageCropShape shape;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  static const _landscapeRatio = 16 / 9;

  final _controller = CropController();
  Uint8List? _imageData;
  bool _ready = false;
  bool _cropping = false;
  String? _loadError;

  bool get _isCircle => widget.shape == ImageCropShape.circle;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      if (!mounted) return;
      setState(() => _imageData = bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not open that photo. Please try again.');
    }
  }

  void _cancel() => Navigator.of(context).pop();

  void _usePhoto() {
    if (!_ready || _cropping) return;
    setState(() => _cropping = true);
    if (_isCircle) {
      _controller.cropCircle();
    } else {
      _controller.crop();
    }
  }

  Future<void> _onCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final file = await _writeCroppedFile(croppedImage);
          if (!mounted) return;
          Navigator.of(context).pop(XFile(file.path));
        } catch (error) {
          if (!mounted) return;
          setState(() => _cropping = false);
          _showError(error);
        }
      case CropFailure(:final cause):
        if (!mounted) return;
        setState(() => _cropping = false);
        _showError(cause);
    }
  }

  Future<File> _writeCroppedFile(Uint8List bytes) async {
    final ext = _isPng(bytes) ? 'png' : 'jpg';
    final path =
        '${Directory.systemTemp.path}/crop_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          userFacingErrorMessage(
            error,
            fallback: 'Could not crop that photo. Please try again.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: PremiumAppBar(
        title: 'Adjust photo',
        showMenu: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cropping ? null : _cancel,
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _editor(colors)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: PremiumButton(
                label: 'Use photo',
                variant: PremiumButtonVariant.accent,
                loading: _cropping,
                onPressed: _ready && !_cropping && _imageData != null
                    ? _usePhoto
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editor(AppThemeExtension colors) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final image = _imageData;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Crop(
      image: image,
      controller: _controller,
      onCropped: _onCropped,
      withCircleUi: _isCircle,
      aspectRatio: _isCircle ? 1 : _landscapeRatio,
      initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
        size: 0.9,
        aspectRatio: _isCircle ? 1 : _landscapeRatio,
      ),
      interactive: true,
      fixCropRect: true,
      willUpdateScale: (scale) => scale >= 1 && scale <= 8,
      baseColor: AppColors.backgroundDark,
      maskColor: Colors.black.withValues(alpha: 0.55),
      radius: _isCircle ? 0 : AppColors.radiusControl,
      cornerDotBuilder: (_, _) => const SizedBox.shrink(),
      progressIndicator: const Center(child: CircularProgressIndicator()),
      onStatusChanged: (status) {
        final ready = status == CropStatus.ready;
        if (ready != _ready && mounted) {
          setState(() => _ready = ready);
        }
      },
    );
  }
}

bool _isPng(Uint8List bytes) {
  return bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}
