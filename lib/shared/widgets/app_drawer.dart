import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/shared/widgets/app_logo.dart';

class DrawerNavItem {
  const DrawerNavItem({
    required this.icon,
    required this.label,
    this.index,
    this.route,
  }) : assert(
          index != null || route != null,
          'Provide either index or route',
        ),
        assert(
          index == null || route == null,
          'Provide only one of index or route',
        );

  final IconData icon;
  final String label;
  final int? index;
  final String? route;
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.headerSubtitle,
    this.isOwnerMode = false,
    this.badgeCounts = const {},
    this.attentionHint,
    this.onAttentionHintTap,
  });

  final List<DrawerNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String? headerSubtitle;
  final bool isOwnerMode;
  final Map<int, int> badgeCounts;
  final String? attentionHint;
  final VoidCallback? onAttentionHintTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final pending = auth?.salonApplication?.isPending ?? false;
    final colors = context.appColors;
    final ownerBusinessName = isOwnerMode
        ? auth?.salonOwner?.businessName
        : null;

    return Drawer(
      child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            border: Border(
              right: BorderSide(color: colors.glassBorder),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 52, borderRadius: 14),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppConfig.appName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontSize: 22,
                                        color: colors.textPrimary,
                                      ),
                                ),
                                Text(
                                  headerSubtitle ??
                                      (isOwnerMode
                                          ? 'Owner Portal'
                                          : 'Customer'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: colors.accent),
                                ),
                                if (ownerBusinessName != null &&
                                    ownerBusinessName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      ownerBusinessName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (auth != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.glassFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    colors.primary.withValues(alpha: 0.2),
                                child: Text(
                                  auth.user.name.isNotEmpty
                                      ? auth.user.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      auth.user.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: colors.textPrimary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      auth.user.email?.isNotEmpty == true
                                          ? auth.user.email!
                                          : (auth.user.phone ?? ''),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Application pending',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (attentionHint != null &&
                            attentionHint!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                onAttentionHintTap?.call();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        attentionHint!,
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (onAttentionHintTap != null)
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: AppColors.warning,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _drawerItemCount(items, isOwnerMode),
                    itemBuilder: (context, i) {
                      final mapped = _mapDrawerIndex(i, items, isOwnerMode);
                      if (mapped.isSection) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                          child: Text(
                            mapped.sectionLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        );
                      }

                      final item = mapped.item!;
                      final selected =
                          item.index != null && item.index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              final route = item.route;
                              if (route != null) {
                                context.push(route);
                              } else {
                                onSelect(item.index!);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? colors.primarySoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? colors.primary
                                      : Colors.transparent,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? colors.primarySoft
                                          : colors.surfaceSunken,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 20,
                                      color: selected
                                          ? colors.primary
                                          : colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: selected
                                            ? colors.textPrimary
                                            : colors.textSecondary,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (item.index != null &&
                                      (badgeCounts[item.index!] ?? 0) > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        badgeCounts[item.index!]! > 99
                                            ? '99+'
                                            : '${badgeCounts[item.index!]}',
                                        style: TextStyle(
                                          color: colors.onPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (selected)
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (auth != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    );
  }
}

int _drawerItemCount(List<DrawerNavItem> items, bool isOwnerMode) {
  if (!isOwnerMode) return items.length;
  return items.length + 3;
}

class _DrawerListEntry {
  const _DrawerListEntry.item(this.item)
      : isSection = false,
        sectionLabel = null;

  const _DrawerListEntry.section(this.sectionLabel)
      : isSection = true,
        item = null;

  final bool isSection;
  final String? sectionLabel;
  final DrawerNavItem? item;
}

_DrawerListEntry _mapDrawerIndex(
  int index,
  List<DrawerNavItem> items,
  bool isOwnerMode,
) {
  if (!isOwnerMode) {
    return _DrawerListEntry.item(items[index]);
  }

  if (index == 0) return const _DrawerListEntry.section('Management');
  if (index <= 4) return _DrawerListEntry.item(items[index - 1]);
  if (index == 5) return const _DrawerListEntry.section('Salon');
  if (index <= 7) return _DrawerListEntry.item(items[index - 2]);
  if (index == 8) return const _DrawerListEntry.section('Account');
  return _DrawerListEntry.item(items[index - 3]);
}
