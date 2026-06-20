import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SalonCardImageCarousel extends StatefulWidget {
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
  State<SalonCardImageCarousel> createState() => _SalonCardImageCarouselState();
}

class _SalonCardImageCarouselState extends State<SalonCardImageCarousel> {
  static const _transitionDuration = Duration(milliseconds: 500);
  static final _random = Random();

  Timer? _timer;
  int _currentIndex = 0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoplay();
  }

  @override
  void didUpdateWidget(SalonCardImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images ||
        oldWidget.autoPlay != widget.autoPlay) {
      _stopAutoplay();
      _currentIndex = 0;
      _scheduleAutoplay();
    }
  }

  void setVisible(bool visible) {
    if (_isVisible == visible) return;
    _isVisible = visible;
    if (visible) {
      _scheduleAutoplay();
    } else {
      _stopAutoplay();
    }
  }

  Duration _randomInterval() {
    final seconds = 2.5 + _random.nextDouble() * 2.5;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  void _scheduleAutoplay() {
    _stopAutoplay();
    if (!_isVisible || !widget.autoPlay || widget.images.length <= 1) return;

    _timer = Timer(_randomInterval(), () {
      if (!mounted || !_isVisible) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
      _scheduleAutoplay();
    });
  }

  void _stopAutoplay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAutoplay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final radius = widget.borderRadius ?? BorderRadius.zero;

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: widget.placeholder ?? _defaultPlaceholder(),
      );
    }

    if (images.length == 1 || !widget.autoPlay) {
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
          color: AppColors.surface,
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
          widget.placeholder ?? _defaultPlaceholder(),
    );
  }

  Widget _defaultPlaceholder({bool showIcon = true}) => Container(
        height: widget.height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surface, AppColors.surfaceElevated],
          ),
        ),
        child: showIcon
            ? const Center(
                child: Icon(
                  Icons.storefront_rounded,
                  size: 36,
                  color: AppColors.accent,
                ),
              )
            : null,
      );
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
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.35),
            ],
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
  });

  final int count;
  final int currentIndex;

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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: isActive ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: isActive
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.45),
            ),
          );
        }),
      ),
    );
  }
}
