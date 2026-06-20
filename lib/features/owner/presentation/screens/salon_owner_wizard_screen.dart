import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/models/place_suggestion.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/salon_hours_picker_row.dart';
import 'package:saloon_booking/shared/widgets/salon_image_picker.dart';
import 'package:saloon_booking/shared/widgets/salon_address_autocomplete_field.dart';
import 'package:saloon_booking/shared/widgets/salon_location_picker.dart';
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
  int _step = 0;
  bool _loading = false;
  String? _error;

  final _businessController = TextEditingController();
  final _gstController = TextEditingController();
  final _salonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  TimeOfDay? _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _closingTime = const TimeOfDay(hour: 21, minute: 0);
  double? _latitude;
  double? _longitude;
  String? _locationLabel;
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
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
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

  void _clearLocationOnManualEdit() {
    if (_latitude == null && _longitude == null) return;
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationLabel = null;
    });
  }

  void _onPlaceSelected(PlaceSuggestion place) {
    setState(() {
      _addressController.text = place.address;
      _cityController.text = place.city;
      _stateController.text = place.state;
      _latitude = place.latitude;
      _longitude = place.longitude;
      _locationLabel = place.label;
      _error = null;
    });
  }

  bool _validateStep(int step) {
    if (step == 0 && _businessController.text.trim().isEmpty) {
      setState(() => _error = 'Business name is required');
      return false;
    }
    if (step == 1) {
      final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (_salonNameController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _stateController.text.trim().isEmpty ||
          phone.length < 10 ||
          _openingTime == null ||
          _closingTime == null) {
        setState(() => _error = 'Please fill all required salon fields');
        return false;
      }
      if (!isClosingAfterOpening(_openingTime!, _closingTime!)) {
        setState(() => _error = 'Closing time must be after opening time');
        return false;
      }
      if (_latitude == null || _longitude == null) {
        setState(() => _error = 'Please set salon location');
        return false;
      }
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;
    if (_step < 2) {
      _goToStep(_step + 1);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider).value;
      if (auth?.salonOwner == null) {
        await ref.read(ownerOnboardingActionsProvider).registerOwner(
              businessName: _businessController.text.trim(),
              gstNumber: _gstController.text.trim().isEmpty
                  ? null
                  : _gstController.text.trim(),
            );
        await ref.read(authProvider.notifier).refreshProfile();
      }

      await ref.read(ownerOnboardingActionsProvider).submitApplication({
        'salon_name': _salonNameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'phone': _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
        'opening_time': formatSalonTimeForApi(_openingTime!),
        'closing_time': formatSalonTimeForApi(_closingTime!),
        'latitude': _latitude,
        'longitude': _longitude,
        ...await _imagePayload(),
      });

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
    } on DioException catch (e) {
      setState(() => _error = e.apiException.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _imagePayload() async {
    if (_selectedImages.isEmpty) return {};

    final urls = await ref
        .read(ownerOnboardingActionsProvider)
        .uploadSalonImages(_selectedImages);

    return {
      'cover_image': urls.first,
      'gallery_images': urls,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Partner with us',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: StepProgressHeader(
                  currentStep: _step,
                  totalSteps: 3,
                  titles: _stepTitles,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _buildStep0(),
                    _buildStep1(),
                    _buildStep2(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
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
                            label: _step == 2 ? 'Submit application' : 'Continue',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedEntrance(
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your business',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This registers you as a salon owner. Your salon listing will be reviewed separately.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: _businessController,
                label: 'Business name *',
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _gstController,
                label: 'GST number (optional)',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedEntrance(
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salon details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This information is sent to admin for approval.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: _salonNameController,
                label: 'Salon name *',
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SalonAddressAutocompleteField(
                onPlaceSelected: _onPlaceSelected,
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _addressController,
                label: 'Address *',
                onChanged: (_) => _clearLocationOnManualEdit(),
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _cityController,
                label: 'City *',
                onChanged: (_) => _clearLocationOnManualEdit(),
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _stateController,
                label: 'State *',
                onChanged: (_) => _clearLocationOnManualEdit(),
              ),
              const SizedBox(height: 16),
              SalonLocationPicker(
                addressController: _addressController,
                cityController: _cityController,
                stateController: _stateController,
                latitude: _latitude,
                longitude: _longitude,
                locationLabel: _locationLabel,
                onLocationSet: (lat, lng, label) => setState(() {
                  _latitude = lat;
                  _longitude = lng;
                  _locationLabel = label;
                  _error = null;
                }),
                onClear: () => setState(() {
                  _latitude = null;
                  _longitude = null;
                  _locationLabel = null;
                }),
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _phoneController,
                label: 'Salon phone *',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              SalonHoursPickerRow(
                openingTime: _openingTime,
                closingTime: _closingTime,
                onOpeningChanged: (time) => setState(() => _openingTime = time),
                onClosingChanged: (time) => setState(() => _closingTime = time),
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
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedEntrance(
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review your application',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _reviewRow('Business', _businessController.text.trim()),
              if (_gstController.text.trim().isNotEmpty)
                _reviewRow('GST', _gstController.text.trim()),
              const Divider(height: 24),
              _reviewRow('Salon', _salonNameController.text.trim()),
              _reviewRow('Address', _addressController.text.trim()),
              _reviewRow(
                'Location',
                '${_cityController.text.trim()}, ${_stateController.text.trim()}',
              ),
              if (_locationLabel != null)
                _reviewRow('Salon pin', _locationLabel!)
              else if (_latitude != null && _longitude != null)
                _reviewRow(
                  'Salon pin',
                  '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                ),
              _reviewRow('Phone', _phoneController.text.trim()),
              if (_openingTime != null && _closingTime != null)
                _reviewRow(
                  'Hours',
                  '${formatTimeOfDayLabel(_openingTime!)} – ${formatTimeOfDayLabel(_closingTime!)}',
                ),
              if (_descriptionController.text.trim().isNotEmpty)
                _reviewRow('Description', _descriptionController.text.trim()),
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
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
