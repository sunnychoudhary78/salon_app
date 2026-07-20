import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_period_filter.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';

class OwnerDashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  const OwnerDashboardHeader({
    super.key,
    required this.greeting,
    required this.ownerName,
    this.businessName,
    required this.meta,
    required this.unreadFromDashboard,
    required this.salonNames,
  });

  final String greeting;
  final String ownerName;
  final String? businessName;
  final OwnerDashboardMeta meta;
  final int unreadFromDashboard;
  final Map<String, String> salonNames;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadFromDashboard > 0
        ? unreadFromDashboard
        : (unreadAsync.value ?? 0);
    final colors = context.appColors;
    final scopedId = ref.watch(ownerDashboardSalonScopeProvider);
    final scopeLabel = _scopeLabel(scopedId);

    return PremiumAppBar(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$greeting, $ownerName',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (businessName != null && businessName!.isNotEmpty)
                Flexible(
                  child: Text(
                    businessName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (businessName != null && businessName!.isNotEmpty)
                Text(' · ', style: TextStyle(color: colors.textMuted)),
              if (meta.salonCount > 1)
                InkWell(
                  onTap: () => _showSalonPicker(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.glassFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          scopeLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Icon(Icons.expand_more_rounded, size: 14, color: colors.textMuted),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  scopeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        const OwnerDashboardPeriodButton(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go(RoutePaths.ownerNotifications),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _scopeLabel(String? scopedId) {
    if (scopedId == null || scopedId.isEmpty) {
      return meta.salonCount > 1 ? 'All salons' : 'My salon';
    }
    return salonNames[scopedId] ?? 'Salon';
  }

  Future<void> _showSalonPicker(BuildContext context, WidgetRef ref) async {
    final currentScopedId = ref.read(ownerDashboardSalonScopeProvider);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All salons'),
                trailing: currentScopedId == null
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(ctx, ''),
              ),
              for (final id in meta.salonIds)
                ListTile(
                  title: Text(salonNames[id] ?? 'Salon'),
                  trailing: currentScopedId == id
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(ctx, id),
                ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selected == null) return;
    ref.read(ownerDashboardSalonScopeProvider.notifier).setScope(
          selected.isEmpty ? null : selected,
        );
    ref.invalidate(ownerDashboardProvider);
  }
}
