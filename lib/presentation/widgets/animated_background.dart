import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/config/theme_config.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Movement animations - slow and organic
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    // Pulse controller for blur/opacity ebbing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base white background
        Container(color: Colors.white),

        // Animated blobs
        AnimatedBuilder(
          animation: Listenable.merge([
            _controller1,
            _controller2,
            _controller3,
            _pulseController,
          ]),
          builder: (context, _) {
            return CustomPaint(
              painter: _FlowingBackgroundPainter(
                animation1: _controller1.value,
                animation2: _controller2.value,
                animation3: _controller3.value,
                pulseValue: _pulseController.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _FlowingBackgroundPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final double pulseValue;

  _FlowingBackgroundPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Primary purple blob - top right area
    _drawFlowingBlob(
      canvas: canvas,
      center: Offset(
        width * 0.75 + math.sin(animation1 * 2 * math.pi) * width * 0.12,
        height * 0.18 + math.cos(animation1 * 2 * math.pi) * height * 0.1,
      ),
      radius: width * 0.55,
      color: ThemeConfig.primaryColor,
      baseOpacity: 0.18,
      animation: animation1,
      stretch: 1.4,
      blurPhase: 0,
    );

    // Secondary purple blob - bottom left
    _drawFlowingBlob(
      canvas: canvas,
      center: Offset(
        width * 0.08 + math.cos(animation2 * 2 * math.pi) * width * 0.15,
        height * 0.82 + math.sin(animation2 * 2 * math.pi) * height * 0.12,
      ),
      radius: width * 0.5,
      color: ThemeConfig.primaryLight,
      baseOpacity: 0.15,
      animation: animation2,
      stretch: 1.3,
      blurPhase: 0.33,
    );

    // Teal blob - center left
    _drawFlowingBlob(
      canvas: canvas,
      center: Offset(
        width * 0.15 + math.sin(animation3 * 2 * math.pi + math.pi / 3) * width * 0.1,
        height * 0.45 + math.cos(animation3 * 2 * math.pi) * height * 0.15,
      ),
      radius: width * 0.45,
      color: ThemeConfig.secondaryColor,
      baseOpacity: 0.14,
      animation: animation3,
      stretch: 1.5,
      blurPhase: 0.66,
    );

    // Teal accent - top left
    _drawFlowingBlob(
      canvas: canvas,
      center: Offset(
        width * 0.2 + math.cos(animation1 * 2 * math.pi + math.pi) * width * 0.08,
        height * 0.08 + math.sin(animation1 * 2 * math.pi) * height * 0.06,
      ),
      radius: width * 0.3,
      color: ThemeConfig.secondaryLight,
      baseOpacity: 0.12,
      animation: animation1,
      stretch: 1.2,
      blurPhase: 0.5,
    );

    // Purple accent - bottom right
    _drawFlowingBlob(
      canvas: canvas,
      center: Offset(
        width * 0.88 + math.sin(animation2 * 2 * math.pi) * width * 0.08,
        height * 0.68 + math.cos(animation2 * 2 * math.pi + math.pi / 2) * height * 0.1,
      ),
      radius: width * 0.4,
      color: ThemeConfig.primaryColor,
      baseOpacity: 0.12,
      animation: animation2,
      stretch: 1.35,
      blurPhase: 0.8,
    );

    // Extra teal blob - center right for more coverage
    _drawFlowingBlob(
      canvas: canvas,
      center: Offset(
        width * 0.7 + math.cos(animation3 * 2 * math.pi) * width * 0.1,
        height * 0.5 + math.sin(animation3 * 2 * math.pi + math.pi / 4) * height * 0.12,
      ),
      radius: width * 0.35,
      color: ThemeConfig.secondaryColor,
      baseOpacity: 0.1,
      animation: animation3,
      stretch: 1.25,
      blurPhase: 0.15,
    );
  }

  void _drawFlowingBlob({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
    required double baseOpacity,
    required double animation,
    required double stretch,
    required double blurPhase,
  }) {
    // Create phase-offset pulsing for each blob
    final phasedPulse = (pulseValue + blurPhase) % 1.0;

    // Smooth easing curve for the pulse
    final easedPulse = _smoothStep(phasedPulse);

    // Blur ranges from tight (more solid) to diffuse (more blurred)
    final minBlur = 30.0;
    final maxBlur = 100.0;
    final currentBlur = minBlur + (maxBlur - minBlur) * easedPulse;

    // Opacity increases slightly when more solid, decreases when diffuse
    final opacityMultiplier = 1.0 + (1.0 - easedPulse) * 0.4;
    final currentOpacity = (baseOpacity * opacityMultiplier).clamp(0.0, 0.35);

    // Size pulses inversely with blur (smaller when solid, larger when diffuse)
    final sizeMultiplier = 0.85 + easedPulse * 0.3;

    final paint = Paint()
      ..color = color.withValues(alpha: currentOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentBlur);

    // Main ellipse with animation-driven distortion
    final animatedRadius = radius * sizeMultiplier;
    final rect = Rect.fromCenter(
      center: center,
      width: animatedRadius * stretch * (1 + 0.15 * math.sin(animation * 4 * math.pi)),
      height: animatedRadius * (1 + 0.15 * math.cos(animation * 4 * math.pi)),
    );

    // Rotate the blob slowly
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation * 0.6 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    final path = Path()..addOval(rect);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  // Attempt at smooth step function for organic easing
  double _smoothStep(double t) {
    // Attempt at smooth step for organic easing
    return t * t * (3 - 2 * t);
  }

  @override
  bool shouldRepaint(covariant _FlowingBackgroundPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2 ||
        oldDelegate.animation3 != animation3 ||
        oldDelegate.pulseValue != pulseValue;
  }
}
