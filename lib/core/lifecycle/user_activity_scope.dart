import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';

/// Tracks pointer activity and drives [userIdleProvider].
class UserActivityScope extends ConsumerWidget {
  const UserActivityScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(userIdleProvider.notifier).recordActivity(),
      onPointerSignal: (_) =>
          ref.read(userIdleProvider.notifier).recordActivity(),
      child: child,
    );
  }
}
