import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/providers/audience_mode_provider.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/booking/booking_service_selection_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/glass_bottom_sheet.dart';
import 'package:saloon_booking/shared/widgets/horizontal_date_strip.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
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
  Timer? _resumeRefreshTimer;
  DateTime? _lastResumeRefreshAt;

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
    _resumeRefreshTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Slot availability can change while the user is away (e.g. the salon
    // accepts/rejects another request), so refetch when returning.
    if (state == AppLifecycleState.resumed && mounted && _dateStr != null) {
      final lastRefreshAt = _lastResumeRefreshAt;
      if (lastRefreshAt != null &&
          DateTime.now().difference(lastRefreshAt) <
              const Duration(seconds: 10)) {
        return;
      }
      _resumeRefreshTimer?.cancel();
      _resumeRefreshTimer = Timer(const Duration(milliseconds: 750), () {
        _resumeRefreshTimer = null;
        if (!mounted || _dateStr == null) return;
        _lastResumeRefreshAt = DateTime.now();
        CrashReporting.breadcrumb('appointment_slots_resume_refresh');
        _refreshSlots();
      });
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
      : const ['Choose services', 'Pick date & time', 'Add notes'];

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

  List<ServiceModel> _visibleServices(SalonModel salon, AudienceMode audience) {
    return salon.services
        .where((s) => isServiceVisibleForAudience(s.serviceName, audience))
        .toList();
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

  bool get _isUrgentSlotSelected {
    final slot = _selectedSlot;
    return slot != null && slot.status != 'available';
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

  bool _isSlotConflictMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('already booked') ||
        lower.contains('blocked by the salon') ||
        lower.contains('this slot is not available');
  }

  String _slotUnavailableMessage(SalonSlotModel? slot, String fallback) {
    if (slot?.status == 'blocked' ||
        fallback.toLowerCase().contains('blocked')) {
      return 'This slot is blocked by the salon. Please choose another time.';
    }
    return 'This time is already booked. Please choose another slot.';
  }

  Future<_UrgentSheetResult?> _showUrgentBookingSheet({
    required String title,
    required String body,
    String dismissLabel = 'Cancel',
  }) {
    return showGlassBottomSheet<_UrgentSheetResult>(
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
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            PremiumButton(
              label: 'Send urgent request',
              onPressed: () =>
                  Navigator.pop(ctx, _UrgentSheetResult.sendUrgent),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, _UrgentSheetResult.chooseAnother),
              child: Text(dismissLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSlotUnavailableSheet(String message) {
    return showGlassBottomSheet<void>(
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
            Text(
              'Slot unavailable',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            PremiumButton(
              label: 'Choose another time',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<SalonSlotsResponse?> _loadSlots() async {
    if (_dateStr == null) return null;
    try {
      return await ref.read(
        salonSlotsProvider((salonId: widget.salonId, date: _dateStr!)).future,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleStandardSlotConflict(String apiMessage) async {
    _refreshSlots();
    final slotsData = await _loadSlots();
    if (!mounted) return;

    final selectedStart = _selectedSlot?.slotStart;
    SalonSlotModel? refreshed;
    if (slotsData != null && selectedStart != null) {
      for (final slot in slotsData.slots) {
        if (slot.slotStart == selectedStart) {
          refreshed = slot;
          break;
        }
      }
    }

    final premiumConfig = slotsData?.premiumConfig;
    final canOfferUrgent =
        premiumConfig != null &&
        premiumConfig.enabled &&
        refreshed != null &&
        (refreshed.premiumEligible ||
            refreshed.status == 'booked' ||
            refreshed.status == 'blocked');

    if (!canOfferUrgent) {
      final message = _slotUnavailableMessage(refreshed, apiMessage);
      setState(() {
        _selectedSlot = null;
        _error = message;
      });
      await _showSlotUnavailableSheet(message);
      return;
    }

    setState(() {
      _selectedSlot = refreshed;
      _error = null;
    });

    final serviceCount = _selectedServiceIds.length;
    final result = await _showUrgentBookingSheet(
      title: 'Slot already taken',
      dismissLabel: 'Choose another time',
      body:
          '${_premiumSlotMessage(refreshed)} If the salon accepts, you will get a timer to pay '
          '₹${premiumConfig.fee.toStringAsFixed(0)} premium for $serviceCount '
          'service${serviceCount > 1 ? 's' : ''}.',
    );

    if (!mounted) return;
    if (result == _UrgentSheetResult.sendUrgent) {
      await _submit(isPremium: true);
    } else {
      setState(() {
        _selectedSlot = null;
        _error = null;
      });
    }
  }

  Future<void> _confirmAndSubmitUrgent() async {
    final slot = _selectedSlot;
    if (slot == null) return;

    final slotsData = await _loadSlots();
    if (!mounted) return;
    final premiumConfig = slotsData?.premiumConfig;
    if (premiumConfig == null || !premiumConfig.enabled) {
      setState(() {
        _error = _slotUnavailableMessage(slot, '');
        _selectedSlot = null;
      });
      return;
    }

    if (_selectedServiceIds.isEmpty) {
      setState(
        () => _error = 'Select at least one service before booking a slot',
      );
      return;
    }

    final serviceCount = _selectedServiceIds.length;
    final result = await _showUrgentBookingSheet(
      title: 'Urgent booking',
      body:
          '${_premiumSlotMessage(slot)} If the salon accepts, you will get a timer to pay '
          '₹${premiumConfig.fee.toStringAsFixed(0)} premium for $serviceCount '
          'service${serviceCount > 1 ? 's' : ''}.',
    );

    if (!mounted) return;
    if (result == _UrgentSheetResult.sendUrgent) {
      await _submit(isPremium: true);
    } else if (result == _UrgentSheetResult.chooseAnother) {
      setState(() {
        _selectedSlot = null;
        _error = null;
      });
    }
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
    } catch (e) {
      final message = userFacingErrorMessage(e);
      // Refresh so the grid reflects the current server state.
      _refreshSlots();
      if (!mounted) return;
      if (!isPremium && _isSlotConflictMessage(message)) {
        setState(() => _loading = false);
        await _handleStandardSlotConflict(message);
        return;
      }
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSlotTap(
    SalonSlotModel slot,
    PremiumConfigModel premiumConfig,
  ) async {
    if (slot.status == 'available') {
      setState(() {
        _selectedSlot = slot;
        _error = null;
      });
      return;
    }

    if (!slot.premiumEligible || !premiumConfig.enabled) {
      setState(() {
        _error = slot.status == 'blocked'
            ? 'This slot is blocked by the salon. Pick an available time.'
            : 'This slot is already booked. Pick an available time.';
      });
      return;
    }

    if (_selectedServiceIds.isEmpty) {
      setState(
        () => _error = 'Select at least one service before booking a slot',
      );
      return;
    }

    final serviceCount = _selectedServiceIds.length;
    final result = await _showUrgentBookingSheet(
      title: 'Urgent booking',
      body:
          '${_premiumSlotMessage(slot)} If the salon accepts, you will get a timer to pay '
          '₹${premiumConfig.fee.toStringAsFixed(0)} premium for $serviceCount '
          'service${serviceCount > 1 ? 's' : ''}.',
    );

    if (result == _UrgentSheetResult.sendUrgent && mounted) {
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
            final audience = ref.watch(audienceModeValueProvider);
            final visibleServices = _visibleServices(salon, audience);

            // Drop selected services hidden for the current audience mode.
            final hiddenSelected = _selectedServiceIds.where(
              (id) => !visibleServices.any((s) => s.id == id),
            );
            if (hiddenSelected.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedServiceIds.removeWhere(
                    (id) => !visibleServices.any((s) => s.id == id),
                  );
                });
              });
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      AnimatedEntrance(
                        index: 0,
                        child: _BookingIntroCard(
                          salonName: salon.salonName,
                          child: StepProgressHeader(
                            currentStep: currentStep,
                            totalSteps: stepTitles.length,
                            titles: stepTitles,
                          ),
                        ),
                      ),
                      if (_selectedServiceIds.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        AnimatedEntrance(
                          index: 1,
                          child: _BookingSummaryCard(
                            serviceCount: _selectedServiceIds.length,
                            durationMinutes: _selectedDurationMinutes(salon),
                            total: _selectedTotal(salon),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      const _BookingSectionHeader(
                        number: 1,
                        title: 'Choose your services',
                        subtitle:
                            'Select one or more services for the same visit',
                      ),
                      const SizedBox(height: 14),
                      AnimatedEntrance(
                        index: 2,
                        child: Column(
                          children: [
                            for (var i = 0; i < visibleServices.length; i++) ...[
                              BookingServiceSelectionCard(
                                service: visibleServices[i],
                                audience: audience,
                                selected: _selectedServiceIds.contains(
                                  visibleServices[i].id,
                                ),
                                onTap: () =>
                                    _toggleService(visibleServices[i].id),
                              ),
                              if (i != visibleServices.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                      if (hasStaff) ...[
                        const SizedBox(height: 28),
                        const AnimatedEntrance(
                          index: 3,
                          child: _BookingSectionHeader(
                            number: 2,
                            title: 'Choose your professional',
                            subtitle:
                                'Optional — choose a specialist or any available staff',
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedEntrance(
                          index: 4,
                          child: SizedBox(
                            height: 152,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _StaffPreferenceTile(
                                  label: 'Any staff',
                                  selected: _preferredStaffId == null,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _preferredStaffId = null);
                                  },
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
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(
                                          () => _preferredStaffId = member.id,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      AnimatedEntrance(
                        index: 5,
                        child: _BookingSectionHeader(
                          number: hasStaff ? 3 : 2,
                          title: 'Date & time',
                          subtitle: 'Choose when you would like to visit',
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedEntrance(
                        index: 6,
                        child: GlassCard(
                          elevated: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HorizontalDateStrip(
                                selectedDate: _selectedDate,
                                onDateSelected: _selectDate,
                                onMoreDates: _pickDate,
                              ),
                              const SizedBox(height: 14),
                              if (slotsAsync == null)
                                _DateHoursMetaRow(
                                  dateLabel: _selectedDate == null
                                      ? 'Choose a date'
                                      : DateFormat.yMMMEd().format(
                                          _selectedDate!,
                                        ),
                                  hoursLabel:
                                      '${salon.openingTime!.substring(0, 5)} – ${salon.closingTime!.substring(0, 5)}',
                                  availableCount: null,
                                )
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
                                    final fee = slotsData.premiumConfig.fee;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _DateHoursMetaRow(
                                          dateLabel: _selectedDate == null
                                              ? 'Choose a date'
                                              : DateFormat.yMMMEd().format(
                                                  _selectedDate!,
                                                ),
                                          hoursLabel:
                                              '${salon.openingTime!.substring(0, 5)} – ${salon.closingTime!.substring(0, 5)}',
                                          availableCount: availableCount,
                                        ),
                                        const SizedBox(height: 14),
                                        Divider(
                                          color: context.appColors.glassBorder,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 14),
                                        if (hasUrgentSlots) ...[
                                          _UrgentCallout(
                                            fee: fee,
                                            allFull: availableCount == 0,
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        SlotPickerGrid(
                                          slots: slotsData.slots,
                                          selectedSlotStart:
                                              _selectedSlot?.slotStart,
                                          premiumFee: fee,
                                          onSlotTap: (slot) => _onSlotTap(
                                            slot,
                                            slotsData.premiumConfig,
                                          ),
                                        ),
                                        if (_selectedSlot != null) ...[
                                          const SizedBox(height: 14),
                                          _SelectedSlotStrip(
                                            label: _selectedSlot!.startLabel,
                                            rangeLabel:
                                                _selectedSlot!.displayLabel,
                                          ),
                                        ],
                                        const SizedBox(height: 14),
                                        const _SlotStatusKey(),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _BookingSectionHeader(
                        number: hasStaff ? 4 : 3,
                        title: 'Notes',
                        subtitle: 'Add any preferences or special requests',
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        elevated: false,
                        child: PremiumTextField(
                          controller: _notesController,
                          label: 'Notes (optional)',
                          maxLines: 2,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(kNotesMaxLength),
                          ],
                          validator: validateOptionalNotes,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
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
            final isUrgentSelection = _isUrgentSlotSelected;
            final canSubmit =
                !_loading &&
                _selectedSlot != null &&
                _selectedServiceIds.isNotEmpty;
            String? disabledMessage;
            if (!_loading && !canSubmit) {
              if (_selectedServiceIds.isEmpty) {
                disabledMessage = 'Please select a service to continue';
              } else if (_selectedSlot == null) {
                disabledMessage = 'Please select a time slot to continue';
              }
            }
            final slotLabel = _selectedSlot?.startLabel;
            final String requestLabel;
            if (count == 0) {
              requestLabel = 'Send request';
            } else if (slotLabel != null && isUrgentSelection) {
              requestLabel = 'Send urgent request · $slotLabel';
            } else if (slotLabel != null) {
              requestLabel = 'Request · $slotLabel';
            } else {
              requestLabel =
                  'Send request ($count service${count > 1 ? 's' : ''})';
            }
            return ScreenActionBar(
              label: requestLabel,
              subtitle: count == 0
                  ? null
                  : '${_selectedDurationMinutes(salon)} min · '
                        '₹${_selectedTotal(salon).toStringAsFixed(0)} estimated'
                        '${count > 1 ? ' · $count services' : ''}'
                        '${isUrgentSelection ? ' · urgent' : ''}',
              icon: isUrgentSelection
                  ? Icons.bolt_rounded
                  : Icons.send_rounded,
              loading: _loading,
              // Only require the basics here; the server (`assertSlotBookable`)
              // is the source of truth for slot availability, and any conflict
              // is surfaced via the conflict sheet / `_error`.
              onPressed: canSubmit
                  ? () => isUrgentSelection
                        ? _confirmAndSubmitUrgent()
                        : _submit(isPremium: false)
                  : null,
              disabledMessage: disabledMessage,
            );
          },
          orElse: () => null,
        ),
      ),
    );
  }
}

enum _UrgentSheetResult { sendUrgent, chooseAnother }

class _BookingIntroCard extends StatelessWidget {
  const _BookingIntroCard({required this.salonName, required this.child});

  final String salonName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceElevated, colors.accentSoft],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
        boxShadow: colors.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your appointment at',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      salonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: colors.glassBorder),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.serviceCount,
    required this.durationMinutes,
    required this.total,
  });

  final int serviceCount;
  final int durationMinutes;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accentSoft,
            colors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking summary',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$serviceCount',
                  label: serviceCount == 1 ? 'Service' : 'Services',
                ),
              ),
              _SummaryDivider(color: colors.glassBorder),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.schedule_rounded,
                  value: '$durationMinutes',
                  label: 'Minutes',
                ),
              ),
              _SummaryDivider(color: colors.glassBorder),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.payments_outlined,
                  value: '₹${total.toStringAsFixed(0)}',
                  label: 'Estimated',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        Icon(icon, size: 17, color: colors.accent),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: color,
    );
  }
}

class _BookingSectionHeader extends StatelessWidget {
  const _BookingSectionHeader({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final int number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateHoursMetaRow extends StatelessWidget {
  const _DateHoursMetaRow({
    required this.dateLabel,
    required this.hoursLabel,
    required this.availableCount,
  });

  final String dateLabel;
  final String hoursLabel;
  final int? availableCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 18, color: colors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hoursLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (availableCount != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: availableCount! > 0
                  ? AppColors.success.withValues(alpha: 0.12)
                  : colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: availableCount! > 0
                    ? AppColors.success.withValues(alpha: 0.35)
                    : colors.glassBorder,
              ),
            ),
            child: Text(
              availableCount! == 1
                  ? '1 open'
                  : '$availableCount open',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: availableCount! > 0
                    ? AppColors.success
                    : colors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _UrgentCallout extends StatelessWidget {
  const _UrgentCallout({required this.fee, required this.allFull});

  final double fee;
  final bool allFull;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final feeLabel = fee > 0 ? ' · ₹${fee.toStringAsFixed(0)}' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, size: 16, color: colors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              allFull
                  ? 'All regular slots are full. Tap a bolt slot for urgent$feeLabel.'
                  : 'Need a taken slot? Tap the bolt for urgent$feeLabel.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedSlotStrip extends StatelessWidget {
  const _SelectedSlotStrip({
    required this.label,
    required this.rangeLabel,
  });

  final String label;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: colors.accentGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: colors.onAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected · $label',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  rangeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onAccent.withValues(alpha: 0.85),
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

class _SlotStatusKey extends StatelessWidget {
  const _SlotStatusKey();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _StatusKeyItem(
          icon: Icons.circle_outlined,
          label: 'Available',
          color: colors.textSecondary,
        ),
        _StatusKeyItem(
          icon: Icons.event_busy_outlined,
          label: 'Taken',
          color: colors.textMuted,
        ),
        _StatusKeyItem(
          icon: Icons.bolt_rounded,
          label: 'Urgent',
          color: colors.accent,
        ),
      ],
    );
  }
}

class _StatusKeyItem extends StatelessWidget {
  const _StatusKeyItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
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

class _StaffPreferenceTile extends StatefulWidget {
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
  State<_StaffPreferenceTile> createState() => _StaffPreferenceTileState();
}

class _StaffPreferenceTileState extends State<_StaffPreferenceTile> {
  int _pulseGeneration = 0;

  @override
  void didUpdateWidget(covariant _StaffPreferenceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected) {
      _pulseGeneration++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final borderColor = widget.selected
        ? colors.accent
        : colors.glassBorder.withValues(alpha: 0.8);

    Widget tile = AnimatedContainer(
      duration: kMicroDuration,
      width: 108,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.selected ? colors.accentSoft : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: widget.selected ? 2 : 1),
        boxShadow: widget.selected
            ? [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : colors.cardShadow(),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              if (widget.imageUrl == null && widget.label == 'Any staff')
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.accent.withValues(alpha: 0.15),
                  child: Icon(Icons.groups_outlined, color: colors.accent),
                )
              else
                StaffAvatar(
                  name: widget.label,
                  imageUrl: widget.imageUrl,
                  size: 56,
                ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.selected ? colors.accent : null,
                ),
              ),
              if (widget.label != 'Any staff') ...[
                const SizedBox(height: 4),
                SalonRatingBadge(
                  averageRating: widget.rating,
                  reviewCount: widget.reviewCount,
                  size: SalonRatingBadgeSize.compact,
                ),
              ],
            ],
          ),
          if (widget.selected)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.check_circle_rounded,
                color: colors.accent,
                size: 18,
              ),
            ),
        ],
      ),
    );

    if (!animationsDisabled(context) && widget.selected) {
      tile = tile
          .animate(key: ValueKey(_pulseGeneration))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.03, 1.03),
            duration: kMicroDuration,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.03, 1.03),
            end: const Offset(1, 1),
            duration: kMicroDuration,
            curve: Curves.easeIn,
          );
    }

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(onTap: widget.onTap, child: tile),
    );
  }
}
