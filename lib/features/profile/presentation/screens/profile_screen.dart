import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/profile_detail_row.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/salon_application_status_card.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.isOwnerMode});

  final bool isOwnerMode;

  Future<void> _refreshProfile(WidgetRef ref) async {
    await ref.read(authProvider.notifier).refreshProfile();
    await ref.read(hasApprovedSalonsProvider.notifier).refresh();
  }

  String get _editRoute =>
      isOwnerMode ? RoutePaths.ownerEditProfile : RoutePaths.customerEditProfile;

  String get _changePasswordRoute => isOwnerMode
      ? RoutePaths.ownerChangePassword
      : RoutePaths.customerChangePassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    if (auth == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final application = auth.salonApplication;
    final showApplicationStatus = isOwnerMode &&
        application != null &&
        (application.isPending || application.isRejected);
    final profileImage = auth.customer?.profileImage;
    final initials = auth.user.name.isNotEmpty
        ? auth.user.name.trim().substring(0, 1).toUpperCase()
        : '?';

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit profile',
            onPressed: () => context.push(_editRoute),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshProfile(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            AppDecorations.shellBottomInset,
          ),
          children: [
            AnimatedEntrance(
              child: GlassCard(
                child: Column(
                  children: [
                    _ProfileAvatar(
                      imageUrl: profileImage,
                      initials: initials,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.user.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (auth.user.email != null && auth.user.email!.isNotEmpty)
                      Text(
                        auth.user.email!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),
                    ProfileDetailRow(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: auth.user.phone ?? '',
                    ),
                    ProfileDetailRow(
                      icon: Icons.wc_rounded,
                      label: 'Gender',
                      value: auth.customer?.gender ?? '',
                    ),
                    if (auth.customer?.dob != null)
                      ProfileDetailRow(
                        icon: Icons.cake_outlined,
                        label: 'Date of birth',
                        value: auth.customer!.dob!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (showApplicationStatus) ...[
              AnimatedEntrance(
                index: 1,
                child: SalonApplicationStatusCard(application: application),
              ),
              const SizedBox(height: 16),
            ],
            AnimatedEntrance(
              index: 2,
              child: GlassCard(
                onTap: () => context.push(_changePasswordRoute),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user.hasPassword
                                ? 'Change password'
                                : 'Set password',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            auth.user.hasPassword
                                ? 'Update your account password'
                                : 'Add a password to your account',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (!isOwnerMode && auth.salonOwner == null) ...[
              const SizedBox(height: 16),
              AnimatedEntrance(
                index: 3,
                child: PremiumButton(
                  label: 'Become a salon owner',
                  icon: Icons.store_rounded,
                  variant: PremiumButtonVariant.primary,
                  onPressed: () => context.push(RoutePaths.becomeOwner),
                ),
              ),
            ],
            if (!isOwnerMode &&
                auth.salonOwner != null &&
                application == null) ...[
              const SizedBox(height: 16),
              AnimatedEntrance(
                index: 3,
                child: PremiumButton(
                  label: 'Complete salon application',
                  icon: Icons.store_rounded,
                  variant: PremiumButtonVariant.primary,
                  onPressed: () => context.push(RoutePaths.becomeOwner),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AnimatedEntrance(
              index: 4,
              child: PremiumButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                variant: PremiumButtonVariant.ghost,
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.initials,
  });

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl == null ? AppColors.accentGradient : null,
        border: Border.all(color: AppColors.glassBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _Initials(initials: initials),
            )
          : _Initials(initials: initials),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
