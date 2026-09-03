import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/widgets/courtyard/courtyard_progress.dart';

void main() {
  group('CourtyardSnapshot', () {
    test('new campaign is an empty field without a house', () {
      final s = CourtyardSnapshot.fromCampaign(
        maxUnlocked: 1,
        lastCompleted: false,
        totalStars: 0,
      );
      expect(s.step, 0);
      expect(s.path, 0);
      expect(s.foundation, 0);
      expect(s.walls, 0);
      expect(s.roof, 0);
      expect(s.door, 0);
      expect(s.fence, 0);
    });

    test('completing the story builds the full house and plot', () {
      final s = CourtyardSnapshot.fromCampaign(
        maxUnlocked: 24,
        lastCompleted: true,
        totalStars: 72,
      );
      expect(s.step, 24);
      expect(s.path, 1);
      expect(s.walls, 1);
      expect(s.roof, 1);
      expect(s.door, 1);
      expect(s.fence, 1);
      expect(s.climber, 1);
      expect(s.goldLight, 1);
    });

    test('stars animate life without building structure', () {
      final barren = CourtyardSnapshot.fromStep(step: 16, totalStars: 0);
      final lively = CourtyardSnapshot.fromStep(step: 16, totalStars: 54);
      expect(barren.walls, lively.walls);
      expect(barren.roof, lively.roof);
      expect(barren.door, lively.door);
      expect(barren.windowGlow, 0);
      expect(lively.windowGlow, 1);
      expect(lively.smoke, 1);
      expect(lively.goldLight, greaterThan(0));
    });

    test('lerp moves dawn between snapshots', () {
      final a = CourtyardSnapshot.fromStep(step: 0, totalStars: 0);
      final b = CourtyardSnapshot.fromStep(step: 24, totalStars: 0);
      final mid = CourtyardSnapshot.lerp(a, b, 0.5);
      expect(mid.dawn, closeTo(0.5, 0.001));
      expect(mid.step, closeTo(12, 0.001));
    });
  });

  group('path phrases', () {
    test('home uses the current era line', () {
      final start = CourtyardSnapshot.fromStep(step: 0, totalStars: 0);
      final shack = CourtyardSnapshot.fromStep(step: 12, totalStars: 10);
      expect(pathPhraseForHome(start), 'A house will stand here.');
      expect(pathPhraseForHome(shack), 'A shack leans on the plot.');
    });

    test('win uses an era line when crossing into a new era', () {
      final from = CourtyardSnapshot.fromStep(step: 8, totalStars: 6);
      final to = CourtyardSnapshot.fromStep(step: 9, totalStars: 8);
      expect(
        pathPhraseForWin(from: from, to: to),
        'A shack leans on the plot.',
      );
    });

    test('more stars without a new step only warm the house', () {
      final from = CourtyardSnapshot.fromStep(step: 8, totalStars: 10);
      final to = CourtyardSnapshot.fromStep(step: 8, totalStars: 14);
      expect(pathPhraseForWin(from: from, to: to), pathLifePhrase);
    });

    test('first win teaches that the house grows', () {
      expect(firstHomePhrase, 'This house grows as you play.');
    });
  });

  group('plot feature layers', () {
    test('empty field is only the yard', () {
      final empty = CourtyardSnapshot.fromStep(step: 0, totalStars: 0);
      expect(empty.layerRoad, 0);
      expect(empty.layerHouse, 0);
      expect(empty.layerPond, 0);
      expect(empty.layerInternet, 0);
      expect(empty.layerFlowers, 0);
    });

    test('house plot grows path, house, then flowers', () {
      final mid = CourtyardSnapshot.fromStep(
        step: 12,
        totalStars: 10,
        plotKind: PlotKind.house,
      );
      expect(mid.layerRoad, 1);
      expect(mid.layerHouse, closeTo(0.6, 0.001));
      expect(mid.layerPond, 0);
      expect(mid.layerInternet, 0);
      expect(mid.layerFlowers, 0);

      final done = CourtyardSnapshot.fromStep(
        step: 24,
        totalStars: 72,
        plotKind: PlotKind.house,
      );
      expect(done.layerHouse, 1);
      expect(done.layerFlowers, 1);
      expect(done.layerPond, 0);
    });

    test('each plot grows its own feature layer', () {
      final pond = CourtyardSnapshot.fromStep(
        step: 16,
        totalStars: 20,
        plotKind: PlotKind.pond,
      );
      expect(pond.layerPond, 1);
      expect(pond.layerHouse, 0);
      expect(pond.layerInternet, 0);

      final pets = CourtyardSnapshot.fromStep(
        step: 12,
        totalStars: 20,
        plotKind: PlotKind.pets,
      );
      expect(pets.layerHouse, closeTo(0.6, 0.001));
      expect(pets.layerPond, 0);

      final guest = CourtyardSnapshot.fromStep(
        step: 20,
        totalStars: 20,
        plotKind: PlotKind.guest,
      );
      expect(guest.layerHouse, 1);
      expect(guest.layerInternet, 1);
      expect(guest.layerPond, 0);
    });

    test('evening overlay waits for a nearly finished house', () {
      final early = CourtyardSnapshot.fromStep(step: 12, totalStars: 72);
      final late = CourtyardSnapshot.fromStep(step: 24, totalStars: 72);
      expect(early.lifeArt, 0);
      expect(late.lifeArt, 1);
    });

    test('streak and festival light the house without building it', () {
      final plain = CourtyardSnapshot.fromStep(step: 8, totalStars: 0);
      final festive = CourtyardSnapshot.fromStep(
        step: 8,
        totalStars: 0,
        streak: 7,
        festival: true,
      );
      expect(plain.festival, 0);
      expect(festive.festival, 1);
      expect(festive.streakLife, 1);
      expect(festive.birds, greaterThan(plain.birds));
      expect(festive.goldLight, greaterThan(plain.goldLight));
      expect(festive.walls, plain.walls);
      expect(festive.layerHouse, plain.layerHouse);
    });
  });
}
