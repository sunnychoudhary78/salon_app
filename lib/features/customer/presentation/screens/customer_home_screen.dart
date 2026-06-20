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

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _bannerController = PageController();
  final _homeScrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_loadMoreNearBottom);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedLocationProvider.notifier).ensureInitialized();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _bannerController.dispose();
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
    final auth = ref.watch(authProvider).value;
    final banners = ref.watch(bannersProvider);
    final forYouSalons = ref.watch(forYouSalonsProvider);
    final allSalons = ref.watch(paginatedSalonsProvider);
    final browseFilters = ref.watch(salonBrowseFiltersProvider);
    final firstName = auth?.user.name.split(' ').first ?? 'there';
    final isSearching = browseFilters.search.isNotEmpty;

    return Scaffold(
      appBar: PremiumAppBar(
        titleWidget: LocationAppBarTitle(
          onTap: () => showLocationPickerSheet(context, ref),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshProfile();
          ref.invalidate(bannersProvider);
          ref.invalidate(forYouSalonsProvider);
          ref.invalidate(paginatedSalonsProvider);
          final selected = ref.read(selectedLocationProvider).location;
          if (selected.source == LocationSource.gps) {
            await ref.read(selectedLocationProvider.notifier).refreshGps();
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
                  _CuratedBannersSection(
                    banners: banners,
                    controller: _bannerController,
                  ),
                  if (!isSearching) ...[
                    const SizedBox(height: 16),
                    AnimatedEntrance(
                      index: 1,
                      child: _ForYouSalonRailSection(value: forYouSalons),
                    ),
                  ],
                  if (!isSearching) const SizedBox(height: 30),
                  AnimatedEntrance(
                    index: 2,
                    child: SectionHeader(
                      title: 'All salons',
                      subtitle: isSearching
                          ? "Results for '${browseFilters.search}'"
                          : browseFilters.hasActiveFilters
                              ? 'Filtered results near you'
                              : 'Keep scrolling to discover more',
                    ),
                  ),
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            allSalons.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: EmptyView(
                  message: error.toString(),
                  icon: Icons.error_outline,
                ),
              ),
              data: (state) => _AllSalonsFeedSliver(state: state, emptyMessage: browseFilters.hasSearchOrFilters
                  ? 'No salons match your search or filters'
                  : 'No salons available yet'),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppDecorations.shellBottomInset),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuratedBannersSection extends StatelessWidget {
  const _CuratedBannersSection({
    required this.banners,
    required this.controller,
  });

  final AsyncValue<List<BannerModel>> banners;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return banners.when(
      loading: () => const SizedBox.shrink(),
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
                      controller: controller,
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
                                        _bannerFallback(),
                                  ),
                                )
                              else
                                _bannerFallback(),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      AppColors.backgroundDark.withValues(
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
                                      child: const Text(
                                        'OFFER',
                                        style: TextStyle(
                                          color: AppColors.backgroundDark,
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
                                            color: AppColors.textPrimary,
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
                        controller: controller,
                        count: items.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 6,
                          dotWidth: 6,
                          expansionFactor: 3,
                          spacing: 6,
                          activeDotColor: AppColors.accent,
                          dotColor: AppColors.glassBorder.withValues(
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

  Widget _bannerFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.surface,
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

class _ForYouSalonRailSection extends StatelessWidget {
  const _ForYouSalonRailSection({required this.value});

  final AsyncValue<List<SalonModel>> value;

  @override
  Widget build(BuildContext context) {
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    SalonCard(
                      salon: items[i],
                      cardWidth: 250,
                      imageHeight: 168,
                      showPromoChips: true,
                      compactRating: true,
                      alwaysShowSubtitle: true,
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
  });

  final PaginatedSalonsState state;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyView(
          message: emptyMessage,
          icon: Icons.store_outlined,
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
                      color: AppColors.textMuted,
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
