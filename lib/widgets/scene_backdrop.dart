import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Living background for every screen: a soft gradient with slow clouds, rising bubbles
/// and twinkling sparkles. One cheap repainting layer, content is drawn on top.
class SceneBackdrop extends StatefulWidget {
  const SceneBackdrop({super.key, required this.colors, this.child});
  final List<Color> colors;
  final Widget? child;

  @override
  State<SceneBackdrop> createState() => _SceneBackdropState();
}

class _SceneBackdropState extends State<SceneBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(painter: _BackdropPainter(widget.colors, _c.value)),
          ),
        ),
      ),
      if (widget.child != null) Positioned.fill(child: widget.child!),
    ]);
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.colors, this.phase);
  final List<Color> colors;
  final double phase;

  void _cloud(Canvas canvas, Offset c, double s, double alpha) {
    final p = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawCircle(c + Offset(-0.9 * s, 0.1 * s), 0.55 * s, p);
    canvas.drawCircle(c + Offset(-0.2 * s, -0.3 * s), 0.75 * s, p);
    canvas.drawCircle(c + Offset(0.7 * s, 0.0), 0.6 * s, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + Offset(-0.1 * s, 0.35 * s), width: 2.8 * s, height: 0.7 * s),
        Radius.circular(0.35 * s),
      ),
      p,
    );
  }

  void _sparkle(Canvas canvas, Offset c, double r, double alpha) {
    final p = Paint()..color = Colors.white.withValues(alpha: alpha);
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tau = 2 * math.pi;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)
            .createShader(Offset.zero & size),
    );

    // clouds drifting right, wrapping around (whole numbers of laps per cycle = seamless)
    for (var i = 0; i < 3; i++) {
      final x = ((phase * (i + 1) + i * 0.4) % 1.0 * 1.4 - 0.2) * w;
      _cloud(canvas, Offset(x, h * (0.12 + 0.2 * i)), w * (0.07 + 0.015 * i), 0.5);
    }

    // bubbles rising
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.4);
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.14);
    for (var i = 0; i < 12; i++) {
      final t = (phase * (1 + i % 3) + i * 0.083) % 1.0;
      final x = w * ((i * 0.37) % 1.0) + math.sin(t * tau * 2 + i) * w * 0.02;
      final y = h * (1.05 - t * 1.15);
      final r = w * (0.012 + 0.008 * (i % 4));
      canvas.drawCircle(Offset(x, y), r, fill);
      canvas.drawCircle(Offset(x, y), r, ring);
    }

    // sparkles
    for (var i = 0; i < 7; i++) {
      final tw = 0.5 + 0.5 * math.sin(phase * tau * 4 + i * 1.7);
      _sparkle(canvas, Offset(w * ((i * 0.61 + 0.1) % 1.0), h * ((i * 0.29 + 0.05) % 0.9)), w * (0.012 + 0.006 * (i % 3)), 0.15 + 0.4 * tw);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.phase != phase || old.colors != colors;
}
