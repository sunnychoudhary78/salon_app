import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';

class SalonCubeImageSlider extends StatefulWidget {
  const SalonCubeImageSlider({
    super.key,
    required this.images,
    this.height = 260,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.autoPlayInterval = const Duration(seconds: 4),
  });

  final List<String> images;
  final double height;
  final BorderRadius borderRadius;
  final Duration autoPlayInterval;

  @override
  State<SalonCubeImageSlider> createState() => _SalonCubeImageSliderState();
}

class _SalonCubeImageSliderState extends State<SalonCubeImageSlider> {
  static const _transitionDuration = Duration(milliseconds: 650);

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() => setState(() {}));
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(SalonCubeImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _currentIndex = 0;
      _pageController.jumpToPage(0);
      _restartAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.images.length <= 1) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || _userDragging || widget.images.length <= 1) return;
      final next = (_currentIndex + 1) % widget.images.length;
      _pageController.animateToPage(
        next,
        duration: _transitionDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: _networkImage(images.first),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _userDragging = true;
                } else if (notification is ScrollEndNotification) {
                  _userDragging = false;
                  _restartAutoPlay();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double offset = 0;
                      if (_pageController.position.haveDimensions) {
                        offset =
                            (_pageController.page ?? _currentIndex.toDouble()) -
                                index;
                      }
                      final angle = offset.clamp(-1.0, 1.0) * math.pi * 0.45;
                      final scale = 1 - (offset.abs() * 0.08);

                      return Transform(
                        alignment: offset < 0
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: Transform.scale(
                          scale: scale.clamp(0.85, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: _networkImage(images[index]),
                  );
                },
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
    );
  }

  Widget _networkImage(String url) {
    return CachedNetworkImage(
      imageUrl: resolveImageUrl(url),
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (context, error, stackTrace) => Container(
        height: widget.height,
        color: AppColors.surface,
        child: const Center(
          child: Icon(
            Icons.storefront_rounded,
            size: 40,
            color: AppColors.accent,
          ),
        ),
      ),
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
      height: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.4),
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
      bottom: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 16 : 6,
            height: 6,
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
