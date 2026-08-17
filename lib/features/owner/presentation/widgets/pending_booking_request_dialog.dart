import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/notifications/booking_alert_feedback.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_gate_provider.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_request.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/premium_chip.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';

/// Non-dismissible Accept/Reject UI for the current pending booking request.
class PendingBookingRequestPanel extends ConsumerStatefulWidget {
  const PendingBookingRequestPanel({super.key});

  @override
  ConsumerState<PendingBookingRequestPanel> createState() =>
      _PendingBookingRequestPanelState();
}

class _PendingBookingRequestPanelState
    extends ConsumerState<PendingBookingRequestPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BookingAlertFeedback.instance.start();
    });
  }

  @override
  void dispose() {
    BookingAlertFeedback.instance.stop();
    super.dispose();
  }

  Future<void> _afterAction(bool ok) async {
    if (!mounted) return;
    if (!ok || ref.read(pendingBookingGateProvider).isBlocking) {
      await BookingAlertFeedback.instance.start();
    }
  }

  Future<void> _accept() async {
    await BookingAlertFeedback.instance.stop();
    final ok = await ref
        .read(pendingBookingGateProvider.notifier)
        .acceptCurrent();
    await _afterAction(ok);
  }

  Future<void> _reject() async {
    // No nested showDialog — this panel sits above the Navigator in
    // MaterialApp.builder, so dialogs from this context are unreliable.
    await BookingAlertFeedback.instance.stop();
    final ok = await ref
        .read(pendingBookingGateProvider.notifier)
        .rejectCurrent();
    await _afterAction(ok);
  }

  String _whenLabel(PendingBookingRequest request) {
    final date = request.bookingDate.trim();
    final time = request.bookingTime.trim();
    if (date.isEmpty && time.isEmpty) return 'Time TBA';
    try {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) {
        final dateText = DateFormat('EEE, d MMM').format(parsed);
        final timeText = time.length >= 5 ? time.substring(0, 5) : time;
        return timeText.isEmpty ? dateText : '$dateText · $timeText';
      }
    } catch (_) {}
    return [date, time].where((p) => p.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(pendingBookingGateProvider);
    final request = gate.current;
    if (request == null) return const SizedBox.shrink();

    final colors = context.appColors;
    final remaining = gate.queue.length;
    final amount = request.amount;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaffAvatar(
                    name: request.customerName?.trim().isNotEmpty == true
                        ? request.customerName!.trim()
                        : 'C',
                    imageUrl: request.customerPhotoUrl,
                    size: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.isPremium
                              ? 'Urgent booking request'
                              : 'New booking request',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                        ),
                        if (request.isPremium) ...[
                          const SizedBox(height: 6),
                          const PremiumChip(label: 'URGENT'),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          remaining > 1
                              ? 'Respond to continue · $remaining waiting'
                              : 'Accept or reject to continue',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: request.customerName?.trim().isNotEmpty == true
                    ? request.customerName!.trim()
                    : 'Customer',
              ),
              _InfoRow(
                icon: Icons.content_cut_rounded,
                label: request.serviceNames,
              ),
              _InfoRow(
                icon: Icons.schedule_rounded,
                label: _whenLabel(request),
              ),
              if (request.salonName != null &&
                  request.salonName!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  label: request.salonName!.trim(),
                ),
              if (amount != null && amount > 0)
                _InfoRow(
                  icon: Icons.currency_rupee_rounded,
                  label: '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                ),
              if (gate.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  gate.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 20),
              PremiumButton(
                label: 'Accept',
                loading: gate.actingAction == PendingBookingGateAction.accept,
                onPressed: gate.acting ? null : _accept,
              ),
              const SizedBox(height: 10),
              PremiumButton(
                label: 'Reject',
                variant: PremiumButtonVariant.accent,
                loading: gate.actingAction == PendingBookingGateAction.reject,
                onPressed: gate.acting ? null : _reject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
