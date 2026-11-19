import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// Downloads a remote image and saves it directly to the device gallery
/// (`Pictures/CATCHY` on Android via MediaStore, Photos library on iOS).
class GalleryImageSaver {
  static const _channel = MethodChannel('com.imt.catchy/gallery_saver');

  static Future<bool> saveNetworkImage({
    required String imageUrl,
    required String nameHint,
  }) async {
    final dio = Dio(
      BaseOptions(
        responseType: ResponseType.bytes,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final response = await dio.get<List<int>>(imageUrl);
    final raw = response.data;
    if (raw == null || raw.isEmpty) {
      throw Exception('Could not download image');
    }

    final bytes = Uint8List.fromList(raw);
    final contentType =
        response.headers.value('content-type')?.toLowerCase() ?? '';
    final lowerUrl = imageUrl.toLowerCase();

    final String ext;
    final String mimeType;
    if (contentType.contains('png') || lowerUrl.endsWith('.png')) {
      ext = 'png';
      mimeType = 'image/png';
    } else if (contentType.contains('webp') || lowerUrl.endsWith('.webp')) {
      ext = 'webp';
      mimeType = 'image/webp';
    } else {
      ext = 'jpg';
      mimeType = 'image/jpeg';
    }

    final sanitized = nameHint
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final prefix = sanitized.isEmpty ? 'TryOn' : sanitized;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'CATCHY_${prefix}_$ts.$ext';

    final saved = await _channel.invokeMethod<bool>('saveImageToGallery', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
    });

    return saved == true;
  }
}
