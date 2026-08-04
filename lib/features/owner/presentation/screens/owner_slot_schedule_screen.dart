import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/horizontal_date_strip.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_dialog.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
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
        builder: (ctx) => PremiumDialog(
          title: 'Booked slot',
          subtitle: slot.displayLabel,
          content: GlassCard(
            elevated: false,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _BookedSlotRow(
                  label: 'Customer',
                  value: b['customer_name']?.toString() ?? 'Customer',
                ),
                _BookedSlotRow(
                  label: 'Service',
                  value: b['service_name']?.toString() ?? 'Service',
                ),
                _BookedSlotRow(
                  label: 'Status',
                  value: b['booking_status']?.toString() ?? '—',
                ),
                _BookedSlotRow(
                  label: 'Type',
                  value: b['booking_type']?.toString() ?? 'STANDARD',
                ),
              ],
            ),
          ),
          confirmLabel: 'Close',
          showCancel: false,
          onConfirm: () => Navigator.pop(ctx),
        ),
      );
      return;
    }

    if (slot.status == 'past') {
      showFormDisabledMessage(context, 'Past slots cannot be changed');
      return;
    }

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
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
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            AppDecorations.scrollBottomPadding(context),
          ),
          children: [
            const SectionHeader(
              title: 'Select date',
              subtitle: 'View and manage slots for a specific day',
            ),
            const SizedBox(height: 12),
            AnimatedEntrance(
              key: ValueKey(_dateStr),
              child: GlassCard(
                elevated: true,
                radius: 18,
                child: HorizontalDateStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) => setState(() => _selectedDate = date),
                  onMoreDates: _pickDate,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'Time slots',
              subtitle: 'Tap to block/unblock or view booking details',
            ),
            const SizedBox(height: 12),
            AsyncValueWidget(
              value: slotsAsync,
              data: (data) => AnimatedEntrance(
                key: ValueKey('slots_$_dateStr'),
                child: GlassCard(
                  elevated: false,
                  radius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlotPickerGrid(
                        slots: data.slots,
                        ownerMode: true,
                        onSlotTap: _onSlotTap,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _ScheduleLegendDot(
                            color: context.appColors.textSecondary,
                            label: 'Available',
                            icon: Icons.circle_outlined,
                          ),
                          _ScheduleLegendDot(
                            color: AppColors.error,
                            label: 'Booked',
                            icon: Icons.event_busy_outlined,
                          ),
                          _ScheduleLegendDot(
                            color: AppColors.warning,
                            label: 'Blocked',
                            icon: Icons.block,
                          ),
                          _ScheduleLegendDot(
                            color: context.appColors.textMuted,
                            label: 'Past',
                            icon: Icons.history,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleLegendDot extends StatelessWidget {
  const _ScheduleLegendDot({
    required this.color,
    required this.label,
    this.icon,
  });

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 13, color: color)
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    return PremiumDialog(
      title: widget.isBlocked ? 'Unblock slot?' : 'Block slot?',
      subtitle: widget.isBlocked
          ? 'Make ${widget.displayLabel} available for booking again.'
          : 'Mark ${widget.displayLabel} unavailable for normal bookings.',
      content: widget.isBlocked
          ? null
          : PremiumTextField(
              controller: _noteController,
              label: 'Reason (optional)',
              inputFormatters: [
                LengthLimitingTextInputFormatter(kNotesMaxLength),
              ],
              validator: validateOptionalNotes,
            ),
      confirmLabel: widget.isBlocked ? 'Unblock' : 'Block',
      cancelLabel: 'Cancel',
      onConfirm: _confirm,
      onCancel: () => Navigator.pop(context),
      confirmVariant: widget.isBlocked
          ? PremiumButtonVariant.primary
          : PremiumButtonVariant.accent,
    );
  }
}

class _BookedSlotRow extends StatelessWidget {
  const _BookedSlotRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.appColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
