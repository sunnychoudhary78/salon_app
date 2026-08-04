import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';

class SalonBookingBar extends StatelessWidget {
  const SalonBookingBar({super.key, required this.salon, required this.onBook});

  final SalonModel salon;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    if (salon.services.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    final minPrice = minServicePrice(salon);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: colors.glassBorder.withValues(alpha: 0.5)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Starting from',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          minPrice != null
                              ? '₹${minPrice.toStringAsFixed(0)}'
                              : '—',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: onBook,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appColors.accent,
                        foregroundColor: colors.onAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
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
