import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
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
  }) : assert(index != null || route != null, 'Provide either index or route'),
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
    final subtitle =
        headerSubtitle ?? (isOwnerMode ? 'Owner' : 'Customer');

    return Drawer(
      backgroundColor: colors.surface,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(right: BorderSide(color: colors.glassBorder)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerHeader(
                subtitle: subtitle,
                ownerBusinessName: ownerBusinessName,
                userName: auth?.user.name,
                userContact: auth?.user.email?.isNotEmpty == true
                    ? auth!.user.email!
                    : (auth?.user.phone ?? ''),
                pending: pending,
                attentionHint: attentionHint,
                onAttentionHintTap: onAttentionHintTap,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  itemCount: _drawerItemCount(items, isOwnerMode),
                  itemBuilder: (context, i) {
                    final mapped = _mapDrawerIndex(i, items, isOwnerMode);
                    if (mapped.isSection) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          10,
                          i == 0 ? 8 : 16,
                          10,
                          8,
                        ),
                        child: Text(
                          mapped.sectionLabel!.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                        ),
                      );
                    }

                    final item = mapped.item!;
                    final selected =
                        item.index != null && item.index == selectedIndex;
                    final badge = item.index != null
                        ? (badgeCounts[item.index!] ?? 0)
                        : 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _DrawerNavTile(
                        icon: item.icon,
                        label: item.label,
                        selected: selected,
                        badgeCount: badge,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                          final route = item.route;
                          if (route != null) {
                            final currentPath = GoRouterState.of(
                              context,
                            ).uri.path;
                            if (currentPath == route) return;
                            context.push(route);
                          } else {
                            onSelect(item.index!);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              if (auth != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    children: [
                      Divider(
                        height: 1,
                        color: colors.glassBorder.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            ref.read(authProvider.notifier).logout();
                          },
                          icon: Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: AppColors.error.withValues(alpha: 0.9),
                          ),
                          label: Text(
                            'Sign out',
                            style: TextStyle(
                              color: AppColors.error.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                            backgroundColor: AppColors.error.withValues(
                              alpha: 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.subtitle,
    required this.pending,
    this.ownerBusinessName,
    this.userName,
    this.userContact = '',
    this.attentionHint,
    this.onAttentionHintTap,
  });

  final String subtitle;
  final String? ownerBusinessName;
  final String? userName;
  final String userContact;
  final bool pending;
  final String? attentionHint;
  final VoidCallback? onAttentionHintTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceElevated, colors.accentSoft],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.glassBorder.withValues(alpha: 0.6),
                  ),
                ),
                child: const AppLogo(size: 36, borderRadius: 10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (ownerBusinessName != null &&
                        ownerBusinessName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          ownerBusinessName!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (userName != null && userName!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.glassBorder.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: colors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      userName![0].toUpperCase(),
                      style: TextStyle(
                        color: colors.onAccent,
                        fontWeight: FontWeight.w800,
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
                          userName!,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (userContact.isNotEmpty)
                          Text(
                            userContact,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 10),
            _HintChip(
              icon: Icons.hourglass_top_rounded,
              label: 'Application pending',
              color: AppColors.warning,
            ),
          ],
          if (attentionHint != null && attentionHint!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onAttentionHintTap?.call();
                },
                borderRadius: BorderRadius.circular(14),
                child: _HintChip(
                  icon: Icons.info_outline_rounded,
                  label: attentionHint!,
                  color: AppColors.warning,
                  trailing: onAttentionHintTap != null
                      ? Icons.chevron_right_rounded
                      : null,
                  expanded: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final IconData? trailing;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        if (expanded)
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          Icon(trailing, size: 16, color: color),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: row,
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: kMicroDuration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? colors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: kMicroDuration,
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.accent.withValues(alpha: 0.16)
                      : colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? colors.accent.withValues(alpha: 0.28)
                        : colors.glassBorder.withValues(alpha: 0.55),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? colors.accent : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? colors.textPrimary : colors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: colors.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      color: colors.onAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (selected)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.accent,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

int _drawerItemCount(List<DrawerNavItem> items, bool isOwnerMode) {
  if (isOwnerMode) return items.length + 3;
  // Customer: Explore + Account section headers.
  return items.length + 2;
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
  if (isOwnerMode) {
    if (index == 0) return const _DrawerListEntry.section('Management');
    if (index <= 4) return _DrawerListEntry.item(items[index - 1]);
    if (index == 5) return const _DrawerListEntry.section('Salon');
    if (index <= 7) return _DrawerListEntry.item(items[index - 2]);
    if (index == 8) return const _DrawerListEntry.section('Account');
    return _DrawerListEntry.item(items[index - 3]);
  }

  // Customer drawer order in shell: Home, Profile, Bookings, Notifications, Settings
  // Display: Explore → Home, Bookings · Account → Profile, Notifications, Settings
  if (index == 0) return const _DrawerListEntry.section('Explore');
  if (index == 1) return _DrawerListEntry.item(items[0]); // Home
  if (index == 2) return _DrawerListEntry.item(items[2]); // Bookings
  if (index == 3) return const _DrawerListEntry.section('Account');
  if (index == 4) return _DrawerListEntry.item(items[1]); // Profile
  if (index == 5) return _DrawerListEntry.item(items[3]); // Notifications
  return _DrawerListEntry.item(items[4]); // Settings
}
