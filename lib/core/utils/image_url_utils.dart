import 'package:saloon_booking/core/config/app_config.dart';

String _apiOrigin() {
  final uri = Uri.parse(AppConfig.baseUrl);
  return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
}

/// Resolves upload paths to absolute URLs for network image loading.
///
/// Relative `/api/uploads/...` paths are prefixed with [AppConfig] origin.
/// Absolute upload URLs are rewritten onto the configured API host so stored
/// request-host URLs still load in the app.
String resolveImageUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.path.startsWith('/api/uploads/')) {
      return '${_apiOrigin()}${parsed.path}'
          '${parsed.hasQuery ? '?${parsed.query}' : ''}';
    }
    return trimmed;
  }

  if (trimmed.startsWith('/')) {
    return '${_apiOrigin()}$trimmed';
  }
  return '${AppConfig.baseUrl}/$trimmed';
}
