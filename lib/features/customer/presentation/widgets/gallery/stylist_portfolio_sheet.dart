import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/gallery_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/gallery/gallery_card_widget.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';

void showStylistPortfolioSheet(
  BuildContext context, {
  required StaffModel staff,
  required void Function(String staffId) onBookStaff,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StylistPortfolioSheet(
      staff: staff,
      onBookStaff: onBookStaff,
    ),
  );
}

class StylistPortfolioSheet extends ConsumerWidget {
  const StylistPortfolioSheet({
    super.key,
    required this.staff,
    required this.onBookStaff,
  });

  final StaffModel staff;
  final void Function(String staffId) onBookStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final portfolioAsync = ref.watch(staffPortfolioProvider(staff.id));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                StaffAvatar(
                  imageUrl: staff.profileImage,
                  name: staff.name,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (staff.averageRating != null) ...[
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              staff.averageRating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: colors.textSecondary)),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'Specialist Stylist',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Portfolio List
          Expanded(
            child: portfolioAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Could not load portfolio: $err', style: TextStyle(color: colors.textSecondary)),
              ),
              data: (data) {
                final posts = data.portfolio;
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No transformations uploaded yet',
                            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check back soon for before & after looks by ${staff.name.split(' ').first}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return GalleryCardWidget(
                      post: posts[index],
                      onBookStaff: onBookStaff,
                    );
                  },
                );
              },
            ),
          ),

          // Floating Book button at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.glassBorder.withValues(alpha: 0.5))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onBookStaff(staff.id);
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text('Book with ${staff.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

