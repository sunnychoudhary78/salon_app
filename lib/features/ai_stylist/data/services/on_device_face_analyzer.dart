import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';

class OnDeviceFaceAnalyzer {
  OnDeviceFaceAnalyzer();

  FaceDetector? _detector;

  FaceDetector get _faceDetector {
    return _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
  }

  Future<OnDeviceFaceResult> analyzeImageFile(
    String filePath, {
    required FaceAngleType expectedAngle,
  }) async {
    final lightingAndColor = await _sampleLightingAndHairColor(filePath);

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return OnDeviceFaceResult(
        angle: expectedAngle,
        faceDetected: true,
        singleFace: true,
        angleValid: true,
        analysisMode: 'cloud_vision_fallback',
        lightingScore: lightingAndColor.lightingScore,
        dominantHairColorHex: lightingAndColor.hairColorHex,
        feedbackMessage: 'Cloud AI vision will analyze this photo.',
      );
    }

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return OnDeviceFaceResult(
          angle: expectedAngle,
          faceDetected: false,
          singleFace: false,
          angleValid: false,
          analysisMode: 'mlkit_on_device',
          lightingScore: lightingAndColor.lightingScore,
          dominantHairColorHex: lightingAndColor.hairColorHex,
          feedbackMessage:
              'No face detected. Please upload a clear, well-lit photo.',
        );
      }

      if (faces.length > 1) {
        return OnDeviceFaceResult(
          angle: expectedAngle,
          faceDetected: true,
          singleFace: false,
          angleValid: false,
          analysisMode: 'mlkit_on_device',
          lightingScore: lightingAndColor.lightingScore,
          dominantHairColorHex: lightingAndColor.hairColorHex,
          feedbackMessage:
              'Multiple faces detected. Please upload a solo photo of yourself.',
        );
      }

      final face = faces.first;
      final yaw = face.headEulerAngleY ?? 0.0;
      final pitch = face.headEulerAngleX ?? 0.0;
      final roll = face.headEulerAngleZ ?? 0.0;

      final angleCheck = _validateAngle(expectedAngle, yaw, pitch);
      final metrics = _extractGeometricMetrics(face);

      return OnDeviceFaceResult(
        angle: expectedAngle,
        faceDetected: true,
        singleFace: true,
        angleValid: angleCheck.isValid,
        analysisMode: 'mlkit_on_device',
        yawDeg: _round2(yaw),
        pitchDeg: _round2(pitch),
        rollDeg: _round2(roll),
        estimatedFaceShape: metrics?.faceShape,
        foreheadWidthRatio: metrics?.foreheadWidthRatio,
        cheekboneWidthRatio: metrics?.cheekboneWidthRatio,
        jawWidthRatio: metrics?.jawWidthRatio,
        faceLengthToWidthRatio: metrics?.lengthToWidthRatio,
        jawlineAngleDeg: metrics?.jawlineAngleDeg,
        upperThirdRatio: metrics?.upperThirdRatio,
        middleThirdRatio: metrics?.middleThirdRatio,
        lowerThirdRatio: metrics?.lowerThirdRatio,
        lightingScore: lightingAndColor.lightingScore,
        dominantHairColorHex: lightingAndColor.hairColorHex,
        feedbackMessage: angleCheck.message,
      );
    } catch (_) {
      return OnDeviceFaceResult(
        angle: expectedAngle,
        faceDetected: true,
        singleFace: true,
        angleValid: true,
        analysisMode: 'cloud_vision_fallback',
        lightingScore: lightingAndColor.lightingScore,
        dominantHairColorHex: lightingAndColor.hairColorHex,
        feedbackMessage: 'Ready for AI analysis.',
      );
    }
  }

  _AngleCheck _validateAngle(
    FaceAngleType expected,
    double yaw,
    double pitch,
  ) {
    final absYaw = yaw.abs();
    if (pitch.abs() > 28) {
      return const _AngleCheck(
        false,
        'Hold the camera at eye level (your face is tilted too far up or down).',
      );
    }

    switch (expected) {
      case FaceAngleType.front:
        if (absYaw <= 18) {
          return const _AngleCheck(true, 'Front angle looks great!');
        }
        return const _AngleCheck(
          false,
          'Look straight at the camera for the Front photo.',
        );
      case FaceAngleType.left:
      case FaceAngleType.right:
        if (absYaw >= 14 && absYaw <= 78) {
          return _AngleCheck(true, '${expected.label} angle looks great!');
        }
        if (absYaw < 14) {
          return _AngleCheck(
            false,
            'Turn your face slightly to the side for the ${expected.label} photo.',
          );
        }
        return _AngleCheck(
          false,
          'Face turned too far; keep roughly a 45° side profile.',
        );
    }
  }

  _FaceGeometryMetrics? _extractGeometricMetrics(Face face) {
    final oval = face.contours[FaceContourType.face]?.points;
    if (oval == null || oval.length < 18) {
      return null;
    }

    double minY = double.infinity;
    double maxY = -double.infinity;
    for (final p in oval) {
      if (p.y < minY) minY = p.y.toDouble();
      if (p.y > maxY) maxY = p.y.toDouble();
    }
    final height = math.max(1.0, maxY - minY);

    double spanWidthAtBand(double bandStart, double bandEnd) {
      double leftX = double.infinity;
      double rightX = -double.infinity;
      for (final p in oval) {
        final normY = (p.y - minY) / height;
        if (normY >= bandStart && normY <= bandEnd) {
          if (p.x < leftX) leftX = p.x.toDouble();
          if (p.x > rightX) rightX = p.x.toDouble();
        }
      }
      if (!leftX.isFinite || !rightX.isFinite) return 0.0;
      return math.max(1.0, rightX - leftX);
    }

    final foreheadW = spanWidthAtBand(0.08, 0.25);
    final cheekW = spanWidthAtBand(0.35, 0.56);
    final jawW = spanWidthAtBand(0.70, 0.86);

    final maxW = [foreheadW, cheekW, jawW].reduce(math.max);
    if (maxW <= 1) return null;

    final fRatio = foreheadW / maxW;
    final cRatio = cheekW / maxW;
    final jRatio = jawW / maxW;
    final lengthToWidth = height / cheekW.clamp(1.0, double.infinity);

    // Jaw angle estimate between cheekbone corner -> jaw corner -> chin
    final leftUpperJaw = oval[(oval.length * 0.28).floor()];
    final leftJawCorner = oval[(oval.length * 0.36).floor()];
    final chin = oval[(oval.length * 0.5).floor()];
    final jawAngle = _angleBetweenPoints(leftUpperJaw, leftJawCorner, chin);

    // Rule of thirds estimate using eyebrow & nose bottom contours
    final browPts = face.contours[FaceContourType.leftEyebrowTop]?.points;
    final nosePts = face.contours[FaceContourType.noseBottom]?.points;
    double upperThird = 0.33;
    double middleThird = 0.33;
    double lowerThird = 0.34;
    if (browPts != null &&
        browPts.isNotEmpty &&
        nosePts != null &&
        nosePts.isNotEmpty) {
      final browY = browPts.first.y.toDouble();
      final noseY = nosePts.last.y.toDouble();
      if (browY > minY && noseY > browY && maxY > noseY) {
        upperThird = (browY - minY) / height;
        middleThird = (noseY - browY) / height;
        lowerThird = (maxY - noseY) / height;
      }
    }

    final faceShape = _classifyFaceShape(
      lengthToWidth: lengthToWidth,
      foreheadRatio: fRatio,
      cheekRatio: cRatio,
      jawRatio: jRatio,
      jawAngle: jawAngle,
    );

    return _FaceGeometryMetrics(
      faceShape: faceShape,
      foreheadWidthRatio: _round2(fRatio),
      cheekboneWidthRatio: _round2(cRatio),
      jawWidthRatio: _round2(jRatio),
      lengthToWidthRatio: _round2(lengthToWidth),
      jawlineAngleDeg: _round2(jawAngle),
      upperThirdRatio: _round2(upperThird),
      middleThirdRatio: _round2(middleThird),
      lowerThirdRatio: _round2(lowerThird),
    );
  }

  String _classifyFaceShape({
    required double lengthToWidth,
    required double foreheadRatio,
    required double cheekRatio,
    required double jawRatio,
    required double jawAngle,
  }) {
    if (lengthToWidth >= 1.52) {
      return 'Oblong';
    }
    if (foreheadRatio > jawRatio + 0.14 && jawRatio < 0.78) {
      return 'Heart';
    }
    if (cheekRatio >= foreheadRatio + 0.08 && cheekRatio >= jawRatio + 0.10) {
      return 'Diamond';
    }
    if ((foreheadRatio - jawRatio).abs() < 0.08 &&
        lengthToWidth <= 1.28 &&
        jawAngle < 126) {
      return 'Square';
    }
    if (lengthToWidth <= 1.24 && jawAngle >= 126) {
      return 'Round';
    }
    return 'Oval';
  }

  double _angleBetweenPoints(
    math.Point<int> a,
    math.Point<int> b,
    math.Point<int> c,
  ) {
    final v1x = (a.x - b.x).toDouble();
    final v1y = (a.y - b.y).toDouble();
    final v2x = (c.x - b.x).toDouble();
    final v2y = (c.y - b.y).toDouble();
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (mag1 == 0 || mag2 == 0) return 125.0;
    final cosAngle = ((v1x * v2x + v1y * v2y) / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180.0 / math.pi;
  }

  Future<_ImageSampleResult> _sampleLightingAndHairColor(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      final image = await completer.future;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return const _ImageSampleResult(lightingScore: 0.75, hairColorHex: null);
      }

      final rgba = byteData.buffer.asUint8List();
      final w = image.width;
      final h = image.height;
      final stepX = math.max(1, w ~/ 24);
      final stepY = math.max(1, h ~/ 24);

      double lumaSum = 0;
      int lumaCount = 0;

      // Top-center region (rough hair crown sampling)
      int rSum = 0;
      int gSum = 0;
      int bSum = 0;
      int hairSamples = 0;

      for (int y = 0; y < h; y += stepY) {
        for (int x = 0; x < w; x += stepX) {
          final idx = (y * w + x) * 4;
          if (idx + 2 >= rgba.length) continue;
          final r = rgba[idx];
          final g = rgba[idx + 1];
          final b = rgba[idx + 2];
          final luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
          lumaSum += luma;
          lumaCount++;

          if (y >= (h * 0.08) &&
              y <= (h * 0.24) &&
              x >= (w * 0.35) &&
              x <= (w * 0.65)) {
            rSum += r;
            gSum += g;
            bSum += b;
            hairSamples++;
          }
        }
      }

      final avgLuma = lumaCount > 0 ? lumaSum / lumaCount : 0.6;
      String? hairHex;
      if (hairSamples > 0) {
        final rr = (rSum ~/ hairSamples).clamp(0, 255);
        final gg = (gSum ~/ hairSamples).clamp(0, 255);
        final bb = (bSum ~/ hairSamples).clamp(0, 255);
        hairHex =
            '#${rr.toRadixString(16).padLeft(2, '0')}${gg.toRadixString(16).padLeft(2, '0')}${bb.toRadixString(16).padLeft(2, '0')}'
                .toUpperCase();
      }

      return _ImageSampleResult(
        lightingScore: _round2(avgLuma),
        hairColorHex: hairHex,
      );
    } catch (_) {
      return const _ImageSampleResult(lightingScore: 0.75, hairColorHex: null);
    }
  }

  static Map<String, dynamic> combineMultiAngleFeatures({
    required OnDeviceFaceResult front,
    OnDeviceFaceResult? left,
    OnDeviceFaceResult? right,
  }) {
    final angles = <String>[
      front.angle.apiValue,
      if (left != null) left.angle.apiValue,
      if (right != null) right.angle.apiValue,
    ];
    final json = front.toJson();
    json['angles_captured'] = angles;
    if (left != null) {
      json['left_profile'] = {
        'yaw_deg': left.yawDeg,
        'angle_valid': left.angleValid,
      };
    }
    if (right != null) {
      json['right_profile'] = {
        'yaw_deg': right.yawDeg,
        'angle_valid': right.angleValid,
      };
    }
    return json;
  }

  static String encodeFeaturesJson(Map<String, dynamic> features) =>
      jsonEncode(features);

  double _round2(double v) => (v * 100).roundToDouble() / 100;

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
  }
}

class _AngleCheck {
  const _AngleCheck(this.isValid, this.message);
  final bool isValid;
  final String message;
}

class _FaceGeometryMetrics {
  const _FaceGeometryMetrics({
    required this.faceShape,
    required this.foreheadWidthRatio,
    required this.cheekboneWidthRatio,
    required this.jawWidthRatio,
    required this.lengthToWidthRatio,
    required this.jawlineAngleDeg,
    required this.upperThirdRatio,
    required this.middleThirdRatio,
    required this.lowerThirdRatio,
  });

  final String faceShape;
  final double foreheadWidthRatio;
  final double cheekboneWidthRatio;
  final double jawWidthRatio;
  final double lengthToWidthRatio;
  final double jawlineAngleDeg;
  final double upperThirdRatio;
  final double middleThirdRatio;
  final double lowerThirdRatio;
}

class _ImageSampleResult {
  const _ImageSampleResult({
    required this.lightingScore,
    required this.hairColorHex,
  });

  final double lightingScore;
  final String? hairColorHex;
}
