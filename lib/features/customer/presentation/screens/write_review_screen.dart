import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  int _salonRating = 5;
  int _staffRating = 5;
  final _reviewController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _friendlyError(Object error) {
    final text = userFacingErrorMessage(
      error,
      fallback: 'Could not submit review. Please try again.',
    );
    final lower = text.toLowerCase();
    if (lower.contains('already reviewed')) {
      return 'You have already reviewed this booking';
    }
    if (lower.contains('after your appointment slot ends')) {
      return 'You can submit a review after your appointment slot ends';
    }
    return text;
  }

  Future<void> _submit({required bool hasStaff}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(reviewActionsProvider.notifier)
          .submit(
            bookingId: widget.bookingId,
            rating: _salonRating,
            staffRating: hasStaff ? _staffRating : null,
            review: _reviewController.text.trim().isEmpty
                ? null
                : _reviewController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your review!')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _ratingLabel(int rating) {
    return switch (rating) {
      1 => 'Poor',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Great',
      _ => 'Excellent',
    };
  }

  BookingStaffRef? _staffFromBookings(List<BookingModel>? bookings) {
    if (bookings == null) return null;
    for (final booking in bookings) {
      if (booking.id == widget.bookingId) return booking.staff;
    }
    return null;
  }

  Widget _starRow({required int rating, required ValueChanged<int> onChanged}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth / 5).clamp(1.0, 56.0);
        final iconSize = (cell * 0.78).clamp(1.0, 44.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final selected = i < rating;
            return SizedBox(
              width: cell,
              height: cell,
              child: IconButton(
                onPressed: () => setState(() {
                  onChanged(i + 1);
                  _formKey.currentState?.validate();
                }),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints.tightFor(width: cell, height: cell),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size(cell, cell),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.starGold,
                  size: iconSize,
                  shadows: selected
                      ? [
                          Shadow(
                            color: AppColors.starGold.withValues(alpha: 0.6),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final staff = _staffFromBookings(bookingsAsync.asData?.value);
    final hasStaff = staff != null;
    final lowRating = _salonRating <= 2 || (hasStaff && _staffRating <= 2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) popOrGoHome(context);
      },
      child: Scaffold(
        appBar: PremiumAppBar(
          title: 'Write review',
          showMenu: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => popOrGoHome(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedEntrance(
            child: Form(
              key: _formKey,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Salon experience',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How was the salon overall?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ratingLabel(_salonRating),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.appColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _starRow(
                      rating: _salonRating,
                      onChanged: (value) => _salonRating = value,
                    ),
                    if (hasStaff) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          StaffAvatar(
                            name: staff.name,
                            imageUrl: staff.profileImage,
                            size: 48,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staff experience',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'How was your experience with ${staff.name}?',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _ratingLabel(_staffRating),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.appColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _starRow(
                        rating: _staffRating,
                        onChanged: (value) => _staffRating = value,
                      ),
                    ],
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _reviewController,
                      label: lowRating
                          ? 'Review (required for low ratings)'
                          : 'Review (optional)',
                      hint: hasStaff
                          ? 'Share what you loved about the salon and ${staff.name}'
                          : 'Share what you loved about your visit',
                      maxLines: 4,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(kReviewMaxLength),
                      ],
                      validator: (v) => validateReviewComment(
                        v,
                        rating: _salonRating,
                        staffRating: hasStaff ? _staffRating : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    PremiumButton(
                      label: 'Submit review',
                      loading: _loading,
                      variant: PremiumButtonVariant.accent,
                      onPressed: _loading
                          ? null
                          : () => _submit(hasStaff: hasStaff),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
