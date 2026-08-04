import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SalonCubeImageSlider extends ConsumerStatefulWidget {
  const SalonCubeImageSlider({
    super.key,
    required this.images,
    this.height = 260,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.autoPlayInterval = const Duration(seconds: 4),
    this.sliderKey,
    this.showDotIndicator = true,
    this.onPageChanged,
  });

  final List<String> images;
  final double height;
  final BorderRadius borderRadius;
  final Duration autoPlayInterval;
  final String? sliderKey;
  final bool showDotIndicator;
  final ValueChanged<int>? onPageChanged;

  @override
  ConsumerState<SalonCubeImageSlider> createState() =>
      _SalonCubeImageSliderState();
}

class _SalonCubeImageSliderState extends ConsumerState<SalonCubeImageSlider> {
  static const _transitionDuration = Duration(milliseconds: 450);

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;
  bool _userDragging = false;
  bool _isVisible = false;
  bool _userIdle = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userIdle = ref.read(userIdleProvider);
  }

  @override
  void didUpdateWidget(SalonCubeImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameImages(oldWidget.images, widget.images)) {
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _restartAutoPlay();
    }
  }

  bool _sameImages(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _setVisible(bool visible) {
    if (_disposed || !mounted || _isVisible == visible) return;
    _isVisible = visible;
    if (visible) {
      _startAutoPlay();
    } else {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
    }
  }

  bool get _shouldAutoPlay =>
      !_disposed &&
      mounted &&
      _isVisible &&
      !_userDragging &&
      !_userIdle &&
      widget.images.length > 1;

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (!_shouldAutoPlay) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!_shouldAutoPlay || !_pageController.hasClients) return;
      final next = (_currentIndex + 1) % widget.images.length;
      _pageController.animateToPage(
        next,
        duration: _transitionDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _restartAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (!_disposed && mounted) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(userIdleProvider, (previous, next) {
      if (_disposed || !mounted) return;
      _userIdle = next;
      if (next) {
        _autoPlayTimer?.cancel();
        _autoPlayTimer = null;
      } else if (_isVisible) {
        _startAutoPlay();
      }
    });

    final images = widget.images;
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: _networkImage(images.first),
      );
    }

    final visibilityKey = widget.sliderKey ?? images.first;

    return VisibilityDetector(
      key: Key('salon-cube-slider-$visibilityKey'),
      onVisibilityChanged: (info) {
        if (_disposed || !mounted) return;
        _setVisible(info.visibleFraction > 0.5);
      },
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_disposed || !mounted) return false;
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
                  onPageChanged: (index) {
                    if (_disposed || !mounted) return;
                    setState(() => _currentIndex = index);
                    widget.onPageChanged?.call(index);
                  },
                  itemBuilder: (context, index) => _networkImage(images[index]),
                ),
              ),
              if (widget.showDotIndicator) ...[
                const _BottomGradientOverlay(),
                _DotIndicator(
                  count: images.length,
                  currentIndex: _currentIndex,
                ),
              ],
            ],
          ),
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
        color: context.appColors.surface,
        child: Center(
          child: Icon(
            Icons.storefront_rounded,
            size: 40,
            color: context.appColors.accent,
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
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.currentIndex});

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
                  ? context.appColors.accent
                  : Colors.white.withValues(alpha: 0.45),
            ),
          );
        }),
      ),
    );
  }
}
