import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';

/// Periodically invokes [onRefresh] while mounted and also refreshes when the
/// app returns to the foreground. Pauses the timer while the app is backgrounded,
/// when [enabled] is false, or when the user is idle. Overlapping runs are skipped.
///
/// This is a safety-net only: live updates are primarily delivered via push
/// notifications, so the polling interval is intentionally conservative to keep
/// the UI thread free of recurring network/parse/rebuild work.
class AutoRefresh extends ConsumerStatefulWidget {
  const AutoRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.interval = const Duration(minutes: 4),
    this.refreshOnResume = true,
    this.enabled = true,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Duration interval;
  final bool refreshOnResume;
  final bool enabled;

  @override
  ConsumerState<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends ConsumerState<AutoRefresh>
    with WidgetsBindingObserver {
  static final _random = Random();

  Timer? _timer;
  bool _refreshing = false;

  bool get _canPoll =>
      widget.enabled && !ref.read(userIdleProvider) && mounted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) _startTimer();
  }

  @override
  void didUpdateWidget(AutoRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    } else if (oldWidget.interval != widget.interval && widget.enabled) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_canPoll) return;
    _timer = Timer.periodic(widget.interval, (_) => _run());
  }

  Future<void> _run() async {
    if (_refreshing || !mounted || !widget.enabled) return;
    if (ref.read(userIdleProvider)) return;
    _refreshing = true;
    try {
      await widget.onRefresh();
      ref.read(lastAutoRefreshAtProvider.notifier).mark();
    } catch (_) {
      // Auto-refresh is best-effort; ignore transient errors.
    } finally {
      _refreshing = false;
    }
  }

  void _scheduleResumeRefresh() {
    if (!widget.refreshOnResume || !widget.enabled) return;
    if (ref.read(userIdleProvider)) return;
    final delay = Duration(milliseconds: _random.nextInt(2000));
    Future.delayed(delay, () {
      if (mounted && widget.enabled && !ref.read(userIdleProvider)) {
        _run();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(userIdleProvider.notifier).recordActivity();
        _scheduleResumeRefresh();
        if (widget.enabled) _startTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _timer?.cancel();
        _timer = null;
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userIdleProvider, (previous, next) {
      if (next) {
        _timer?.cancel();
        _timer = null;
      } else if (widget.enabled) {
        _startTimer();
      }
    });

    return widget.child;
  }
}
