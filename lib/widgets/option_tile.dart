import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';
import 'chunky.dart';
import 'effects.dart';
import 'pressable.dart';

enum TileState { normal, wrong, hint, done, selected }

/// Big rounded card used for answer choices, letters and pictures.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.size,
    required this.child,
    required this.onTap,
    this.state = TileState.normal,
    this.color = Colors.white,
    this.shakeTrigger = 0,
    this.semanticLabel,
  });
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  final TileState state;
  final Color color;
  final int shakeTrigger;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      TileState.selected => const Color(0xFFFF9F1C),
      TileState.done => const Color(0xFF3FBF4A),
      TileState.hint => const Color(0xFFFFD43B),
      _ => Colors.transparent,
    };
    final wrong = state == TileState.wrong;
    Widget tile = ChunkyBox(
      width: size,
      height: size,
      color: wrong ? color.withValues(alpha: 0.45) : color,
      radius: AppRadius.card,
      depth: wrong ? 0 : size * 0.04,
      gloss: !wrong,
      shadow: !wrong,
      borderColor: border,
      borderWidth: border == Colors.transparent ? 0 : 5,
      padding: EdgeInsets.all(size * 0.08),
      child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: child)),
    );
    if (state == TileState.hint) tile = Pulse(child: tile);
    return Shake(
      trigger: shakeTrigger,
      child: Pressable(
        onTap: (state == TileState.wrong || state == TileState.done) ? null : onTap,
        semanticLabel: semanticLabel,
        child: Opacity(opacity: state == TileState.done ? 0.65 : 1, child: tile),
      ),
    );
  }
}
