import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_section.dart';

class SalonAboutSection extends StatefulWidget {
  const SalonAboutSection({super.key, required this.salon});

  final SalonModel salon;

  @override
  State<SalonAboutSection> createState() => _SalonAboutSectionState();
}

class _SalonAboutSectionState extends State<SalonAboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.salon.description?.trim() ?? '';
    if (description.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    final showReadMore = description.length > 120;

    return SalonDetailSection(
      title: 'About Salon',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: compactSalonDetailCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              maxLines: !_expanded && showReadMore ? 4 : null,
              overflow: !_expanded && showReadMore
                  ? TextOverflow.ellipsis
                  : null,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            if (showReadMore)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                child: Text(_expanded ? 'Read less' : 'Read more'),
              ),
          ],
        ),
      ),
    );
  }
}
