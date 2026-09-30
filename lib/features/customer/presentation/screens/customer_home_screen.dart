import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/utils/image_decode_utils.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
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
      ref
          .read(selectedLocationProvider.notifier)
          .scheduleBackgroundGpsRefresh();
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
            ref.invalidate(favoriteSalonsProvider);
            ref.invalidate(forYouSalonsProvider);
            await ref.read(paginatedSalonsProvider.notifier).reload();
            final selected = ref.read(selectedLocationProvider).location;
            if (selected.source == LocationSource.gps) {
              await ref.read(selectedLocationProvider.notifier).refreshGps();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refresh failed: ${userFacingErrorMessage(e)}'),
                ),
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
                  const SizedBox(height: 14),
                  const _BeautyAssistantEntryCard(),
                  if (!isSearching) ...[
                    const SizedBox(height: 16),
                    const AnimatedEntrance(
                      index: 1,
                      animateKey: ValueKey('home-favorites-rail'),
                      child: _FavoriteSalonRailSection(),
                    ),
                    const AnimatedEntrance(
                      index: 2,
                      animateKey: ValueKey('home-foryou-rail'),
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
                        message: userFacingErrorMessage(error),
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
                      showLocationPrompt:
                          !locationState.location.isSet &&
                          !locationState.isLoading,
                      onLocationTap: () =>
                          showLocationPickerSheet(context, ref),
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

class _BeautyAssistantEntryCard extends StatelessWidget {
  const _BeautyAssistantEntryCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push(RoutePaths.customerBeautyAssistant),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: colors.accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Beauty Assistant',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Get ideas for your next look',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.textMuted,
              ),
            ],
          ),
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

class _CuratedBannersSectionState
    extends ConsumerState<_CuratedBannersSection> {
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
        child: ShimmerBox(width: double.infinity, height: 160, radius: 16),
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
                          shadowColor: context.appColors.glowAccent,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (banner.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl: banner.imageUrl!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: memCachePx(
                                      context,
                                      MediaQuery.sizeOf(context).width,
                                    ),
                                    memCacheHeight: memCachePx(context, 190),
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
                                        gradient:
                                            context.appColors.accentGradient,
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
                                            color:
                                                context.appColors.textPrimary,
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
                          activeDotColor: context.appColors.accent,
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
    child: Center(
      child: Icon(
        Icons.local_offer_rounded,
        size: 48,
        color: context.appColors.accent,
      ),
    ),
  );
}

class _FavoriteSalonRailSection extends ConsumerWidget {
  const _FavoriteSalonRailSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _HomeSalonRail(
      value: ref.watch(favoriteSalonsProvider),
      title: 'Favorites',
      subtitle: 'Salons you saved',
    );
  }
}

class _ForYouSalonRailSection extends ConsumerWidget {
  const _ForYouSalonRailSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forYou = ref.watch(forYouSalonsProvider);
    final allSalons = ref.watch(paginatedSalonsProvider);

    // Dual featured/deals fetches often lag the main feed. Once All salons has
    // settled, hide the tall skeleton instead of leaving it up until empty.
    final mainFeedSettled = allSalons.hasValue || allSalons.hasError;
    if (forYou.isLoading && !forYou.hasValue && mainFeedSettled) {
      return const SizedBox.shrink();
    }

    return _HomeSalonRail(
      value: forYou,
      title: 'For you',
      subtitle: 'Featured picks & deals near you',
      skipLoadingOnReload: true,
    );
  }
}

class _HomeSalonRail extends StatelessWidget {
  const _HomeSalonRail({
    required this.value,
    required this.title,
    required this.subtitle,
    this.skipLoadingOnReload = false,
  });

  static const _cardWidth = 268.0;
  static const _railHeight = 320.0;

  final AsyncValue<List<SalonModel>> value;
  final String title;
  final String subtitle;
  final bool skipLoadingOnReload;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: skipLoadingOnReload,
      skipLoadingOnRefresh: skipLoadingOnReload,
      loading: () => _railShell(child: _railShimmer()),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return _railShell(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final salon = items[i];
              return Align(
                alignment: Alignment.topCenter,
                child: SalonCard(
                  key: ValueKey(salon.id),
                  salon: salon,
                  cardWidth: _cardWidth,
                  compactRating: true,
                  autoPlayImages: true,
                  showPromoChips: true,
                  onTap: () =>
                      context.push('${RoutePaths.customerSalons}/${salon.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _railShell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 14),
          SizedBox(height: _railHeight, child: child),
        ],
      ),
    );
  }

  Widget _railShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, __) => const Align(
        alignment: Alignment.topCenter,
        child: ShimmerBox(width: _cardWidth, height: _railHeight, radius: 16),
      ),
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

    final itemCount =
        state.items.length +
        (state.isLoadingMore ? 1 : 0) +
        (!state.hasMore && !state.isLoadingMore ? 1 : 0);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < state.items.length) {
            final salon = state.items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RepaintBoundary(
                child: SalonCard(
                  salon: salon,
                  autoPlayImages: true,
                  onTap: () =>
                      context.push('${RoutePaths.customerSalons}/${salon.id}'),
                  onBook: salon.hasServices
                      ? () => context.push(
                          '${RoutePaths.customerSalons}/${salon.id}/book',
                        )
                      : null,
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
        }, childCount: itemCount),
      ),
    );
  }
}
