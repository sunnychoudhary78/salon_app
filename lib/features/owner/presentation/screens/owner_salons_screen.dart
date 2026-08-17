import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/core/utils/image_decode_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_metric_tile.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_dialog.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

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
        await ref
            .read(ownerOnboardingActionsProvider)
            .submitActivateRequest(salonId: salon.id, reason: reason);
      } else {
        await ref
            .read(ownerOnboardingActionsProvider)
            .submitDeactivateRequest(salonId: salon.id, reason: reason);
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
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
    }
  }

  String? _pendingLabel(SalonApplicationModel? pending) {
    if (pending == null) return null;
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
      body: GradientBackground(
        child: RefreshIndicator(
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
              final activeCount = items
                  .where((salon) => salon.isActiveForCustomers)
                  .length;
              final pendingCount = items
                  .where(
                    (salon) =>
                        pendingApplicationForSalon(pendingApps, salon.id) !=
                        null,
                  )
                  .length;
              final colors = context.appColors;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  AppDecorations.scrollBottomPadding(context),
                ),
                children: [
                  OwnerMetricGroup(
                    tiles: [
                      OwnerMetricTile(
                        label: 'Locations',
                        value: '${items.length}',
                        icon: Icons.storefront_rounded,
                        tint: colors.primary,
                      ),
                      OwnerMetricTile(
                        label: 'Active',
                        value: '$activeCount',
                        icon: Icons.visibility_rounded,
                        tint: AppColors.success,
                      ),
                      OwnerMetricTile(
                        label: 'Inactive',
                        value: '${items.length - activeCount}',
                        icon: Icons.visibility_off_outlined,
                        tint: colors.textSecondary,
                      ),
                    ],
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      pendingCount == 1
                          ? '1 request pending admin approval'
                          : '$pendingCount requests pending admin approval',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Your locations',
                    subtitle: 'Tap a salon to edit details',
                  ),
                  const SizedBox(height: 12),
                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final salon = entry.value;
                    final pending = pendingApplicationForSalon(
                      pendingApps,
                      salon.id,
                    );
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
                          onServices: () =>
                              _openManageServices(context, salon.id),
                          onStaff: () => _openManageStaff(context, salon.id),
                          onSchedule: () =>
                              _openManageSchedule(context, salon.id),
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
      radius: 20,
      elevated: true,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                if (imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 168,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: memCachePx(
                      context,
                      MediaQuery.sizeOf(context).width,
                    ),
                    memCacheHeight: memCachePx(context, 168),
                    placeholder: (_, _) => Container(
                      height: 168,
                      color: context.appColors.glassFill,
                    ),
                    errorWidget: (_, _, _) => Container(
                      height: 168,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: const Center(
                        child: Icon(Icons.store_rounded, size: 40),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 168,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          context.appColors.accent.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.store_rounded, size: 40),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _StatusChip(
                    label: salon.isFeatured ? 'Featured' : 'Not featured',
                    color: salon.isFeatured
                        ? context.appColors.accent
                        : context.appColors.textMuted,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatusChip(
                    label: pendingLabel ?? salon.statusLabel,
                    color: pendingLabel != null
                        ? AppColors.warning
                        : _salonStatusColor(context, salon),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (salon.reviewCount > 0) ...[
                  const SizedBox(height: 8),
                  SalonRatingBadge(
                    averageRating: salon.averageRating,
                    reviewCount: salon.reviewCount,
                    size: SalonRatingBadgeSize.compact,
                  ),
                ],
                if (_salonLocation(salon) != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: context.appColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _salonLocation(salon)!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.appColors.textMuted),
                        ),
                      ),
                    ],
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
                        disabledMessage: hasPending
                            ? 'Salon update is pending approval'
                            : null,
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
                _StatusToggleButton(
                  activate: !isActive,
                  onPressed: onToggleStatus,
                  disabledMessage: hasPending
                      ? 'Salon update is pending approval'
                      : null,
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
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.18),
          colors.surface.withValues(alpha: 0.92),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String? _salonLocation(SalonModel salon) {
  final location = [
    salon.city,
    salon.state,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
  return location.isEmpty ? null : location;
}

Color _salonStatusColor(BuildContext context, SalonModel salon) {
  final colors = context.appColors;
  switch (salon.status?.toUpperCase()) {
    case 'ACTIVE':
      return AppColors.success;
    case 'SUSPENDED':
      return AppColors.warning;
    case 'CLOSED':
      return colors.textSecondary;
    default:
      return salon.isActive ? AppColors.success : colors.textSecondary;
  }
}

class _StatusToggleButton extends StatelessWidget {
  const _StatusToggleButton({
    required this.activate,
    required this.onPressed,
    this.disabledMessage,
  });

  final bool activate;
  final VoidCallback? onPressed;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = context.appColors;
    final fill = !enabled
        ? colors.glassFill.withValues(alpha: 0.3)
        : activate
        ? AppColors.success
        : AppColors.error.withValues(alpha: 0.12);
    final foreground = !enabled
        ? colors.textMuted
        : activate
        ? Colors.white
        : AppColors.error;
    final border = !enabled
        ? colors.glassBorder.withValues(alpha: 0.5)
        : activate
        ? AppColors.success
        : AppColors.error.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? onPressed
            : (disabledMessage != null
                  ? () => showFormDisabledMessage(context, disabledMessage!)
                  : null),
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                activate
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: foreground,
              ),
              const SizedBox(width: 8),
              Text(
                activate ? 'Activate' : 'Deactivate',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
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
    this.disabledMessage,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? onTap
            : (disabledMessage != null
                  ? () => showFormDisabledMessage(context, disabledMessage!)
                  : null),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: enabled
                ? context.appColors.accent.withValues(alpha: 0.1)
                : context.appColors.glassFill.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? context.appColors.accent.withValues(alpha: 0.28)
                  : context.appColors.glassBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? context.appColors.accent
                    : context.appColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
