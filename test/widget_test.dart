import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/app_scope.dart';
import 'package:sely_kids/features/adventure/adventure_map_screen.dart';
import 'package:sely_kids/features/adventure/adventure_models.dart';
import 'package:sely_kids/features/adventure/forest_quest_screen.dart';
import 'package:sely_kids/features/games/feed_cat_game.dart';
import 'package:sely_kids/features/home/home_screen.dart';
import 'package:sely_kids/widgets/count_objects.dart';
import 'package:sely_kids/features/games/game_items.dart';
import 'package:sely_kids/features/games/quiz_view.dart';
import 'package:sely_kids/features/trace/trace_board.dart';
import 'package:sely_kids/models/content_models.dart';
import 'package:sely_kids/widgets/hold_to_unlock.dart';
import 'package:sely_kids/widgets/option_tile.dart';
import 'test_helpers.dart';

Widget wrap(TestEnv env, Widget child) => AppScope(
      state: env.state,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
           localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('QuizView: wrong answer is gentle, correct answer gives a star and finishes', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    final pool = buildGameItems(ContentKind.shapes, env.state.repo, env.state.strings);
    final target = pool.first;
    int? finishedCorrect;

    await tester.pumpWidget(wrap(
      env,
      QuizView(pool: pool, targets: [target], optionCount: 3, skill: 'test', onFinished: (c, t) => finishedCorrect = c),
    ));
    await tester.pump();
    expect(env.audio.spoken, contains(target.promptKey));

    // Tap a wrong option first.
    final targetKey = ValueKey('opt_${target.id}');
    final wrong = find
        .byType(OptionTile)
        .evaluate()
        .map((e) => e.widget as OptionTile)
        .firstWhere((w) => w.key != targetKey);
    await tester.tap(find.byWidget(wrong));
    await tester.pump();
    expect(env.state.progress.stars, 0);
    expect(env.audio.spoken, contains('try_again'));

    await tester.tap(find.byKey(targetKey));
    await tester.pump();
    expect(env.state.progress.stars, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(finishedCorrect, isNotNull);
    expect(env.state.progress.results['test']!.length, 1);
  });

  testWidgets('TraceBoard completes when the finger follows the guide', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    var done = false;
    const shape = TraceShape(strokes: [
      [Offset(0.5, 0.1), Offset(0.5, 0.9)]
    ], dots: []);
    await tester.pumpWidget(wrap(
      env,
      Align(alignment: Alignment.topLeft, child: SizedBox(width: 600, height: 700, child: TraceBoard(shape: shape, onComplete: () => done = true))),
    ));
    final surface = find.byKey(const Key('trace_surface'));
    final rect = tester.getRect(surface);
    final pad = rect.width * 0.1;
    final inner = rect.width - 2 * pad;
    final gesture = await tester.startGesture(Offset(rect.left + pad + inner * 0.5, rect.top + pad + inner * 0.1));
    for (var i = 1; i <= 40; i++) {
      await gesture.moveTo(Offset(rect.left + pad + inner * 0.5, rect.top + pad + inner * (0.1 + 0.8 * i / 40)));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(done, isTrue);
    expect(env.audio.sfx, isNotEmpty);
  });

  testWidgets('HoldToUnlock needs a 3 second hold', (tester) async {
    final env = await TestEnv.create();
    var unlocked = 0;
    await tester.pumpWidget(wrap(env, Center(child: HoldToUnlock(onUnlocked: () => unlocked++))));
    final g1 = await tester.startGesture(tester.getCenter(find.byType(HoldToUnlock)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await g1.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);

    final g2 = await tester.startGesture(tester.getCenter(find.byType(HoldToUnlock)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3100));
    await g2.up();
    await tester.pump();
    expect(unlocked, 1);
  });

  testWidgets('Adventure map: only the first level is open at the start', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    final levels = AdventureMap.build(env.state.repo);
    await tester.pumpWidget(wrap(env, const AdventureMapScreen()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('level_adv:ar:alef')), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(levels.length - 1));
  });

  testWidgets('Forest quest: find the things, trace the letter, earn the level', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    final letter = env.state.repo.letters.first;
    await tester.pumpWidget(wrap(
      env,
      const ForestQuestScreen(letterIndex: 0, levelId: 'adv:ar:alef', levelNumber: 1),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(env.audio.spoken, contains('quest_intro'));

    await tester.tap(find.byKey(const ValueKey('quest_start')));
    await tester.pump(const Duration(milliseconds: 400));
    for (final w in letter.words) {
      await tester.tap(find.byKey(ValueKey('quest_item_${w.emoji}')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byKey(const Key('trace_surface')), findsOneWidget);

    final rect = tester.getRect(find.byKey(const Key('trace_surface')));
    final pad = rect.width * 0.1;
    final inner = rect.width - 2 * pad;
    Offset at(Offset n) => Offset(rect.left + pad + inner * n.dx, rect.top + pad + inner * n.dy);
    final stroke = letter.trace.strokes.first;
    final gesture = await tester.startGesture(at(stroke.first));
    for (final p in stroke.skip(1)) {
      await gesture.moveTo(at(p));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));

    expect(env.state.progress.starsFor('adv:ar:alef'), 3);
    expect(env.state.progress.isDone('ar:alef'), isTrue);
  });

  testWidgets('Feed the cat: a wrong amount is never punished, the cat just asks again', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    await tester.pumpWidget(wrap(env, const FeedCatGameScreen()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(env.audio.spoken, contains('feed_ask'));
    expect(find.byKey(const ValueKey('berry_0')), findsOneWidget);

    // an empty bowl is "too few": gentle hint, no stars lost, nothing finished
    await tester.tap(find.byKey(const ValueKey('feed_done')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(env.audio.spoken, contains('feed_too_few'));
    expect(env.state.progress.stars, 0);

    // tapping a treat moves it to the bowl, tapping it there puts it back
    await tester.tap(find.byKey(const ValueKey('berry_0')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('bowl_0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bowl_0')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('berry_0')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2)); // let the cat calm down
  });

  testWidgets('Home: the adventure card opens the map with the first level', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    await tester.pumpWidget(wrap(env, const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('adventure_card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('adventure_card')));
    // Flutter keeps a freshly pushed page offstage for its first frame (hero check),
    // so it needs one frame to appear and a second one to be on stage.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('level_adv:ar:alef')), findsOneWidget);
  });

  testWidgets('CountObjects: a tap reports the object, badges follow the tapping order', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final env = await TestEnv.create();
    int? tapped;
    await tester.pumpWidget(wrap(
      env,
      Center(child: CountObjects(count: 3, art: 'apple', counted: const {2, 0}, onTap: (i) => tapped = i)),
    ));
    await tester.pump();
    expect(find.text('1'), findsOneWidget); // object 2 was tapped first
    expect(find.text('2'), findsOneWidget); // object 0 second
    expect(find.text('3'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('count_obj_1')));
    expect(tapped, 1);
  });
}
