import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/glass_bottom_sheet.dart';
import 'package:saloon_booking/shared/widgets/horizontal_date_strip.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/service_tile.dart';
import 'package:saloon_booking/shared/widgets/slot_picker_grid.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';
import 'package:saloon_booking/shared/widgets/step_progress_header.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({
    super.key,
    required this.salonId,
    this.initialServiceIds = const {},
    this.initialStaffId,
  });

  final String salonId;
  final Set<String> initialServiceIds;
  /// Preferred staff prefilled from salon detail (optional).
  final String? initialStaffId;

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen>
    with WidgetsBindingObserver {
  final Set<String> _selectedServiceIds = {};
  /// null means "Any staff". Only sent when a specific member is chosen.
  String? _preferredStaffId;
  DateTime? _selectedDate;
  SalonSlotModel? _selectedSlot;
  final _notesController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = DateTime.now();
    if (widget.initialServiceIds.isNotEmpty) {
      _selectedServiceIds.addAll(widget.initialServiceIds);
    }
    final staffId = widget.initialStaffId;
    if (staffId != null && staffId.isNotEmpty) {
      _preferredStaffId = staffId;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Slot availability can change while the user is away (e.g. the salon
    // accepts/rejects another request), so refetch when returning.
    if (state == AppLifecycleState.resumed && mounted && _dateStr != null) {
      _refreshSlots();
    }
  }

  void _refreshSlots() {
    if (_dateStr == null) return;
    ref.invalidate(
      salonSlotsProvider((salonId: widget.salonId, date: _dateStr!)),
    );
  }

  String? get _dateStr => _selectedDate != null
      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
      : null;

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
    });
  }

  int _currentBookingStep({required bool hasStaff}) {
    if (_selectedServiceIds.isEmpty) return 0;
    if (_selectedSlot != null) return hasStaff ? 3 : 2;
    return hasStaff ? 2 : 1;
  }

  List<String> _stepTitles({required bool hasStaff}) => hasStaff
      ? const [
          'Choose services',
          'Preferred staff',
          'Pick date & time',
          'Add notes',
        ]
      : const [
          'Choose services',
          'Pick date & time',
          'Add notes',
        ];

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _selectedDate ?? DateTime.now(),
    );
    if (date != null) {
      _selectDate(date);
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

  int _selectedDurationMinutes(SalonModel salon) {
    return salon.services
        .where((s) => _selectedServiceIds.contains(s.id))
        .fold(0, (sum, s) => sum + (s.durationMinutes ?? 30));
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
      CrashReporting.breadcrumb('booking_submit');
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
            staffId: _preferredStaffId,
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
      // The request may have failed because slot availability changed; refresh
      // so the grid reflects the current server state.
      _refreshSlots();
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
    final confirmed = await showGlassBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          28 + MediaQuery.paddingOf(ctx).bottom,
        ),
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

            // Drop prefills that no longer match ACTIVE staff on this salon.
            if (_preferredStaffId != null &&
                !salon.staff.any((m) => m.id == _preferredStaffId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _preferredStaffId = null);
              });
            }

            final hasStaff = salon.staff.isNotEmpty;
            final stepTitles = _stepTitles(hasStaff: hasStaff);
            final currentStep = _currentBookingStep(hasStaff: hasStaff);

            return Column(
              children: [
                if (_selectedServiceIds.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    child: Text(
                      '${_selectedServiceIds.length} service${_selectedServiceIds.length > 1 ? 's' : ''} selected · '
                      '${_selectedDurationMinutes(salon)} min · '
                      '₹${_selectedTotal(salon).toStringAsFixed(0)} est.',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.accent,
                          ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AnimatedEntrance(
                        index: 0,
                        child: StepProgressHeader(
                          currentStep: currentStep,
                          totalSteps: stepTitles.length,
                          titles: stepTitles,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select one or more for the same time slot',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.appColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedEntrance(
                        index: 1,
                        child: GlassCard(
                        child: Column(
                          children: salon.services
                              .map(
                                (s) => ServiceTile(
                                  service: s,
                                  multiSelect: true,
                                  selected: _selectedServiceIds.contains(s.id),
                                  onTap: () => _toggleService(s.id),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      ),
                      if (hasStaff) ...[
                        const SizedBox(height: 24),
                        const AnimatedEntrance(
                          index: 2,
                          child: SectionHeader(
                            title: 'Preferred staff',
                            subtitle: 'Optional — pick anyone or leave as Any',
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedEntrance(
                          index: 3,
                          child: SizedBox(
                            height: 148,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _StaffPreferenceTile(
                                  label: 'Any staff',
                                  selected: _preferredStaffId == null,
                                  onTap: () => setState(
                                    () => _preferredStaffId = null,
                                  ),
                                ),
                                ...salon.staff.map(
                                  (member) => Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: _StaffPreferenceTile(
                                      label: member.name,
                                      imageUrl: member.profileImage,
                                      rating: member.averageRating,
                                      reviewCount: member.reviewCount,
                                      selected: _preferredStaffId == member.id,
                                      onTap: () => setState(
                                        () => _preferredStaffId = member.id,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AnimatedEntrance(
                        index: 4,
                        child: const SectionHeader(
                          title: 'Date & time',
                          subtitle: 'Choose when you would like to visit',
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedEntrance(
                        index: 3,
                        child: HorizontalDateStrip(
                          selectedDate: _selectedDate,
                          onDateSelected: _selectDate,
                          onMoreDates: _pickDate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            DateFormat.yMMMEd().format(_selectedDate!),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.accent,
                                ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Hours: ${salon.openingTime!.substring(0, 5)} – ${salon.closingTime!.substring(0, 5)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.appColors.textMuted,
                            ),
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
                                      color: AppColors.accent
                                          .withValues(alpha: 0.12),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.accent),
                                    ),
                                  )
                                else if (hasUrgentSlots)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Booked or unavailable slots can be taken urgently for '
                                      '₹${slotsData.premiumConfig.fee.toStringAsFixed(0)} after salon approval.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: context.appColors.textMuted),
                                    ),
                                  ),
                                SlotPickerGrid(
                                  slots: slotsData.slots,
                                  selectedSlotStart: _selectedSlot?.slotStart,
                                  premiumFee: slotsData.premiumConfig.fee,
                                  onSlotTap: (slot) => _onSlotTap(
                                    slot,
                                    slotsData.premiumConfig,
                                  ),
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
                      const SizedBox(height: 24),
                      const SectionHeader(
                        title: 'Notes',
                        subtitle: 'Optional — special requests for the salon',
                      ),
                      const SizedBox(height: 12),
                      PremiumTextField(
                        controller: _notesController,
                        label: 'Notes (optional)',
                        maxLines: 2,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: salonAsync.maybeWhen(
          data: (salon) {
            if (salon.openingTime == null || salon.closingTime == null) {
              return null;
            }
            final count = _selectedServiceIds.length;
            return ScreenActionBar(
              label: count == 0
                  ? 'Send request'
                  : 'Send request ($count service${count > 1 ? 's' : ''})',
              icon: Icons.send_rounded,
              loading: _loading,
              // Only require the basics here; the server (`assertSlotBookable`)
              // is the source of truth for slot availability, and any conflict
              // is surfaced via `_error`. This avoids a stale cached slot status
              // silently locking the button.
              onPressed:
                  _loading || _selectedSlot == null || _selectedServiceIds.isEmpty
                  ? null
                  : () => _submit(isPremium: false),
            );
          },
          orElse: () => null,
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

class _StaffPreferenceTile extends StatelessWidget {
  const _StaffPreferenceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.imageUrl,
    this.rating,
    this.reviewCount = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? imageUrl;
  final double? rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.accent
        : context.appColors.glassBorder.withValues(alpha: 0.8);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 108,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            if (imageUrl == null && label == 'Any staff')
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                child: Icon(
                  Icons.groups_outlined,
                  color: AppColors.accent,
                ),
              )
            else
              StaffAvatar(name: label, imageUrl: imageUrl, size: 56),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.accent : null,
                  ),
            ),
            if (label != 'Any staff') ...[
              const SizedBox(height: 4),
              SalonRatingBadge(
                averageRating: rating,
                reviewCount: reviewCount,
                size: SalonRatingBadgeSize.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
