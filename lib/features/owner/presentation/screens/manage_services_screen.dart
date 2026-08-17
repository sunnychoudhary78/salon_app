import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/service_form_sheet.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_bottom_sheet.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(ownerDashboardProvider);
    });
  }

  void _refreshServiceDependentData() {
    ref.invalidate(ownerServicesProvider(widget.salonId));
    ref.invalidate(ownerDashboardProvider);
  }

  Future<void> _showServiceDialog({ServiceModel? existing}) async {
    final result = await showGlassBottomSheet<bool>(
      context: context,
      builder: (ctx) =>
          ServiceFormSheet(salonId: widget.salonId, existing: existing),
    );

    if (result == true && mounted) {
      _refreshServiceDependentData();
    }
  }

  SalonType _salonType(WidgetRef ref) {
    final salons = ref.watch(ownerSalonsProvider).value ?? const [];
    for (final salon in salons) {
      if (salon.id == widget.salonId) return salon.salonType;
    }
    return SalonType.unisex;
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(ownerServicesProvider(widget.salonId));
    final salonType = _salonType(ref);
    final showServiceFor = salonType == SalonType.unisex;

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
          onRefresh: () async {
            ref.invalidate(ownerServicesProvider(widget.salonId));
            ref.invalidate(ownerDashboardProvider);
          },
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
                        showServiceFor: showServiceFor,
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
