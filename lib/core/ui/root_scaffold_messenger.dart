import 'package:flutter/material.dart';

/// Shared messenger for app-wide SnackBars (session expiry, permission hints).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Root navigator so app-level dialogs (Play updates) can be shown from
/// [MaterialApp.router]'s builder, which sits above the navigator.
final rootNavigatorKey = GlobalKey<NavigatorState>();
