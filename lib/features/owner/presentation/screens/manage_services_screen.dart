import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
import 'package:saloon_booking/shared/widgets/service_tile.dart';

class ManageServicesScreen extends ConsumerStatefulWidget {
  const ManageServicesScreen({super.key, required this.salonId});

  final String salonId;

  @override
  ConsumerState<ManageServicesScreen> createState() =>
      _ManageServicesScreenState();
}

class _ManageServicesScreenState extends ConsumerState<ManageServicesScreen> {
  Future<void> _showServiceDialog({ServiceModel? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _ServiceFormSheet(salonId: widget.salonId, existing: existing),
    );

    if (result == true && mounted) {
      ref.invalidate(ownerServicesProvider(widget.salonId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(ownerServicesProvider(widget.salonId));

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Manage services',
        showMenu: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add service',
            onPressed: _showServiceDialog,
          ),
        ],
      ),
      bottomNavigationBar: ScreenActionBar(
        label: 'Add service',
        icon: Icons.add_rounded,
        onPressed: _showServiceDialog,
      ),
      body: GradientBackground(
        child: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(ownerServicesProvider(widget.salonId)),
        child: AsyncValueWidget(
          value: services,
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateScrollable(
                child: EmptyState(
                  icon: Icons.spa_outlined,
                  title: 'No services yet',
                  subtitle:
                      'Tap Add service below to create your first offering.',
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              children: [
                SectionHeader(
                  title:
                      '${items.length} service${items.length == 1 ? '' : 's'}',
                  subtitle: 'Tap a service to edit',
                ),
                const SizedBox(height: 12),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return AnimatedEntrance(
                    index: index,
                    child: ServiceTile(
                      service: service,
                      showStatus: true,
                      onTap: () => _showServiceDialog(existing: service),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

class _ServiceFormSheet extends ConsumerStatefulWidget {
  const _ServiceFormSheet({required this.salonId, this.existing});

  final String salonId;
  final ServiceModel? existing;

  @override
  ConsumerState<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedServiceOption;
  bool _saving = false;
  late bool _isActive;
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

  List<String> get _catalogNames => serviceNamesForSalonType(_salonType);

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
    _priceController.text = existing?.price.toString() ?? '';
    _discountPriceController.text = existing?.discountPrice?.toString() ?? '';
    _durationController.text = existing?.durationMinutes?.toString() ?? '';
    _descriptionController.text = existing?.description ?? '';
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _serviceNameFields(BuildContext context) {
    final catalog = _catalogNames;
    final options = [
      if (catalog.contains(_selectedServiceOption) ||
          _selectedServiceOption == kCustomSalonServiceName)
        ...catalog
      else
        ...[_selectedServiceOption, ...catalog],
      kCustomSalonServiceName,
    ];
    final dropdownValue = options.contains(_selectedServiceOption)
        ? _selectedServiceOption
        : kCustomSalonServiceName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          isExpanded: true,
          decoration: AppDecorations.inputDecoration(
            context,
            label: 'Service *',
            hint: 'Select a service',
            prefixIcon: Icon(
              Icons.spa_outlined,
              color: context.appColors.textMuted,
            ),
          ),
          items: options
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _saving
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedServiceOption = value;
                    if (value != kCustomSalonServiceName) {
                      _customNameController.clear();
                    }
                    if (_error != null) _error = null;
                  });
                },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Select a service';
            }
            return null;
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
              if (_error != null) _setError(null);
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isWide = MediaQuery.sizeOf(context).width >= 400;

    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: _isEditing ? 'Edit service' : 'Add service',
                  subtitle: _isEditing
                      ? 'Update service details for your salon menu'
                      : 'Add a new offering to your salon menu',
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Service details'),
                      const SizedBox(height: 16),
                      _serviceNameFields(context),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                      ),
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
                          LengthLimitingTextInputFormatter(kNotesMaxLength),
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
                GlassCard(
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    subtitle: Text(
                      'Inactive services are hidden from customers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                    value: _isActive,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
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
                  onPressed: _saving ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
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
      label: 'Discount price',
      hint: 'Optional',
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
