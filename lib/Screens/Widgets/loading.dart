import 'package:flutter/material.dart';
import 'dart:math' as math;

// Gradient loading indicator
class GradientLoadingIndicator extends StatefulWidget {
  const GradientLoadingIndicator({super.key});

  @override
  State<GradientLoadingIndicator> createState() =>
      _GradientLoadingIndicatorState();
}

class _GradientLoadingIndicatorState extends State<GradientLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: const Size(80, 80), // Increased size
            painter: _GradientLoadingPainter(),
          ),
        );
      },
    );
  }
}

class _GradientLoadingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final Paint paint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.blue[50]!,
          Colors.blue[300]!,
          Colors.blue[400]!,
          Colors.blue[200]!,
          Colors.blue[100]!,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 1.5 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
