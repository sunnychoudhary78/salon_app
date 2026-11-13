import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';
import 'package:saloon_booking/features/ai_stylist/data/services/on_device_face_analyzer.dart';
import 'package:saloon_booking/features/ai_stylist/presentation/providers/ai_stylist_provider.dart';
import 'package:saloon_booking/features/customer/data/providers/audience_mode_provider.dart';

class MultiAngleScanScreen extends ConsumerStatefulWidget {
  const MultiAngleScanScreen({super.key});

  @override
  ConsumerState<MultiAngleScanScreen> createState() =>
      _MultiAngleScanScreenState();
}

class _MultiAngleScanScreenState extends ConsumerState<MultiAngleScanScreen> {
  final _picker = ImagePicker();
  final _analyzer = OnDeviceFaceAnalyzer();
  final _noteController = TextEditingController();

  String? _frontPath;
  String? _leftPath;
  String? _rightPath;

  OnDeviceFaceResult? _frontAnalysis;
  OnDeviceFaceResult? _leftAnalysis;
  OnDeviceFaceResult? _rightAnalysis;

  bool _analyzingLocal = false;
  late AiStylistPreferences _prefs;

  @override
  void initState() {
    super.initState();
    final audience = ref.read(audienceModeValueProvider).apiValue;
    _prefs = AiStylistPreferences(
      gender: audience == 'women' ? 'women' : 'men',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _analyzer.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(FaceAngleType angle, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null || !mounted) return;

      setState(() => _analyzingLocal = true);
      final result = await _analyzer.analyzeImageFile(
        picked.path,
        expectedAngle: angle,
      );
      if (!mounted) return;

      setState(() {
        switch (angle) {
          case FaceAngleType.front:
            _frontPath = picked.path;
            _frontAnalysis = result;
            break;
          case FaceAngleType.left:
            _leftPath = picked.path;
            _leftAnalysis = result;
            break;
          case FaceAngleType.right:
            _rightPath = picked.path;
            _rightAnalysis = result;
            break;
        }
        _analyzingLocal = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzingLocal = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick photo: $e')),
      );
    }
  }

  void _showSourcePicker(FaceAngleType angle) {
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: colors.accent),
                title: Text(
                  'Take Selfie (${angle.label})',
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(angle, ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_rounded, color: colors.primaryLight),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(angle, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitScan() async {
    if (_frontPath == null || _frontAnalysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least a Front photo is required.'),
        ),
      );
      return;
    }

    if (!_frontAnalysis!.faceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No clear face was detected in the Front photo. Please retake it.',
          ),
        ),
      );
      return;
    }

    final features = OnDeviceFaceAnalyzer.combineMultiAngleFeatures(
      front: _frontAnalysis!,
      left: _leftAnalysis,
      right: _rightAnalysis,
    );

    final ok = await ref.read(aiStylistProvider.notifier).analyzeMultiAngleScan(
          frontImagePath: _frontPath!,
          leftImagePath: _leftPath,
          rightImagePath: _rightPath,
          onDeviceFeatures: features,
          preferences: _prefs,
          userNote: _noteController.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final err = ref.read(aiStylistProvider).errorMessage ??
          'Analysis failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final state = ref.watch(aiStylistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Multi-Angle Face Scan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.glassBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: colors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Front photo is required. Adding Left and Right angles helps our AI analyze your hairline and jawline more accurately.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AngleSlotCard(
                      angle: FaceAngleType.front,
                      requiredLabel: 'Required',
                      imagePath: _frontPath,
                      result: _frontAnalysis,
                      onTap: () => _showSourcePicker(FaceAngleType.front),
                      onClear: () => setState(() {
                        _frontPath = null;
                        _frontAnalysis = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AngleSlotCard(
                      angle: FaceAngleType.left,
                      requiredLabel: 'Recommended',
                      imagePath: _leftPath,
                      result: _leftAnalysis,
                      onTap: () => _showSourcePicker(FaceAngleType.left),
                      onClear: () => setState(() {
                        _leftPath = null;
                        _leftAnalysis = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AngleSlotCard(
                      angle: FaceAngleType.right,
                      requiredLabel: 'Recommended',
                      imagePath: _rightPath,
                      result: _rightAnalysis,
                      onTap: () => _showSourcePicker(FaceAngleType.right),
                      onClear: () => setState(() {
                        _rightPath = null;
                        _rightAnalysis = null;
                      }),
                    ),
                  ),
                ],
              ),
              if (_frontAnalysis != null && _frontAnalysis!.faceDetected) ...[
                const SizedBox(height: 12),
                _OnDevicePreviewBanner(result: _frontAnalysis!),
              ],
              const SizedBox(height: 20),
              Text(
                'Your Style Preferences',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _ChipSection(
                label: 'Styling Category',
                options: const [('Men', 'men'), ('Women', 'women')],
                selected: _prefs.gender,
                onChanged: (v) => setState(() => _prefs = _prefs.copyWith(gender: v)),
              ),
              _ChipSection(
                label: 'Hair Length Goal',
                options: const [
                  ('Short', 'short'),
                  ('Medium', 'medium'),
                  ('Long', 'long'),
                ],
                selected: _prefs.hairLengthGoal,
                onChanged: (v) =>
                    setState(() => _prefs = _prefs.copyWith(hairLengthGoal: v)),
              ),
              _ChipSection(
                label: 'Daily Maintenance',
                options: const [
                  ('Low (2 min)', 'low'),
                  ('Medium', 'medium'),
                  ('High Styled', 'high'),
                ],
                selected: _prefs.maintenanceLevel,
                onChanged: (v) =>
                    setState(() => _prefs = _prefs.copyWith(maintenanceLevel: v)),
              ),
              _ChipSection(
                label: 'Occasion',
                options: const [
                  ('Daily', 'daily'),
                  ('Office', 'office'),
                  ('Wedding', 'wedding'),
                  ('Party', 'party'),
                ],
                selected: _prefs.occasion,
                onChanged: (v) =>
                    setState(() => _prefs = _prefs.copyWith(occasion: v)),
              ),
              if (_prefs.gender == 'men')
                _ChipSection(
                  label: 'Beard Preference',
                  options: const [
                    ('Clean Shave', 'clean'),
                    ('Stubble', 'stubble'),
                    ('Full Beard', 'full_beard'),
                  ],
                  selected: _prefs.beardPreference,
                  onChanged: (v) =>
                      setState(() => _prefs = _prefs.copyWith(beardPreference: v)),
                ),
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'Extra note (e.g. "Cover my forehead a bit, I want a side fade")',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.glassBorder),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed:
                    (_frontPath == null || state.isAnalyzing || _analyzingLocal)
                        ? null
                        : _submitScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: state.isAnalyzing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onAccent,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_rounded),
                label: Text(
                  state.isAnalyzing
                      ? 'Analyzing Face & Suggesting Looks...'
                      : 'Analyze Face & Suggest Hairstyles',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _AngleSlotCard extends StatelessWidget {
  const _AngleSlotCard({
    required this.angle,
    required this.requiredLabel,
    required this.imagePath,
    required this.result,
    required this.onTap,
    required this.onClear,
  });

  final FaceAngleType angle;
  final String requiredLabel;
  final String? imagePath;
  final OnDeviceFaceResult? result;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasFile = imagePath != null;
    final isGood = result?.faceDetected == true && result?.angleValid == true;
    final borderColor = !hasFile
        ? colors.glassBorder
        : isGood
            ? AppColors.success
            : AppColors.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 156,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: hasFile ? 1.5 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: hasFile
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(imagePath!), fit: BoxFit.cover),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onClear,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        color: Colors.black.withValues(alpha: 0.68),
                        child: Row(
                          children: [
                            Icon(
                              isGood
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_amber_rounded,
                              size: 13,
                              color:
                                  isGood ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                angle.apiValue.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: colors.accent,
                        size: 26,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        angle.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        requiredLabel,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _OnDevicePreviewBanner extends StatelessWidget {
  const _OnDevicePreviewBanner({required this.result});
  final OnDeviceFaceResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ok = result.angleValid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (ok ? AppColors.success : AppColors.warning)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (ok ? AppColors.success : AppColors.warning)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.verified_user_rounded : Icons.info_outline_rounded,
            size: 18,
            color: ok ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (result.feedbackMessage != null) result.feedbackMessage!,
                if (result.estimatedFaceShape != null)
                  'Est. Shape: ${result.estimatedFaceShape}',
              ].join(' • '),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((opt) {
              final isSelected = opt.$2 == selected;
              return ChoiceChip(
                label: Text(opt.$1),
                selected: isSelected,
                onSelected: (_) => onChanged(opt.$2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
