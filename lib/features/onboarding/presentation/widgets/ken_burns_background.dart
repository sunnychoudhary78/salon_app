import 'package:flutter/material.dart';

class KenBurnsBackground extends StatefulWidget {
  const KenBurnsBackground({
    super.key,
    required this.imagePath,
    required this.isActive,
    this.alignment = Alignment.center,
  });

  final String imagePath;
  final bool isActive;
  final Alignment alignment;

  @override
  State<KenBurnsBackground> createState() => _KenBurnsBackgroundState();
}

class _KenBurnsBackgroundState extends State<KenBurnsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(KenBurnsBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller
        ..reset()
        ..forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return ClipRect(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: widget.alignment,
            child: child,
          );
        },
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
            width: size.width * 1.15,
            height: size.height * 1.15,
            alignment: widget.alignment,
          ),
        ),
      ),
    );
  }
}
