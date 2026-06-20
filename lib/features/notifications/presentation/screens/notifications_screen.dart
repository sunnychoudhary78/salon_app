import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_router.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/notifications/data/models/notification_model.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/notifications/presentation/widgets/notification_tile.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _onTap(AppNotificationModel notification) async {
    if (notification.isUnread) {
      await ref.read(notificationActionsProvider).markRead(notification.id);
    }
    if (!mounted) return;
    ref.read(notificationRouterProvider).navigate(
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
          data: (state) {
            if (state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  AppDecorations.shellBottomInset,
                ),
                children: const [
                  SectionHeader(
                    title: 'Inbox',
                    subtitle: 'Booking updates and offers',
                  ),
                  SizedBox(height: 32),
                  EmptyView(
                    message: 'No notifications yet',
                    icon: Icons.notifications_none_rounded,
                  ),
                ],
              );
            }

            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                AppDecorations.shellBottomInset,
              ),
              children: [
                SectionHeader(
                  title: 'Inbox',
                  subtitle: '${state.items.length} notification${state.items.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 14),
                ...state.items.map(
                  (n) => NotificationTile(
                    notification: n,
                    onTap: () => _onTap(n),
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
