import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/lifecycle/carousel_autoplay_lease.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SalonCardImageCarousel extends ConsumerStatefulWidget {
  const SalonCardImageCarousel({
    super.key,
    required this.images,
    required this.height,
    required this.salonId,
    this.borderRadius,
    this.autoPlay = true,
    this.placeholder,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final List<String> images;
  final double height;
  final String salonId;
  final BorderRadius? borderRadius;
  final bool autoPlay;
  final Widget? placeholder;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  ConsumerState<SalonCardImageCarousel> createState() =>
      _SalonCardImageCarouselState();
}

class _SalonCardImageCarouselState
    extends ConsumerState<SalonCardImageCarousel> {
  static const _transitionDuration = Duration(milliseconds: 500);

  Timer? _timer;
  int _currentIndex = 0;
  bool _isVisible = false;
  bool _hasLease = false;
  ProviderContainer? _container;
  String? _leasedSalonId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
  }

  @override
  void didUpdateWidget(SalonCardImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.salonId != widget.salonId) {
      _scheduleReleaseLease(oldWidget.salonId);
      _hasLease = false;
      _leasedSalonId = null;
    }
    if (oldWidget.images != widget.images ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.salonId != widget.salonId) {
      _stopAutoplay();
      _currentIndex = 0;
      _scheduleReleaseLease(widget.salonId);
      _hasLease = false;
      _leasedSalonId = null;
      _queueAutoplay();
    }
  }

  void setVisible(bool visible) {
    if (_isVisible == visible) return;
    _isVisible = visible;
    if (visible) {
      _queueAutoplay();
    } else {
      _stopAutoplay();
      _scheduleReleaseLease(widget.salonId);
      _hasLease = false;
      _leasedSalonId = null;
    }
  }

  bool _computeShouldAutoplay({required bool userIdle}) {
    return _isVisible &&
        widget.autoPlay &&
        widget.images.length > 1 &&
        !userIdle &&
        _hasLease;
  }

  void _scheduleReleaseLease(String salonId) {
    final container = _container;
    if (container == null) return;
    // Never mutate providers synchronously from lifecycle / listen / dispose.
    Future.microtask(() {
      container.read(carouselAutoplayLeaseProvider.notifier).release(salonId);
    });
  }

  void _scheduleAcquireLease() {
    final container = _container;
    if (container == null || !widget.autoPlay || widget.images.length <= 1) {
      return;
    }
    final salonId = widget.salonId;
    Future.microtask(() {
      if (!mounted || !_isVisible) return;
      final acquired = container
          .read(carouselAutoplayLeaseProvider.notifier)
          .tryAcquire(salonId);
      if (!mounted) {
        if (acquired) {
          container.read(carouselAutoplayLeaseProvider.notifier).release(salonId);
        }
        return;
      }
      _hasLease = acquired;
      _leasedSalonId = acquired ? salonId : null;
      if (acquired) {
        _startTimerIfReady();
      }
    });
  }

  void _queueAutoplay() {
    // Defer so we never acquire/read providers mid-build or mid-lifecycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAutoplaySafe();
    });
  }

  void _startAutoplaySafe() {
    _stopAutoplay();
    if (!_isVisible || !widget.autoPlay || widget.images.length <= 1) return;

    final container = _container;
    if (container == null) return;

    final userIdle = container.read(userIdleProvider);
    if (userIdle) return;

    if (!_hasLease) {
      _scheduleAcquireLease();
      return;
    }

    _startTimerIfReady();
  }

  void _startTimerIfReady() {
    final container = _container;
    if (container == null || !mounted) return;
    final userIdle = container.read(userIdleProvider);
    if (!_computeShouldAutoplay(userIdle: userIdle)) return;

    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      final idle = _container?.read(userIdleProvider) ?? true;
      if (!_computeShouldAutoplay(userIdle: idle)) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
      _startAutoplaySafe();
    });
  }

  void _stopAutoplay() {
    _timer?.cancel();
    _timer = null;
  }

  void _showImage(int index) {
    setState(() {
      _currentIndex = index % widget.images.length;
    });
    if (widget.autoPlay && _isVisible) {
      _queueAutoplay();
    }
  }

  @override
  void dispose() {
    _stopAutoplay();
    final leasedId = _leasedSalonId ?? (_hasLease ? widget.salonId : null);
    final container = _container;
    _hasLease = false;
    _leasedSalonId = null;
    if (leasedId != null && container != null) {
      Future.microtask(() {
        container.read(carouselAutoplayLeaseProvider.notifier).release(leasedId);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userIdleProvider, (previous, next) {
      // Defer mutations — listen can fire during provider/widget flush.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (next) {
          _stopAutoplay();
          _scheduleReleaseLease(widget.salonId);
          _hasLease = false;
          _leasedSalonId = null;
        } else if (_isVisible) {
          _startAutoplaySafe();
        }
      });
    });

    ref.listen(carouselAutoplayLeaseProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (next != widget.salonId && _hasLease) {
          _hasLease = false;
          _leasedSalonId = null;
          _stopAutoplay();
        } else if (next == widget.salonId && _isVisible) {
          _hasLease = true;
          _leasedSalonId = widget.salonId;
          _startAutoplaySafe();
        }
      });
    });

    final images = widget.images;
    final radius = widget.borderRadius ?? BorderRadius.zero;

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: widget.placeholder ?? _defaultPlaceholder(context),
      );
    }

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: _networkImage(images.first),
      );
    }

    return VisibilityDetector(
      key: Key('salon-carousel-${widget.salonId}'),
      onVisibilityChanged: (info) {
        setVisible(info.visibleFraction > 0.5);
      },
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: _transitionDuration,
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: _networkImage(
                  images[_currentIndex],
                  key: ValueKey(_currentIndex),
                ),
              ),
              const _BottomGradientOverlay(),
              _DotIndicator(
                count: images.length,
                currentIndex: _currentIndex,
                onDotTap: _showImage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _networkImage(String url, {Key? key}) {
    return CachedNetworkImage(
      key: key,
      imageUrl: resolveImageUrl(url),
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      progressIndicatorBuilder: (context, _, progress) {
        final loading = Container(
          height: widget.height,
          width: double.infinity,
          color: context.appColors.surface,
          alignment: Alignment.center,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.progress,
            ),
          ),
        );
        return widget.placeholder ?? loading;
      },
      errorWidget: (context, error, stackTrace) =>
          widget.placeholder ?? _defaultPlaceholder(context),
    );
  }

  Widget _defaultPlaceholder(BuildContext context, {bool showIcon = true}) {
    final colors = context.appColors;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceElevated],
        ),
      ),
      child: showIcon
          ? Center(
              child: Icon(
                Icons.storefront_rounded,
                size: 36,
                color: context.appColors.accent,
              ),
            )
          : null,
    );
  }
}

class _BottomGradientOverlay extends StatelessWidget {
  const _BottomGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.count,
    required this.currentIndex,
    required this.onDotTap,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDotTap(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? context.appColors.accent
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
