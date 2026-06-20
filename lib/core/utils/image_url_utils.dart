import 'package:saloon_booking/core/config/app_config.dart';

/// Resolves relative upload paths to absolute URLs for network image loading.
String resolveImageUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  final base = AppConfig.baseUrl;
  if (url.startsWith('/')) {
    final uri = Uri.parse(base);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$url';
  }
  return '$base/$url';
}
