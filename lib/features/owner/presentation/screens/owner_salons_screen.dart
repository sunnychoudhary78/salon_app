import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_dialog.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

class OwnerSalonsScreen extends ConsumerWidget {
  const OwnerSalonsScreen({super.key});

  void _openManageSchedule(BuildContext context, String salonId) {
    context.push('${RoutePaths.ownerSalons}/$salonId/schedule');
  }

  void _openManageServices(BuildContext context, String salonId) {
    context.push('${RoutePaths.ownerSalons}/$salonId/services');
  }

  void _openManageStaff(BuildContext context, String salonId) {
    context.push('${RoutePaths.ownerSalons}/$salonId/staff');
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
      builder: (ctx) => PremiumDialog(
        title: activate
            ? 'Request salon activation?'
            : 'Request salon deactivation?',
        subtitle: activate
            ? 'Your salon will become visible to customers once admin approves.'
            : 'Your salon stays visible to customers until admin approves deactivation.',
        content: PremiumTextField(
          controller: reasonController,
          label: 'Reason (optional)',
          maxLines: 3,
        ),
        confirmLabel: 'Submit request',
        cancelLabel: 'Cancel',
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
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
        subtitle: salons.maybeWhen(
          data: (items) =>
              '${items.length} location${items.length == 1 ? '' : 's'}',
          orElse: () => null,
        ),
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
              return EmptyStateScrollable(
                child: EmptyState(
                  icon: Icons.store_outlined,
                  title: 'No salons yet',
                  subtitle:
                      'Apply for a salon first, then add services and start taking bookings.',
                  actionLabel: 'Apply for a salon',
                  onAction: () => context.push(RoutePaths.becomeOwner),
                ),
              );
            }

            final pendingApps = applications.maybeWhen(
              data: (apps) => apps,
              orElse: () => const <SalonApplicationModel>[],
            );

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final salon = items[i];
                final pending =
                    pendingApplicationForSalon(pendingApps, salon.id);
                final pendingLabel = _pendingLabel(pending);
                final hasPending = pending != null;
                final isActive = salon.isActiveForCustomers;

                return AnimatedEntrance(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _OwnerSalonCard(
                      salon: salon,
                      pendingLabel: pendingLabel,
                      hasPending: hasPending,
                      isActive: isActive,
                      onEdit: () => _openEditSalon(context, salon.id),
                      onServices: () => _openManageServices(context, salon.id),
                      onStaff: () => _openManageStaff(context, salon.id),
                      onSchedule: () => _openManageSchedule(context, salon.id),
                      onToggleStatus: hasPending
                          ? null
                          : () => _submitStatusRequest(
                                context: context,
                                ref: ref,
                                salon: salon,
                                activate: !isActive,
                              ),
                    ),
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

class _OwnerSalonCard extends StatelessWidget {
  const _OwnerSalonCard({
    required this.salon,
    required this.hasPending,
    required this.isActive,
    required this.onEdit,
    required this.onServices,
    required this.onStaff,
    required this.onSchedule,
    required this.onToggleStatus,
    this.pendingLabel,
  });

  final SalonModel salon;
  final String? pendingLabel;
  final bool hasPending;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onServices;
  final VoidCallback onStaff;
  final VoidCallback onSchedule;
  final VoidCallback? onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final imageUrl = salon.displayCoverImage;

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                if (imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 140,
                      color: context.appColors.glassFill,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 140,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: const Center(
                        child: Icon(Icons.store_rounded, size: 40),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.accent.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.store_rounded, size: 40),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatusChip(
                    label: pendingLabel ??
                        (isActive ? 'Active' : 'Inactive'),
                    color: pendingLabel != null
                        ? AppColors.warning
                        : (isActive ? AppColors.success : AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.salonName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (salon.city != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [salon.city, salon.state].whereType<String>().join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SalonActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        enabled: !hasPending,
                        onTap: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SalonActionButton(
                        icon: Icons.spa_outlined,
                        label: 'Services',
                        onTap: onServices,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SalonActionButton(
                        icon: Icons.groups_outlined,
                        label: 'Staff',
                        onTap: onStaff,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SalonActionButton(
                        icon: Icons.schedule_rounded,
                        label: 'Schedule',
                        onTap: onSchedule,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PremiumButton(
                  label: isActive ? 'Deactivate' : 'Activate',
                  icon: isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  variant: PremiumButtonVariant.ghost,
                  onPressed: onToggleStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SalonActionButton extends StatelessWidget {
  const _SalonActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.1)
                : context.appColors.glassFill.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.appColors.glassBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? AppColors.accent : context.appColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: enabled
                          ? context.appColors.textPrimary
                          : context.appColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
