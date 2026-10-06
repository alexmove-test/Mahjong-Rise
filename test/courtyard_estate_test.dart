import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/courtyard_reward.dart';
import 'package:mahjong/models/leaderboard_entry.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_lot_build.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world_layout.dart';
import 'package:mahjong/widgets/courtyard/plot_stage_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new player unlocks only the first level plot', () async {
    SharedPreferences.setMockInitialValues({'progress.maxUnlocked': 1});
    final store = await ProgressStore.open();
    final estate = CourtyardEstate.fromStore(store);
    final first = Levels.plotKindOf(1);

    expect(estate.lot(first).unlocked, isTrue);
    expect(estate.lot(first).loop, 0);
    expect(estate.lot(first).stage, 0);
    for (final kind in PlotKind.order) {
      if (kind == first) continue;
      expect(estate.lot(kind).unlocked, isFalse, reason: kind.name);
    }
    expect(CourtyardEstate.latestUnlockedCycle(store, first), 0);
    expect(
      CourtyardEstate.latestUnlockedCycle(
        store,
        PlotKind.order.firstWhere((k) => k != first),
      ),
      isNull,
    );
  });

  test('early clears grow only the house', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 5,
      'progress.stars.4': 1,
    });
    final store = await ProgressStore.open();
    final estate = CourtyardEstate.fromStore(store);

    expect(estate.lot(PlotKind.house).unlocked, isTrue);
    expect(estate.lot(PlotKind.house).stage, 4);
    expect(estate.lot(PlotKind.pond).unlocked, isFalse);
    expect(estate.lot(PlotKind.guest).unlocked, isFalse);
    expect(estate.lot(PlotKind.pets).unlocked, isFalse);
  });

  test('manual plot unlocks immediately and takes later wins', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 3,
      'progress.stars.1': 1,
      'progress.stars.2': 1,
    });
    final store = await ProgressStore.open();
    await store.selectPlot(PlotKind.guest);
    final afterSelect = CourtyardEstate.fromStore(store);
    expect(afterSelect.lot(PlotKind.house).stage, 2);
    expect(afterSelect.lot(PlotKind.guest).unlocked, isTrue);
    expect(afterSelect.lot(PlotKind.guest).stage, 0);

    await store.recordWin(
      level: Levels.byId(3),
      score: Levels.byId(3).starsThresholds.$1,
    );
    final afterWin = CourtyardEstate.fromStore(store);
    expect(afterWin.lot(PlotKind.house).stage, 2);
    expect(afterWin.lot(PlotKind.guest).stage, 1);
    expect(afterWin.lot(PlotKind.pond).unlocked, isFalse);
  });

  test('later levels keep upgrading the same four lots', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 110,
      'progress.stars.24': 1,
      'progress.stars.48': 1,
      'progress.stars.72': 1,
      'progress.stars.96': 1,
    });
    final store = await ProgressStore.open();
    final estate = CourtyardEstate.fromStore(store);

    for (final kind in PlotKind.order) {
      final lot = estate.lot(kind);
      expect(lot.unlocked, isTrue, reason: kind.name);
      expect(lot.stage, Levels.completedStages(kind, 110), reason: kind.name);
      expect(lot.stage, greaterThan(20), reason: kind.name);
    }
  });

  testWidgets('the courtyard exposes one tappable home on the map', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 25,
      'progress.stars.24': 1,
    });
    final store = await ProgressStore.open();
    PlotKind? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CourtyardWorld(
            to: CourtyardEstate.fromStore(store),
            onSelectLot: (kind) => selected = kind,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const ValueKey('courtyard-lot-house')));
    await tester.pump();
    expect(selected, PlotKind.house);
    expect(find.byKey(courtyardHomeKey), findsOneWidget);
    expect(find.byKey(courtyardPetAreaKey), findsOneWidget);
    expect(find.byKey(const ValueKey('courtyard-lot-pond')), findsNothing);
  });

  testWidgets('all saved plot progress feeds the single house', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CourtyardWorld(to: CourtyardEstate.fromUnlocked(8)),
        ),
      ),
    );
    await tester.pump();
    final views = tester.widgetList<PlotStageView>(find.byType(PlotStageView));
    expect(views, isNotEmpty);
    expect(views.single.kind, PlotKind.house);
    final accumulated = PlotKind.order.fold<double>(
      0,
      (value, kind) => value + CourtyardEstate.fromUnlocked(8).lot(kind).stage,
    );
    final expectedStage = accumulated.clamp(
      0,
      CourtyardLotBuild.maxStage.toDouble(),
    );
    expect(views.single.stage, closeTo(expectedStage, 0.001));
    expect(
      CourtyardEstate.fromUnlocked(8).homeStage,
      closeTo(expectedStage, 0.001),
    );
    // Шкала до следующего облика переехала в HUD, поверх двора её нет.
    expect(find.byType(PlotProgressMeter), findsNothing);
  });

  testWidgets('the house stays and the pond grows after it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CourtyardWorld(to: CourtyardEstate.fromUnlocked(80)),
        ),
      ),
    );
    await tester.pump();
    final views = tester.widgetList<PlotStageView>(find.byType(PlotStageView));
    expect(views.map((view) => view.kind), [
      PlotKind.house,
      PlotKind.pond,
    ]);
    expect(
      views.firstWhere((view) => view.kind == PlotKind.pond).stage,
      CourtyardEstate.fromUnlocked(80).pondStage,
    );
  });

  test('the home and pet stand on the cropped lawn', () {
    expect(
      CourtyardWorldLayout.mapAspect,
      closeTo(
        CourtyardWorldLayout.mapWidth / CourtyardWorldLayout.mapHeight,
        0.001,
      ),
    );

    final lawn = CourtyardWorldLayout.lawn;
    final home = CourtyardWorldLayout.homeYard;
    final pond = CourtyardWorldLayout.pondYard;
    final pet = CourtyardWorldLayout.petYard;
    final cover = CourtyardWorldLayout.yardCover;

    // Дом сзади-слева, питомец впереди-справа, обе опоры внутри ограды.
    expect(home.center.dx, lessThan(pond.center.dx));
    expect(home.center.dx, lessThan(pet.center.dx));
    expect(home.center.dy, lessThan(pet.center.dy));
    expect(pond.bottom, lessThanOrEqualTo(pet.top));
    expect(lawn.contains(home.bottomCenter), isTrue);
    expect(lawn.contains(pond.bottomCenter), isTrue);
    expect(lawn.contains(pet.bottomCenter), isTrue);
    expect(home.left, greaterThan(lawn.left));
    expect(pet.right, lessThan(lawn.right));

    expect(cover.left, lessThan(lawn.left));
    expect(cover.right, greaterThan(lawn.right));
    expect(cover.top, lessThan(lawn.top));
    expect(cover.bottom, greaterThan(lawn.bottom));

    for (final reward in CourtyardReward.values) {
      final rect = CourtyardWorldLayout.rewardOf(reward);
      expect(lawn.contains(rect.bottomCenter), isTrue, reason: reward.name);
      expect(rect.overlaps(home), isFalse, reason: reward.name);
      expect(rect.overlaps(pet), isFalse, reason: reward.name);
    }

    expect(CourtyardWorldLayout.neighbors, isEmpty);
  });

  test('camera covers the viewport so the map has no side gaps', () {
    void expectCovers(Size viewport, Rect focus) {
      final cam = CourtyardWorldLayout.camera(
        viewport: viewport,
        focusNorm: focus,
      );
      final right = cam.tx + CourtyardWorldLayout.mapWidth * cam.scale;
      final bottom = cam.ty + CourtyardWorldLayout.mapHeight * cam.scale;
      expect(cam.tx, lessThanOrEqualTo(0.01), reason: '$viewport left');
      expect(cam.ty, lessThanOrEqualTo(0.01), reason: '$viewport top');
      expect(
        right,
        greaterThanOrEqualTo(viewport.width - 0.01),
        reason: '$viewport right',
      );
      expect(
        bottom,
        greaterThanOrEqualTo(viewport.height - 0.01),
        reason: '$viewport bottom',
      );
    }

    for (final focus in [
      CourtyardWorldLayout.lawn,
      CourtyardWorldLayout.yardCover,
    ]) {
      expectCovers(const Size(1280, 720), focus);
      expectCovers(const Size(1920, 1080), focus);
      expectCovers(const Size(390, 844), focus);
      expectCovers(const Size(900, 1600), focus);
      expectCovers(const Size(800, 1280), focus);
    }
  });

  test('campaign unlock rebuilds the same lots as the local store', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 110,
      'progress.stars.24': 1,
      'progress.stars.48': 1,
      'progress.stars.72': 1,
      'progress.stars.96': 1,
    });
    final store = await ProgressStore.open();
    final fromStore = CourtyardEstate.fromStore(store);
    final fromRank = CourtyardEstate.fromUnlocked(store.maxUnlocked);

    for (final kind in PlotKind.order) {
      final a = fromStore.lot(kind);
      final b = fromRank.lot(kind);
      expect(b.unlocked, a.unlocked, reason: kind.name);
      expect(b.cycle, a.cycle, reason: kind.name);
      expect(b.loop, a.loop, reason: kind.name);
      expect(b.stage, closeTo(a.stage, 0.001), reason: kind.name);
      expect(b.era, a.era, reason: kind.name);
    }
  });

  test('neighbor yards use nearby ranked players and their lots', () {
    const above = LeaderboardEntry(
      id: 'a',
      name: 'Ada',
      rating: 400,
      totalStars: 20,
      levelsUnlocked: 50,
      isCurrentPlayer: false,
    );
    const below = LeaderboardEntry(
      id: 'b',
      name: 'Bo',
      rating: 200,
      totalStars: 4,
      levelsUnlocked: 10,
      isCurrentPlayer: false,
    );

    expect(NeighborYard.placed(others: const [above], online: false), isEmpty);
    expect(
      NeighborYard.placed(others: const [above, below], online: true),
      isEmpty,
    );
  });

  test('the cropped map has no neighbor hills', () {
    expect(CourtyardWorldLayout.neighborCount, 0);
  });

  test('each cleared level advances the single house', () {
    expect(CourtyardEstate.fromUnlocked(1).homeStage, 0);
    expect(CourtyardEstate.fromUnlocked(2).homeStage, 1);
    expect(CourtyardEstate.fromUnlocked(5).homeStage, 4);
    expect(CourtyardEstate.fromUnlocked(6).homeStage, 5);
    expect(PlotStages.currentFrame(CourtyardEstate.fromUnlocked(2).homeStage), 1);
    expect(PlotStages.currentFrame(CourtyardEstate.fromUnlocked(3).homeStage), 2);
    expect(PlotStages.currentFrame(CourtyardEstate.fromUnlocked(5).homeStage), 4);
    expect(PlotStages.currentFrame(CourtyardEstate.fromUnlocked(25).homeStage), 24);
    expect(CourtyardEstate.fromUnlocked(25).homeStage, 24);
    expect(CourtyardEstate.fromUnlocked(97).homeStage, 96);
    expect(CourtyardEstate.fromUnlocked(200).homeStage, 96);
  });

  test('house stage accumulates across loops and caps at 96', () {
    final first = Levels.plotKindOf(1);
    final fresh = CourtyardEstate.fromUnlocked(1).lot(first);
    expect(fresh.stage, 0);

    expect(CourtyardEstate.fromUnlocked(5).lot(PlotKind.house).stage, 4);
    expect(CourtyardEstate.fromUnlocked(5).lot(PlotKind.pond).stage, 0);

    final mid = CourtyardEstate.fromUnlocked(110).lot(PlotKind.house);
    expect(mid.stage, Levels.completedStages(PlotKind.house, 110));
    expect(mid.stage, greaterThan(20));

    final castle = CourtyardEstate.fromUnlocked(385).lot(PlotKind.house);
    expect(castle.stage, 96);
    expect(castle.era, 11);

    final later = CourtyardEstate.fromUnlocked(500).lot(PlotKind.house);
    expect(later.stage, 96);
  });

  test('lot lerp fades the next stage in without collapsing the loop', () {
    late CourtyardLotView a;
    late CourtyardLotView b;
    for (var id = 1; id < 40; id++) {
      if (Levels.plotKindOf(id) != PlotKind.house) continue;
      a = CourtyardEstate.fromUnlocked(id).lot(PlotKind.house);
      b = CourtyardEstate.fromUnlocked(id + 1).lot(PlotKind.house);
      break;
    }
    expect(b.stage, a.stage + 1);
    final mid = CourtyardLotView.lerp(a, b, 0.5);
    expect(mid.stage, closeTo(a.stage + 0.5, 0.001));
    expect(
      CourtyardLotBuild.layerOpacity(mid.stage, b.stage.floor()),
      closeTo(0.5, 0.001),
    );
  });
}
