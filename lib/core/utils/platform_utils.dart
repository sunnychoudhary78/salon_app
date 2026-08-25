import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Whether the current platform should use iOS/Cupertino chrome.
bool isCupertinoPlatform([BuildContext? context]) {
  final platform = context != null
      ? Theme.of(context).platform
      : defaultTargetPlatform;
  return !kIsWeb && platform == TargetPlatform.iOS;
}

/// Back affordance icon: iOS chevron, Material arrow elsewhere.
IconData platformBackIcon([BuildContext? context]) {
  return isCupertinoPlatform(context)
      ? Icons.arrow_back_ios_new_rounded
      : Icons.arrow_back_rounded;
}
