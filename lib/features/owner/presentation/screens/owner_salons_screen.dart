import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/salon_card.dart';

class OwnerSalonsScreen extends ConsumerWidget {
  const OwnerSalonsScreen({super.key});

  void _openManageSchedule(BuildContext context, String salonId) {
    context.push('${RoutePaths.ownerSalons}/$salonId/schedule');
  }

  void _openManageServices(BuildContext context, String salonId) {
    context.push('${RoutePaths.ownerSalons}/$salonId/services');
  }

  void _openEditSalon(BuildContext context, String salonId) {
    context.push('${RoutePaths.ownerSalons}/$salonId/edit');
  }

  Future<void> _submitStatusRequest({
    required BuildContext context,
    required WidgetRef ref,
    required SalonModel salon,
    required bool activate,
  }) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          activate
              ? 'Request salon activation?'
              : 'Request salon deactivation?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activate
                  ? 'Your salon will become visible to customers once admin approves.'
                  : 'Your salon stays visible to customers until admin approves deactivation.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim().isEmpty
        ? null
        : reasonController.text.trim();
    reasonController.dispose();

    try {
      if (activate) {
        await ref.read(ownerOnboardingActionsProvider).submitActivateRequest(
              salonId: salon.id,
              reason: reason,
            );
      } else {
        await ref.read(ownerOnboardingActionsProvider).submitDeactivateRequest(
              salonId: salon.id,
              reason: reason,
            );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? 'Activation request submitted — pending admin approval'
                : 'Deactivation request submitted — pending admin approval',
          ),
        ),
      );
      await ref.read(authProvider.notifier).refreshProfile();
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.apiException.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String? _pendingLabel(SalonApplicationModel? pending) {
    if (pending == null) return null;
    if (pending.isUpdate) return 'Update pending approval';
    if (pending.isDeactivate) return 'Deactivation pending approval';
    if (pending.isActivate) return 'Activation pending approval';
    return 'Request pending approval';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salons = ref.watch(ownerSalonsProvider);
    final applications = ref.watch(ownerSalonApplicationsProvider);

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'My salons',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Apply for a salon',
            onPressed: () => context.push(RoutePaths.becomeOwner),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownerSalonsProvider);
          ref.invalidate(ownerSalonApplicationsProvider);
        },
        child: AsyncValueWidget(
          value: salons,
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  const Center(
                    child: Text(
                      'No salons yet — apply for a salon first, then add services',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumButton(
                    label: 'Apply for a salon',
                    variant: PremiumButtonVariant.accent,
                    onPressed: () => context.push(RoutePaths.becomeOwner),
                  ),
                ],
              );
            }

            final pendingApps = applications.maybeWhen(
              data: (apps) => apps,
              orElse: () => const <SalonApplicationModel>[],
            );

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppDecorations.shellBottomInset,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final salon = items[i];
                final pending =
                    pendingApplicationForSalon(pendingApps, salon.id);
                final pendingLabel = _pendingLabel(pending);
                final hasPending = pending != null;
                final isActive = salon.isActiveForCustomers;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pendingLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.hourglass_top_rounded,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pendingLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.warning),
                              ),
                            ],
                          ),
                        )
                      else if (!isActive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_off_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Deactivated — hidden from customers',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      SalonCard(
                        salon: salon,
                        autoPlayImages: false,
                        onTap: () => _openManageServices(context, salon.id),
                        footerActionLabel: 'Manage services',
                        onFooterAction: () =>
                            _openManageServices(context, salon.id),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openManageSchedule(context, salon.id),
                              icon: const Icon(Icons.schedule_rounded, size: 18),
                              label: const Text('Schedule'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: hasPending
                                  ? null
                                  : () => _openEditSalon(context, salon.id),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: hasPending
                                  ? null
                                  : () => _submitStatusRequest(
                                        context: context,
                                        ref: ref,
                                        salon: salon,
                                        activate: !isActive,
                                      ),
                              icon: Icon(
                                isActive
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: Text(
                                isActive ? 'Deactivate' : 'Activate',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
