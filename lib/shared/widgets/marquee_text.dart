import 'package:flutter/material.dart';

/// Single-line text that scrolls horizontally when it exceeds the available width.
class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.blankSpace = 40,
    this.velocity = 28,
    this.pauseDuration = const Duration(milliseconds: 900),
  });

  final String text;
  final TextStyle style;

  /// Gap between the end of the text and its repeat while scrolling.
  final double blankSpace;

  /// Scroll speed in logical pixels per second.
  final double velocity;

  /// Pause before each scroll cycle starts.
  final Duration pauseDuration;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _textWidth = 0;
  double _containerWidth = 0;
  bool _needsScroll = false;
  bool _loopRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.blankSpace != widget.blankSpace ||
        oldWidget.velocity != widget.velocity) {
      _resetMeasurement();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetMeasurement() {
    _controller.stop();
    _controller.reset();
    _loopRunning = false;
    _textWidth = 0;
    _containerWidth = 0;
    _needsScroll = false;
  }

  double _measureTextWidth() {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  void _updateMetrics(double maxWidth) {
    final textWidth = _measureTextWidth();
    final needsScroll = textWidth > maxWidth + 0.5;

    if (textWidth == _textWidth &&
        maxWidth == _containerWidth &&
        needsScroll == _needsScroll) {
      return;
    }

    setState(() {
      _textWidth = textWidth;
      _containerWidth = maxWidth;
      _needsScroll = needsScroll;
    });

    if (!needsScroll) {
      _controller.stop();
      _controller.reset();
      _loopRunning = false;
      return;
    }

    final scrollDistance = textWidth + widget.blankSpace;
    final ms = ((scrollDistance / widget.velocity) * 1000).round().clamp(
      800,
      20000,
    );
    _controller.duration = Duration(milliseconds: ms);
    _startLoop();
  }

  Future<void> _startLoop() async {
    if (_loopRunning) return;
    _loopRunning = true;

    while (mounted && _needsScroll) {
      await Future<void>.delayed(widget.pauseDuration);
      if (!mounted || !_needsScroll) break;
      await _controller.forward(from: 0);
      if (!mounted || !_needsScroll) break;
      _controller.reset();
    }

    _loopRunning = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !maxWidth.isFinite || maxWidth <= 0) return;
          _updateMetrics(maxWidth);
        });

        if (!_needsScroll) {
          return Text(
            widget.text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        return ClipRect(
          child: SizedBox(
            height: (widget.style.fontSize ?? 14) * (widget.style.height ?? 1.2),
            width: maxWidth,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset =
                    _controller.value * (_textWidth + widget.blankSpace);
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Transform.translate(
                      offset: Offset(-offset, 0),
                      child: child,
                    ),
                    Transform.translate(
                      offset: Offset(
                        -offset + _textWidth + widget.blankSpace,
                        0,
                      ),
                      child: child,
                    ),
                  ],
                );
              },
              child: Text(
                widget.text,
                maxLines: 1,
                softWrap: false,
                style: widget.style,
              ),
            ),
          ),
        );
      },
    );
  }
}
