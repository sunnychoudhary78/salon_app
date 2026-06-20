import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  Future<void> _checkStatus(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).refreshProfile();
    final approved =
        await ref.read(hasApprovedSalonsProvider.notifier).refresh();
    if (!context.mounted) return;
    if (approved) {
      context.go(RoutePaths.ownerDashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still pending approval')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final application = auth?.salonApplication;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            PremiumAppBar(
              title: 'Application status',
              showMenu: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _checkStatus(context, ref),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Under review',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      application != null
                          ? 'Your application for "${application.salonName}" is pending admin approval.'
                          : 'Your salon application is pending admin approval.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You are on the owner portal while your application is reviewed. Pull down or tap below to refresh.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    PremiumButton(
                      label: 'Check status',
                      variant: PremiumButtonVariant.accent,
                      onPressed: () => _checkStatus(context, ref),
                    ),
                    const SizedBox(height: 12),
                    PremiumButton(
                      label: 'Back to dashboard',
                      variant: PremiumButtonVariant.ghost,
                      onPressed: () => context.go(RoutePaths.ownerDashboard),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
