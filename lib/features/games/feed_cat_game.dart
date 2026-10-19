import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/audio_service.dart';
import '../../widgets/art_image.dart';
import '../../widgets/chunky.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/result_view.dart';

enum _CatMood { idle, happy, unsure }

/// "Feed the cat": the cat asks for a number of treats. The child taps or drags that many
/// from the plate into the bowl and presses the green check. Too few or too many is never
/// punished: the cat just asks again, and every treat is counted out loud.
class FeedCatGameScreen extends StatefulWidget {
  const FeedCatGameScreen({super.key});

  @override
  State<FeedCatGameScreen> createState() => _FeedCatGameScreenState();
}

class _FeedCatGameScreenState extends State<FeedCatGameScreen> {
  static const rounds = 5;
  static const foods = ['🍓', '🍎'];
  static const foodArt = {'🍓': 'strawberry', '🍎': 'apple'};
  int _round = 0;
  int _earned = 0;
  bool _done = false;
  bool _locked = false;
  bool _hadWrong = false;
  int _target = 1;
  String _food = '🍓';
  List<bool> _inBowl = [];
  _CatMood _mood = _CatMood.idle;
  int _catTick = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  int get _count => _inBowl.where((e) => e).length;

  String _numWord(AppState app, int k) {
    for (final n in app.repo.numbers) {
      if (n.value == k) return app.progress.locale == 'en' ? n.en : n.ar;
    }
    return '$k';
  }

  void _newRound() {
    final app = AppScope.read(context);
    final level = app.adaptive.levelFor('feed_cat');
    final maxN = switch (level) { 1 => 3, 2 => 5, _ => 8 };
    _target = 1 + app.random.nextInt(maxN);
    _food = foods[app.random.nextInt(foods.length)];
    _inBowl = List<bool>.filled(math.min(10, _target + 3), false);
    _hadWrong = false;
    _locked = false;
    _mood = _CatMood.idle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _askAgain();
    });
  }

  void _askAgain() {
    final app = AppScope.read(context);
    unawaited(app.say('feed_ask', {'x': _numWord(app, _target)}));
  }

  void _add(int i) {
    if (_locked || i < 0 || i >= _inBowl.length || _inBowl[i]) return;
    final app = AppScope.read(context);
    setState(() => _inBowl[i] = true);
    final k = _count;
    unawaited(app.audio.speak('ar_num_$k', _numWord(app, k), lang: 'ar'));
  }

  void _remove(int i) {
    if (_locked || i < 0 || i >= _inBowl.length || !_inBowl[i]) return;
    setState(() => _inBowl[i] = false);
  }

  Future<void> _check() async {
    if (_locked) return;
    final app = AppScope.read(context);
    final n = _count;
    if (n == _target) {
      _locked = true;
      app.progress.recordAnswer('feed_cat', !_hadWrong);
      app.progress.addStars(1);
      _earned++;
      unawaited(app.audio.playSfx(Sfx.correct));
      unawaited(app.say('feed_yum'));
      setState(() {
        _mood = _CatMood.happy;
        _catTick++;
      });
      await showStarBurst(context, text: app.strings.get(app.cheerKey()));
      if (!mounted) return;
      if (_round + 1 >= rounds) {
        app.progress.addStars(2, activity: app.strings.get('game_feed'));
        app.progress.recordGame('feed', activity: app.strings.get('game_feed'));
        unawaited(app.audio.playSfx(Sfx.win));
        setState(() {
          _done = true;
          _earned += 2;
        });
      } else {
        setState(() {
          _round++;
          _newRound();
        });
      }
    } else {
      _hadWrong = true;
      unawaited(app.audio.playSfx(Sfx.wrong));
      unawaited(app.say(n < _target ? 'feed_too_few' : 'feed_too_many'));
      setState(() {
        _mood = _CatMood.unsure;
        _catTick++;
      });
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && !_locked) setState(() => _mood = _CatMood.idle);
      });
    }
  }

  void _restart() {
    setState(() {
      _round = 0;
      _earned = 0;
      _done = false;
      _newRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.app;
    if (_done) {
      return KidScaffold(
        title: context.tr('game_feed'),
        child: ResultView(
          title: context.tr('game_done_title'),
          stars: _earned,
          actions: [
            BigActionButton(label: context.tr('play_again'), icon: Icons.replay_rounded, color: AppColors.green, onTap: _restart),
            BigActionButton(label: context.tr('back'), icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      );
    }
    final word = _numWord(app, _target);
    final ask = context.tr('feed_ask', {'x': word});
    final plate = [for (var i = 0; i < _inBowl.length; i++) if (!_inBowl[i]) i];
    final inBowl = [for (var i = 0; i < _inBowl.length; i++) if (_inBowl[i]) i];

    return KidScaffold(
      title: context.tr('game_feed'),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(12 * u, 4 * u, 12 * u, 16 * u),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // the cat asks
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _cat(u),
            SizedBox(width: 8 * u),
            Expanded(
              child: Pressable(
                onTap: _askAgain,
                semanticLabel: ask,
                child: ChunkyBox(
                  color: Colors.white,
                  radius: 26 * u,
                  depth: 5 * u,
                  gloss: false,
                  padding: EdgeInsets.symmetric(horizontal: 14 * u, vertical: 10 * u),
                  child: Row(children: [
                    Expanded(
                      child: Text(ask, style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w900, color: AppColors.navy, height: 1.25)),
                    ),
                    SizedBox(width: 8 * u),
                    Container(
                      width: 52 * u,
                      height: 52 * u,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                      child: Text('$_target', style: TextStyle(fontSize: 30 * u, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
          SizedBox(height: 14 * u),
          // the bowl (picture), the treats sit in its opening
          DragTarget<int>(
            onAcceptWithDetails: (d) => _add(d.data),
            builder: (context, candidate, rejected) => AnimatedScale(
              scale: candidate.isNotEmpty ? 1.05 : 1,
              duration: const Duration(milliseconds: 120),
              child: SizedBox(
                key: const ValueKey('feed_bowl'),
                height: 200 * u,
                width: double.infinity,
                child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                  Positioned(
                    bottom: 0,
                    child: ArtImage(
                      'bowl',
                      width: 320 * u,
                      fallback: ChunkyBox(
                        color: const Color(0xFF3AA0FF),
                        radius: 54 * u,
                        depth: 8 * u,
                        width: 320 * u,
                        height: 150 * u,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 34 * u,
                    child: SizedBox(
                      width: 250 * u,
                      child: Wrap(alignment: WrapAlignment.center, spacing: 2 * u, runSpacing: 0, children: [
                        for (final i in inBowl)
                          Pressable(
                            key: ValueKey('bowl_$i'),
                            onTap: () => _remove(i),
                            semanticLabel: _food,
                            child: _foodPicture(46 * u),
                          ),
                      ]),
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 14 * u,
                    child: ChunkyBox(
                      circle: true,
                      color: AppColors.green,
                      width: 56 * u,
                      height: 56 * u,
                      depth: 4 * u,
                      borderColor: Colors.white,
                      borderWidth: 3,
                      child: Center(
                        child: Text('${inBowl.length}', style: TextStyle(fontSize: 28 * u, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          SizedBox(height: 16 * u),
          // the plate
          ChunkyBox(
            color: const Color(0xFFE2A765),
            radius: 40 * u,
            depth: 7 * u,
            width: double.infinity,
            padding: EdgeInsets.all(12 * u),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 84 * u),
              child: Wrap(alignment: WrapAlignment.center, spacing: 10 * u, runSpacing: 8 * u, children: [
                for (final i in plate) _berry(i, u),
              ]),
            ),
          ),
          SizedBox(height: 16 * u),
          Pressable(
            key: const ValueKey('feed_done'),
            onTap: _check,
            semanticLabel: context.tr('feed_ok'),
            child: ChunkyBox(
              circle: true,
              color: AppColors.green,
              width: 84 * u,
              height: 84 * u,
              depth: 7 * u,
              child: Center(child: Icon(Icons.check_rounded, size: 56 * u, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _foodPicture(double size) => ArtImage(
        foodArt[_food] ?? 'apple',
        width: size,
        height: size,
        fallback: Text(_food, style: TextStyle(fontSize: size * 0.8)),
      );

  Widget _berry(int i, double u) {
    final face = Container(
      key: ValueKey('berry_$i'),
      width: 68 * u,
      height: 68 * u,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
      child: _foodPicture(54 * u),
    );
    return Draggable<int>(
      data: i,
      affinity: Axis.vertical,
      feedback: Material(color: Colors.transparent, child: _foodPicture(74 * u)),
      childWhenDragging: Opacity(opacity: 0.25, child: face),
      child: Pressable(onTap: () => _add(i), semanticLabel: _food, child: face),
    );
  }

  Widget _cat(double u) {
    final fallback = Text('🐱', style: TextStyle(fontSize: 90 * u));
    return TweenAnimationBuilder<double>(
      key: ValueKey(_catTick),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      builder: (context, v, child) {
        final hop = _mood == _CatMood.happy ? -math.sin(v * math.pi) * 22 * u : 0.0;
        final tilt = _mood == _CatMood.unsure ? math.sin(v * math.pi * 2) * 0.12 : 0.0;
        return Transform.translate(offset: Offset(0, hop), child: Transform.rotate(angle: tilt, child: child));
      },
      child: Stack(clipBehavior: Clip.none, children: [
        ArtImage('cat_happy', height: 130 * u, fallback: fallback),
        if (_mood != _CatMood.idle)
          PositionedDirectional(
            top: -6 * u,
            end: -6 * u,
            child: Text(_mood == _CatMood.happy ? '💗' : '🤔', style: TextStyle(fontSize: 30 * u)),
          ),
      ]),
    );
  }
}
