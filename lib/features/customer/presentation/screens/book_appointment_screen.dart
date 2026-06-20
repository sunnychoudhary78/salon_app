import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/service_tile.dart';
import 'package:saloon_booking/shared/widgets/slot_picker_grid.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final Set<String> _selectedServiceIds = {};
  DateTime? _selectedDate;
  SalonSlotModel? _selectedSlot;
  final _notesController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String? get _dateStr => _selectedDate != null
      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
      : null;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _selectedDate ?? DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedSlot = null;
      });
    }
  }

  String _slotTimeForApi(String slotStart) => slotStart.substring(0, 5);

  void _toggleService(String serviceId) {
    setState(() {
      if (_selectedServiceIds.contains(serviceId)) {
        _selectedServiceIds.remove(serviceId);
      } else {
        _selectedServiceIds.add(serviceId);
      }
    });
  }

  double _selectedTotal(SalonModel salon) {
    return salon.services
        .where((s) => _selectedServiceIds.contains(s.id))
        .fold(0.0, (sum, s) => sum + s.effectivePrice);
  }

  String _premiumSlotMessage(SalonSlotModel slot) {
    return switch (slot.status) {
      'booked' =>
        'This slot is already booked. You can request an urgent premium booking.',
      'blocked' =>
        'The salon marked this slot unavailable. You can request an urgent premium booking.',
      _ => 'You can request an urgent premium booking for this slot.',
    };
  }

  Future<void> _submit({required bool isPremium}) async {
    if (_selectedServiceIds.isEmpty ||
        _selectedDate == null ||
        _selectedSlot == null) {
      setState(
        () => _error = 'Select at least one service, date, and time slot',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final count = _selectedServiceIds.length;
      await ref
          .read(bookingActionsProvider.notifier)
          .create(
            salonId: widget.salonId,
            serviceIds: _selectedServiceIds.toList(),
            bookingDate: _dateStr!,
            bookingTime: _slotTimeForApi(_selectedSlot!.slotStart),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            isPremium: isPremium,
          );
      if (!mounted) return;
      context.go(RoutePaths.customerBookings);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPremium
                ? 'Urgent request sent — awaiting salon approval ($count service${count > 1 ? 's' : ''})'
                : 'Request sent — awaiting salon approval ($count service${count > 1 ? 's' : ''})',
          ),
        ),
      );
    } on DioException catch (e) {
      setState(() => _error = e.apiException.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSlotTap(
    SalonSlotModel slot,
    PremiumConfigModel premiumConfig,
  ) async {
    if (slot.status == 'available') {
      setState(() => _selectedSlot = slot);
      return;
    }

    if (!slot.premiumEligible || !premiumConfig.enabled) return;

    if (_selectedServiceIds.isEmpty) {
      setState(
        () => _error = 'Select at least one service before booking a slot',
      );
      return;
    }

    final serviceCount = _selectedServiceIds.length;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Urgent booking', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${_premiumSlotMessage(slot)} If the salon accepts, you will get a timer to pay '
              '₹${premiumConfig.fee.toStringAsFixed(0)} premium for $serviceCount '
              'service${serviceCount > 1 ? 's' : ''}.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            PremiumButton(
              label: 'Send urgent request',
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _selectedSlot = slot);
      await _submit(isPremium: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonAsync = ref.watch(salonDetailProvider(widget.salonId));
    final slotsAsync = _dateStr == null
        ? null
        : ref.watch(
            salonSlotsProvider((salonId: widget.salonId, date: _dateStr!)),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) popOrGoHome(context);
      },
      child: Scaffold(
        appBar: PremiumAppBar(
          title: 'Book appointment',
          showMenu: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => popOrGoHome(context),
          ),
        ),
        body: AsyncValueWidget(
          value: salonAsync,
          data: (salon) {
            if (salon.openingTime == null || salon.closingTime == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This salon has not set operating hours yet. Please call the salon to book.',
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Select services',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'You can choose more than one service for the same time slot',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                ...salon.services.map(
                  (s) => ServiceTile(
                    service: s,
                    multiSelect: true,
                    selected: _selectedServiceIds.contains(s.id),
                    onTap: () => _toggleService(s.id),
                  ),
                ),
                if (_selectedServiceIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedServiceIds.length} selected · ₹${_selectedTotal(salon).toStringAsFixed(0)} est.',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.accent),
                  ),
                ],
                const SizedBox(height: 16),
                GlassCard(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                            Text(
                              _selectedDate != null
                                  ? DateFormat.yMMMd().format(_selectedDate!)
                                  : 'Pick a date',
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select time slot',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Hours: ${salon.openingTime!.substring(0, 5)} – ${salon.closingTime!.substring(0, 5)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                if (slotsAsync == null)
                  const SizedBox.shrink()
                else
                  AsyncValueWidget(
                    value: slotsAsync,
                    data: (slotsData) {
                      final availableCount = slotsData.slots
                          .where((s) => s.status == 'available')
                          .length;
                      final hasUrgentSlots = slotsData.slots.any(
                        (s) =>
                            s.premiumEligible &&
                            slotsData.premiumConfig.enabled,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (availableCount == 0 && hasUrgentSlots)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                'All regular slots are full. Tap any booked or unavailable slot marked '
                                '“Urgent · ₹${slotsData.premiumConfig.fee.toStringAsFixed(0)}” to send a premium request.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.accent),
                              ),
                            )
                          else if (hasUrgentSlots)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Booked or unavailable slots can be taken urgently for '
                                '₹${slotsData.premiumConfig.fee.toStringAsFixed(0)} after salon approval.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ),
                          SlotPickerGrid(
                            slots: slotsData.slots,
                            selectedSlotStart: _selectedSlot?.slotStart,
                            premiumFee: slotsData.premiumConfig.fee,
                            onSlotTap: (slot) =>
                                _onSlotTap(slot, slotsData.premiumConfig),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: const [
                              _LegendDot(
                                color: AppColors.success,
                                label: 'Available',
                              ),
                              _LegendDot(
                                color: AppColors.error,
                                label: 'Booked',
                              ),
                              _LegendDot(
                                color: AppColors.warning,
                                label: 'Blocked',
                              ),
                              _LegendDot(
                                color: AppColors.accent,
                                label: 'Urgent',
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _notesController,
                  label: 'Notes (optional)',
                  maxLines: 2,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                PremiumButton(
                  label: _selectedServiceIds.isEmpty
                      ? 'Send request'
                      : 'Send request (${_selectedServiceIds.length} service${_selectedServiceIds.length > 1 ? 's' : ''})',
                  loading: _loading,
                  onPressed:
                      _loading ||
                          _selectedSlot?.status != 'available' ||
                          _selectedServiceIds.isEmpty
                      ? null
                      : () => _submit(isPremium: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
