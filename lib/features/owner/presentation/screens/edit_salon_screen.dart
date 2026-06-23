import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/salon_geocoding.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
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
import 'package:saloon_booking/shared/widgets/section_header.dart';

class EditSalonScreen extends ConsumerStatefulWidget {
  const EditSalonScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<EditSalonScreen> createState() => _EditSalonScreenState();
}

class _EditSalonScreenState extends ConsumerState<EditSalonScreen> {
  final _salonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  double? _latitude;
  double? _longitude;
  String? _locationLabel;

  List<String> _existingImageUrls = [];
  List<XFile> _newImages = [];
  bool _loading = false;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _salonNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeFromSalon(SalonModel salon) {
    if (_initialized) return;
    _initialized = true;
    _salonNameController.text = salon.salonName;
    _descriptionController.text = salon.description ?? '';
    _addressController.text = salon.address ?? '';
    _cityController.text = salon.city ?? '';
    _stateController.text = salon.state ?? '';
    _phoneController.text = salon.phone ?? '';
    _openingTime = parseSalonTime(salon.openingTime) ??
        const TimeOfDay(hour: 9, minute: 0);
    _closingTime = parseSalonTime(salon.closingTime) ??
        const TimeOfDay(hour: 21, minute: 0);
    _latitude = salon.latitude;
    _longitude = salon.longitude;
    if (_latitude != null && _longitude != null) {
      resolveSalonLocationLabel(_latitude!, _longitude!).then((label) {
        if (mounted) setState(() => _locationLabel = label);
      });
    }
    _existingImageUrls = List<String>.from(salon.allDisplayImages);
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

  Future<Map<String, dynamic>> _imagePayload() async {
    final uploaded = _newImages.isEmpty
        ? <String>[]
        : await ref
            .read(ownerOnboardingActionsProvider)
            .uploadSalonImages(_newImages);

    final allUrls = [..._existingImageUrls, ...uploaded];
    if (allUrls.isEmpty) return {};

    return {
      'cover_image': allUrls.first,
      'gallery_images': allUrls,
    };
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (_salonNameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        phone.length < 10 ||
        _openingTime == null ||
        _closingTime == null) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }
    if (!isClosingAfterOpening(_openingTime!, _closingTime!)) {
      setState(() => _error = 'Closing time must be after opening time');
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'Please set salon location');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(ownerOnboardingActionsProvider).submitUpdateRequest(
            salonId: widget.salonId,
            body: {
              'salon_name': _salonNameController.text.trim(),
              'description': _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              'address': _addressController.text.trim(),
              'city': _cityController.text.trim(),
              'state': _stateController.text.trim(),
              'phone': phone,
              'opening_time': formatSalonTimeForApi(_openingTime!),
              'closing_time': formatSalonTimeForApi(_closingTime!),
              'latitude': _latitude,
              'longitude': _longitude,
              ...await _imagePayload(),
            },
          );

      if (!mounted) return;
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update request submitted — pending admin approval'),
        ),
      );
      context.pop();
    } on DioException catch (e) {
      setState(() => _error = e.apiException.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonsAsync = ref.watch(ownerSalonsProvider);

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
                      onPressed: _loading ? null : () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Edit salon',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: salonsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (salons) {
                    SalonModel? salon;
                    for (final item in salons) {
                      if (item.id == widget.salonId) {
                        salon = item;
                        break;
                      }
                    }

                    if (salon == null) {
                      return const Center(child: Text('Salon not found'));
                    }

                    _initializeFromSalon(salon);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedEntrance(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionHeader(
                              title: 'Request salon changes',
                              subtitle:
                                  'Updates are sent to admin for approval before going live.',
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Basic info',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
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
                                  PremiumTextField(
                                    controller: _phoneController,
                                    label: 'Salon phone *',
                                    keyboardType: TextInputType.phone,
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
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  SalonAddressAutocompleteField(
                                    onPlaceSelected: _onPlaceSelected,
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumTextField(
                                    controller: _addressController,
                                    label: 'Address *',
                                    onChanged: (_) =>
                                        _clearLocationOnManualEdit(),
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumTextField(
                                    controller: _cityController,
                                    label: 'City *',
                                    onChanged: (_) =>
                                        _clearLocationOnManualEdit(),
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumTextField(
                                    controller: _stateController,
                                    label: 'State *',
                                    onChanged: (_) =>
                                        _clearLocationOnManualEdit(),
                                  ),
                                  const SizedBox(height: 16),
                                  SalonLocationPicker(
                                    addressController: _addressController,
                                    cityController: _cityController,
                                    stateController: _stateController,
                                    latitude: _latitude,
                                    longitude: _longitude,
                                    locationLabel: _locationLabel,
                                    onLocationSet: (lat, lng, label) =>
                                        setState(() {
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hours',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
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
                                    'Images',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  SalonImageEditor(
                                    existingUrls: _existingImageUrls,
                                    newImages: _newImages,
                                    onExistingUrlsChanged: (urls) =>
                                        setState(() => _existingImageUrls = urls),
                                    onNewImagesChanged: (images) =>
                                        setState(() => _newImages = images),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                    PremiumButton(
                      label: 'Submit for approval',
                      variant: PremiumButtonVariant.accent,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
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
}
