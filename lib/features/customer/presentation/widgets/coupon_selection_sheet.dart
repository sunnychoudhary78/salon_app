import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';

class CouponSelectionSheet extends ConsumerStatefulWidget {
  const CouponSelectionSheet({
    super.key,
    required this.orderAmount,
    this.currentlyAppliedCode,
  });

  final double orderAmount;
  final String? currentlyAppliedCode;

  static Future<CouponModel?> show(
    BuildContext context, {
    required double orderAmount,
    String? currentlyAppliedCode,
  }) {
    return showModalBottomSheet<CouponModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CouponSelectionSheet(
        orderAmount: orderAmount,
        currentlyAppliedCode: currentlyAppliedCode,
      ),
    );
  }

  @override
  ConsumerState<CouponSelectionSheet> createState() => _CouponSelectionSheetState();
}

class _CouponSelectionSheetState extends ConsumerState<CouponSelectionSheet> {
  final _codeController = TextEditingController();
  bool _validating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndApply(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter a coupon code');
      return;
    }

    setState(() {
      _validating = true;
      _errorMessage = null;
    });

    try {
      final coupon = await ref.read(customerServiceProvider).validateCoupon(
        cleanCode,
        orderAmount: widget.orderAmount,
      );

      if (!mounted) return;
      if (coupon == null) {
        setState(() {
          _validating = false;
          _errorMessage = 'Invalid or expired coupon code';
        });
        return;
      }

      if (coupon.minOrderValue > 0 && widget.orderAmount < coupon.minOrderValue) {
        setState(() {
          _validating = false;
          _errorMessage =
              'Minimum order of ${formatMoney(coupon.minOrderValue)} required for this offer.';
        });
        return;
      }

      Navigator.of(context).pop(coupon);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      setState(() {
        _validating = false;
        _errorMessage = msg.contains('400') || msg.contains('404')
            ? 'Coupon is not valid for this order'
            : msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final couponsAsync = ref.watch(activeCouponsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_offer_rounded, color: colors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Coupon',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                      ),
                      Text(
                        'Order total: ${formatMoney(widget.orderAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.textMuted),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Manual Input Box
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.glassBorder),
                        ),
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ENTER COUPON CODE',
                            hintStyle: TextStyle(
                              color: colors.textMuted.withValues(alpha: 0.7),
                              fontSize: 13,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _validating
                            ? null
                            : () => _validateAndApply(_codeController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: _validating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Apply',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Text(
              'AVAILABLE OFFERS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Coupons List
          Expanded(
            child: couponsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No coupons available at the moment.',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              ),
              data: (coupons) {
                if (coupons.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.discount_outlined, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No active offers found right now',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check back soon for exclusive salon discounts!',
                            style: TextStyle(color: colors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: coupons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    final isApplied = widget.currentlyAppliedCode != null &&
                        widget.currentlyAppliedCode!.toUpperCase() == coupon.code.toUpperCase();
                    final bool isEligible = coupon.minOrderValue <= 0 ||
                        widget.orderAmount >= coupon.minOrderValue;
                    final discount = coupon.calculateDiscount(widget.orderAmount);

                    return _CouponCard(
                      coupon: coupon,
                      isApplied: isApplied,
                      isEligible: isEligible,
                      discountAmount: discount,
                      onApply: () => Navigator.of(context).pop(coupon),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.isApplied,
    required this.isEligible,
    required this.discountAmount,
    required this.onApply,
  });

  final CouponModel coupon;
  final bool isApplied;
  final bool isEligible;
  final double discountAmount;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApplied
              ? colors.accent
              : colors.glassBorder,
          width: isApplied ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Discount Badge Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.accent,
                        colors.accent.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      coupon.isPercent
                          ? '${coupon.discountValue.toInt()}%'
                          : '₹${coupon.discountValue.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colors.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              coupon.code,
                              style: TextStyle(
                                color: colors.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isApplied)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 13, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'Applied',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isEligible)
                            TextButton(
                              onPressed: onApply,
                              style: TextButton.styleFrom(
                                foregroundColor: colors.accent,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: const Text(
                                'APPLY',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            )
                          else
                            Text(
                              'Min ${formatMoney(coupon.minOrderValue)}',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (coupon.title != null && coupon.title!.isNotEmpty)
                        Text(
                          coupon.title!,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      if (coupon.description != null && coupon.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          coupon.description!,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Savings footer strip
          if (isEligible && discountAmount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Save ${formatMoney(discountAmount)} with this code',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
