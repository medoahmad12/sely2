import 'package:flutter/material.dart';

Color darken(Color c, [double amount = 0.14]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0).toDouble()).toColor();
}

Color lighten(Color c, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0).toDouble()).toColor();
}

/// The "toy button" look used everywhere: a gradient face, a soft glossy highlight on
/// top, a solid darker edge underneath (so it looks thick) and a soft drop shadow.
/// The edge is a shadow, so it never changes the layout size.
class ChunkyBox extends StatelessWidget {
  const ChunkyBox({
    super.key,
    required this.color,
    required this.child,
    this.radius = 28,
    this.depth = 6,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.circle = false,
    this.gloss = true,
    this.clip = false,
    this.shadow = true,
    this.borderColor,
    this.borderWidth = 0,
  });
  final Color color;
  final Widget child;
  final double radius;
  final double depth;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool circle;
  final bool gloss;

  /// Clip the content to the shape (needed when the child paints outside the box).
  final bool clip;
  final bool shadow;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final edge = darken(color, 0.17);
    final top = lighten(color, 0.07);
    final borderRadius = circle ? null : BorderRadius.circular(radius);
    final shape = circle ? BoxShape.circle : BoxShape.rectangle;

    Widget content = Padding(padding: padding, child: child);
    if (gloss) {
      content = Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: borderRadius,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x44FFFFFF), Color(0x00FFFFFF)],
                  stops: [0.0, 0.55],
                ),
              ),
            ),
          ),
        ),
        content,
      ]);
    }
    if (clip) {
      content = circle ? ClipOval(child: content) : ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: borderRadius,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, color]),
        border: borderWidth > 0 ? Border.all(color: borderColor ?? Colors.white, width: borderWidth) : null,
        boxShadow: depth <= 0
            ? null
            : [
                BoxShadow(color: edge, offset: Offset(0, depth)),
                if (shadow) BoxShadow(color: const Color(0x33000000), blurRadius: 14, offset: Offset(0, depth + 6)),
              ],
      ),
      child: content,
    );
  }
}
