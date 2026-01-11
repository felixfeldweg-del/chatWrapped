import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CountUpAnimation extends StatefulWidget {
  final int endValue;
  final Duration duration;
  final bool precentage;
  final double fontSize;
  const CountUpAnimation({
    super.key,
    required this.endValue,
    this.duration = const Duration(seconds: 3),
    this.precentage = false,
    this.fontSize = 100
  });

  @override
  State<CountUpAnimation> createState() => _CountUpAnimationState();
}

class _CountUpAnimationState extends State<CountUpAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = IntTween(begin: 0, end: widget.endValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _startAnimation() {
    if (!_hasAnimated) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key:UniqueKey(),
      onVisibilityChanged: (info) {
        // Startet Animation wenn mindestens 50% sichtbar
        if (info.visibleFraction > 0.5) {
          _startAnimation();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Text(
            widget.precentage ? '${_animation.value}%' : '${_animation.value}' ,
            style: GoogleFonts.fugazOne(fontSize: widget.fontSize),
          );
        },
      ),
    );
  }
}