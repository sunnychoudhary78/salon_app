import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

/// Self-contained countdown that ticks once per second on its own, so it does
/// not force the parent screen to rebuild every second. Pauses while idle.
class PremiumCountdown extends ConsumerStatefulWidget {
  const PremiumCountdown({
    super.key,
    required this.expiresAt,
    this.unpaidLabel = 'Pay now to confirm this premium booking',
  });

  final DateTime? expiresAt;
  final String unpaidLabel;

  @override
  ConsumerState<PremiumCountdown> createState() => _PremiumCountdownState();
}

class _PremiumCountdownState extends ConsumerState<PremiumCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(PremiumCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _timer?.cancel();
      _timer = null;
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    if (widget.expiresAt == null || ref.read(userIdleProvider)) return;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || ref.read(userIdleProvider)) return;
      setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userIdleProvider, (previous, next) {
      if (next) {
        _stopTimer();
      } else {
        _startTimerIfNeeded();
        if (mounted) setState(() {});
      }
    });

    return Text(
      remainingLabel(widget.expiresAt, unpaidLabel: widget.unpaidLabel),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.warning,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

@visibleForTesting
String remainingLabel(DateTime? expiresAt, {String unpaidLabel = 'Pay now to confirm this premium booking'}) {
  if (expiresAt == null) return unpaidLabel;
  final remaining = expiresAt.difference(DateTime.now());
  if (remaining.isNegative) return 'Premium payment window expired';
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (remaining.inHours > 0) {
    return 'Premium payment due in ${remaining.inHours}:$minutes:$seconds';
  }
  return 'Premium payment due in $minutes:$seconds';
}
