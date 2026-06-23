import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/api_exception.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
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
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ServiceFormDialog(
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
                  subtitle: 'Tap Add service below to create your first offering.',
                ),
              );
            }
            final grouped = <String, List<ServiceModel>>{};
            for (final service in items) {
              final key = service.category?.name ?? 'General';
              grouped.putIfAbsent(key, () => []).add(service);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppDecorations.shellBottomInset,
              ),
              children: [
                SectionHeader(
                  title: '${items.length} service${items.length == 1 ? '' : 's'}',
                  subtitle: 'Tap a service to edit',
                ),
                const SizedBox(height: 12),
                ...grouped.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map(
                            (service) => ServiceTile(
                              service: service,
                              onTap: () =>
                                  _showServiceDialog(existing: service),
                            ),
                          ),
                        ],
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

class _ServiceFormDialog extends ConsumerStatefulWidget {
  const _ServiceFormDialog({
    required this.salonId,
    required this.categories,
    this.existing,
  });

  final String salonId;
  final List<ServiceCategoryModel> categories;
  final ServiceModel? existing;

  @override
  ConsumerState<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<_ServiceFormDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  bool _saving = false;

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

  Future<void> _save() async {
    if (_selectedCategoryId == null || _nameController.text.trim().isEmpty) {
      _showMessage('Name and category are required');
      return;
    }

    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceController.text) ?? 0;
      final discountText = _discountPriceController.text.trim();
      final discountPrice = discountText.isEmpty
          ? null
          : double.tryParse(discountText);

      if (price <= 0) {
        _showMessage('Price must be greater than 0');
        return;
      }
      if (discountText.isNotEmpty && discountPrice == null) {
        _showMessage('Discount price must be a valid number');
        return;
      }
      if (discountPrice != null &&
          (discountPrice <= 0 || discountPrice >= price)) {
        _showMessage('Discount price must be lower than regular price');
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
      _showMessage(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
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
    return AlertDialog(
      backgroundColor: AppColors.backgroundMid,
      title: Text(widget.existing == null ? 'Add service' : 'Edit service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _selectedCategoryId = v),
            ),
            TextField(
              controller: _nameController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Service name'),
            ),
            TextField(
              controller: _priceController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _discountPriceController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Discount price (optional)',
                helperText: 'Leave empty to clear any discount',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _durationController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Duration (min)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _descriptionController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
