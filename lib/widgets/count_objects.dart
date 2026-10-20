import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import 'art_image.dart';
import 'pressable.dart';

/// A row of countable objects drawn with the cartoon art (apple, strawberry, star, chick,
/// butterfly, bird). The child taps each one: it pops and gets a number badge in tapping order.
/// Used by the number lesson and the counting game, so new counting activities can reuse it.
class CountObjects extends StatelessWidget {
  const CountObjects({
    super.key,
    required this.count,
    required this.art,
    required this.counted,
    required this.onTap,
    this.size = 76,
  });

  final int count;

  /// One of [arts].
  final String art;

  /// Indexes already counted, in the order they were tapped.
  final Set<int> counted;
  final ValueChanged<int> onTap;
  final double size;

  static const arts = ['apple', 'strawberry', 'star', 'chick', 'butterfly', 'bird_blue'];
  static const _emoji = {
    'apple': '🍎',
    'strawberry': '🍓',
    'star': '⭐',
    'chick': '🐥',
    'butterfly': '🦋',
    'bird_blue': '🐦',
  };

  static String artFor(int seed) => arts[seed.abs() % arts.length];

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final order = counted.toList();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10 * u,
      runSpacing: 12 * u,
      children: [
        for (var i = 0; i < count; i++)
          Pressable(
            key: ValueKey('count_obj_$i'),
            sound: false,
            semanticLabel: '${i + 1}',
            onTap: () => onTap(i),
            child: AnimatedScale(
              scale: counted.contains(i) ? 1.15 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: size * u,
                  height: size * u,
                  padding: EdgeInsets.all(size * u * 0.1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: counted.contains(i) ? const Color(0xFFFFF0B8) : Colors.white.withValues(alpha: 0.88),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: ArtImage(
                    art,
                    fallback: Center(child: Text(_emoji[art] ?? '⭐', style: TextStyle(fontSize: size * u * 0.55))),
                  ),
                ),
                if (counted.contains(i))
                  PositionedDirectional(
                    top: -6 * u,
                    end: -6 * u,
                    child: Container(
                      width: 30 * u,
                      height: 30 * u,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text('${order.indexOf(i) + 1}', style: TextStyle(fontSize: 18 * u, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),
      ],
    );
  }
}
