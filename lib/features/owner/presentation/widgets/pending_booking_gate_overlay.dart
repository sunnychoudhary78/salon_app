import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_gate_provider.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/pending_booking_request_dialog.dart';

/// Full-screen blocking overlay while the owner has pending booking requests.
class PendingBookingGateOverlay extends ConsumerWidget {
  const PendingBookingGateOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(pendingBookingGateProvider);
    if (!gate.isBlocking) return const SizedBox.shrink();

    return Positioned.fill(
      child: PopScope(
        canPop: false,
        child: Material(
          color: Colors.black.withValues(alpha: 0.62),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: const PendingBookingRequestPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
