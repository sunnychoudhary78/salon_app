import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';

void popOrGoHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(RoutePaths.customerHome);
  }
}

/// Leaf [matchedLocation] from the current GoRouter configuration.
String? routerLeafLocation(GoRouter router) {
  final matches = router.routerDelegate.currentConfiguration;
  if (matches.isEmpty) return null;
  return matches.last.matchedLocation;
}

/// True when [leaf] is a nested child of a shell branch root (e.g. `/owner/profile/edit`).
bool isNestedShellLeaf(String? leaf, Set<String> branchRoots) {
  if (leaf == null || leaf.isEmpty) return false;
  if (branchRoots.contains(leaf)) return false;
  return branchRoots.any((root) => leaf.startsWith('$root/'));
}

enum ShellBackAction { popNested, goHome, doubleBackExit }

/// System-back decision for owner/customer shells.
///
/// Only pop when the leaf is a real nested child of a tab. Otherwise return to
/// the home tab — never pop a branch root, which would exit the app.
ShellBackAction resolveShellBack({
  required String? leaf,
  required Set<String> branchRoots,
  required bool canPop,
  required bool atHomeTab,
}) {
  if (isNestedShellLeaf(leaf, branchRoots) && canPop) {
    return ShellBackAction.popNested;
  }
  if (!atHomeTab) {
    return ShellBackAction.goHome;
  }
  return ShellBackAction.doubleBackExit;
}
