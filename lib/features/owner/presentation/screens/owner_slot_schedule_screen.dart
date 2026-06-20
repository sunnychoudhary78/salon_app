import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/slot_picker_grid.dart';

class OwnerSlotScheduleScreen extends ConsumerStatefulWidget {
  const OwnerSlotScheduleScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<OwnerSlotScheduleScreen> createState() =>
      _OwnerSlotScheduleScreenState();
}

class _OwnerSlotScheduleScreenState
    extends ConsumerState<OwnerSlotScheduleScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _selectedDate,
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _onSlotTap(SalonSlotModel slot) async {
    if (slot.status == 'booked' && slot.booking != null) {
      final b = slot.booking!;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Booked slot'),
          content: Text(
            '${b['customer_name'] ?? 'Customer'}\n'
            '${b['service_name'] ?? 'Service'}\n'
            'Status: ${b['booking_status']}\n'
            'Type: ${b['booking_type'] ?? 'STANDARD'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    if (slot.status == 'past') return;

    final isBlocked = slot.status == 'blocked';
    final action = await showDialog<_SlotBlockDialogResult>(
      context: context,
      builder: (ctx) => _SlotBlockDialog(
        displayLabel: slot.displayLabel,
        isBlocked: isBlocked,
        initialNote: slot.blockNote,
      ),
    );

    if (action == null || !mounted) return;

    try {
      await ref
          .read(ownerSlotActionsProvider)
          .setBlocked(
            salonId: widget.salonId,
            slotDate: _dateStr,
            slotStart: slot.slotStart,
            isBlocked: !isBlocked,
            note: action.note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked ? 'Slot available again' : 'Slot marked unavailable',
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.apiException.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(
      ownerSlotsProvider((salonId: widget.salonId, date: _dateStr)),
    );

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Manage schedule',
        showMenu: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(DateFormat.yMMMd().format(_selectedDate))),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap a slot to block/unblock or view booking details.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          AsyncValueWidget(
            value: slotsAsync,
            data: (data) => SlotPickerGrid(
              slots: data.slots,
              ownerMode: true,
              onSlotTap: _onSlotTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotBlockDialogResult {
  const _SlotBlockDialogResult({this.note});

  final String? note;
}

class _SlotBlockDialog extends StatefulWidget {
  const _SlotBlockDialog({
    required this.displayLabel,
    required this.isBlocked,
    this.initialNote,
  });

  final String displayLabel;
  final bool isBlocked;
  final String? initialNote;

  @override
  State<_SlotBlockDialog> createState() => _SlotBlockDialogState();
}

class _SlotBlockDialogState extends State<_SlotBlockDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _confirm() {
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      _SlotBlockDialogResult(note: note.isEmpty ? null : note),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isBlocked ? 'Unblock slot?' : 'Block slot?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isBlocked
                ? 'Make ${widget.displayLabel} available for booking again.'
                : 'Mark ${widget.displayLabel} unavailable for normal bookings.',
          ),
          if (!widget.isBlocked) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(widget.isBlocked ? 'Unblock' : 'Block'),
        ),
      ],
    );
  }
}
