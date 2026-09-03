import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_lot_build.dart';

void main() {
  test('96 stages are 12 eras of 8 steps', () {
    expect(CourtyardLotBuild.maxStage, 96);
    expect(CourtyardLotBuild.eraCount * CourtyardLotBuild.eraLength, 96);
    expect(houseEraPhrasesEn, hasLength(12));
    expect(pondEraPhrasesEn, hasLength(12));
    expect(petsEraPhrasesEn, hasLength(12));
    expect(guestEraPhrasesEn, hasLength(12));
    expect(houseEraPhrasesRu, hasLength(12));
  });

  test('era index follows the shack-to-castle table', () {
    expect(CourtyardLotBuild.eraIndex(0), 0);
    expect(CourtyardLotBuild.eraIndex(1), 0);
    expect(CourtyardLotBuild.eraIndex(8), 0);
    expect(CourtyardLotBuild.eraIndex(9), 1);
    expect(CourtyardLotBuild.eraIndex(24), 2);
    expect(CourtyardLotBuild.eraIndex(25), 3);
    expect(CourtyardLotBuild.eraIndex(37), 4);
    expect(CourtyardLotBuild.eraIndex(96), 11);
    expect(CourtyardLotBuild.eraNameEn(PlotKind.house, 1), 'Shack');
    expect(CourtyardLotBuild.eraNameEn(PlotKind.house, 9), 'Castle');
    expect(CourtyardLotBuild.eraNameRu(PlotKind.house, 11), 'Резиденция');
  });

  test('layer opacity fades in the next part during lerp', () {
    expect(CourtyardLotBuild.layerOpacity(0, 1), 0);
    expect(CourtyardLotBuild.layerOpacity(0.4, 1), closeTo(0.4, 0.001));
    expect(CourtyardLotBuild.layerOpacity(1, 1), 1);
    expect(CourtyardLotBuild.layerOpacity(23.5, 24), closeTo(0.5, 0.001));
    expect(CourtyardLotBuild.layerOpacity(24, 24), 1);
    expect(CourtyardLotBuild.layerOpacity(24, 25), 0);
  });

  test('plot stages map 24 frames across 96 levels, two steps per era', () {
    expect(PlotStages.frameCount, 24);
    expect(PlotStages.stagesPerFrame, 4);
    expect(PlotStages.currentFrame(0), 0);
    expect(PlotStages.nextFrame(0), 0);
    expect(PlotStages.currentFrame(0.4), 0);
    expect(PlotStages.nextFrame(0.4), 1);
    expect(PlotStages.nextOpacity(0.4), closeTo(0.4, 0.001));
    expect(PlotStages.currentFrame(1), 1);
    expect(PlotStages.nextFrame(1), 1);
    expect(PlotStages.nextOpacity(1), 0);
    expect(PlotStages.currentFrame(4), 1);
    expect(PlotStages.currentFrame(5), 2);
    expect(PlotStages.nextFrame(4.5), 2);
    expect(PlotStages.nextOpacity(4.5), closeTo(0.5, 0.001));
    expect(PlotStages.currentFrame(96), 24);
    expect(PlotStages.allAssets, hasLength(96));
    expect(
      PlotStages.assetOf(PlotKind.house, 7),
      'assets/courtyard/builds/house/07.png',
    );
    expect(PlotKind.guest.buildFolder, 'internet');
    expect(PlotKind.house.buildFolder, 'house');
    expect(
      PlotStages.assetOf(PlotKind.guest, 7),
      'assets/courtyard/builds/internet/07.png',
    );
    expect(PlotStages.frameProgress(0), 0);
    expect(PlotStages.remainingToNextFrame(0), 1);
    expect(PlotStages.remainingExact(0), 1);
    expect(PlotStages.frameProgress(1), 0);
    expect(PlotStages.remainingToNextFrame(1), 4);
    expect(PlotStages.remainingExact(1), 4);
    expect(PlotStages.frameProgress(3), closeTo(0.5, 0.001));
    expect(PlotStages.remainingToNextFrame(3), 2);
    expect(PlotStages.remainingExact(3), 2);
    expect(PlotStages.frameProgress(4), closeTo(0.75, 0.001));
    expect(PlotStages.remainingToNextFrame(4), 1);
    expect(PlotStages.remainingToNextFrame(4.2), 1);
    expect(PlotStages.remainingExact(4.2), closeTo(0.8, 0.001));
    expect(PlotStages.frameProgress(5), 0);
    expect(PlotStages.remainingToNextFrame(5), 4);
    expect(PlotStages.isMaxFrame(96), isTrue);
    expect(PlotStages.remainingToNextFrame(96), 0);
    expect(PlotStages.frameProgress(96), 1);
  });

  test('plots grow in campaign order: house, pond, guest, pets', () {
    expect(CourtyardLotBuild.revealOf(stage: 0, unlocked: false), 0);
    expect(CourtyardLotBuild.revealOf(stage: 0, unlocked: true), 0);
    expect(
      CourtyardLotBuild.revealOf(stage: 12, unlocked: true),
      closeTo(0.5, 0.001),
    );
    expect(CourtyardLotBuild.revealOf(stage: 24, unlocked: true), 1);
    expect(CourtyardLotBuild.revealOf(stage: 48, unlocked: true), 1);

    expect(PlotKind.order, [
      PlotKind.house,
      PlotKind.pond,
      PlotKind.guest,
      PlotKind.pets,
    ]);
    for (var id = 1; id <= 24; id++) {
      expect(Levels.plotKindOf(id), PlotKind.house, reason: 'level $id');
    }
    expect(Levels.plotKindOf(25), PlotKind.pond);
    expect(Levels.plotKindOf(49), PlotKind.guest);
    expect(Levels.plotKindOf(73), PlotKind.pets);

    final start = CourtyardEstate.fromUnlocked(1);
    expect(start.lot(PlotKind.house).unlocked, isTrue);
    expect(start.lot(PlotKind.house).stage, 0);
    expect(start.lot(PlotKind.pond).unlocked, isFalse);

    final houseMid = CourtyardEstate.fromUnlocked(13);
    expect(houseMid.lot(PlotKind.house).stage, 12);
    expect(houseMid.lot(PlotKind.pond).unlocked, isFalse);

    final houseDone = CourtyardEstate.fromUnlocked(25);
    expect(houseDone.lot(PlotKind.house).stage, 24);
    expect(houseDone.lot(PlotKind.pond).unlocked, isTrue);
    expect(houseDone.lot(PlotKind.pond).stage, 0);
    expect(houseDone.lot(PlotKind.guest).unlocked, isFalse);
  });

  test('each plot kind has its own era names', () {
    expect(CourtyardLotBuild.eraNameEn(PlotKind.pond, 4), 'Koi pond');
    expect(CourtyardLotBuild.eraNameEn(PlotKind.pets, 4), 'Pet house');
    expect(CourtyardLotBuild.eraNameEn(PlotKind.guest, 4), 'Screens');
    expect(CourtyardLotBuild.eraNameEn(PlotKind.guest, 8), 'Observatory');
  });
}
