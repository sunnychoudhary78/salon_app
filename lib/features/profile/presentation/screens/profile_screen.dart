import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/core/utils/image_decode_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/owner_account_alerts_card.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/profile_detail_row.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/salon_application_status_card.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.isOwnerMode});

  final bool isOwnerMode;

  Future<void> _refreshProfile(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(authProvider.notifier).refreshProfile();
      await ref.read(hasApprovedSalonsProvider.notifier).refresh();
      if (isOwnerMode) {
        ref.invalidate(ownerDashboardProvider);
        ref.invalidate(ownerPayoutAccountProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not refresh profile: ${userFacingErrorMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  String get _editRoute => isOwnerMode
      ? RoutePaths.ownerEditProfile
      : RoutePaths.customerEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    if (auth == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final application = auth.salonApplication;
    final showApplicationStatus =
        isOwnerMode &&
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
        onRefresh: () => _refreshProfile(ref, context),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            AppDecorations.scrollBottomPadding(context),
          ),
          children: [
            AnimatedEntrance(
              child: isOwnerMode
                  ? _OwnerProfileHeader(
                      imageUrl: profileImage,
                      initials: initials,
                      name: auth.user.name,
                      businessName: auth.salonOwner?.businessName,
                      email: auth.user.email,
                      phone: auth.user.phone,
                      dob: auth.customer?.dob,
                    )
                  : GlassCard(
                      child: Column(
                        children: [
                          _ProfileAvatar(
                            imageUrl: profileImage,
                            initials: initials,
                            showOwnerRing: false,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            auth.user.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          if (auth.user.email != null &&
                              auth.user.email!.isNotEmpty)
                            Text(
                              auth.user.email!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: context.appColors.textSecondary,
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
            if (isOwnerMode && auth.salonOwner != null) ...[
              AnimatedEntrance(
                index: showApplicationStatus ? 2 : 1,
                child: const OwnerAccountAlertsCard(),
              ),
              const SizedBox(height: 16),
            ],
            if (isOwnerMode && auth.salonOwner != null) ...[
              AnimatedEntrance(
                index: showApplicationStatus ? 3 : 2,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Business',
                        subtitle: 'Your salon owner account',
                      ),
                      const SizedBox(height: 8),
                      ProfileDetailRow(
                        icon: Icons.business_rounded,
                        label: 'Business name',
                        value: auth.salonOwner!.businessName,
                      ),
                      if (auth.salonOwner!.gstNumber != null &&
                          auth.salonOwner!.gstNumber!.isNotEmpty)
                        ProfileDetailRow(
                          icon: Icons.receipt_long_outlined,
                          label: 'GST number',
                          value: auth.salonOwner!.gstNumber!,
                        ),
                      if (auth.salonOwner!.status != null)
                        ProfileDetailRow(
                          icon: Icons.verified_outlined,
                          label: 'Status',
                          value: auth.salonOwner!.status!,
                        ),
                      const SizedBox(height: 12),
                      PremiumButton(
                        label: 'Earnings & payouts',
                        icon: Icons.payments_outlined,
                        variant: PremiumButtonVariant.ghost,
                        onPressed: () => context.push(RoutePaths.ownerEarnings),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!isOwnerMode &&
                auth.salonOwner != null &&
                application == null) ...[
              const SizedBox(height: 16),
              AnimatedEntrance(
                index: 2,
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
              index: 3,
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

class _OwnerProfileHeader extends StatelessWidget {
  const _OwnerProfileHeader({
    required this.imageUrl,
    required this.initials,
    required this.name,
    this.businessName,
    this.email,
    this.phone,
    this.dob,
  });

  final String? imageUrl;
  final String initials;
  final String name;
  final String? businessName;
  final String? email;
  final String? phone;
  final String? dob;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      shadowColor: context.appColors.accent,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.35),
                  context.appColors.accent.withValues(alpha: 0.2),
                  context.appColors.surface.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                _ProfileAvatar(
                  imageUrl: imageUrl,
                  initials: initials,
                  showOwnerRing: true,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (businessName != null && businessName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    businessName!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.appColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.appColors.accent.withValues(alpha: 0.25),
                        AppColors.primary.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.appColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Salon Owner',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
                ProfileDetailRow(
                  icon: Icons.phone_rounded,
                  label: 'Phone',
                  value: phone ?? '',
                ),
                if (dob != null)
                  ProfileDetailRow(
                    icon: Icons.cake_outlined,
                    label: 'Date of birth',
                    value: dob!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.initials,
    this.showOwnerRing = false,
  });

  final String? imageUrl;
  final String initials;
  final bool showOwnerRing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl == null ? context.appColors.accentGradient : null,
        border: Border.all(
          color: showOwnerRing
              ? context.appColors.accent.withValues(alpha: 0.6)
              : context.appColors.glassBorder,
          width: showOwnerRing ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.accent.withValues(
              alpha: showOwnerRing ? 0.35 : 0.2,
            ),
            blurRadius: showOwnerRing ? 20 : 16,
            spreadRadius: showOwnerRing ? 2 : 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: resolveImageUrl(imageUrl!),
              fit: BoxFit.cover,
              memCacheWidth: memCachePx(context, 96),
              memCacheHeight: memCachePx(context, 96),
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
          color: context.appColors.onAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
