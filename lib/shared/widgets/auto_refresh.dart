import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
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
    this.minimumGap = const Duration(seconds: 10),
    this.refreshOnResume = true,
    this.enabled = true,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Duration interval;
  final Duration minimumGap;
  final bool refreshOnResume;
  final bool enabled;

  @override
  ConsumerState<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends ConsumerState<AutoRefresh>
    with WidgetsBindingObserver {
  static final _random = Random();

  Timer? _timer;
  Timer? _resumeTimer;
  bool _refreshing = false;
  DateTime? _lastRunAt;

  bool get _canPoll => widget.enabled && !ref.read(userIdleProvider) && mounted;

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
        _resumeTimer?.cancel();
        _resumeTimer = null;
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
    final lastRunAt = _lastRunAt;
    if (lastRunAt != null &&
        DateTime.now().difference(lastRunAt) < widget.minimumGap) {
      return;
    }
    _refreshing = true;
    _lastRunAt = DateTime.now();
    try {
      await CrashReporting.measureAsync('auto_refresh', widget.onRefresh);
      ref.read(lastAutoRefreshAtProvider.notifier).mark();
    } catch (error) {
      // Auto-refresh is best-effort; ignore transient errors.
      CrashReporting.log('auto_refresh_failed: $error');
    } finally {
      _refreshing = false;
    }
  }

  void _scheduleResumeRefresh() {
    if (!widget.refreshOnResume || !widget.enabled) return;
    if (ref.read(userIdleProvider)) return;
    _resumeTimer?.cancel();
    final delay = Duration(milliseconds: _random.nextInt(2000));
    _resumeTimer = Timer(delay, () {
      _resumeTimer = null;
      if (mounted && widget.enabled && !ref.read(userIdleProvider)) {
        unawaited(_run());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.enabled) {
          ref.read(userIdleProvider.notifier).recordActivity();
          CrashReporting.breadcrumb('auto_refresh_resume');
          _scheduleResumeRefresh();
          _startTimer();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _timer?.cancel();
        _timer = null;
        _resumeTimer?.cancel();
        _resumeTimer = null;
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
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
