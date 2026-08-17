import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/core/utils/role_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/providers/booking_action_completed_signal.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_request.dart';

enum PendingBookingGateAction { accept, reject }

class PendingBookingGateState {
  const PendingBookingGateState({
    this.queue = const [],
    this.refreshing = false,
    this.actingAction,
    this.errorMessage,
  });

  final List<PendingBookingRequest> queue;
  final bool refreshing;
  final PendingBookingGateAction? actingAction;
  final String? errorMessage;

  bool get acting => actingAction != null;

  bool get isBlocking => queue.isNotEmpty;

  PendingBookingRequest? get current => queue.isEmpty ? null : queue.first;

  PendingBookingGateState copyWith({
    List<PendingBookingRequest>? queue,
    bool? refreshing,
    PendingBookingGateAction? actingAction,
    String? errorMessage,
    bool clearError = false,
    bool clearActing = false,
  }) {
    return PendingBookingGateState(
      queue: queue ?? this.queue,
      refreshing: refreshing ?? this.refreshing,
      actingAction:
          clearActing ? null : (actingAction ?? this.actingAction),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PendingBookingGateNotifier extends Notifier<PendingBookingGateState> {
  Future<void>? _refreshInFlight;

  @override
  PendingBookingGateState build() {
    ref.listen(authProvider, (previous, next) {
      final wasOwner = previous?.value != null &&
          isSalonOwnerAccount(previous!.value!);
      final isOwner =
          next.value != null && isSalonOwnerAccount(next.value!);
      if (!wasOwner && isOwner) {
        unawaited(refresh());
      } else if (wasOwner && !isOwner) {
        state = const PendingBookingGateState();
      }
    });

    // Notification Accept/Reject finishes on the main isolate then bumps this.
    void onActionTick() {
      if (!ref.mounted) return;
      unawaited(refresh());
    }

    bookingActionCompletedTick.addListener(onActionTick);
    ref.onDispose(() {
      bookingActionCompletedTick.removeListener(onActionTick);
    });

    Future.microtask(() {
      final auth = ref.read(authProvider).value;
      if (auth != null && isSalonOwnerAccount(auth)) {
        unawaited(refresh());
      }
    });

    return const PendingBookingGateState();
  }

  bool get _isOwnerSession {
    final auth = ref.read(authProvider).value;
    return auth != null && isSalonOwnerAccount(auth);
  }

  /// Reload PENDING bookings and rebuild the oldest-first queue.
  Future<void> refresh() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshBody();
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<void> _refreshBody() async {
    if (!_isOwnerSession) {
      state = const PendingBookingGateState();
      return;
    }

    state = state.copyWith(refreshing: true, clearError: true);
    try {
      final items = await ref
          .read(ownerServiceProvider)
          .getBookings(status: 'PENDING');
      final pending = ownerPendingBookings(items);
      final queue = buildPendingBookingQueue(pending);
      state = state.copyWith(queue: queue, refreshing: false, clearError: true);
    } catch (e, st) {
      debugPrint('[pending_booking_gate] refresh failed: $e\n$st');
      state = state.copyWith(
        refreshing: false,
        errorMessage: 'Could not load pending bookings.',
      );
    }
  }

  Future<bool> acceptCurrent() async {
    final current = state.current;
    if (current == null || state.acting) return false;

    state = state.copyWith(
      actingAction: PendingBookingGateAction.accept,
      clearError: true,
    );
    try {
      await ref.read(ownerBookingActionsProvider).accept(current.representativeId);
      await _refreshBody();
      state = state.copyWith(clearActing: true);
      return true;
    } catch (e, st) {
      debugPrint('[pending_booking_gate] accept failed: $e\n$st');
      state = state.copyWith(
        clearActing: true,
        errorMessage: 'Could not accept booking. Try again.',
      );
      return false;
    }
  }

  Future<bool> rejectCurrent({String? reason}) async {
    final current = state.current;
    if (current == null || state.acting) return false;

    state = state.copyWith(
      actingAction: PendingBookingGateAction.reject,
      clearError: true,
    );
    try {
      await ref
          .read(ownerBookingActionsProvider)
          .reject(current.representativeId, reason: reason);
      await _refreshBody();
      state = state.copyWith(clearActing: true);
      return true;
    } catch (e, st) {
      debugPrint('[pending_booking_gate] reject failed: $e\n$st');
      state = state.copyWith(
        clearActing: true,
        errorMessage: 'Could not reject booking. Try again.',
      );
      return false;
    }
  }
}

final pendingBookingGateProvider =
    NotifierProvider<PendingBookingGateNotifier, PendingBookingGateState>(
      PendingBookingGateNotifier.new,
    );
