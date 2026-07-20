import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/api_exception.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
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
    final categoriesAsync = ref.read(serviceCategoriesProvider);

    final categories = categoriesAsync.when<List<ServiceCategoryModel>?>(
      data: (items) => items,
      loading: () => null,
      error: (error, stackTrace) => null,
    );

    if (categories == null) {
      try {
        final loaded = await ref.refresh(serviceCategoriesProvider.future);
        if (!mounted) return;
        if (loaded.isEmpty) {
          _showMessage('No service categories available. Contact admin.');
          return;
        }
        await _openServiceDialog(categories: loaded, existing: existing);
      } catch (e) {
        if (!mounted) return;
        _showMessage('Failed to load categories: ${_errorMessage(e)}');
      }
      return;
    }

    if (categories.isEmpty) {
      _showMessage('No service categories available. Contact admin.');
      return;
    }

    await _openServiceDialog(categories: categories, existing: existing);
  }

  Future<void> _openServiceDialog({
    required List<ServiceCategoryModel> categories,
    ServiceModel? existing,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ServiceFormSheet(
        salonId: widget.salonId,
        categories: categories,
        existing: existing,
      ),
    );

    if (result == true && mounted) {
      ref.invalidate(ownerServicesProvider(widget.salonId));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) return error.apiException.message;
    return error.toString();
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
      body: RefreshIndicator(
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
            final grouped = <String, List<ServiceModel>>{};
            for (final service in items) {
              final key = service.category?.name ?? 'General';
              grouped.putIfAbsent(key, () => []).add(service);
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
                ...grouped.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final group = entry.value;
                  return AnimatedEntrance(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        shadowColor: AppColors.accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  group.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${group.value.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: context.appColors.textMuted,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...group.value.map(
                              (service) => ServiceTile(
                                service: service,
                                onTap: () =>
                                    _showServiceDialog(existing: service),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ServiceFormSheet extends ConsumerStatefulWidget {
  const _ServiceFormSheet({
    required this.salonId,
    required this.categories,
    this.existing,
  });

  final String salonId;
  final List<ServiceCategoryModel> categories;
  final ServiceModel? existing;

  @override
  ConsumerState<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<_ServiceFormSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.serviceName ?? '';
    _priceController.text = existing?.price.toString() ?? '';
    _discountPriceController.text = existing?.discountPrice?.toString() ?? '';
    _durationController.text = existing?.durationMinutes?.toString() ?? '30';
    _descriptionController.text = existing?.description ?? '';
    _selectedCategoryId = existing?.category?.id ?? widget.categories.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _save() async {
    if (_selectedCategoryId == null || _nameController.text.trim().isEmpty) {
      _setError('Name and category are required');
      return;
    }

    _setError(null);
    _setSaving(true);
    try {
      final price = double.tryParse(_priceController.text) ?? 0;
      final discountText = _discountPriceController.text.trim();
      final discountPrice = discountText.isEmpty
          ? null
          : double.tryParse(discountText);

      if (price <= 0) {
        _setError('Price must be greater than 0');
        return;
      }
      if (discountText.isNotEmpty && discountPrice == null) {
        _setError('Discount price must be a valid number');
        return;
      }
      if (discountPrice != null &&
          (discountPrice <= 0 || discountPrice >= price)) {
        _setError('Discount price must be lower than regular price');
        return;
      }

      final body = {
        'category_id': _selectedCategoryId,
        'service_name': _nameController.text.trim(),
        'price': price,
        'discount_price': discountPrice,
        'duration_minutes': int.tryParse(_durationController.text) ?? 30,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        'status': 'ACTIVE',
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

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) return error.apiException.message;
    return error.toString();
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _categoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      isExpanded: true,
      dropdownColor: context.appColors.surfaceElevated,
      style: TextStyle(color: context.appColors.textPrimary),
      decoration: AppDecorations.inputDecoration(context, label: 'Category *',
        prefixIcon: Icon(
          Icons.category_outlined,
          color: context.appColors.textMuted,
        ),
      ),
      items: widget.categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: _saving
          ? null
          : (value) => setState(() => _selectedCategoryId = value),
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
                    _categoryField(),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _nameController,
                      label: 'Service name *',
                      hint: 'e.g. Haircut, Beard trim',
                      enabled: !_saving,
                      prefixIcon: Icon(
                        Icons.spa_outlined,
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
                    _sectionTitle(context, 'Session'),
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      onChanged: (_) {
                        if (_error != null) _setError(null);
                      },
                    ),
                  ],
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
