import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/providers/salon_browse_filters_provider.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/home_search_header.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/location_picker_sheet.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_filters_sheet.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/location_app_bar_title.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/salon_card.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen>
    with AutomaticKeepAliveClientMixin {
  static const _homeTabIndex = 0;

  final _homeScrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _wantKeepAlive = true;

  @override
  bool get wantKeepAlive => _wantKeepAlive;

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_loadMoreNearBottom);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedLocationProvider.notifier).scheduleBackgroundGpsRefresh();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(salonBrowseFiltersProvider.notifier).setSearch(query);
    });
  }

  void _loadMoreNearBottom() {
    if (!_homeScrollController.hasClients) return;
    final position = _homeScrollController.position;
    if (position.extentAfter < 600) {
      ref.read(paginatedSalonsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isHomeTabActive =
        ref.watch(customerShellTabIndexProvider) == _homeTabIndex;
    if (_wantKeepAlive != isHomeTabActive) {
      _wantKeepAlive = isHomeTabActive;
      updateKeepAlive();
    }

    final firstName = ref.watch(
      authProvider.select(
        (auth) => auth.value?.user.name.split(' ').first ?? 'there',
      ),
    );
    final locationState = ref.watch(selectedLocationProvider);
    final browseFilters = ref.watch(salonBrowseFiltersProvider);
    final isSearching = browseFilters.search.isNotEmpty;
    final waitingForLocation =
        locationState.isLoading && !locationState.location.isSet;
    final allSalons = ref.watch(paginatedSalonsProvider);
    final showSalonShimmer =
        waitingForLocation || (allSalons.isLoading && !allSalons.hasValue);

    return Scaffold(
      appBar: PremiumAppBar(
        titleWidget: LocationAppBarTitle(
          onTap: () => showLocationPickerSheet(context, ref),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(authProvider.notifier).refreshProfile();
            ref.invalidate(bannersProvider);
            ref.invalidate(forYouSalonsProvider);
            await ref.read(paginatedSalonsProvider.notifier).reload();
            final selected = ref.read(selectedLocationProvider).location;
            if (selected.source == LocationSource.gps) {
              await ref.read(selectedLocationProvider.notifier).refreshGps();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refresh failed: $e')),
              );
            }
          }
        },
        child: CustomScrollView(
          controller: _homeScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedEntrance(
                    child: HomeSearchHeader(
                      firstName: firstName,
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onFilterTap: () => showSalonFiltersSheet(context, ref),
                    ),
                  ),
                  const _CuratedBannersSection(),
                  if (!isSearching) ...[
                    const SizedBox(height: 16),
                    const AnimatedEntrance(
                      index: 1,
                      child: _ForYouSalonRailSection(),
                    ),
                  ],
                  if (!isSearching) const SizedBox(height: 30),
                  AnimatedEntrance(
                    index: 2,
                    child: SectionHeader(
                      title: 'All salons',
                      subtitle: isSearching
                          ? "Results for '${browseFilters.search}'"
                          : browseFilters.hasAvailableSlots
                              ? 'Open slots today near you'
                              : browseFilters.hasActiveFilters
                                  ? 'Filtered results near you'
                                  : 'Keep scrolling to discover more',
                    ),
                  ),
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            showSalonShimmer
                ? SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShimmerBox(
                            width: double.infinity,
                            height: 208,
                            radius: 16,
                          ),
                          const SizedBox(height: 10),
                          ShimmerBox(width: 180, height: 16, radius: 8),
                          const SizedBox(height: 6),
                          ShimmerBox(width: 120, height: 12, radius: 6),
                        ],
                      ),
                    ),
                    childCount: 3,
                  ),
                ),
              )
                : allSalons.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShimmerBox(
                            width: double.infinity,
                            height: 208,
                            radius: 16,
                          ),
                          const SizedBox(height: 10),
                          ShimmerBox(width: 180, height: 16, radius: 8),
                          const SizedBox(height: 6),
                          ShimmerBox(width: 120, height: 12, radius: 6),
                        ],
                      ),
                    ),
                    childCount: 3,
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: EmptyView(
                  message: error.toString(),
                  icon: Icons.error_outline,
                ),
              ),
              data: (state) => _AllSalonsFeedSliver(
                state: state,
                emptyMessage: browseFilters.hasAvailableSlots
                    ? 'No salons with open slots today near you — try widening distance or turning off the filter.'
                    : browseFilters.hasSearchOrFilters
                        ? 'No salons match your search or filters'
                        : !locationState.location.isSet
                            ? 'Set your location to see nearby salons'
                            : 'No salons available yet',
                showLocationPrompt: !locationState.location.isSet &&
                    !locationState.isLoading,
                onLocationTap: () => showLocationPickerSheet(context, ref),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: AppDecorations.scrollBottomPadding(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuratedBannersSection extends ConsumerStatefulWidget {
  const _CuratedBannersSection();

  @override
  ConsumerState<_CuratedBannersSection> createState() =>
      _CuratedBannersSectionState();
}

class _CuratedBannersSectionState extends ConsumerState<_CuratedBannersSection> {
  late final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannersProvider);

    return banners.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ShimmerBox(
          width: double.infinity,
          height: 160,
          radius: 16,
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            AnimatedEntrance(
              index: 1,
              child: const SectionHeader(
                title: 'Curated for you',
                subtitle: 'Exclusive offers & promotions',
              ),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              index: 2,
              child: Column(
                children: [
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final banner = items[i];
                        return GlassCard(
                          padding: EdgeInsets.zero,
                          margin: const EdgeInsets.only(right: 4),
                          shadowColor: AppColors.glowAccent,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (banner.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl: banner.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, error, stackTrace) =>
                                        _bannerFallback(context),
                                  ),
                                )
                              else
                                _bannerFallback(context),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      context.appColors.surface.withValues(
                                        alpha: 0.85,
                                      ),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.65],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.accentGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'OFFER',
                                        style: TextStyle(
                                          color: context.appColors.onAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      banner.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: context.appColors.textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (items.length > 1) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: SmoothPageIndicator(
                        controller: _controller,
                        count: items.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          expansionFactor: 3,
                          spacing: 6,
                          activeDotColor: AppColors.accent,
                          dotColor: context.appColors.glassBorder.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _bannerFallback(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.3),
              context.appColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(
            Icons.local_offer_rounded,
            size: 48,
            color: AppColors.accent,
          ),
        ),
      );
}

class _ForYouSalonRailSection extends ConsumerWidget {
  const _ForYouSalonRailSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(forYouSalonsProvider);

    return value.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'For you',
              subtitle: 'Featured picks & deals near you',
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    SalonCard(
                      salon: items[i],
                      cardWidth: 268,
                      autoPlayImages: false,
                      showPromoChips: true,
                      onTap: () => context.push(
                        '${RoutePaths.customerSalons}/${items[i].id}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AllSalonsFeedSliver extends StatelessWidget {
  const _AllSalonsFeedSliver({
    required this.state,
    required this.emptyMessage,
    this.showLocationPrompt = false,
    this.onLocationTap,
  });

  final PaginatedSalonsState state;
  final String emptyMessage;
  final bool showLocationPrompt;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyView(
          message: emptyMessage,
          icon: Icons.store_outlined,
          action: showLocationPrompt ? onLocationTap : null,
          actionLabel: showLocationPrompt ? 'Set location' : null,
        ),
      );
    }

    final itemCount = state.items.length +
        (state.isLoadingMore ? 1 : 0) +
        (!state.hasMore && !state.isLoadingMore ? 1 : 0);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < state.items.length) {
              final salon = state.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RepaintBoundary(
                  child: AnimatedEntrance(
                    index: index + 3,
                    child: SalonCard(
                      salon: salon,
                      autoPlayImages: false,
                      onTap: () => context.push(
                        '${RoutePaths.customerSalons}/${salon.id}',
                      ),
                      onBook: salon.hasServices
                          ? () => context.push(
                              '${RoutePaths.customerSalons}/${salon.id}/book',
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }

            if (state.isLoadingMore && index == state.items.length) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'You have reached the end',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.textMuted,
                    ),
              ),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}
