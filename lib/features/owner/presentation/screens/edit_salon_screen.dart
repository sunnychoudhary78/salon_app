import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/core/utils/phone_validation.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/models/salon_location_selection.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/salon_type_picker.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/owner_salon_location_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
import 'package:saloon_booking/shared/widgets/salon_hours_picker_row.dart';
import 'package:saloon_booking/shared/widgets/salon_image_picker.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class EditSalonScreen extends ConsumerStatefulWidget {
  const EditSalonScreen({super.key, required this.salonId, this.focusField});

  final String salonId;
  final String? focusField;

  @override
  ConsumerState<EditSalonScreen> createState() => _EditSalonScreenState();
}

class _EditSalonScreenState extends ConsumerState<EditSalonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _premiumFeeController = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _basicInfoKey = GlobalKey();
  final _hoursKey = GlobalKey();
  final _imagesKey = GlobalKey();
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  SalonLocationSelection? _location;
  SalonType _salonType = SalonType.unisex;

  List<String> _existingImageUrls = [];
  List<XFile> _newImages = [];
  bool _loading = false;
  bool _savingPremiumFee = false;
  String? _error;
  String? _premiumError;
  bool _initialized = false;
  bool _didApplyFocus = false;

  @override
  void dispose() {
    _salonNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _premiumFeeController.dispose();
    _descriptionFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String? get _normalizedFocusField {
    final field = widget.focusField;
    if (field == null || field.isEmpty) return null;
    if (field == 'opening_time' || field == 'closing_time') return 'hours';
    return field;
  }

  void _initializeFromSalon(SalonModel salon) {
    if (_initialized) return;
    _initialized = true;
    _salonNameController.text = salon.salonName;
    _salonType = salon.salonType;
    _descriptionController.text = salon.description ?? '';
    _phoneController.text = salon.phone ?? '';
    if (salon.premiumBookingFee != null) {
      _premiumFeeController.text = salon.premiumBookingFee!.toStringAsFixed(2);
    }
    _openingTime =
        parseSalonTime(salon.openingTime) ??
        const TimeOfDay(hour: 9, minute: 0);
    _closingTime =
        parseSalonTime(salon.closingTime) ??
        const TimeOfDay(hour: 21, minute: 0);
    _location = SalonLocationSelection.fromSalonFields(
      address: salon.address,
      street: salon.address,
      formattedAddress: salon.formattedAddress,
      locality: salon.locality,
      city: salon.city,
      state: salon.state,
      postalCode: salon.postalCode,
      latitude: salon.latitude,
      longitude: salon.longitude,
      isConfirmed: true,
    );
    _existingImageUrls = List<String>.from(salon.allDisplayImages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFocusTarget());
  }

  void _applyFocusTarget() {
    if (_didApplyFocus || !mounted) return;
    final focus = _normalizedFocusField;
    if (focus == null) return;

    final GlobalKey? sectionKey = switch (focus) {
      'description' || 'phone' => _basicInfoKey,
      'hours' => _hoursKey,
      'cover_image' || 'gallery_images' => _imagesKey,
      _ => null,
    };
    if (sectionKey?.currentContext != null) {
      Scrollable.ensureVisible(
        sectionKey!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }

    final FocusNode? fieldFocus = switch (focus) {
      'description' => _descriptionFocus,
      'phone' => _phoneFocus,
      _ => null,
    };
    if (fieldFocus != null) {
      fieldFocus.requestFocus();
    }

    _didApplyFocus = true;
  }

  Future<Map<String, dynamic>> _imagePayload() async {
    final uploaded = _newImages.isEmpty
        ? <String>[]
        : await ref
              .read(ownerOnboardingActionsProvider)
              .uploadSalonImages(_newImages);

    final allUrls = [..._existingImageUrls, ...uploaded];
    if (allUrls.isEmpty) return {};

    return {'cover_image': allUrls.first, 'gallery_images': allUrls};
  }

  Future<void> _savePremiumFee() async {
    final raw = _premiumFeeController.text.trim();
    double? fee;
    if (raw.isNotEmpty) {
      fee = double.tryParse(raw);
      if (fee == null || fee <= 0 || fee > 10000) {
        setState(() => _premiumError = 'Enter a fee between 1 and 10000');
        return;
      }
    }

    setState(() {
      _savingPremiumFee = true;
      _premiumError = null;
    });

    try {
      await ref
          .read(ownerServiceProvider)
          .updatePremiumBookingFee(salonId: widget.salonId, fee: fee);
      ref.invalidate(ownerSalonsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fee == null
                ? 'Urgent fee reset to platform default'
                : 'Urgent booking fee updated',
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _premiumError = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _savingPremiumFee = false);
    }
  }

  Future<void> _resetPremiumFee() async {
    _premiumFeeController.clear();
    await _savePremiumFee();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _error = 'Please fix the highlighted fields');
      return;
    }
    final phone = normalizePhoneDigits(_phoneController.text);
    final location = _location;
    if (_salonNameController.text.trim().isEmpty ||
        _openingTime == null ||
        _closingTime == null) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }
    if (!isValidPhoneDigits(phone)) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }
    if (!isClosingAfterOpening(_openingTime!, _closingTime!)) {
      setState(() => _error = 'Closing time must be after opening time');
      return;
    }
    if (location?.isConfirmed != true || location?.isComplete != true) {
      setState(() => _error = 'Please set and confirm salon location');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(ownerOnboardingActionsProvider)
          .submitUpdateRequest(
            salonId: widget.salonId,
            body: {
              'salon_name': _salonNameController.text.trim(),
              'salon_type': _salonType.apiValue,
              'description': _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              ...location!.toApiPayload(),
              'phone': phone,
              'opening_time': formatSalonTimeForApi(_openingTime!),
              'closing_time': formatSalonTimeForApi(_closingTime!),
              ...await _imagePayload(),
            },
          );

      if (!mounted) return;
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon details saved')),
      );
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonsAsync = ref.watch(ownerSalonsProvider);
    final platformPremiumAsync = ref.watch(ownerPremiumConfigProvider);

    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumAppBar(
              title: 'Edit salon',
              subtitle: 'Update your salon details anytime',
              showMenu: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _loading ? null : () => context.pop(),
              ),
            ),
            Expanded(
              child: salonsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load salon',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userFacingErrorMessage(e),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.appColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (salons) {
                  SalonModel? salon;
                  for (final item in salons) {
                    if (item.id == widget.salonId) {
                      salon = item;
                      break;
                    }
                  }

                  if (salon == null) {
                    return Center(
                      child: GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 40,
                              color: context.appColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Salon not found',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  _initializeFromSalon(salon);

                  return Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        AppDecorations.scrollBottomPadding(context) + 80,
                      ),
                      child: AnimatedEntrance(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionHeader(
                              title: 'Salon details',
                              subtitle:
                                  'Changes go live immediately after you save.',
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              key: _basicInfoKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Basic info',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumTextField(
                                    controller: _salonNameController,
                                    label: 'Salon name *',
                                    validator: validateRequiredName,
                                  ),
                                  const SizedBox(height: 16),
                                  SalonTypePicker(
                                    value: _salonType,
                                    onChanged: (type) =>
                                        setState(() => _salonType = type),
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumTextField(
                                    controller: _descriptionController,
                                    focusNode: _descriptionFocus,
                                    label: 'Description',
                                    maxLines: 3,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        kNotesMaxLength,
                                      ),
                                    ],
                                    validator: validateOptionalNotes,
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumTextField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    label: 'Salon phone *',
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: phoneDigitInputFormatters,
                                    validator: validatePhoneDigits,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  OwnerSalonLocationCard(
                                    value: _location,
                                    onChanged: (location) => setState(() {
                                      _location = location;
                                      _error = null;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              key: _hoursKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hours',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  SalonHoursPickerRow(
                                    openingTime: _openingTime,
                                    closingTime: _closingTime,
                                    onOpeningChanged: (time) =>
                                        setState(() => _openingTime = time),
                                    onClosingChanged: (time) =>
                                        setState(() => _closingTime = time),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Urgent booking',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  platformPremiumAsync.when(
                                    loading: () => Text(
                                      'Loading platform default…',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context.appColors.textMuted,
                                          ),
                                    ),
                                    error: (_, __) => Text(
                                      'Fee customers pay to book occupied slots urgently.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                context.appColors.textSecondary,
                                          ),
                                    ),
                                    data: (config) => Text(
                                      config.enabled
                                          ? 'Leave empty to use platform default '
                                                '(${formatMoney(config.fee)}). '
                                                'Changes apply immediately.'
                                          : 'Urgent bookings are disabled platform-wide.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                context.appColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumTextField(
                                    controller: _premiumFeeController,
                                    label: 'Urgent booking fee (₹)',
                                    keyboardType: TextInputType.number,
                                    enabled: !_savingPremiumFee,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _savingPremiumFee
                                              ? null
                                              : _resetPremiumFee,
                                          child: const Text('Use default'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: _savingPremiumFee
                                              ? null
                                              : _savePremiumFee,
                                          child: _savingPremiumFee
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text('Save fee'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_premiumError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _premiumError!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              key: _imagesKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Images',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  SalonImageEditor(
                                    existingUrls: _existingImageUrls,
                                    newImages: _newImages,
                                    onExistingUrlsChanged: (urls) => setState(
                                      () => _existingImageUrls = urls,
                                    ),
                                    onNewImagesChanged: (images) =>
                                        setState(() => _newImages = images),
                                  ),
                                ],
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              GlassCard(
                                shadowColor: AppColors.error,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ScreenActionBar(
        label: 'Save changes',
        loading: _loading,
        onPressed: _loading ? null : _submit,
      ),
    );
  }
}
