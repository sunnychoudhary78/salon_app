import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/shared/widgets/premium_dialog.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

double _parseExtra(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 0;
  return double.tryParse(trimmed) ?? 0;
}

/// Returns extra cash (0 if skipped) or null if the owner cancels.
Future<double?> showExtraCashDialog({
  required BuildContext context,
  required double bookedAmount,
  required String title,
  required String confirmLabel,
  bool alreadyPaidOnline = false,
}) async {
  final extraController = TextEditingController();
  final extra = await showDialog<double>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final extraAmount = _parseExtra(extraController.text);
          final totalCash = bookedAmount + extraAmount;
          return PremiumDialog(
            title: title,
            subtitle: alreadyPaidOnline
                ? 'The booked fee is already paid online. Add extra cash if the customer took more services at the shop.'
                : 'Add extra cash if the customer took more services at the shop.',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  alreadyPaidOnline
                      ? 'Paid online: ${formatMoney(bookedAmount)}'
                      : 'Booking total: ${formatMoney(bookedAmount)}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: ctx.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: extraController,
                  label: 'Extra cash (optional)',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text(
                  alreadyPaidOnline
                      ? extraAmount > 0
                            ? 'Extra cash to collect: ${formatMoney(extraAmount)}'
                            : 'No extra cash'
                      : 'Total cash: ${formatMoney(totalCash)}',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                    color: ctx.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            confirmLabel: extraAmount > 0
                ? alreadyPaidOnline
                      ? '$confirmLabel · extra ${formatMoney(extraAmount)}'
                      : '$confirmLabel ${formatMoney(totalCash)}'
                : confirmLabel,
            cancelLabel: 'Cancel',
            onConfirm: () => Navigator.pop(ctx, extraAmount),
            onCancel: () => Navigator.pop(ctx),
          );
        },
      );
    },
  );
  extraController.dispose();
  return extra;
}
