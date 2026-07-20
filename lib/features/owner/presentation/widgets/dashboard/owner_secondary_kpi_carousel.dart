import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class OwnerSecondaryKpiCarousel extends StatefulWidget {
  const OwnerSecondaryKpiCarousel({
    super.key,
    required this.bookings,
  });

  final OwnerDashboardBookingsSummary bookings;

  @override
  State<OwnerSecondaryKpiCarousel> createState() =>
      _OwnerSecondaryKpiCarouselState();
}

class _OwnerSecondaryKpiCarouselState extends State<OwnerSecondaryKpiCarousel> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookings.pending == 0 && widget.bookings.upcoming == 0) {
      return const SizedBox.shrink();
    }

    final cards = <Widget>[
      if (widget.bookings.pending > 0)
        _SecondaryCard(
          label: 'Pending requests',
          value: '${widget.bookings.pending}',
          icon: Icons.pending_actions_rounded,
          color: AppColors.warning,
        ),
      if (widget.bookings.upcoming > 0)
        _SecondaryCard(
          label: 'Upcoming',
          value: '${widget.bookings.upcoming}',
          icon: Icons.upcoming_rounded,
          color: AppColors.primary,
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 72,
          child: PageView(
            controller: _controller,
            children: cards,
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: _controller,
            count: cards.length,
            effect: WormEffect(
              dotHeight: 6,
              dotWidth: 6,
              activeDotColor: AppColors.primary,
              dotColor: context.appColors.textMuted.withValues(alpha: 0.3),
            ),
          ),
        ],
      ],
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  const _SecondaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
