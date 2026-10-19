import 'package:flutter/material.dart';

/// A picture from `assets/images/art/<name>.png` (cartoon characters and props).
/// If the file is missing the [fallback] is shown instead, so the app never breaks
/// when an illustration has not been added yet.
class ArtImage extends StatelessWidget {
  const ArtImage(this.name, {super.key, this.height, this.width, this.fallback});
  final String name;
  final double? height;
  final double? width;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/art/$name.png',
      height: height,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => fallback ?? SizedBox(width: width, height: height),
    );
  }
}

/// A star from the art set; an unlit star is grey and see-through (used for ratings).
class StarArt extends StatelessWidget {
  const StarArt({super.key, required this.size, this.lit = true});
  final double size;
  final bool lit;

  static const _grey = ColorFilter.matrix(<double>[
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0,
    0.33, 0.33, 0.33, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final star = ArtImage('star', width: size, height: size, fallback: Icon(Icons.star_rounded, size: size, color: const Color(0xFFFFC21A)));
    if (lit) return star;
    return Opacity(opacity: 0.55, child: ColorFiltered(colorFilter: _grey, child: star));
  }
}
