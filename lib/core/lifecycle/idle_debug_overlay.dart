import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';

/// Debug-only HUD for monitoring idle state and image cache pressure.
class IdleDebugOverlay extends ConsumerWidget {
  const IdleDebugOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return child;

    final isIdle = ref.watch(userIdleProvider);
    final lastRefresh = ref.watch(lastAutoRefreshAtProvider);
    final cache = PaintingBinding.instance.imageCache;
    final cacheMb = (cache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final refreshLabel = lastRefresh == null
        ? 'never'
        : DateFormat.Hms().format(lastRefresh);

    return Stack(
      children: [
        child,
        Positioned(
          left: 8,
          bottom: 88,
          child: IgnorePointer(
            child: Material(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('idle: $isIdle'),
                      Text('cache: ${cache.currentSize} img / ${cacheMb}MB'),
                      Text('autoRefresh: $refreshLabel'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
