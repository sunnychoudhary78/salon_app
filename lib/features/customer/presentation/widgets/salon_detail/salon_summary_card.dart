import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';

class SalonSummaryCard extends ConsumerStatefulWidget {
  const SalonSummaryCard({
    super.key,
    required this.salon,
    required this.onDirections,
    required this.onCall,
  });

  final SalonModel salon;
  final VoidCallback onDirections;
  final VoidCallback onCall;

  @override
  ConsumerState<SalonSummaryCard> createState() => _SalonSummaryCardState();
}

class _SalonSummaryCardState extends ConsumerState<SalonSummaryCard> {
  bool _busy = false;

  Future<void> _toggleFavorite() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(salonFavoriteProvider(widget.salon.id).notifier)
          .toggle();
      if (!mounted) return;
      final favorited = ref.read(salonFavoriteProvider(widget.salon.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favorited ? 'Saved to favorites' : 'Removed from favorites',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final salon = widget.salon;
    final favorited = ref.watch(salonFavoriteProvider(salon.id));
    final category = salon.isFeatured ? 'Featured Salon' : 'Salon';
    final address = (salon.formattedAddress?.trim().isNotEmpty == true)
        ? salon.formattedAddress!.trim()
        : salonLocationLine(salon);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: premiumCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompactInfoRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: category,
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _CompactInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: address,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _toggleFavorite,
                  tooltip: favorited ? 'Remove favorite' : 'Add favorite',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    favorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: favorited
                        ? AppColors.error
                        : context.appColors.accent,
                    size: 22,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: colors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _InlineAction(
                    icon: Icons.directions_rounded,
                    label: 'Directions',
                    onTap: widget.onDirections,
                  ),
                ),
                Expanded(
                  child: _InlineAction(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    onTap: widget.onCall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 16, color: context.appColors.accent),
        const SizedBox(width: 8),
        Text(
          '$label · ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.appColors.accent, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
