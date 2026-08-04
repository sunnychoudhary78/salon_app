import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_section.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';

class SalonStaffSection extends StatelessWidget {
  const SalonStaffSection({
    super.key,
    required this.staff,
    required this.onBookStaff,
  });

  final List<StaffModel> staff;
  final void Function(String staffId) onBookStaff;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) return const SizedBox.shrink();

    return SalonDetailSection(
      title: 'Our Staff',
      subtitle: 'Choose a preferred stylist when you book',
      child: SizedBox(
        height: 136,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          itemCount: staff.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final member = staff[index];
            return _StaffCard(
              member: member,
              onTap: () => onBookStaff(member.id),
            );
          },
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.member, required this.onTap});

  final StaffModel member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 120,
      child: DecoratedBox(
        decoration: compactSalonDetailCardDecoration(context),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  StaffAvatar(
                    name: member.name,
                    imageUrl: member.profileImage,
                    size: 54,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SalonRatingBadge(
                    averageRating: member.averageRating,
                    reviewCount: member.reviewCount,
                    size: SalonRatingBadgeSize.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
