import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/chunky.dart';
import '../../widgets/effects.dart';
import '../../widgets/hold_to_unlock.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/speech_bubble.dart';
import '../adventure/adventure_card.dart';
import '../arabic/arabic_world.dart';
import '../colors_shapes/colors_shapes_world.dart';
import '../english/english_world.dart';
import '../games/games_hub.dart';
import '../math/math_world.dart';
import '../math/numbers_world.dart';
import '../parent/parent_screen.dart';
import '../rewards/rewards_screen.dart';

/// SELY WORLD: the interactive home with one big tile per learning world.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.read(context);
      if (!app.greeted) {
        app.greeted = true;
        _greet();
      }
    });
  }

  String _greeting(BuildContext context) =>
      context.tr('home_greet', {'name': context.app.progress.profile?.name ?? ''});

  void _greet() {
    final app = AppScope.read(context);
    final name = app.progress.profile?.name ?? '';
    app.audio.speak('home_greet', app.strings.get('home_greet', {'name': name}), lang: app.progress.locale, folder: 'ui');
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final p = context.app.progress;
    final worlds = <_World>[
      _World('📚', 'world_arabic', AppColors.primary, p.percent(['ar']), () => const ArabicWorldScreen()),
      _World('🔢', 'world_numbers', AppColors.purple, p.percent(['num']), () => const NumbersWorldScreen()),
      _World('➕', 'world_math', AppColors.green, p.percent(['add', 'sub']), () => const MathWorldScreen()),
      _World('🇬🇧', 'world_english', AppColors.orange, p.percent(['en']), () => const EnglishWorldScreen()),
      _World('🎨', 'world_colors', AppColors.pink, p.percent(['col', 'shp']), () => const ColorsShapesWorldScreen()),
      _World('🧠', 'world_games', const Color(0xFF00B8A9), null, () => const GamesHubScreen()),
      _World('🏆', 'world_rewards', const Color(0xFFFFB400), null, () => const RewardsScreen()),
    ];
    return KidScaffold(
      title: context.tr('app_name'),
      showBack: false,
      actions: [
        HoldToUnlock(
          semanticLabel: '${context.tr('parent_title')} - ${context.tr('parent_hold')}',
          onUnlocked: () => Navigator.of(context).push(fadeRoute(const ParentScreen())),
        ),
      ],
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: SelyGuide(text: _greeting(context), onTap: _greet, mascotSize: 110, hat: p.hat),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16 * u, 4 * u, 16 * u, 0),
            child: const AdventureCard(),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(16 * u),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220 * u,
              mainAxisSpacing: 16 * u,
              crossAxisSpacing: 16 * u,
              childAspectRatio: 0.92,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => PopIn(index: i, child: _WorldTile(world: worlds[i])),
              childCount: worlds.length,
            ),
          ),
        ),
      ]),
    );
  }
}

class _World {
  const _World(this.emoji, this.labelKey, this.color, this.progress, this.builder);
  final String emoji;
  final String labelKey;
  final Color color;
  final double? progress;
  final Widget Function() builder;
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({required this.world});
  final _World world;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final label = context.tr(world.labelKey);
    final progress = world.progress;
    return Pressable(
      semanticLabel: label,
      onTap: () => Navigator.of(context).push(fadeRoute(world.builder())),
      child: ChunkyBox(
        color: world.color,
        radius: 34 * u,
        depth: 8 * u,
        clip: true,
        padding: EdgeInsets.all(10 * u),
        child: Stack(children: [
          Positioned(top: -26 * u, left: -26 * u, child: _Blob(size: 100 * u, alpha: 0.14)),
          Positioned(bottom: 44 * u, right: -30 * u, child: _Blob(size: 84 * u, alpha: 0.11)),
          Positioned(top: 40 * u, right: 10 * u, child: _Blob(size: 18 * u, alpha: 0.25)),
          Column(children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 108 * u,
                  height: 108 * u,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 92 * u,
                      height: 92 * u,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(world.emoji, style: TextStyle(fontSize: 52 * u)),
                    ),
                    if (progress != null)
                      SizedBox(
                        width: 108 * u,
                        height: 108 * u,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7 * u,
                          strokeCap: StrokeCap.round,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                  ]),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8 * u, vertical: 7 * u),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22 * u),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 21 * u, fontWeight: FontWeight.w900, color: darken(world.color, 0.12)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.alpha});
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}
