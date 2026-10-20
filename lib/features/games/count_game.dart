import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../services/audio_service.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/count_objects.dart';
import '../../widgets/option_tile.dart';
import '../../widgets/pressable.dart';
import '../../widgets/result_view.dart';
import '../../widgets/speech_bubble.dart';

/// Count the objects and choose the right number. Difficulty follows the child's level.
class CountGameScreen extends StatefulWidget {
  const CountGameScreen({super.key});

  @override
  State<CountGameScreen> createState() => _CountGameScreenState();
}

class _CountGameScreenState extends State<CountGameScreen> {
  static const rounds = 5;
  int _round = 0;
  int _earned = 0;
  bool _done = false;
  bool _locked = false;
  bool _hadWrong = false;
  int _shake = 0;
  late int _n;
  late String _art;
  late List<int> _options;
  final Set<int> _wrong = {};
  final Set<int> _counted = {};

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final app = AppScope.read(context);
    final level = app.adaptive.levelFor('count');
    final maxN = switch (level) { 1 => 3, 2 => 5, _ => 10 };
    _n = 1 + app.random.nextInt(maxN);
    _art = CountObjects.arts[app.random.nextInt(CountObjects.arts.length)];
    final set = <int>{_n};
    final upper = maxN < 4 ? 4 : maxN + 1;
    var guard = 0;
    while (set.length < 3 && guard++ < 50) {
      set.add(1 + app.random.nextInt(upper));
    }
    _options = set.toList()..sort();
    _wrong.clear();
    _counted.clear();
    _hadWrong = false;
    _locked = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(app.say('count_prompt'));
    });
  }

  Future<void> _answer(int v) async {
    if (_locked) return;
    final app = AppScope.read(context);
    if (v == _n) {
      _locked = true;
      app.progress.recordAnswer('count', !_hadWrong);
      app.progress.addStars(1);
      _earned++;
      app.audio.playSfx(Sfx.correct);
      await showStarBurst(context, text: app.strings.get(app.cheerKey()));
      if (!mounted) return;
      if (_round + 1 >= rounds) {
        app.progress.addStars(2, activity: app.strings.get('count_title'));
        app.progress.recordGame('count', activity: app.strings.get('count_title'));
        app.audio.playSfx(Sfx.win);
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
      app.audio.playSfx(Sfx.wrong);
      unawaited(app.say('try_again'));
      setState(() {
        _wrong.add(v);
        _shake++;
      });
    }
  }

  void _tapObject(int i) {
    if (_counted.contains(i)) return;
    setState(() => _counted.add(i));
    final k = _counted.length;
    final app = AppScope.read(context);
    final ar = app.repo.numbers.where((e) => e.value == k).map((e) => e.ar).firstOrNull ?? '$k';
    unawaited(app.audio.speak('ar_num_$k', ar, lang: 'ar'));
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
    if (_done) {
      return KidScaffold(
        title: context.tr('count_title'),
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
    return KidScaffold(
      title: context.tr('count_title'),
      child: Column(children: [
        SelyGuide(text: context.tr('count_prompt'), mascotSize: 80, hat: context.app.progress.hat, onTap: () => context.appRead.say('count_prompt')),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12 * u),
              child: CountObjects(count: _n, art: _art, counted: _counted, onTap: _tapObject),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 18 * u),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16 * u,
            children: [
              for (final o in _options)
                OptionTile(
                  size: 100 * u,
                  state: _wrong.contains(o) ? TileState.wrong : (_wrong.length >= 2 && o == _n ? TileState.hint : TileState.normal),
                  shakeTrigger: _wrong.contains(o) ? _shake : 0,
                  semanticLabel: '$o',
                  onTap: () => _answer(o),
                  child: Text('$o', style: TextStyle(fontSize: 64 * u, fontWeight: FontWeight.w900, color: AppColors.purple)),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
