import 'package:mahjong/l10n/app_localizations.dart';
import 'package:mahjong/l10n/catalog_text.dart';
import 'package:mahjong/l10n/format_text.dart';
import 'package:mahjong/models/garden.dart';
import 'package:mahjong/models/hub_goal.dart';
import 'package:mahjong/models/level_challenge.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/pet.dart';
import 'package:mahjong/models/pet_combat.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/models/seed_catalog.dart';
import 'package:mahjong/models/weekly_quests.dart';
import 'package:mahjong/utils/points_format.dart';
import 'package:mahjong/widgets/courtyard/courtyard_lot_build.dart';
import 'package:mahjong/widgets/courtyard/courtyard_progress.dart';

/// Game rules that choose an [AppLocalizations] message. No copy of its own.
extension GameText on AppLocalizations {
  String challengeGoal(LevelChallenge challenge, {int cleared = 0}) =>
      switch (challenge) {
        LevelChallenge.none => '',
        LevelChallenge.compactTower => challengeCompactTower,
        LevelChallenge.specialPair => challengeSpecialPair(cleared),
        LevelChallenge.noShuffle => challengeNoShuffle,
      };

  String plot(int cycle) => plotTitle(PlotKind.ofCycle(cycle));

  String plotTitle(PlotKind kind) => plotKindTitle(kind.name);

  String plotEra(PlotKind kind, int era) => plotEraName(kind, era);

  String plotLookProgress(PlotKind kind, int remaining) {
    final name = plotTitle(kind);
    if (remaining <= 0) return plotLookComplete(name);
    if (remaining == 1) return plotLookNextOne(name);
    return plotLookProgressText(remaining, name);
  }

  String winsUntilHouseUpgrade(int count) =>
      count <= 1 ? nextWinUpgradesHouse : winsUntilHouseUpgradeText(count);

  String winsUntilPondUpgrade(int count) =>
      count <= 1 ? nextWinImprovesPond : winsUntilPondUpgradeText(count);

  String hubDailiesUntilReward(int count) =>
      count <= 1 ? oneDailyUntilReward : hubDailiesUntilRewardText(count);

  String hubLevelsUntilReward(int count) =>
      count <= 1 ? oneLevelUntilReward : hubLevelsUntilRewardText(count);

  String houseUpgradeStatus({required int cost, required int shortfall}) {
    if (shortfall > 0) return pointsShortfall(shortfall);
    return houseUpgradeOffer(cost);
  }

  String nextBuildLook(PlotKind kind) => switch (kind) {
    PlotKind.house => nextHouseLook,
    PlotKind.pond => nextPondLook,
    _ => nextHouseLook,
  };

  String homeUpgradeRemaining(int remaining) =>
      buildUpgradeRemaining(PlotKind.house, remaining);

  String buildUpgradeRemaining(PlotKind kind, int remaining) {
    if (kind == PlotKind.pond) return winsUntilPondUpgrade(remaining);
    return winsUntilHouseUpgrade(remaining);
  }

  String plotTitleToward(PlotKind kind) => plotKindTitleToward(kind.name);

  String hubStarsUntilPlot(PlotKind kind, int n) =>
      hubStarsUntilPlotText(n, plotTitleToward(kind));

  String hubQuestRemaining(QuestProgress quest) {
    final left = (quest.target - quest.current).clamp(0, quest.target);
    return switch (quest.def.kind) {
      QuestKind.stars => hubStarsUntilReward(left),
      QuestKind.dailyWins => hubDailiesUntilReward(left),
      QuestKind.campaignClears => hubLevelsUntilReward(left),
      QuestKind.threeStar => hubThreeStarUntilReward,
      QuestKind.streakHold => hubDailiesUntilReward(left),
    };
  }

  String hubGoalText(HubGoal goal) {
    return switch (goal.kind) {
      HubGoalKind.plotUnlock => hubStarsUntilPlot(
        goal.plot ?? PlotKind.house,
        goal.remaining,
      ),
      HubGoalKind.plotLook =>
        goal.plot == PlotKind.house && goal.pointsCost != null
            ? houseUpgradeStatus(
                cost: goal.pointsCost!,
                shortfall: goal.pointsShort ?? goal.remaining,
              )
            : plotLookProgress(goal.plot ?? PlotKind.house, goal.remaining),
      HubGoalKind.dailyReward => hubDailiesUntilReward(goal.remaining),
      HubGoalKind.questRemain =>
        goal.quest == null
            ? hubStarsUntilReward(goal.remaining)
            : hubQuestRemaining(goal.quest!),
      HubGoalKind.questClaim => hubQuestRewardReady,
      HubGoalKind.petUnlock => hubLevelUnlocksPet(
        goal.levelId ?? Levels.plotStartId(PlotKind.pets),
      ),
    };
  }

  String streakWinSubtitle(int n) {
    if (n <= 0) return streakLabel(0);
    if (n < 3) return streakNights(n);
    if (n == 3) return streakKept;
    return streakLabel(n);
  }

  String dailyStreakSubtitle({
    required int streak,
    required bool completedToday,
  }) {
    if (completedToday) {
      if (streak >= 3) return streakKept;
      if (streak > 0) return streakNights(streak);
      return clearedToday;
    }
    if (streak > 0) return streakAtRisk;
    return keepTheLight;
  }

  String pointsReward(int value) =>
      pointsRewardText(value, formatPoints(value));

  String scoreValue(int value) => '$value';

  String combo(int n) => '×$n';

  String pointsGain(int value) => '+$value';

  String boostTooltip(String name, int left, {required bool adsAvailable}) {
    if (left > 0) return name;
    if (adsAvailable) return watchAd(name);
    return noneLeft;
  }

  String coachMessage(String stepName) => switch (stepName) {
    'tapFree' => coachTapFree,
    'matchPair' => coachMatchPair,
    _ => coachTrayLimit,
  };

  String difficulty(LevelDef level) {
    final n = level.storyId;
    if (n <= 5) return easy;
    if (n <= 12) return normal;
    if (n <= 20) return hard;
    return expert;
  }

  String style(LevelDef level) {
    return switch (level.style) {
      'fruit' => styleFruit,
      'nature' => styleNature,
      'court' => styleCourt,
      'myth' => styleMyth,
      'classic' => styleClassic,
      'shape' => styleShape,
      'number' => styleNumber,
      _ => styleMix,
    };
  }

  String levelTitle(LevelDef level, {PlotKind? plotKind}) {
    if (level.title == 'Today') return today;
    return plotTitle(plotKind ?? level.plotKind);
  }

  String displayName(String raw) {
    if (raw.isEmpty || raw == 'You' || raw == 'Вы' || raw == 'Ви') return you;
    if (raw == 'Player' || raw == 'Игрок' || raw == 'Гравець') return player;
    return raw;
  }

  String firstHomePhraseFor(PlotKind kind) => switch (kind) {
    PlotKind.house => firstPhraseHouse,
    PlotKind.pond => firstPhrasePond,
    PlotKind.pets => firstPhrasePets,
    PlotKind.guest => firstPhraseGuest,
  };

  String get firstHomePhrase => firstHomePhraseFor(PlotKind.house);

  List<String> pathStagePhrasesFor(PlotKind kind) => [
    for (var era = 0; era < 12; era++) eraPhrase(kind, era),
  ];

  List<String> get pathStagePhrases => pathStagePhrasesFor(PlotKind.house);

  List<String> pathWarmPhrasesFor(PlotKind kind) => [
    for (var i = 0; i < 3; i++) warmPhrase(kind, i),
  ];

  List<String> get pathWarmPhrases => pathWarmPhrasesFor(PlotKind.house);

  String pathLifePhraseFor(PlotKind kind) => switch (kind) {
    PlotKind.house => pathLifeHouse,
    PlotKind.pond => pathLifePond,
    PlotKind.pets => pathLifePets,
    PlotKind.guest => pathLifeGuest,
  };

  String get pathLifePhrase => pathLifePhraseFor(PlotKind.house);

  String questTitle(String id) => switch (id) {
    'daily3' => questDaily3,
    'stars8' => questStars8,
    'clears4' => questClears4,
    'threeStar1' => questThreeStar1,
    'streak3' => questStreak3,
    _ => id,
  };

  String weekEventTitle(String id) => switch (id) {
    'garden' => weekGarden,
    'court' => weekCourt,
    'lanterns' => weekLanterns,
    'myth' => weekMyth,
    'harvest' => weekHarvest,
    _ => weekDefault,
  };

  String petsTitle(int count) => count > 1 ? pets : pet;

  String petName(PetKind kind) => switch (kind) {
    PetKind.cat => petCat,
    PetKind.dog => petDog,
    PetKind.raccoon => petRaccoon,
    PetKind.hamster => petHamster,
    PetKind.fox => petFox,
  };

  String petNeedLabel(PetNeed need) => switch (need) {
    PetNeed.hunger => petNeedHunger,
    PetNeed.play => petNeedPlay,
    PetNeed.rest => petNeedRest,
  };

  String petMoodLine(PetKind kind, PetMood mood) {
    final name = petName(kind);
    return switch (mood) {
      PetMood.content => petMoodContent(name),
      PetMood.asking => petMoodAsking(name),
      PetMood.starving => petMoodStarving(name),
    };
  }

  String petCareWinLine(PetKind kind, PetNeed need) {
    final name = petName(kind);
    return switch (need) {
      PetNeed.hunger => petCareHunger(name),
      PetNeed.play => petCarePlay(name),
      PetNeed.rest => petCareRest(name),
    };
  }

  String petRole(PetRole role) => switch (role) {
    PetRole.attacker => petRoleAttacker,
    PetRole.defender => petRoleDefender,
  };

  String petStat(PetRole role) => switch (role) {
    PetRole.attacker => petStatAttack,
    PetRole.defender => petStatDefense,
  };

  String petSlot(GearSlot slot) => switch (slot) {
    GearSlot.main => gearSlotMain,
    GearSlot.accessory => gearSlotAccessory,
  };

  String gearName(String id) => gearItemName(id);

  String gearOfferLabel({required PetRole role, required GearSlot slot}) =>
      gearOfferText(petRole(role), petSlot(slot));

  String petBadgeLabel(PetRole role, int level) =>
      petBadgeText(petRole(role), petLevelLabel(level));

  String homePathPhrase(CourtyardSnapshot snapshot, {double? stage}) {
    final era = CourtyardLotBuild.eraIndex(stage ?? snapshot.step);
    return eraPhrase(snapshot.plotKind, era);
  }

  String winPathPhrase({
    required CourtyardSnapshot from,
    required CourtyardSnapshot to,
    double? fromStage,
    double? toStage,
  }) {
    final a = fromStage ?? from.step;
    final b = toStage ?? to.step;
    final fromEra = CourtyardLotBuild.eraIndex(a);
    final toEra = CourtyardLotBuild.eraIndex(b);
    if (toEra > fromEra) return eraPhrase(to.plotKind, toEra);
    if (b > a + 0.01) return warmPhrase(to.plotKind, b.floor());
    if (to.totalStars > from.totalStars ||
        to.streakLife > from.streakLife + 0.01 ||
        to.festival > from.festival + 0.01) {
      return pathLifePhraseFor(to.plotKind);
    }
    return warmPhrase(to.plotKind, 0);
  }

  String courtyardSemantic(int cycle) =>
      courtyardSemanticKind(PlotKind.ofCycle(cycle));

  String courtyardSemanticKind(PlotKind kind) =>
      courtyardSemanticText(plotTitle(kind));

  String petsButtonSemantic({required bool asking}) {
    if (asking) return petsNeedCare;
    return pets;
  }

  String dailyButtonSemantic({
    required int streak,
    required bool completedToday,
  }) {
    final status = dailyStreakSubtitle(
      streak: streak,
      completedToday: completedToday,
    );
    return dailyButtonSemanticText(today, status);
  }

  String levelCardSemantic({
    required int localId,
    required String title,
    required bool unlocked,
    required int stars,
    required bool inProgress,
  }) {
    if (!unlocked) return levelCardLocked(localId);
    final star = stars == 0 ? levelStarsNone : levelStarsSome(stars);
    final progress = inProgress ? levelInProgress : '';
    return levelCardOpen(localId, title, star, progress);
  }

  String boostSemantic(String name, int left, {required bool adsAvailable}) {
    if (left > 0) return boostLeft(name, left);
    if (adsAvailable) return watchAd(name);
    return boostNone(name);
  }

  String tileFamilyName(String family) {
    switch (family) {
      case 'fruit':
        return familyFruit;
      case 'flower':
        return familyFlower;
      case 'animal':
        return familyAnimal;
      case 'bamboo':
        return familyBamboo;
      case 'character':
        return familyCharacter;
      case 'dot':
      case 'dots':
        return familyDot;
      case 'dragon':
        return familyDragon;
      case 'wind':
        return familyWind;
      case 'season':
        return familySeason;
      case 'number':
        return familyNumber;
      case 'shape':
        return familyShape;
      case 'soft':
      case 'tile':
        return familyTile;
      case 'art':
        return familyArt;
      case 'clown':
        return familyClown;
      case 'emperor':
        return familyEmperor;
      case 'joker':
        return familyJoker;
      case 'profession':
        return familyProfession;
      case 'queen':
        return familyQueen;
      case 'east':
        return familyEast;
      case 'south':
        return familySouth;
      case 'west':
        return familyWest;
      case 'north':
        return familyNorth;
      case 'spring':
        return familySpring;
      case 'summer':
        return familySummer;
      case 'fall':
      case 'autumn':
        return familyAutumn;
      case 'winter':
        return familyWinter;
      default:
        if (family.isEmpty) return family;
        return '${family[0].toUpperCase()}${family.substring(1)}';
    }
  }

  String tileSymbolName(String symbol) {
    var s = symbol.toLowerCase().trim();
    if (s.startsWith('set1-')) s = s.substring(5);
    switch (s) {
      case 'wind-east':
        return windEast;
      case 'wind-south':
        return windSouth;
      case 'wind-west':
        return windWest;
      case 'wind-north':
        return windNorth;
    }
    final parts = s
        .split(RegExp(r'[-_/]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return symbol;
    final family = tileFamilyName(parts.first);
    if (parts.length == 1) return family;
    final rest = parts
        .skip(1)
        .map((part) {
          final n = int.tryParse(part);
          if (n != null) return '$n';
          return tileFamilyName(part);
        })
        .join(' ');
    return '$family $rest';
  }

  String tileSemanticLabel({
    required String symbol,
    required bool free,
    required bool hinted,
    required bool inTray,
    required bool removing,
  }) {
    final name = tileSymbolName(symbol);
    if (removing) return tileRemoving(name);
    if (inTray) return hinted ? tileInTrayHinted(name) : tileInTray(name);
    if (hinted) return free ? tileFreeHinted(name) : tileLockedHinted(name);
    return free ? tileFreeState(name) : tileLockedState(name);
  }

  String seedName(SeedSpecies species) => switch (species) {
    SeedSpecies.amberbell => seedAmberbell,
    SeedSpecies.mistfern => seedMistfern,
    SeedSpecies.glassreed => seedGlassreed,
    SeedSpecies.crimsonplum => seedCrimsonplum,
    SeedSpecies.nightlotus => seedNightlotus,
    SeedSpecies.starbamboo => seedStarbamboo,
  };

  String seedBlurb(SeedSpecies species) => switch (species) {
    SeedSpecies.amberbell => seedBlurbAmberbell,
    SeedSpecies.mistfern => seedBlurbMistfern,
    SeedSpecies.glassreed => seedBlurbGlassreed,
    SeedSpecies.crimsonplum => seedBlurbCrimsonplum,
    SeedSpecies.nightlotus => seedBlurbNightlotus,
    SeedSpecies.starbamboo => seedBlurbStarbamboo,
  };

  String seedShare(int count) => '1/$count';

  String seedClassName(SeedClass seedClass) => switch (seedClass) {
    SeedClass.common => seedClassCommon,
    SeedClass.nutrient => seedClassNutrient,
    SeedClass.rare => seedClassRare,
  };

  String catalogDuration(Duration duration) {
    final total = duration.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    if (seconds == 0) return seedMinutes(minutes);
    return seedSpan(minutes, seconds);
  }

  String seedChanceSummary(List<SeedClassChance> chances) => chances
      .map(
        (chance) =>
            seedClassLine(seedClassName(chance.seedClass), chance.percent),
      )
      .join(', ');

  String gardenBedLabel({
    required int number,
    required String name,
    required String stage,
    required String time,
    required bool ready,
  }) {
    if (ready) return gardenBedReady(number, name);
    return gardenBedGrowing(number, name, stage, time);
  }

  String growthStage(GrowthStage stage) => switch (stage) {
    GrowthStage.sown => growthSown,
    GrowthStage.sprout => growthSprout,
    GrowthStage.growing => growthGrowing,
    GrowthStage.ripe => growthRipe,
  };

  String plantOrigin(String source) {
    if (source == 'house_production') return plantOriginHouse;
    return plantOriginOther(source);
  }

  String foxGoal(int stage) => switch (stage) {
    0 => foxGoal0,
    1 => foxGoal1,
    2 => foxGoal2,
    _ => foxGoalDone,
  };

  String rewardTitle(String id) => switch (id) {
    'pond' => rewardPond,
    'swing' => rewardSwing,
    'flowerBed' => rewardFlowerBed,
    _ => id,
  };
}
