import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class SalonApplicationStatusCard extends ConsumerWidget {
  const SalonApplicationStatusCard({
    super.key,
    required this.application,
  });

  final SalonApplicationProfileModel application;

  String get _pendingTitle {
    if (application.isUpdate) return 'Salon update pending';
    if (application.isDeactivate) return 'Salon deactivation pending';
    if (application.isActivate) return 'Salon activation pending';
    return 'Salon application pending';
  }

  String get _rejectedTitle {
    if (application.isUpdate) return 'Salon update rejected';
    if (application.isDeactivate) return 'Salon deactivation rejected';
    if (application.isActivate) return 'Salon activation rejected';
    return 'Salon application rejected';
  }

  String get _pendingMessage {
    if (application.isUpdate) {
      return 'Your salon changes will go live once admin approves the update request.';
    }
    if (application.isDeactivate) {
      return 'Your salon will be hidden from customers once admin approves deactivation.';
    }
    if (application.isActivate) {
      return 'Your salon will become visible to customers once admin approves activation.';
    }
    return 'Your salon will go live once admin approves your application. Pull down to refresh status.';
  }

  Future<void> _refresh(WidgetRef ref, BuildContext context) async {
    await ref.read(authProvider.notifier).refreshProfile();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application status updated')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (application.isPending) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  _pendingTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Salon: ${application.salonName}'),
            if (application.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Submitted: ${_formatDate(application.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _pendingMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: 'Refresh status',
                    expand: false,
                    variant: PremiumButtonVariant.ghost,
                    onPressed: () => _refresh(ref, context),
                  ),
                ),
                if (application.isCreate) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push(RoutePaths.pendingApproval),
                    child: const Text('Details'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    if (application.isRejected) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel_outlined, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  _rejectedTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Salon: ${application.salonName}'),
            if (application.rejectionReason != null &&
                application.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: ${application.rejectionReason}'),
            ],
            const SizedBox(height: 12),
            if (application.isCreate)
              PremiumButton(
                label: 'Apply again',
                variant: PremiumButtonVariant.accent,
                onPressed: () => context.push(RoutePaths.becomeOwner),
              )
            else
              PremiumButton(
                label: 'Try again',
                variant: PremiumButtonVariant.accent,
                onPressed: () {
                  if (application.isUpdate &&
                      application.salonId != null) {
                    context.push(
                      '${RoutePaths.ownerSalons}/${application.salonId}/edit',
                    );
                  } else {
                    context.push(RoutePaths.ownerSalons);
                  }
                },
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDate(String iso) {
    try {
      return DateFormat.yMMMd().format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
