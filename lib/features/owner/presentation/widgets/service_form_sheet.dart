import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/core/utils/service_identity_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/service_catalog_picker.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/service_artwork.dart';

const _kDurationPresets = [15, 30, 45, 60, 90, 120];

class ServiceFormSheet extends ConsumerStatefulWidget {
  const ServiceFormSheet({super.key, required this.salonId, this.existing});

  final String salonId;
  final ServiceModel? existing;

  @override
  ConsumerState<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedServiceOption;
  bool _saving = false;
  late bool _isActive;
  late SalonType _serviceFor;
  String? _error;

  bool get _isEditing => widget.existing != null;
  bool get _isCustomSelected =>
      _selectedServiceOption == kCustomSalonServiceName;

  SalonType get _salonType {
    final salons = ref.watch(ownerSalonsProvider).value ?? const [];
    for (final salon in salons) {
      if (salon.id == widget.salonId) return salon.salonType;
    }
    return SalonType.unisex;
  }

  bool get _canPickServiceFor => _salonType == SalonType.unisex;

  SalonType get _effectiveServiceFor {
    switch (_salonType) {
      case SalonType.men:
        return SalonType.men;
      case SalonType.women:
        return SalonType.women;
      case SalonType.unisex:
        return _serviceFor;
    }
  }

  List<String> get _catalogNames => serviceNamesForSalonType(_salonType);

  AudienceMode get _previewAudience {
    switch (_effectiveServiceFor) {
      case SalonType.men:
        return AudienceMode.men;
      case SalonType.women:
        return AudienceMode.women;
      case SalonType.unisex:
        return defaultAudienceForSalonType(_salonType);
    }
  }

  String? get _savingsHint {
    final price = double.tryParse(_priceController.text.trim());
    final discount = double.tryParse(_discountPriceController.text.trim());
    if (price == null || discount == null) return null;
    if (price <= 0 || discount <= 0 || discount >= price) return null;
    return 'Customers save ${formatMoney(price - discount)}';
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final matched = matchingSalonServiceName(existing?.serviceName);
    if (matched != null) {
      _selectedServiceOption = matched;
      _customNameController.clear();
    } else if (existing?.serviceName.trim().isNotEmpty == true) {
      _selectedServiceOption = kCustomSalonServiceName;
      _customNameController.text = existing!.serviceName.trim();
    } else {
      _selectedServiceOption = kSharedSalonServiceNames.first;
      _customNameController.clear();
    }
    _priceController.text = existing != null
        ? existing.price.toStringAsFixed(2)
        : '';
    _discountPriceController.text = existing?.discountPrice != null
        ? existing!.discountPrice!.toStringAsFixed(2)
        : '';
    _durationController.text = existing?.durationMinutes?.toString() ?? '';
    _descriptionController.text = existing?.description ?? '';
    _isActive = existing?.isActive ?? true;
    _serviceFor = existing?.serviceFor ?? SalonType.unisex;
    for (final controller in [
      _customNameController,
      _priceController,
      _discountPriceController,
      _durationController,
      _descriptionController,
    ]) {
      controller.addListener(_rebuildPreview);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(_clearErrorAndSyncAudience);
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _customNameController,
      _priceController,
      _discountPriceController,
      _durationController,
      _descriptionController,
    ]) {
      controller.removeListener(_rebuildPreview);
    }
    _customNameController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _rebuildPreview() {
    if (mounted) setState(() {});
  }

  void _setSaving(bool value) {
    setState(() => _saving = value);
  }

  void _setError(String? message) {
    setState(() => _error = message);
  }

  String _resolvedServiceName() {
    if (_isCustomSelected) return _customNameController.text.trim();
    return _selectedServiceOption;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final priceError = validatePrice(_priceController.text);
    if (priceError != null) {
      _setError(priceError);
      return;
    }
    final price = double.parse(_priceController.text.trim());
    final discountError = validateDiscountPrice(
      _discountPriceController.text,
      price: price,
    );
    if (discountError != null) {
      _setError(discountError);
      return;
    }
    final durationError = validateDurationMinutes(_durationController.text);
    if (durationError != null) {
      _setError(durationError);
      return;
    }

    final serviceName = _resolvedServiceName();
    if (serviceName.isEmpty) {
      _setError('Service name is required');
      return;
    }

    final serviceFor = _effectiveServiceFor;
    final conflict = serviceIdentityConflictMessage(
      serviceName: serviceName,
      requested: serviceFor,
      existingServiceFors: _siblingServiceFors(serviceName),
    );
    if (conflict != null) {
      _setError(conflict);
      return;
    }

    final discountText = _discountPriceController.text.trim();
    final discountPrice = discountText.isEmpty
        ? null
        : double.parse(discountText);

    _setError(null);
    _setSaving(true);
    try {
      final body = {
        'service_name': serviceName,
        'price': price,
        'discount_price': discountPrice,
        'duration_minutes': int.parse(_durationController.text.trim()),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'status': _isActive ? 'ACTIVE' : 'INACTIVE',
        'service_for': serviceFor.apiValue,
      };

      final api = ref.read(ownerServiceProvider);
      if (widget.existing == null) {
        await api.createService(salonId: widget.salonId, body: body);
      } else {
        await api.updateService(
          salonId: widget.salonId,
          serviceId: widget.existing!.id,
          body: body,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _setError(_errorMessage(e));
    } finally {
      if (mounted) _setSaving(false);
    }
  }

  String _errorMessage(Object error) => userFacingErrorMessage(error);

  String _normalizedServiceName(String value) =>
      normalizedServiceIdentityName(value);

  List<SalonType> _siblingServiceFors([String? serviceName]) {
    final name = _normalizedServiceName(serviceName ?? _resolvedServiceName());
    if (name.isEmpty) return const [];
    final services =
        ref.read(ownerServicesProvider(widget.salonId)).value ?? const [];
    final editingId = widget.existing?.id;
    return [
      for (final service in services)
        if (editingId == null || service.id != editingId)
          if (_normalizedServiceName(service.serviceName) == name)
            service.serviceFor,
    ];
  }

  bool _isServiceForEnabled(SalonType value) {
    return isServiceForAllowedWithSiblings(
      requested: value,
      existingServiceFors: _siblingServiceFors(),
    );
  }

  String? _serviceForHelperText() {
    if (!_canPickServiceFor) return null;
    final conflict = serviceIdentityConflictMessage(
      serviceName: _resolvedServiceName(),
      requested: _effectiveServiceFor,
      existingServiceFors: _siblingServiceFors(),
    );
    if (conflict != null) return conflict;
    return 'A service can be for Everyone, or separate Men and Women — not both.';
  }

  void _clearErrorAndSyncAudience() {
    final allowed = [
      SalonType.men,
      SalonType.women,
      SalonType.unisex,
    ].where(_isServiceForEnabled);
    if (allowed.isNotEmpty && !_isServiceForEnabled(_serviceFor)) {
      _serviceFor = allowed.first;
    }
    if (_error != null) _error = null;
  }

  Future<void> _pickService() async {
    if (_saving) return;
    final selected = await showServiceCatalogPicker(
      context: context,
      catalogNames: _catalogNames,
      selectedName: _selectedServiceOption,
      audience: _previewAudience,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedServiceOption = selected;
      if (selected != kCustomSalonServiceName) {
        _customNameController.clear();
      }
      _clearErrorAndSyncAudience();
    });
  }

  void _selectDuration(int minutes) {
    if (_saving) return;
    HapticFeedback.selectionClick();
    _durationController.text = '$minutes';
    if (_error != null) _setError(null);
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final handleAllowance = 28.0;
    final available = media.size.height - keyboard - handleAllowance;
    final sheetHeight = math.min(media.size.height * 0.88, available);
    final isWide = media.size.width >= 400;
    final bottomSafe = keyboard > 0 ? 12.0 : 16.0 + media.padding.bottom;

    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: sheetHeight,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        title: _isEditing ? 'Edit service' : 'Add service',
                        subtitle: _isEditing
                            ? 'Update service details for your salon menu'
                            : 'Add a new offering to your salon menu',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(context, 'Service details'),
                              const SizedBox(height: 16),
                              _serviceNameFields(context),
                              if (_canPickServiceFor) ...[
                                const SizedBox(height: 18),
                                _audiencePicker(context),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(context, 'Pricing'),
                              const SizedBox(height: 16),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _priceField()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _discountField()),
                                  ],
                                )
                              else ...[
                                _priceField(),
                                const SizedBox(height: 16),
                                _discountField(),
                              ],
                              if (_savingsHint != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _savingsHint!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(context, 'Duration'),
                              const SizedBox(height: 8),
                              Text(
                                'How long this service usually takes',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _durationChips(context),
                              const SizedBox(height: 16),
                              PremiumTextField(
                                controller: _durationController,
                                label: 'Duration (minutes) *',
                                hint: '30',
                                enabled: !_saving,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: validateDurationMinutes,
                                prefixIcon: Icon(
                                  Icons.schedule_outlined,
                                  color: context.appColors.textMuted,
                                ),
                                onChanged: (_) {
                                  if (_error != null) _setError(null);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(context, 'Description'),
                              const SizedBox(height: 16),
                              PremiumTextField(
                                controller: _descriptionController,
                                label: 'Description (optional)',
                                hint: 'What is included in this service?',
                                enabled: !_saving,
                                maxLines: 3,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(
                                    kNotesMaxLength,
                                  ),
                                ],
                                validator: validateOptionalNotes,
                                onChanged: (_) {
                                  if (_error != null) _setError(null);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _activeToggle(context),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomSafe),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        _ErrorBanner(message: _error!),
                        const SizedBox(height: 12),
                      ],
                      PremiumButton(
                        label: _isEditing ? 'Save changes' : 'Add service',
                        loading: _saving,
                        loadingLabel: 'Saving',
                        onPressed: _saving ? null : _save,
                      ),
                      const SizedBox(height: 8),
                      PremiumButton(
                        label: 'Cancel',
                        variant: PremiumButtonVariant.ghost,
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceNameFields(BuildContext context) {
    final colors = context.appColors;
    final displayName = _isCustomSelected
        ? kCustomSalonServiceName
        : _selectedServiceOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormField<String>(
          initialValue: _selectedServiceOption,
          validator: (value) {
            if (_selectedServiceOption.trim().isEmpty) {
              return 'Select a service';
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service *',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppColors.radiusControl),
                  child: InkWell(
                    onTap: _saving ? null : _pickService,
                    borderRadius: BorderRadius.circular(
                      AppColors.radiusControl,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusControl,
                        ),
                        border: Border.all(
                          color: state.hasError
                              ? AppColors.error
                              : colors.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          ServiceArtwork(
                            serviceName: _isCustomSelected
                                ? ''
                                : _selectedServiceOption,
                            audience: _previewAudience,
                            size: 44,
                            padding: const EdgeInsets.all(6),
                            borderRadius: 12,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    state.errorText!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ],
              ],
            );
          },
        ),
        if (_isCustomSelected) ...[
          const SizedBox(height: 16),
          PremiumTextField(
            controller: _customNameController,
            label: 'Custom service name *',
            hint: 'Enter your service name',
            enabled: !_saving,
            validator: validateRequiredName,
            prefixIcon: Icon(
              Icons.edit_outlined,
              color: context.appColors.textMuted,
            ),
            onChanged: (_) {
              setState(_clearErrorAndSyncAudience);
            },
          ),
        ],
      ],
    );
  }

  Widget _audiencePicker(BuildContext context) {
    final colors = context.appColors;
    final helper = _serviceForHelperText();
    final hasConflict =
        serviceIdentityConflictMessage(
          serviceName: _resolvedServiceName(),
          requested: _effectiveServiceFor,
          existingServiceFors: _siblingServiceFors(),
        ) !=
        null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This service is for *',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (index, type) in [
              SalonType.men,
              SalonType.women,
              SalonType.unisex,
            ].indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _AudienceChip(
                  label: type.serviceAudienceLabel,
                  selected: _serviceFor == type,
                  enabled: !_saving && _isServiceForEnabled(type),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _serviceFor = type;
                      if (_error != null) _error = null;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              helper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasConflict ? AppColors.error : colors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _durationChips(BuildContext context) {
    final selectedMinutes = int.tryParse(_durationController.text.trim());
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final minutes in _kDurationPresets)
          _DurationChip(
            label: '$minutes min',
            selected: selectedMinutes == minutes,
            enabled: !_saving,
            onTap: () => _selectDuration(minutes),
          ),
      ],
    );
  }

  Widget _activeToggle(BuildContext context) {
    final colors = context.appColors;
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isActive
                  ? AppColors.success.withValues(alpha: 0.12)
                  : colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isActive
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_outlined,
              color: _isActive ? AppColors.success : colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Inactive services are hidden from customers',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            onChanged: _saving
                ? null
                : (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }

  Widget _priceField() {
    return PremiumTextField(
      controller: _priceController,
      label: 'Price *',
      hint: '499',
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: validatePrice,
      prefixIcon: Icon(
        Icons.currency_rupee,
        color: context.appColors.textMuted,
        size: 20,
      ),
      onChanged: (_) {
        if (_error != null) _setError(null);
      },
    );
  }

  Widget _discountField() {
    return PremiumTextField(
      controller: _discountPriceController,
      label: 'Final price after discount',
      hint: 'Optional — e.g. 450.00',
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (v) => validateDiscountPrice(
        v,
        price: double.tryParse(_priceController.text.trim()),
      ),
      prefixIcon: Icon(
        Icons.local_offer_outlined,
        color: context.appColors.textMuted,
        size: 20,
      ),
      onChanged: (_) {
        if (_error != null) _setError(null);
      },
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? colors.accentSoft : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.accent : colors.glassBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected ? colors.accentSoft : colors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? colors.accent : colors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
