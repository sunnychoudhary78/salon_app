import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/core/utils/phone_validation.dart';
import 'package:saloon_booking/core/utils/salon_geocoding.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/models/salon_location_selection.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/salon_type_picker.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/owner_salon_location_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/salon_hours_picker_row.dart';
import 'package:saloon_booking/shared/widgets/salon_image_picker.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/step_progress_header.dart';

class SalonOwnerWizardScreen extends ConsumerStatefulWidget {
  const SalonOwnerWizardScreen({super.key});

  @override
  ConsumerState<SalonOwnerWizardScreen> createState() =>
      _SalonOwnerWizardScreenState();
}

class _SalonOwnerWizardScreenState
    extends ConsumerState<SalonOwnerWizardScreen> {
  final _pageController = PageController();
  final _step0FormKey = GlobalKey<FormState>();
  final _step1FormKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;
  String? _error;

  final _businessController = TextEditingController();
  final _gstController = TextEditingController();
  final _salonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _premiumFeeController = TextEditingController();
  TimeOfDay? _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _closingTime = const TimeOfDay(hour: 21, minute: 0);
  SalonLocationSelection? _location;
  SalonType? _salonType;
  List<XFile> _selectedImages = [];

  static const _stepTitles = [
    'Business details',
    'Salon information',
    'Review & submit',
  ];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider).value;
    if (auth?.salonOwner != null) {
      _businessController.text = auth!.salonOwner!.businessName;
      _gstController.text = auth.salonOwner!.gstNumber ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step == 0) _goToStep(1);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessController.dispose();
    _gstController.dispose();
    _salonNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _premiumFeeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (!(_step0FormKey.currentState?.validate() ?? false)) {
        setState(() => _error = 'Please fix the highlighted fields');
        return false;
      }
      if (_businessController.text.trim().isEmpty) {
        setState(() => _error = 'Business name is required');
        return false;
      }
    }
    if (step == 1) {
      if (!(_step1FormKey.currentState?.validate() ?? false)) {
        setState(() => _error = 'Please fix the highlighted fields');
        return false;
      }
      final phone = normalizePhoneDigits(_phoneController.text);
      if (_salonNameController.text.trim().isEmpty ||
          _salonType == null ||
          _openingTime == null ||
          _closingTime == null) {
        setState(() => _error = 'Please fill all required salon fields');
        return false;
      }
      if (!isValidPhoneDigits(phone)) {
        setState(() => _error = 'Enter a valid 10-digit phone number');
        return false;
      }
      if (!isClosingAfterOpening(_openingTime!, _closingTime!)) {
        setState(() => _error = 'Closing time must be after opening time');
        return false;
      }
      if (_location?.isConfirmed != true || _location?.isComplete != true) {
        setState(() => _error = 'Please set and confirm salon location');
        return false;
      }
      final premiumRaw = _premiumFeeController.text.trim();
      if (premiumRaw.isNotEmpty) {
        final fee = double.tryParse(premiumRaw);
        if (fee == null || fee < 1 || fee > 10000) {
          setState(() => _error = 'Enter an urgent fee between 1 and 10000');
          return false;
        }
      }
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;
    if (_step == 0) {
      final auth = ref.read(authProvider).value;
      if (auth?.salonOwner == null) {
        setState(() {
          _loading = true;
          _error = null;
        });
        try {
          await ref
              .read(ownerOnboardingActionsProvider)
              .registerOwner(
                businessName: _businessController.text.trim(),
                gstNumber: _gstController.text.trim().isEmpty
                    ? null
                    : _gstController.text.trim(),
              );
          await ref.read(authProvider.notifier).refreshProfile();
        } catch (e) {
          if (mounted) setState(() => _error = userFacingErrorMessage(e));
          return;
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      }
    }
    if (_step < 2) {
      _goToStep(_step + 1);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final location = _location;
    if (location == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider).value;
      if (auth?.salonOwner == null) {
        await ref
            .read(ownerOnboardingActionsProvider)
            .registerOwner(
              businessName: _businessController.text.trim(),
              gstNumber: _gstController.text.trim().isEmpty
                  ? null
                  : _gstController.text.trim(),
            );
        await ref.read(authProvider.notifier).refreshProfile();
      }

      final body = <String, dynamic>{
        'salon_name': _salonNameController.text.trim(),
        'salon_type': _salonType!.apiValue,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        ...location.toApiPayload(),
        'phone': normalizePhoneDigits(_phoneController.text),
        'opening_time': formatSalonTimeForApi(_openingTime!),
        'closing_time': formatSalonTimeForApi(_closingTime!),
        ...await _imagePayload(),
      };
      final premiumRaw = _premiumFeeController.text.trim();
      if (premiumRaw.isNotEmpty) {
        final fee = double.tryParse(premiumRaw);
        if (fee == null || fee < 1 || fee > 10000) {
          setState(() {
            _loading = false;
            _error = 'Enter an urgent fee between 1 and 10000';
          });
          return;
        }
        body['premium_booking_fee'] = fee;
      }

      await ref.read(ownerOnboardingActionsProvider).submitApplication(body);

      if (!mounted) return;
      await ref.read(authProvider.notifier).refreshProfile();
      await ref.read(hasApprovedSalonsProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted — pending admin approval'),
        ),
      );
      context.go(RoutePaths.ownerDashboard);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _imagePayload() async {
    if (_selectedImages.isEmpty) return {};

    final urls = await ref
        .read(ownerOnboardingActionsProvider)
        .uploadSalonImages(_selectedImages);

    return {'cover_image': urls.first, 'gallery_images': urls};
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Partner with us',
        subtitle: 'Become a CATCHY salon partner',
        showMenu: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: AnimatedEntrance(
                child: GlassCard(
                  elevated: false,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: StepProgressHeader(
                    currentStep: _step,
                    totalSteps: 3,
                    titles: _stepTitles,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [_buildStep0(), _buildStep1(), _buildStep2()],
              ),
            ),
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.navBarBackground,
                    border: Border(
                      top: BorderSide(
                        color: colors.glassBorder.withValues(alpha: 0.6),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              if (_step > 0)
                                Expanded(
                                  child: PremiumButton(
                                    label: 'Back',
                                    variant: PremiumButtonVariant.ghost,
                                    onPressed: _loading
                                        ? null
                                        : () => _goToStep(_step - 1),
                                  ),
                                ),
                              if (_step > 0) const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: PremiumButton(
                                  label: _step == 2
                                      ? 'Submit application'
                                      : 'Continue',
                                  variant: PremiumButtonVariant.accent,
                                  loading: _loading,
                                  onPressed: _loading ? null : _next,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedEntrance(
        child: Form(
          key: _step0FormKey,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Business details',
                  subtitle: 'Register as a salon owner',
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _businessController,
                  label: 'Business name *',
                  validator: validateRequiredName,
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _gstController,
                  label: 'GST number (optional)',
                  validator: validateGstOptional,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedEntrance(
        child: Form(
          key: _step1FormKey,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Salon information',
                  subtitle: 'Details sent to admin for approval',
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
                  onChanged: (type) => setState(() {
                    _salonType = type;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 3,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(kNotesMaxLength),
                  ],
                  validator: validateOptionalNotes,
                ),
                const SizedBox(height: 16),
                OwnerSalonLocationCard(
                  value: _location,
                  onChanged: (location) => setState(() {
                    _location = location;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _phoneController,
                  label: 'Salon phone *',
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneDigitInputFormatters,
                  validator: validatePhoneDigits,
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
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _premiumFeeController,
                  label: 'Urgent booking fee (₹, optional)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional. Leave empty to use the platform default after approval.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                SalonImagePicker(
                  images: _selectedImages,
                  onImagesChanged: (images) =>
                      setState(() => _selectedImages = images),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final location = _location;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedEntrance(
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Review & submit',
                subtitle: 'Confirm your application details',
              ),
              const SizedBox(height: 16),
              GlassCard(
                elevated: false,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _reviewRow('Business', _businessController.text.trim()),
                    if (_gstController.text.trim().isNotEmpty)
                      _reviewRow('GST', _gstController.text.trim()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                elevated: false,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _reviewRow('Salon', _salonNameController.text.trim()),
                    if (_salonType != null)
                      _reviewRow(
                        'Salon type',
                        switch (_salonType!) {
                          SalonType.men => 'Men',
                          SalonType.women => 'Women',
                          SalonType.unisex => 'Unisex',
                        },
                      ),
                    if (location != null) ...[
                      _reviewRow('Location', location.displayLabel),
                      if (location.cityStateLine.isNotEmpty)
                        _reviewRow('Area', location.cityStateLine),
                      _reviewRow(
                        'Salon pin',
                        formatCoordinatesLabel(
                          location.latitude,
                          location.longitude,
                        ),
                      ),
                    ],
                    _reviewRow('Phone', _phoneController.text.trim()),
                    if (_openingTime != null && _closingTime != null)
                      _reviewRow(
                        'Hours',
                        '${formatTimeOfDayLabel(_openingTime!)} – ${formatTimeOfDayLabel(_closingTime!)}',
                      ),
                    if (_premiumFeeController.text.trim().isNotEmpty)
                      _reviewRow(
                        'Urgent fee',
                        '₹${_premiumFeeController.text.trim()}',
                      ),
                    if (_descriptionController.text.trim().isNotEmpty)
                      _reviewRow(
                        'Description',
                        _descriptionController.text.trim(),
                      ),
                  ],
                ),
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 10),
                SalonImageReviewStrip(images: _selectedImages),
              ],
              const SizedBox(height: 16),
              Text(
                'After submission you can continue using the app as a customer until admin approves your salon.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.appColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
