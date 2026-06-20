import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 5;
  final _reviewController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final message = error.response?.data;
      if (message is Map && message['message'] != null) {
        return message['message'].toString();
      }
    }
    final text = error.toString();
    if (text.contains('already reviewed')) {
      return 'You have already reviewed this booking';
    }
    if (text.contains('after your appointment slot ends')) {
      return 'You can submit a review after your appointment slot ends';
    }
    return 'Could not submit review. Please try again.';
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(reviewActionsProvider.notifier).submit(
            bookingId: widget.bookingId,
            rating: _rating,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedEntrance(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rating', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return IconButton(
                      onPressed: () => setState(() => _rating = i + 1),
                      icon: Icon(
                        i < _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    );
                  }),
                ),
                PremiumTextField(
                  controller: _reviewController,
                  label: 'Review (optional)',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                PremiumButton(
                  label: 'Submit review',
                  loading: _loading,
                  variant: PremiumButtonVariant.accent,
                  onPressed: _loading ? null : _submit,
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
