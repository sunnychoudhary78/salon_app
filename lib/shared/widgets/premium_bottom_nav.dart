import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class PremiumBottomNavItem {
  const PremiumBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
}

class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<PremiumBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 4 : 8, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final selected = item.index == selectedIndex;
                return Expanded(
                  child: _NavItem(
                    item: item,
                    selected: selected,
                    onTap: () => onSelect(item.index),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PremiumBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.accentGradient : null,
                  color: selected
                      ? null
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: selected
                      ? AppColors.backgroundDark
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
