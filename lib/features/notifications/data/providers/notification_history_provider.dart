import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/utils/role_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/notifications/data/models/notification_model.dart';
import 'package:saloon_booking/features/notifications/data/services/notification_history_service.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';

const customerNotificationsTabIndex = 3;
const ownerNotificationsTabIndex = 3;

class NotificationsListState {
  const NotificationsListState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<AppNotificationModel> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  NotificationsListState copyWith({
    List<AppNotificationModel>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationsList extends AsyncNotifier<NotificationsListState> {
  static const _pageSize = 20;

  @override
  Future<NotificationsListState> build() async {
    final result = await ref
        .read(notificationHistoryServiceProvider)
        .listNotifications(page: 1, limit: _pageSize);
    return NotificationsListState(
      items: result.items,
      page: 1,
      hasMore: result.hasMore,
    );
  }

  Future<void> refresh() async {
    final previous = state.value;
    try {
      final result = await ref
          .read(notificationHistoryServiceProvider)
          .listNotifications(page: 1, limit: _pageSize);
      state = AsyncData(
        NotificationsListState(
          items: result.items,
          page: 1,
          hasMore: result.hasMore,
        ),
      );
      ref.invalidate(unreadCountProvider);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final result = await ref
          .read(notificationHistoryServiceProvider)
          .listNotifications(page: nextPage, limit: _pageSize);
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...result.items],
          page: nextPage,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(isLoadingMore: false));
      debugPrint('notifications loadMore failed: $e\n$st');
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsList, NotificationsListState>(
  NotificationsList.new,
);

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationHistoryServiceProvider).getUnreadCount();
});

/// True while the notifications shell tab is selected. Derived from tab index
/// so we never toggle state from widget lifecycle methods.
final notificationsScreenActiveProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider).value;
  if (auth == null) return false;
  if (isSalonOwnerAccount(auth)) {
    return ref.watch(ownerShellTabIndexProvider) == ownerNotificationsTabIndex;
  }
  return ref.watch(customerShellTabIndexProvider) ==
      customerNotificationsTabIndex;
});

class NotificationActions {
  NotificationActions(this._ref);

  final Ref _ref;

  Future<void> markRead(String id) async {
    await _ref.read(notificationHistoryServiceProvider).markRead(id);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllRead() async {
    await _ref.read(notificationHistoryServiceProvider).markAllRead();
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }
}

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});
