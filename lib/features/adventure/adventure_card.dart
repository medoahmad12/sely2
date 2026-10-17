import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/chunky.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import 'adventure_map_screen.dart';
import 'adventure_models.dart';
import 'forest_scene.dart';
import 'rabbit.dart';

/// Big call-to-action on the home screen: a little forest scene that opens the adventure map.
class AdventureCard extends StatelessWidget {
  const AdventureCard({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.app;
    final levels = AdventureMap.build(app.repo);
    final done = AdventureMap.doneCount(levels, app.progress);
    final started = done > 0;
    final title = context.tr(started ? 'adventure_continue' : 'adventure_start');
    return Pressable(
      onTap: () => Navigator.of(context).push(fadeRoute(const AdventureMapScreen())),
      semanticLabel: title,
      child: ChunkyBox(
        key: const ValueKey('adventure_card'),
        color: const Color(0xFF39C0F5),
        radius: 34 * u,
        depth: 8 * u,
        clip: true,
        gloss: false,
        height: 168 * u,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _SceneCardPainter())),
          Positioned(
            left: 8 * u,
            bottom: 0,
            child: Rabbit(size: 138 * u, mood: RabbitMood.happy),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: 150 * u, end: 14 * u, top: 12 * u, bottom: 12 * u),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  title,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 27 * u,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    shadows: const [Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                ),
                SizedBox(height: 4 * u),
                Text(
                  context.tr('adventure_sub'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16 * u,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: const [Shadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1))],
                  ),
                ),
                SizedBox(height: 10 * u),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10 * u),
                      child: LinearProgressIndicator(
                        value: levels.isEmpty ? 0 : done / levels.length,
                        minHeight: 12 * u,
                        backgroundColor: Colors.white.withValues(alpha: 0.45),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * u),
                  Pulse(
                    child: ChunkyBox(
                      circle: true,
                      color: AppColors.orange,
                      width: 58 * u,
                      height: 58 * u,
                      depth: 5 * u,
                      child: Center(child: Icon(Icons.play_arrow_rounded, size: 40 * u, color: Colors.white)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Sky, sun and two rolling hills behind the rabbit.
class _SceneCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF39C0F5), Color(0xFFB8EDFF)],
        ).createShader(Offset.zero & size),
    );
    drawSun(canvas, Offset(w * 0.9, h * 0.2), h * 0.1, 0.1);
    drawCloud(canvas, Offset(w * 0.55, h * 0.22), h * 0.08, alpha: 0.9);
    drawCloud(canvas, Offset(w * 0.78, h * 0.42), h * 0.055, alpha: 0.75);
    for (final layer in [
      (0.62, 0.05, ForestPalette.hillFar, 1.2),
      (0.76, 0.045, ForestPalette.hillMid, 1.7),
    ]) {
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w + 6; x += 6) {
        path.lineTo(x, h * layer.$1 + math.sin(x / w * 2 * math.pi * layer.$4 + 1) * h * layer.$2);
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = layer.$3);
    }
    drawTree(canvas, Offset(w * 0.62, h * 0.86), h * 0.42, 0.3);
    drawTree(canvas, Offset(w * 0.78, h * 0.9), h * 0.34, -0.2, variant: 1);
  }

  @override
  bool shouldRepaint(_SceneCardPainter old) => false;
}
