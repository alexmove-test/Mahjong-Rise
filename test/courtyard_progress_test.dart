import 'package:flutter_test/flutter_test.dart';
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
    test('home uses the current stage line', () {
      final start = CourtyardSnapshot.fromStep(step: 0, totalStars: 0);
      final roof = CourtyardSnapshot.fromStep(step: 14, totalStars: 10);
      expect(pathPhraseForHome(start), 'A house will stand here.');
      expect(pathPhraseForHome(roof), 'The roof is on.');
    });

    test('win uses a stage line when crossing a band', () {
      final from = CourtyardSnapshot.fromStep(step: 4, totalStars: 6);
      final to = CourtyardSnapshot.fromStep(step: 5, totalStars: 8);
      expect(pathPhraseForWin(from: from, to: to), 'The fence holds the plot.');
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

  group('CourtyardArtFade', () {
    test('maps campaign steps onto neighboring plates', () {
      expect(
        CourtyardArtFade.assets.length,
        CourtyardArtFade.plateSteps.length,
      );
      expect(CourtyardArtFade.plateSteps, [
        0,
        2,
        4,
        6,
        8,
        10,
        12,
        14,
        16,
        18,
        20,
        22,
        24,
      ]);
      final empty = CourtyardArtFade.fromStep(0);
      expect(empty.fromIndex, 0);
      expect(empty.toIndex, 0);
      expect(empty.blend, 0);

      final path = CourtyardArtFade.fromStep(1);
      expect(path.fromIndex, 0);
      expect(path.toIndex, 1);
      expect(path.blend, closeTo(0.5, 0.001));

      final walls = CourtyardArtFade.fromStep(12);
      expect(walls.fromIndex, 5);
      expect(walls.toIndex, 6);
      expect(walls.blend, closeTo(1.0, 0.001));

      final roof = CourtyardArtFade.fromStep(13);
      expect(roof.fromIndex, 6);
      expect(roof.toIndex, 7);
      expect(roof.blend, closeTo(0.5, 0.001));

      final done = CourtyardArtFade.fromStep(24);
      expect(done.fromIndex, 11);
      expect(done.toIndex, 12);
      expect(done.blend, closeTo(1.0, 0.001));
    });

    test('evening overlay waits for a nearly finished house', () {
      final early = CourtyardSnapshot.fromStep(step: 12, totalStars: 72);
      final late = CourtyardSnapshot.fromStep(step: 24, totalStars: 72);
      expect(early.lifeArt, 0);
      expect(late.lifeArt, 1);
    });
  });
}
