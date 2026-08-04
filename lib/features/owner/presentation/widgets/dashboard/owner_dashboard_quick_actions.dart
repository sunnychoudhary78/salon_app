import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/owner_quick_link_tile.dart';

class OwnerDashboardQuickActions extends StatelessWidget {
  const OwnerDashboardQuickActions({super.key, required this.pendingBookings});

  final int pendingBookings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              OwnerQuickLinkTile(
                icon: Icons.calendar_month_rounded,
                label: 'Bookings',
                color: AppColors.success,
                onTap: () => context.go(RoutePaths.ownerBookings),
              ),
              if (pendingBookings > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      pendingBookings > 9 ? '9+' : '$pendingBookings',
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
          const SizedBox(width: 10),
          OwnerQuickLinkTile(
            icon: Icons.store_rounded,
            label: 'Salons',
            color: AppColors.primary,
            onTap: () => context.go(RoutePaths.ownerSalons),
          ),
          const SizedBox(width: 10),
          OwnerQuickLinkTile(
            icon: Icons.star_rounded,
            label: 'Reviews',
            color: context.appColors.accent,
            onTap: () => context.go(RoutePaths.ownerReviews),
          ),
          const SizedBox(width: 10),
          OwnerQuickLinkTile(
            icon: Icons.payments_rounded,
            label: 'Earnings',
            color: AppColors.warning,
            onTap: () => context.push(RoutePaths.ownerEarnings),
          ),
          const SizedBox(width: 10),
          OwnerQuickLinkTile(
            icon: Icons.settings_rounded,
            label: 'Settings',
            color: AppColors.primaryLight,
            onTap: () => context.push(RoutePaths.ownerSettings),
          ),
        ],
      ),
    );
  }
}
