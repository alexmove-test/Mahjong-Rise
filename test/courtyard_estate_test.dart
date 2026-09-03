import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('tapping an unlocked lot selects it', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 25,
      'progress.stars.24': 1,
    });
    final store = await ProgressStore.open();
    PlotKind? selected;
    await tester.pumpWidget(
      MaterialApp(
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

    await tester.tap(find.byKey(const ValueKey('courtyard-lot-pond')));
    await tester.pump();
    expect(selected, PlotKind.pond);
    expect(find.byKey(const ValueKey('plot-inspect-pond')), findsOneWidget);
    expect(find.text('Pond'), findsOneWidget);
  });

  testWidgets('tapping a locked lot selects it for the next wins', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'progress.maxUnlocked': 1});
    final store = await ProgressStore.open();
    final lockedKind = PlotKind.order.firstWhere(
      (kind) => !Levels.plotReached(kind, 1),
    );
    PlotKind? selected;
    PlotKind? locked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtyardWorld(
            to: CourtyardEstate.fromStore(store),
            onSelectLot: (kind) => selected = kind,
            onLockedLot: (kind) => locked = kind,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(ValueKey('courtyard-lot-${lockedKind.name}')));
    await tester.pump();
    expect(selected, lockedKind);
    expect(locked, lockedKind);
    expect(
      find.byKey(ValueKey('plot-inspect-${lockedKind.name}')),
      findsOneWidget,
    );
    expect(find.text('Next wins will grow this plot'), findsOneWidget);
  });

  testWidgets('reached plots use the 24-frame build sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtyardWorld(to: CourtyardEstate.fromUnlocked(8)),
        ),
      ),
    );
    await tester.pump();
    final views = tester.widgetList<PlotStageView>(find.byType(PlotStageView));
    expect(views, isNotEmpty);
    expect(views.single.kind, PlotKind.house);
    expect(views.single.stage, Levels.completedStages(PlotKind.house, 8));
    expect(find.byType(PlotProgressMeter), findsOneWidget);
    final houseMeter = tester.widget<PlotProgressMeter>(
      find.byKey(const ValueKey('plot-progress-house')),
    );
    expect(houseMeter.stage, Levels.completedStages(PlotKind.house, 8));
  });

  testWidgets('unlocked lots all use plot stage sprites', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtyardWorld(to: CourtyardEstate.fromUnlocked(80)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(PlotStageView), findsNWidgets(4));
    final views = tester.widgetList<PlotStageView>(find.byType(PlotStageView));
    expect(views.map((v) => v.kind).toSet(), PlotKind.order.toSet());
  });

  test('lots sit on the circular plateau and neighbors on the hills', () {
    expect(CourtyardWorldLayout.mapAspect, closeTo(1.5, 0.001));

    final house = CourtyardWorldLayout.lotOf(PlotKind.house);
    final pond = CourtyardWorldLayout.lotOf(PlotKind.pond);
    final pets = CourtyardWorldLayout.lotOf(PlotKind.pets);
    final guest = CourtyardWorldLayout.lotOf(PlotKind.guest);

    expect(house.center.dx * CourtyardWorldLayout.mapWidth, closeTo(594, 0.5));
    expect(house.center.dy * CourtyardWorldLayout.mapHeight, closeTo(470, 0.5));
    expect(pond.center.dx * CourtyardWorldLayout.mapWidth, closeTo(971, 0.5));
    expect(pond.center.dy * CourtyardWorldLayout.mapHeight, closeTo(474, 0.5));
    expect(pets.center.dx * CourtyardWorldLayout.mapWidth, closeTo(979, 0.5));
    expect(pets.center.dy * CourtyardWorldLayout.mapHeight, closeTo(766, 0.5));
    expect(guest.center.dx * CourtyardWorldLayout.mapWidth, closeTo(574, 0.5));
    expect(guest.center.dy * CourtyardWorldLayout.mapHeight, closeTo(715, 0.5));

    expect(house.top, lessThan(pets.top));
    expect(pond.top, lessThan(guest.top));
    expect(house.left, lessThan(pond.left));
    expect(guest.left, lessThan(pets.left));

    final plateau = CourtyardWorldLayout.plateau;
    expect(house.top, greaterThan(0.30));
    expect(pets.bottom, lessThan(0.90));
    expect(plateau.width, closeTo(0.400, 0.02));
    expect(plateau.height, closeTo(0.444, 0.02));

    final hills = CourtyardWorldLayout.neighbors;
    expect(hills, hasLength(4));
    expect(hills[0].center.dx, lessThan(plateau.left));
    expect(hills[1].bottom, lessThan(plateau.top));
    expect(hills[2].center.dx, greaterThan(plateau.center.dx));
    expect(hills[3].center.dx, greaterThan(plateau.center.dx));
  });

  test('camera covers the viewport so the map has no side gaps', () {
    void expectCovers(Size viewport) {
      final cam = CourtyardWorldLayout.camera(
        viewport: viewport,
        focusNorm: CourtyardWorldLayout.plateau,
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

    expectCovers(const Size(1280, 720));
    expectCovers(const Size(1920, 1080));
    expectCovers(const Size(390, 844));
    expectCovers(const Size(900, 1600));
    expectCovers(const Size(800, 1280));
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

    final yards = NeighborYard.placed(
      others: const [above, below],
      online: true,
    );
    expect(yards, hasLength(2));
    expect(yards[0].name, 'Ada');
    expect(yards[0].estate.lot(PlotKind.house).unlocked, isTrue);
    expect(yards[0].estate.lot(PlotKind.pond).unlocked, isTrue);
    expect(yards[0].estate.lot(PlotKind.guest).unlocked, isTrue);
    expect(yards[0].estate.lot(PlotKind.pets).unlocked, isFalse);
    expect(yards[1].estate.lot(PlotKind.house).unlocked, isTrue);
    expect(yards[1].estate.lot(PlotKind.pond).unlocked, isFalse);
  });

  test('neighbor lots sit in a 2x2 inside each hill', () {
    final hill = CourtyardWorldLayout.neighborOf(0);
    final house = CourtyardWorldLayout.neighborLotOf(0, PlotKind.house);
    final pond = CourtyardWorldLayout.neighborLotOf(0, PlotKind.pond);
    final pets = CourtyardWorldLayout.neighborLotOf(0, PlotKind.pets);
    final guest = CourtyardWorldLayout.neighborLotOf(0, PlotKind.guest);

    expect(house.left, closeTo(hill.left, 0.0001));
    expect(pond.right, closeTo(hill.right, 0.0001));
    expect(guest.bottom, closeTo(hill.bottom, 0.0001));
    expect(pets.right, closeTo(hill.right, 0.0001));
    expect(house.top, lessThan(guest.top));
    expect(house.left, lessThan(pond.left));
    expect(house.width, closeTo(hill.width / 2, 0.0001));
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
