import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_gate_provider.dart';

/// Refreshes the pending booking gate on app resume for salon owners.
class PendingBookingGateLifecycle extends ConsumerStatefulWidget {
  const PendingBookingGateLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PendingBookingGateLifecycle> createState() =>
      _PendingBookingGateLifecycleState();
}

class _PendingBookingGateLifecycleState
    extends ConsumerState<PendingBookingGateLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.read(pendingBookingGateProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
