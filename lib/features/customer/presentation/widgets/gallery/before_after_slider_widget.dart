import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';

class BeforeAfterSliderWidget extends StatefulWidget {
  const BeforeAfterSliderWidget({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.height = 300,
    this.initialPosition = 0.5,
    this.borderRadius = 16,
  });

  final String beforeImageUrl;
  final String afterImageUrl;
  final double height;
  final double initialPosition;
  final double borderRadius;

  @override
  State<BeforeAfterSliderWidget> createState() => _BeforeAfterSliderWidgetState();
}

class _BeforeAfterSliderWidgetState extends State<BeforeAfterSliderWidget> {
  late double _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition.clamp(0.0, 1.0);
  }

  void _updatePosition(double localDx, double width) {
    if (width <= 0) return;
    setState(() {
      _position = (localDx / width).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBefore = resolveImageUrl(widget.beforeImageUrl);
    final resolvedAfter = resolveImageUrl(widget.afterImageUrl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              _updatePosition(details.localPosition.dx, width);
            },
            onTapDown: (details) {
              _updatePosition(details.localPosition.dx, width);
            },
            child: SizedBox(
              width: width,
              height: widget.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. After Image (Background full)
                  CachedNetworkImage(
                    imageUrl: resolvedAfter,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _buildPlaceholder(),
                    errorWidget: (_, _, _) => _buildErrorWidget('After'),
                  ),

                  // 2. Before Image (Clipped on top based on _position)
                  ClipRect(
                    clipper: _HorizontalSplitClipper(_position),
                    child: CachedNetworkImage(
                      imageUrl: resolvedBefore,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _buildPlaceholder(),
                      errorWidget: (_, _, _) => _buildErrorWidget('Before'),
                    ),
                  ),

                  // 3. Before Badge (Top Left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildLabelBadge('BEFORE', Colors.black.withValues(alpha: 0.6)),
                  ),

                  // 4. After Badge (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildLabelBadge('AFTER', Theme.of(context).primaryColor.withValues(alpha: 0.85)),
                  ),

                  // 5. Divider Line & Slider Thumb
                  Positioned(
                    left: (width * _position) - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: Colors.white,
                    ),
                  ),

                  // 6. Center Drag Knob
                  Positioned(
                    left: (width * _position) - 18,
                    top: (widget.height / 2) - 18,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.unfold_more_rounded,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelBadge(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget(String label) {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 32),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  const _HorizontalSplitClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_HorizontalSplitClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}

