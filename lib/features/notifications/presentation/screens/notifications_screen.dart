import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_router.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/notifications/data/models/notification_model.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.isOwnerMode = false});

  final bool isOwnerMode;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  int get _notificationsTabIndex => widget.isOwnerMode
      ? ownerNotificationsTabIndex
      : customerNotificationsTabIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabIndex = widget.isOwnerMode
          ? ref.read(ownerShellTabIndexProvider)
          : ref.read(customerShellTabIndexProvider);
      if (tabIndex == _notificationsTabIndex) {
        ref.read(notificationsProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _onTap(AppNotificationModel notification) async {
    if (notification.isUnread) {
      await ref.read(notificationActionsProvider).markRead(notification.id);
    }
    if (!mounted) return;
    ref
        .read(notificationRouterProvider)
        .navigate(
          NotificationPayload(
            type: notification.type,
            screen: notification.screen,
            userRole: notification.userRole,
            bookingId: notification.bookingId,
            title: notification.title,
            body: notification.body,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final tabIndexProvider = widget.isOwnerMode
        ? ownerShellTabIndexProvider
        : customerShellTabIndexProvider;

    ref.listen(tabIndexProvider, (previous, next) {
      if (next == _notificationsTabIndex &&
          previous != _notificationsTabIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(notificationsProvider.notifier).refresh();
        });
      }
    });

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Notifications',
        subtitle: widget.isOwnerMode ? 'Owner updates' : 'Your updates',
        actions: [
          unreadCount.when(
            data: (count) {
              if (count <= 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    ref.read(notificationActionsProvider).markAllRead(),
                child: const Text('Mark all read'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: AsyncValueWidget(
          value: notifications,
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              ErrorView(
                message: userFacingErrorMessage(e),
                onRetry: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
              ),
            ],
          ),
          data: (state) {
            if (state.items.isEmpty) {
              final emptySubtitle = widget.isOwnerMode
                  ? 'Booking requests, reviews, and salon updates'
                  : 'Booking updates and offers';
              final emptyIcon = widget.isOwnerMode
                  ? Icons.storefront_rounded
                  : Icons.notifications_none_rounded;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  AppDecorations.scrollBottomPadding(context),
                ),
                children: [
                  SectionHeader(title: 'Inbox', subtitle: emptySubtitle),
                  const SizedBox(height: 32),
                  EmptyView(message: 'No notifications yet', icon: emptyIcon),
                ],
              );
            }

            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              children: [
                SectionHeader(
                  title: 'Inbox',
                  subtitle:
                      '${state.items.length} notification${state.items.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 14),
                ...state.items.map(
                  (notification) => NotificationTile(
                    notification: notification,
                    onTap: () => _onTap(notification),
                  ),
                ),
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
