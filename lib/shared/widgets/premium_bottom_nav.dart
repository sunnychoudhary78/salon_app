import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

/// Height of the bottom nav content row (icons + labels), excluding system inset.
const double kPremiumBottomNavHeight = 64;

class PremiumBottomNavItem {
  const PremiumBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int badgeCount;
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
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.navBarBackground,
        border: Border(
          top: BorderSide(color: colors.glassBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.elevationShadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomPadding + 8,
          top: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final selected = item.index == selectedIndex;
            return Expanded(
              child: _NavItem(
                key: ValueKey('nav_${item.index}'),
                item: item,
                selected: selected,
                colors: colors,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect(item.index);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    super.key,
    required this.item,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final PremiumBottomNavItem item;
  final bool selected;
  final AppThemeExtension colors;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  int _bounceGeneration = 0;

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _bounceGeneration++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.colors.primary;
    final inactiveColor = widget.colors.textMuted;

    Widget icon = Icon(
      widget.selected ? widget.item.activeIcon : widget.item.icon,
      size: 24,
      color: widget.selected ? activeColor : inactiveColor,
    );

    if (!animationsDisabled(context) && widget.selected) {
      icon = icon
          .animate(key: ValueKey(_bounceGeneration))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 90.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1, 1),
            duration: 90.ms,
            curve: Curves.easeIn,
          );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        child: AnimatedContainer(
          duration: kMicroDuration,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  icon,
                  if (widget.item.badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: _NavBadge(
                        count: widget.item.badgeCount,
                        borderColor: widget.colors.surfaceElevated,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.selected ? activeColor : inactiveColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({
    required this.count,
    required this.borderColor,
  });

  final int count;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
