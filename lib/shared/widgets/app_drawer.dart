import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/shared/widgets/app_logo.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';

class DrawerNavItem {
  const DrawerNavItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final String label;
  final int index;
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
  });

  final List<DrawerNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String? headerSubtitle;
  final bool isOwnerMode;
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final pending = auth?.salonApplication?.isPending ?? false;

    return Drawer(
      child: AppDecorations.blurLayer(
        sigma: 24,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundMid.withValues(alpha: 0.95),
                AppColors.backgroundLight.withValues(alpha: 0.92),
              ],
            ),
            border: const Border(
              right: BorderSide(color: AppColors.glassBorder),
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
                                      ?.copyWith(fontSize: 22),
                                ),
                                Text(
                                  headerSubtitle ??
                                      (isOwnerMode
                                          ? 'Owner Portal'
                                          : 'Customer'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.accent),
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
                          decoration: AppDecorations.glass(radius: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.2),
                                child: Text(
                                  auth.user.name.isNotEmpty
                                      ? auth.user.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
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
                                            color: AppColors.textPrimary,
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
                                          .bodySmall,
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
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppDecorations.sectionHeaderAccent(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final selected = item.index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              onSelect(item.index);
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
                                    ? AppColors.primary
                                        .withValues(alpha: 0.14)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: selected
                                          ? AppColors.accentGradient
                                          : null,
                                      color: selected
                                          ? null
                                          : AppColors.glassFill,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 20,
                                      color: selected
                                          ? AppColors.backgroundDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: selected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if ((badgeCounts[item.index] ?? 0) > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        badgeCounts[item.index]! > 99
                                            ? '99+'
                                            : '${badgeCounts[item.index]}',
                                        style: const TextStyle(
                                          color: AppColors.backgroundDark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (selected)
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.accent,
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.glassBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
