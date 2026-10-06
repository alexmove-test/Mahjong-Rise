// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get continueGame => 'Continue';

  @override
  String get noShuffleMoves =>
      'No pair available — try undo, a hint or a magnet';

  @override
  String get shuffleLockedChallenge =>
      'Shuffling is disabled for this challenge';

  @override
  String get specialTile => 'Starred goal tile';

  @override
  String continueWith(String title) {
    return 'Continue · $title';
  }

  @override
  String get newPlot => 'New plot';

  @override
  String get previousPlot => 'Previous plot';

  @override
  String get nextPlot => 'Next plot';

  @override
  String get plotLockedHint => 'Next wins will grow this plot';

  @override
  String neighborYard(String name) {
    return '$name\'s courtyard';
  }

  @override
  String neighborRating(String name, int rating) {
    return '$name · $rating';
  }

  @override
  String get neighboringCourtyard => 'A neighboring courtyard';

  @override
  String get courtyardPanHint => 'Drag to look around the courtyard';

  @override
  String houseStateTitle(int state, int total) {
    return 'House · $state/$total';
  }

  @override
  String get houseFullyUpgraded => 'House fully upgraded';

  @override
  String get houseDetailsShow => 'Details';

  @override
  String get houseDetailsHide => 'Hide';

  @override
  String upgradeHouseForText(String price) {
    return 'Upgrade for $price';
  }

  @override
  String pointsShortfallText(String amount) {
    return '$amount points short';
  }

  @override
  String houseUpgradeOfferText(String cost) {
    return 'House upgrade · $cost';
  }

  @override
  String get nextHouseLook => 'Next house look';

  @override
  String houseLookLine(int built, int total) {
    return 'House looks built: $built of $total';
  }

  @override
  String hubLevelUnlocksPet(int id) {
    return 'Level $id unlocks a pet';
  }

  @override
  String get hubQuestRewardReady => 'Weekly reward is ready';

  @override
  String get hubThreeStarUntilReward => 'A 3★ clear unlocks the reward';

  @override
  String get today => 'Today';

  @override
  String get clearedToday => 'Cleared today';

  @override
  String streakNights(int n) {
    return 'Day $n of 3';
  }

  @override
  String get streakKept => 'Three nights kept';

  @override
  String get streakAtRisk => 'Goes out at midnight';

  @override
  String get keepTheLight => 'Keep the light';

  @override
  String openedProgress(int unlocked, int total) {
    return '$unlocked/$total open';
  }

  @override
  String get courtyard => 'Courtyard';

  @override
  String get howToPlay => 'How to play';

  @override
  String get levels => 'Levels';

  @override
  String get retry => 'Retry';

  @override
  String get playAgain => 'Play again';

  @override
  String get next => 'Next';

  @override
  String get menu => 'Menu';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacySettings => 'Privacy settings';

  @override
  String get hideBannerButton => '24 hours';

  @override
  String get hideBannerTitle => 'Hide the banner for 24 hours';

  @override
  String get hideBannerSubtitle => 'Watch an ad. It stays off on this device.';

  @override
  String get hideBannerWatch => 'Watch ad';

  @override
  String get hideBannerNotNow => 'Not now';

  @override
  String get aboutGame => 'About game';

  @override
  String builtAt(String time) {
    return 'Built: $time';
  }

  @override
  String get settings => 'Settings';

  @override
  String get sound => 'Sound';

  @override
  String get music => 'Music';

  @override
  String get hapticFeedback => 'Haptic feedback';

  @override
  String get qMode => 'Q mode';

  @override
  String get qModeHint => 'Magnet ads grant 50';

  @override
  String get dimCoveredTiles => 'Dim covered tiles';

  @override
  String get dimCoveredTilesHint => 'Gray out tiles you cannot pick';

  @override
  String get tableLook => 'Table look';

  @override
  String get tableLookClassic => 'Classic mahjong';

  @override
  String get tableLookClassicHint => '3D tiles and copper buttons';

  @override
  String get tableLookCasual => 'Bright match';

  @override
  String get tableLookCasualHint => 'Flat tiles, green and gold';

  @override
  String get tableLookPremium => 'New';

  @override
  String get tableLookPremiumHint => 'Ivory tiles, warm wood table';

  @override
  String get tableLookGift => 'Table';

  @override
  String get tableLookUse => 'Use';

  @override
  String get tableLookLockedHint => 'Unlock as a courtyard gift';

  @override
  String get tableLookSettingsHint =>
      'You can choose different table themes in the menu';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get tileLocked => 'Tile is locked';

  @override
  String get trayFull => 'Tray is full';

  @override
  String get trayFullHint => 'No matching pair.';

  @override
  String get noMovesShuffle => 'No moves — shuffle';

  @override
  String get youWin => 'You win!';

  @override
  String get noFreeTiles => 'No free tiles';

  @override
  String get shuffled => 'Shuffled';

  @override
  String get stillNoMoves => 'Still no moves';

  @override
  String get loadingAd => 'Loading ad…';

  @override
  String get rewardNotEarned => 'Reward not earned';

  @override
  String get adUnavailable => 'Could not load ad. Try again.';

  @override
  String get noUsefulMoves => 'No useful moves';

  @override
  String get continuing => 'Continuing';

  @override
  String get moveUndone => 'Move undone';

  @override
  String get noMatchingTiles => 'No matching tiles';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get dailyComplete => 'Daily complete';

  @override
  String streakLabel(int n) {
    return 'Streak: $n';
  }

  @override
  String score(int value) {
    return 'Score: $value';
  }

  @override
  String starsCount(int n) {
    return '$n stars';
  }

  @override
  String get dailyBonus => 'Bonus: +1 hint and shuffle';

  @override
  String get points => 'Points';

  @override
  String pointsBalanceText(String value) {
    return 'Points: $value';
  }

  @override
  String get pointsShopTitle => 'Points';

  @override
  String get pointsShopSubtitle =>
      'Earned on every cleared table. Top up any time.';

  @override
  String pointsEarnRuleText(int perClear, int perStar) {
    return 'Clear a level: +$perClear, plus +$perStar per star.';
  }

  @override
  String pointsPackBonus(int percent) {
    return '+$percent% bonus';
  }

  @override
  String get pointsPackPopular => 'Most taken';

  @override
  String get pointsPackBest => 'Best value';

  @override
  String get pointsBuy => 'Buy';

  @override
  String pointsCreditedText(String value) {
    return 'Credited +$value';
  }

  @override
  String get pointsPurchaseCancelled => 'Purchase cancelled';

  @override
  String get pointsPurchaseUnavailable => 'Store is unavailable';

  @override
  String get pointsDemoNote =>
      'Payments are not wired up yet — the pack lands right away.';

  @override
  String get pointsWatchAd => 'Watch ad';

  @override
  String pointsWatchAdRewardText(String value) {
    return 'Free +$value';
  }

  @override
  String level(int id) {
    return 'Level $id';
  }

  @override
  String get anotherLevelCleared => 'Another level cleared';

  @override
  String get newBest => 'New best!';

  @override
  String levelUnlocked(int id) {
    return 'Level $id unlocked';
  }

  @override
  String get shuffle => 'Shuffle';

  @override
  String get magnet => 'Magnet';

  @override
  String get hint => 'Hint';

  @override
  String get undo => 'Undo';

  @override
  String watchAd(String name) {
    return 'Watch ad → $name';
  }

  @override
  String boostEarnedText(int count, String name) {
    return '+$count $name';
  }

  @override
  String get noneLeft => 'none left';

  @override
  String get coachTapFree => 'Take a free tile — open on top and one side';

  @override
  String get coachMatchPair => 'A pair in the tray clears';

  @override
  String get coachTrayLimit =>
      'The tray holds 4 — fill it with no pair and you lose';

  @override
  String get easy => 'Easy';

  @override
  String get normal => 'Normal';

  @override
  String get hard => 'Hard';

  @override
  String get expert => 'Expert';

  @override
  String get you => 'You';

  @override
  String get player => 'Player';

  @override
  String get yourName => 'Your name';

  @override
  String get youClimbed => 'You climbed!';

  @override
  String rankClimbPlaces(int from, int to) {
    return 'Place $from → $to';
  }

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get refresh => 'Refresh';

  @override
  String get changeName => 'Change name';

  @override
  String get nameNotAllowed => 'That name isn’t allowed. Choose another.';

  @override
  String get rankingNamesNote =>
      'Names are chosen by players. Report or hide anyone who breaks the rules.';

  @override
  String get reportPlayer => 'Report or hide';

  @override
  String get reportName => 'Report this name';

  @override
  String get hidePlayer => 'Hide this player';

  @override
  String get reportThanks => 'Thanks. We’ll review this name.';

  @override
  String get playerHidden => 'This player is hidden on your device.';

  @override
  String get name => 'Name';

  @override
  String onlineRanking(int top) {
    return 'Online ranking · top $top';
  }

  @override
  String get offlineRanking => 'Offline: only your result is shown.';

  @override
  String get rankingFormula =>
      'Rating: stars × 100,000 + best scores + campaign progress.';

  @override
  String get scorePlotsLegend => 'Score : plots';

  @override
  String get loadRankingFailed => 'Could not load the online ranking';

  @override
  String starsLevel(int stars, int unlocked) {
    return '$stars ★ · lv. $unlocked';
  }

  @override
  String get ad => 'AD';

  @override
  String get done => 'Done';

  @override
  String get closeWithoutReward => 'Close without reward';

  @override
  String get simulatedAd => 'Simulated ad';

  @override
  String get watchClipForBoost => 'Watch the clip to earn a boost';

  @override
  String get claimReward => 'Claim reward';

  @override
  String get watchingAd => 'Watching ad…';

  @override
  String get weeklyQuests => 'Weekly quests';

  @override
  String get claim => 'Claim';

  @override
  String get claimed => 'Claimed';

  @override
  String get questBonus => '+1 hint and shuffle';

  @override
  String get extraBoostThisWeek => '+1 boost on today’s table';

  @override
  String get seasonClosed => 'Season closed';

  @override
  String lastWeekPlace(int rank) {
    return 'Last week: place $rank';
  }

  @override
  String lastWeekScore(String rating) {
    return 'Score $rating';
  }

  @override
  String get reminders => 'Daily reminders';

  @override
  String get reminderDailyTitle => 'Your courtyard is waiting';

  @override
  String get reminderDailyBody => 'A new table is ready today.';

  @override
  String get reminderStreakTitle => 'Your streak is at risk';

  @override
  String get reminderStreakBody => 'The third lantern goes out at midnight.';

  @override
  String get reminderWeekTitle => 'A new courtyard season';

  @override
  String get reminderWeekBody => 'Weekly quests and ranking have reset.';

  @override
  String get pet => 'Pet';

  @override
  String get pets => 'Pets';

  @override
  String get chooseAPet => 'Choose a companion';

  @override
  String get addPet => 'Add a companion';

  @override
  String get petInviteAdopt => 'A friend is waiting';

  @override
  String get petInviteShow => 'Show pets';

  @override
  String get petYardStartAdventure => 'Start an adventure';

  @override
  String get petYardVisit => 'Visit the den';

  @override
  String get petYardShow => 'Show in yard';

  @override
  String get petYardShowing => 'In the yard';

  @override
  String get petYardShowAll => 'Show everyone in the yard';

  @override
  String get petCareHint =>
      'Wins help them play and rest. Feed harvested plants from the warehouse.';

  @override
  String get petStarvingLine =>
      'They are starving. Feed a harvested plant from the warehouse.';

  @override
  String get petRemindersPromptTitle => 'Hungry reminders?';

  @override
  String get petRemindersPromptBody => 'We can ping you when they get hungry.';

  @override
  String get petRemindersYes => 'Remind me';

  @override
  String get petRemindersLater => 'Not now';

  @override
  String reminderPetHungerTitle(String name) {
    return '$name is hungry';
  }

  @override
  String get reminderPetHungerBody =>
      'Feed a harvested plant from the warehouse.';

  @override
  String reminderPetPlayTitle(String name) {
    return '$name wants to play';
  }

  @override
  String get reminderPetPlayBody => 'Clear a table to play with them.';

  @override
  String reminderPetRestTitle(String name) {
    return '$name wants to rest';
  }

  @override
  String get reminderPetRestBody => 'Clear a table so they can rest.';

  @override
  String reminderPetStarveTitle(String name) {
    return '$name is starving';
  }

  @override
  String get reminderPetStarveBody =>
      'Feed a harvested plant from the warehouse.';

  @override
  String petLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String petLevelShort(int level) {
    return 'Lv $level';
  }

  @override
  String get petMaxLevel => 'Maximum level';

  @override
  String petXpLabel(int xp, int need) {
    return 'Experience $xp / $need';
  }

  @override
  String petStrengthLineText(
    String stat,
    int total,
    int base,
    int main,
    int accessory,
  ) {
    return '$stat $total = base $base + item $main + accessory $accessory';
  }

  @override
  String petLevelChange(int from, int to) {
    return 'Level $from → $to';
  }

  @override
  String petStatChange(String stat, int from, int to) {
    return '$stat $from → $to';
  }

  @override
  String get petFeed => 'Feed';

  @override
  String get petFeedTitle => 'Choose a plant';

  @override
  String get petFeedEmpty => 'No harvested plants in the warehouse.';

  @override
  String get petFeedPointless => 'Fully fed, and already at maximum level.';

  @override
  String petFeedXp(int xp) {
    return 'Experience: $xp';
  }

  @override
  String get petFeedSatiety => 'Restores hunger. Strength will not grow.';

  @override
  String get petFeedConfirm => 'Feed this plant';

  @override
  String petFedReaction(String name) {
    return '$name enjoys the meal.';
  }

  @override
  String get petFeedFailed => 'Could not save. The plant was not spent.';

  @override
  String get petFeedMissing => 'That plant is no longer in the warehouse.';

  @override
  String get petSlotEmpty => 'Empty';

  @override
  String get petGuardAction => 'Guard the garden';

  @override
  String get petGuarding => 'Guarding the garden';

  @override
  String get petStopGuard => 'Stop guarding';

  @override
  String get petRaidAction => 'Choose for raids';

  @override
  String get petRaiding => 'Chosen for raids';

  @override
  String get petStopRaid => 'Clear raid choice';

  @override
  String gearBonus(int bonus) {
    return '+$bonus strength';
  }

  @override
  String gearPriceText(String price) {
    return '$price points';
  }

  @override
  String gearLevelRequired(int level) {
    return 'Requires level $level';
  }

  @override
  String gearIfEquipped(String stat, int from, int to) {
    return 'If equipped: $stat $from → $to';
  }

  @override
  String get gearBuy => 'Buy';

  @override
  String get gearEquip => 'Equip';

  @override
  String get gearUnequip => 'Take off';

  @override
  String gearWornBy(String name) {
    return 'Worn by $name';
  }

  @override
  String gearShortfallText(String shortfall) {
    return 'Need $shortfall more points';
  }

  @override
  String get gearBuyFailed => 'Could not save. Points were not spent.';

  @override
  String gardenGuardLabel(String name, int power) {
    return '$name guards the garden. Defense $power';
  }

  @override
  String get gardenNoDefender => 'No defender yet';

  @override
  String get gardenUnguarded => 'Garden is unguarded';

  @override
  String get boardSemantic => 'Board';

  @override
  String traySemantic(int filled, int capacity) {
    return 'Tray, $filled of $capacity';
  }

  @override
  String get trayEmptySlot => 'Empty slot';

  @override
  String get trayAlmostFull => 'One space left — find a pair';

  @override
  String get houseCardTitle => 'House';

  @override
  String get seedsHeading => 'Seeds';

  @override
  String seedsButton(int count) {
    return 'Seeds · $count';
  }

  @override
  String seedPowerStep(int from, int to) {
    return 'Seed power: $from → $to';
  }

  @override
  String seedCostStep(int from, int to) {
    return 'Production cost: $from → $to points';
  }

  @override
  String seedSpeciesUnlock(String name) {
    return 'New seed: $name';
  }

  @override
  String seedDurationStep(String from, String to) {
    return 'Production time: $from → $to';
  }

  @override
  String seedChanceStep(String summary) {
    return 'Chances: $summary';
  }

  @override
  String get seedClassCommon => 'Common';

  @override
  String get seedClassNutrient => 'Nutrient';

  @override
  String get seedClassRare => 'Rare';

  @override
  String seedClassLine(String name, int percent) {
    return '$name $percent%';
  }

  @override
  String seedSpan(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String seedPowerLabel(int power) {
    return 'Feed: $power';
  }

  @override
  String seedPowerPending(int power) {
    return 'Expected seed power: $power';
  }

  @override
  String seedMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get seedSpeciesHeading => 'Possible seeds';

  @override
  String get seedEqualChance => 'Both species in a class are equally likely';

  @override
  String produceSeedForText(String price) {
    return 'Produce a seed · $price points';
  }

  @override
  String get claimSeed => 'Collect seed';

  @override
  String get seedAdded => 'Seed added to storage';

  @override
  String get openSeedStorage => 'Open storage';

  @override
  String get seedPurpose => 'A plant can be grown from this seed.';

  @override
  String seedHouseLevel(int level) {
    return 'Grown by house level $level';
  }

  @override
  String seedReceived(String date) {
    return 'Received $date';
  }

  @override
  String seedGroupCount(int count) {
    return '×$count';
  }

  @override
  String get seedSortPower => 'By feed';

  @override
  String get seedSortTime => 'By time received';

  @override
  String get seedProducing => 'A seed is growing';

  @override
  String get seedReadyTitle => 'The seed is ready';

  @override
  String get seedUnknown => 'Unknown seed';

  @override
  String seedTimeLeft(int minutes, int seconds) {
    return '$minutes min $seconds sec left';
  }

  @override
  String get seedBadgeIdle => 'Seed production is available';

  @override
  String seedBadgeProducing(String time) {
    return 'Seed growing, $time left';
  }

  @override
  String get seedBadgeReady => 'Seed ready to collect';

  @override
  String get seedReadyMark => 'Ready';

  @override
  String get seedPlayMahjong => 'Play mahjong';

  @override
  String get produceFirstSeed => 'Produce the first seed';

  @override
  String get seedsEmptyBody => 'The house has not produced a seed yet.';

  @override
  String seedStackLabel(String name, int power, int count) {
    return '$name, feed $power, $count';
  }

  @override
  String get seedProductionTitle => 'Seed production';

  @override
  String plantsButton(int count) {
    return 'Plants · $count';
  }

  @override
  String get warehouseTitle => 'Warehouse';

  @override
  String warehouseSemantic(int count) {
    return 'Warehouse, $count plants';
  }

  @override
  String get warehouseEmptyBody => 'Harvested plants will be kept here';

  @override
  String get openGarden => 'Open the garden';

  @override
  String plantActionText(int seeds, String points) {
    return 'Plant · $seeds seed + $points points';
  }

  @override
  String get chooseSeedTitle => 'Choose a seed';

  @override
  String get noSeedsBody => 'There are no seeds yet. Produce one in the house.';

  @override
  String get openHouseProduction => 'Open production';

  @override
  String gardenBedEmpty(int number) {
    return 'Bed $number, empty';
  }

  @override
  String bedTitle(int number) {
    return 'Bed $number';
  }

  @override
  String get harvestAction => 'Collect';

  @override
  String get harvestMark => 'Collect';

  @override
  String plantPower(int power) {
    return 'Feed: $power';
  }

  @override
  String plantCostLabelText(String points) {
    return 'Planting cost: $points points';
  }

  @override
  String growDurationLabel(int minutes) {
    return 'Growing time: $minutes min';
  }

  @override
  String seedsAvailable(int count) {
    return 'Available: $count';
  }

  @override
  String get plantPreviewLabel => 'Future plant';

  @override
  String plantVariant(String variant) {
    return 'Look: $variant';
  }

  @override
  String plantedOn(String date) {
    return 'Planted $date';
  }

  @override
  String maturedOn(String date) {
    return 'Matured $date';
  }

  @override
  String harvestedOn(String date) {
    return 'Collected $date';
  }

  @override
  String get gardenSaveFailed => 'Could not save. Nothing was spent.';

  @override
  String get gardenNotReady => 'Not ready yet';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageThai => 'ไทย';

  @override
  String get challengeCompactTower => 'Tower: clear every layer';

  @override
  String challengeSpecialPair(int cleared) {
    return 'Remove the two starred tiles · $cleared/2';
  }

  @override
  String get challengeNoShuffle => 'Clear the board without shuffling';

  @override
  String plotKindTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'house': 'House',
      'pond': 'Pond',
      'pets': 'Pets',
      'guest': 'Guest house',
      'other': 'House',
    });
    return '$_temp0';
  }

  @override
  String plotKindTitleToward(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'house': 'House',
      'pond': 'Pond',
      'pets': 'Pets',
      'guest': 'Guest house',
      'other': 'House',
    });
    return '$_temp0';
  }

  @override
  String plotLookComplete(String name) {
    return '$name is complete';
  }

  @override
  String plotLookNextOne(String name) {
    return '1 level until the next $name look';
  }

  @override
  String plotLookProgressText(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels until the next $name look',
    );
    return '$_temp0';
  }

  @override
  String get nextWinUpgradesHouse => 'Your next win upgrades the house';

  @override
  String winsUntilHouseUpgradeText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins until the house upgrade',
      one: '$count win until the house upgrade',
    );
    return '$_temp0';
  }

  @override
  String get nextWinImprovesPond => 'Your next win improves the pond';

  @override
  String winsUntilPondUpgradeText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins until the pond grows',
      one: '$count win until the pond grows',
    );
    return '$_temp0';
  }

  @override
  String get nextPondLook => 'Next pond look';

  @override
  String hubStarsUntilPlotText(int count, String dest) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more stars until the $dest',
      one: '1 more star until the $dest',
      zero: '1 more star until the $dest',
    );
    return '$_temp0';
  }

  @override
  String get oneDailyUntilReward => 'One daily until the reward';

  @override
  String hubDailiesUntilRewardText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dailies until the reward',
      one: '$count daily until the reward',
    );
    return '$_temp0';
  }

  @override
  String get oneLevelUntilReward => 'One level until the reward';

  @override
  String hubLevelsUntilRewardText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels until the reward',
      one: '$count level until the reward',
    );
    return '$_temp0';
  }

  @override
  String courtyardLevelsUntilGift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels until a courtyard gift',
      one: 'One level until a courtyard gift',
      zero: 'One level until a courtyard gift',
    );
    return '$_temp0';
  }

  @override
  String hubStarsUntilReward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more stars until the reward',
      one: '1 more star until the reward',
      zero: '1 more star until the reward',
    );
    return '$_temp0';
  }

  @override
  String pointsRewardText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$amount points',
      one: '+$amount point',
    );
    return '$_temp0';
  }

  @override
  String get styleFruit => 'Fruit';

  @override
  String get styleNature => 'Nature';

  @override
  String get styleCourt => 'Court';

  @override
  String get styleMyth => 'Myth';

  @override
  String get styleClassic => 'Classic';

  @override
  String get styleShape => 'Shapes';

  @override
  String get styleNumber => 'Numbers';

  @override
  String get styleMix => 'Mix';

  @override
  String get questDaily3 => 'Clear daily 3 times';

  @override
  String get questStars8 => 'Earn 8 stars';

  @override
  String get questClears4 => 'Clear 4 campaign levels';

  @override
  String get questThreeStar1 => 'Score 3★ on a level';

  @override
  String get questStreak3 => 'Keep three nights lit';

  @override
  String get weekGarden => 'Garden week';

  @override
  String get weekCourt => 'Courtyard week';

  @override
  String get weekLanterns => 'Lantern week';

  @override
  String get weekMyth => 'Myth week';

  @override
  String get weekHarvest => 'Harvest week';

  @override
  String get weekDefault => 'This week’s table';

  @override
  String get petCat => 'Cat';

  @override
  String get petDog => 'Dog';

  @override
  String get petRaccoon => 'Raccoon';

  @override
  String get petHamster => 'Hamster';

  @override
  String get petFox => 'Fox';

  @override
  String get petNeedHunger => 'Hunger';

  @override
  String get petNeedPlay => 'Play';

  @override
  String get petNeedRest => 'Rest';

  @override
  String petMoodContent(String name) {
    return '$name is content.';
  }

  @override
  String petMoodAsking(String name) {
    return '$name needs you.';
  }

  @override
  String petMoodStarving(String name) {
    return '$name is starving.';
  }

  @override
  String petCareHunger(String name) {
    return 'You fed $name.';
  }

  @override
  String petCarePlay(String name) {
    return 'You played with $name.';
  }

  @override
  String petCareRest(String name) {
    return '$name rested.';
  }

  @override
  String get petRoleAttacker => 'Attacker';

  @override
  String get petRoleDefender => 'Defender';

  @override
  String get petStatAttack => 'Attack';

  @override
  String get petStatDefense => 'Defense';

  @override
  String get gearSlotMain => 'Main item';

  @override
  String get gearSlotAccessory => 'Accessory';

  @override
  String get growthSown => 'Seed planted';

  @override
  String get growthSprout => 'Sprout';

  @override
  String get growthGrowing => 'Growing';

  @override
  String get growthRipe => 'Ready to collect';

  @override
  String get seedAmberbell => 'Amber Bell';

  @override
  String get seedMistfern => 'Mist Fern';

  @override
  String get seedGlassreed => 'Glass Reed';

  @override
  String get seedCrimsonplum => 'Crimson Plum';

  @override
  String get seedNightlotus => 'Night Lotus';

  @override
  String get seedStarbamboo => 'Star Bamboo';

  @override
  String get seedBlurbAmberbell => 'A warm seed with a tiny bell inside.';

  @override
  String get seedBlurbMistfern => 'A pale frond folded into a seed.';

  @override
  String get seedBlurbGlassreed =>
      'A clear reed that rings when the light hits it.';

  @override
  String get seedBlurbCrimsonplum =>
      'A dark sweet stone from a courtyard plum.';

  @override
  String get seedBlurbNightlotus => 'A violet bud that opens only after dusk.';

  @override
  String get seedBlurbStarbamboo => 'A jointed grain with a spark at the tip.';

  @override
  String get plantOriginHouse => 'Origin: house production';

  @override
  String plantOriginOther(String source) {
    return 'Origin: $source';
  }

  @override
  String get firstPhraseHouse => 'The next house look is bought with points.';

  @override
  String get firstPhrasePond => 'This pond fills as you play.';

  @override
  String get firstPhrasePets => 'This pet house grows as you play.';

  @override
  String get firstPhraseGuest => 'This yard comes online as you play.';

  @override
  String get pathLifeHouse => 'The house feels warmer.';

  @override
  String get pathLifePond => 'The pond feels alive.';

  @override
  String get pathLifePets => 'The pet house feels warmer.';

  @override
  String get pathLifeGuest => 'The yard hums a little.';

  @override
  String get rewardPond => 'Little pond';

  @override
  String get rewardSwing => 'Garden swing';

  @override
  String get rewardFlowerBed => 'Flower bed';

  @override
  String get tileStateFree => 'free';

  @override
  String get tileStateLocked => 'locked';

  @override
  String tileRemoving(String name) {
    return '$name, matching';
  }

  @override
  String tileInTrayHinted(String name) {
    return '$name in tray, hinted';
  }

  @override
  String tileInTray(String name) {
    return '$name in tray';
  }

  @override
  String tileFreeHinted(String name) {
    return '$name, free, hinted';
  }

  @override
  String tileLockedHinted(String name) {
    return '$name, locked, hinted';
  }

  @override
  String tileFreeState(String name) {
    return '$name, free';
  }

  @override
  String tileLockedState(String name) {
    return '$name, locked';
  }

  @override
  String levelCardLocked(int id) {
    return 'Level $id, locked';
  }

  @override
  String levelCardOpen(int id, String title, String stars, String progress) {
    return 'Level $id, $title, $stars$progress';
  }

  @override
  String get levelStarsNone => 'no stars';

  @override
  String levelStarsSome(int count) {
    return '$count stars';
  }

  @override
  String get levelInProgress => ', in progress';

  @override
  String boostLeft(String name, int count) {
    return '$name, $count left';
  }

  @override
  String boostNone(String name) {
    return '$name, none left';
  }

  @override
  String get petsNeedCare => 'Pets, need care';

  @override
  String dailyButtonSemanticText(String today, String status) {
    return '$today. $status';
  }

  @override
  String courtyardSemanticText(String name) {
    return '$name courtyard';
  }

  @override
  String gardenBedReady(int number, String name) {
    return 'Bed $number, $name, ready to collect';
  }

  @override
  String gardenBedGrowing(int number, String name, String stage, String time) {
    return 'Bed $number, $name, $stage, $time left';
  }

  @override
  String storyNextItem(String item) {
    return 'Next: $item';
  }

  @override
  String newGiftItem(String item) {
    return 'New gift: $item';
  }

  @override
  String storyProgressLine(String title, int progress) {
    return '$title · $progress/3';
  }

  @override
  String newChapterProgress(int progress) {
    return 'New chapter · $progress/3';
  }

  @override
  String storyReadyProgress(int stage) {
    return 'Story ready · $stage/3';
  }

  @override
  String foxStoryProgress(int stage) {
    return 'Fox’s story · $stage/3';
  }

  @override
  String gearOfferText(String role, String slot) {
    return '$role · $slot';
  }

  @override
  String petBadgeText(String role, String level) {
    return '$role, $level';
  }

  @override
  String get chooseAPetYard => 'Choose a companion';

  @override
  String get chooseAPetStatus => 'Choose a pet';

  @override
  String get homeSemantic => 'Home';

  @override
  String get petAdventures => 'Pet adventures';

  @override
  String get adventures => 'Adventures';

  @override
  String get adventureComplete => 'Adventure complete';

  @override
  String get adventureCompleteBang => 'Adventure complete!';

  @override
  String get play => 'Play';

  @override
  String get storyLocked => 'Complete the previous story';

  @override
  String get fiveAdventures => '5 adventures';

  @override
  String get foxTitle => 'A cozy corner for Fox';

  @override
  String get foxGoal0 => 'One win to prepare a spot';

  @override
  String get foxGoal1 => 'One win to make a bed';

  @override
  String get foxGoal2 => 'One win to bring a toy';

  @override
  String get foxGoalDone => 'Fox feels at home!';

  @override
  String get foxSeeWhatChanged => 'See what changed!';

  @override
  String get foxHelpSettle => 'Help Fox settle in · 3 wins';

  @override
  String get foxSaveFailed => 'Could not save. Please try again.';

  @override
  String get foxIntro =>
      'Fox found a quiet spot in your courtyard. Three campaign wins will turn it into a home.';

  @override
  String get foxStage0 =>
      'Let’s clear the leaves. Win a campaign level to prepare the spot.';

  @override
  String get foxStage1 =>
      'The spot is ready! One more win will bring a soft bed.';

  @override
  String get foxStage2 =>
      'A soft bed! Pick a color. One more win will bring a toy.';

  @override
  String get foxStageDone =>
      'Fox feels at home! Tap Fox to play. This corner stays in your courtyard.';

  @override
  String get foxHoney => 'Honey';

  @override
  String get foxSkyBlue => 'Sky blue';

  @override
  String get foxBall => 'Ball';

  @override
  String get foxPlushToy => 'Plush toy';

  @override
  String get later => 'Later';

  @override
  String get foxHelpStages => 'Help · 3 stages';

  @override
  String get foxLovely => 'Lovely!';

  @override
  String get foxIsHome => 'Fox is home · 3/3';

  @override
  String get foxStory => 'Fox’s story';

  @override
  String get windEast => 'East wind';

  @override
  String get windSouth => 'South wind';

  @override
  String get windWest => 'West wind';

  @override
  String get windNorth => 'North wind';

  @override
  String get familyFruit => 'Fruit';

  @override
  String get familyFlower => 'Flower';

  @override
  String get familyAnimal => 'Animal';

  @override
  String get familyBamboo => 'Bamboo';

  @override
  String get familyCharacter => 'Character';

  @override
  String get familyDot => 'Dot';

  @override
  String get familyDragon => 'Dragon';

  @override
  String get familyWind => 'Wind';

  @override
  String get familySeason => 'Season';

  @override
  String get familyNumber => 'Number';

  @override
  String get familyShape => 'Shape';

  @override
  String get familyTile => 'Tile';

  @override
  String get familyArt => 'Art';

  @override
  String get familyClown => 'Clown';

  @override
  String get familyEmperor => 'Emperor';

  @override
  String get familyJoker => 'Joker';

  @override
  String get familyProfession => 'Profession';

  @override
  String get familyQueen => 'Queen';

  @override
  String get familyEast => 'East';

  @override
  String get familySouth => 'South';

  @override
  String get familyWest => 'West';

  @override
  String get familyNorth => 'North';

  @override
  String get familySpring => 'Spring';

  @override
  String get familySummer => 'Summer';

  @override
  String get familyAutumn => 'Autumn';

  @override
  String get familyWinter => 'Winter';

  @override
  String get gearAttackerMain1 => 'Silk Sash';

  @override
  String get gearAttackerMain2 => 'Night Claw';

  @override
  String get gearAttackerMain3 => 'Raid Lantern';

  @override
  String get gearAttackerAccessory1 => 'Scout Bell';

  @override
  String get gearAttackerAccessory2 => 'Prowl Pouch';

  @override
  String get gearAttackerAccessory3 => 'Moon Charm';

  @override
  String get gearDefenderMain1 => 'Padded Vest';

  @override
  String get gearDefenderMain2 => 'Guard Vest';

  @override
  String get gearDefenderMain3 => 'Lantern Plate';

  @override
  String get gearDefenderAccessory1 => 'Leather Collar';

  @override
  String get gearDefenderAccessory2 => 'Watch Band';

  @override
  String get gearDefenderAccessory3 => 'Gate Charm';

  @override
  String get storyCampaign0 => 'Sprout';

  @override
  String get storyCampaign1 => 'Bud';

  @override
  String get storyCampaign2 => 'Bloom';

  @override
  String get storyCampaign3 => 'Glade';

  @override
  String get storyCampaign4 => 'Lawn';

  @override
  String get storyCampaign5 => 'Grove';

  @override
  String get storyCampaign6 => 'Wave';

  @override
  String get storyCampaign7 => 'Stream';

  @override
  String get storyCampaign8 => 'Garden';

  @override
  String get storyCampaign9 => 'Gazebo';

  @override
  String get storyCampaign10 => 'Fan';

  @override
  String get storyCampaign11 => 'Peacock Fan';

  @override
  String get storyCampaign12 => 'Lotus';

  @override
  String get storyCampaign13 => 'Pond';

  @override
  String get storyCampaign14 => 'Carp';

  @override
  String get storyCampaign15 => 'Lake';

  @override
  String get storyCampaign16 => 'Vine';

  @override
  String get storyCampaign17 => 'Ivy';

  @override
  String get storyCampaign18 => 'Festival';

  @override
  String get storyCampaign19 => 'Lanterns';

  @override
  String get storyCampaign20 => 'Pavilion';

  @override
  String get storyCampaign21 => 'Wind Temple';

  @override
  String get storyCampaign22 => 'Dragon';

  @override
  String get storyCampaign23 => 'Sky Dragon';

  @override
  String get houseEraName0 => 'Clearing';

  @override
  String get houseEraPhrase0 => 'A house will stand here.';

  @override
  String get houseEraName1 => 'Shack';

  @override
  String get houseEraPhrase1 => 'A shack leans on the plot.';

  @override
  String get houseEraName2 => 'Hut';

  @override
  String get houseEraPhrase2 => 'The hut has a door.';

  @override
  String get houseEraName3 => 'Cabin';

  @override
  String get houseEraPhrase3 => 'The cabin is timber now.';

  @override
  String get houseEraName4 => 'House';

  @override
  String get houseEraPhrase4 => 'A real house stands here.';

  @override
  String get houseEraName5 => 'Cottage';

  @override
  String get houseEraPhrase5 => 'The cottage has two floors.';

  @override
  String get houseEraName6 => 'Estate';

  @override
  String get houseEraPhrase6 => 'The estate spreads its wings.';

  @override
  String get houseEraName7 => 'Mansion';

  @override
  String get houseEraPhrase7 => 'The mansion is stone.';

  @override
  String get houseEraName8 => 'Keep';

  @override
  String get houseEraPhrase8 => 'The walls become a keep.';

  @override
  String get houseEraName9 => 'Castle';

  @override
  String get houseEraPhrase9 => 'A castle rises.';

  @override
  String get houseEraName10 => 'Grand castle';

  @override
  String get houseEraPhrase10 => 'The castle fills the hill.';

  @override
  String get houseEraName11 => 'Residence';

  @override
  String get houseEraPhrase11 => 'The residence is complete.';

  @override
  String get pondEraName0 => 'Hollow';

  @override
  String get pondEraPhrase0 => 'A pond will fill this hollow.';

  @override
  String get pondEraName1 => 'Puddle';

  @override
  String get pondEraPhrase1 => 'The puddle holds.';

  @override
  String get pondEraName2 => 'Pond';

  @override
  String get pondEraPhrase2 => 'Reeds take the shore.';

  @override
  String get pondEraName3 => 'Walkway';

  @override
  String get pondEraPhrase3 => 'The walkway is down.';

  @override
  String get pondEraName4 => 'Koi pond';

  @override
  String get pondEraPhrase4 => 'Koi have a home.';

  @override
  String get pondEraName5 => 'Pavilion';

  @override
  String get pondEraPhrase5 => 'A pavilion watches the water.';

  @override
  String get pondEraName6 => 'Water garden';

  @override
  String get pondEraPhrase6 => 'The pond is a garden.';

  @override
  String get pondEraName7 => 'Stone banks';

  @override
  String get pondEraPhrase7 => 'Stone banks and lanterns.';

  @override
  String get pondEraName8 => 'Bridge';

  @override
  String get pondEraPhrase8 => 'A bridge crosses the water.';

  @override
  String get pondEraName9 => 'Water court';

  @override
  String get pondEraPhrase9 => 'The water court is walled.';

  @override
  String get pondEraName10 => 'Palace pond';

  @override
  String get pondEraPhrase10 => 'Palace gardens reach the pond.';

  @override
  String get pondEraName11 => 'Water garden complete';

  @override
  String get pondEraPhrase11 => 'The water garden is complete.';

  @override
  String get petsEraName0 => 'Yard';

  @override
  String get petsEraPhrase0 => 'A pet house will stand here.';

  @override
  String get petsEraName1 => 'Bowls';

  @override
  String get petsEraPhrase1 => 'Bowls wait in the grass.';

  @override
  String get petsEraName2 => 'Kennel';

  @override
  String get petsEraPhrase2 => 'A kennel leans on the plot.';

  @override
  String get petsEraName3 => 'Hutch';

  @override
  String get petsEraPhrase3 => 'The hutch has a door.';

  @override
  String get petsEraName4 => 'Pet house';

  @override
  String get petsEraPhrase4 => 'The pets have a house.';

  @override
  String get petsEraName5 => 'Play yard';

  @override
  String get petsEraPhrase5 => 'A play yard opens.';

  @override
  String get petsEraName6 => 'Garden';

  @override
  String get petsEraPhrase6 => 'The garden is theirs.';

  @override
  String get petsEraName7 => 'Den';

  @override
  String get petsEraPhrase7 => 'A den is lined.';

  @override
  String get petsEraName8 => 'Lodge';

  @override
  String get petsEraPhrase8 => 'The lodge is warm.';

  @override
  String get petsEraName9 => 'Menagerie';

  @override
  String get petsEraPhrase9 => 'A menagerie gathers.';

  @override
  String get petsEraName10 => 'Sanctuary';

  @override
  String get petsEraPhrase10 => 'The sanctuary is fenced.';

  @override
  String get petsEraName11 => 'Pet home complete';

  @override
  String get petsEraPhrase11 => 'The pet house is complete.';

  @override
  String get guestEraName0 => 'Quiet yard';

  @override
  String get guestEraPhrase0 => 'A signal will reach this yard.';

  @override
  String get guestEraName1 => 'Pole';

  @override
  String get guestEraPhrase1 => 'The pole holds the line.';

  @override
  String get guestEraName2 => 'Cable';

  @override
  String get guestEraPhrase2 => 'Cable finds the house.';

  @override
  String get guestEraName3 => 'Dish';

  @override
  String get guestEraPhrase3 => 'The dish is up.';

  @override
  String get guestEraName4 => 'Screens';

  @override
  String get guestEraPhrase4 => 'Screens glow in the yard.';

  @override
  String get guestEraName5 => 'Line lamp';

  @override
  String get guestEraPhrase5 => 'A lamp of the line.';

  @override
  String get guestEraName6 => 'Far talk';

  @override
  String get guestEraPhrase6 => 'The yard talks farther.';

  @override
  String get guestEraName7 => 'Signal tower';

  @override
  String get guestEraPhrase7 => 'A tower of the signal.';

  @override
  String get guestEraName8 => 'Observatory';

  @override
  String get guestEraPhrase8 => 'The observatory rises.';

  @override
  String get guestEraName9 => 'Crystal line';

  @override
  String get guestEraPhrase9 => 'Crystal and wire.';

  @override
  String get guestEraName10 => 'Beacon';

  @override
  String get guestEraPhrase10 => 'A beacon on the hill.';

  @override
  String get guestEraName11 => 'Yard online';

  @override
  String get guestEraPhrase11 => 'The yard is fully online.';

  @override
  String get houseWarm0 => 'Another step along the path.';

  @override
  String get houseWarm1 => 'The plot is yours now.';

  @override
  String get houseWarm2 => 'The house is a little closer.';

  @override
  String get pondWarm0 => 'The water rose a little.';

  @override
  String get pondWarm1 => 'The pond is more yours now.';

  @override
  String get pondWarm2 => 'The banks sit closer.';

  @override
  String get petsWarm0 => 'The pet house grew a little.';

  @override
  String get petsWarm1 => 'The yard is more theirs now.';

  @override
  String get petsWarm2 => 'The kennel sits closer.';

  @override
  String get guestWarm0 => 'The signal grew a little.';

  @override
  String get guestWarm1 => 'The yard is more connected.';

  @override
  String get guestWarm2 => 'The line sits closer.';

  @override
  String get storyCatWindowTitle => 'Sunny Windowsill';

  @override
  String get storyCatWindowChapter0 => 'Find the warmest patch of sunlight.';

  @override
  String get storyCatWindowChapter1 =>
      'Bring a soft cushion and a ball of yarn.';

  @override
  String get storyCatWindowChapter2 =>
      'Hang a curtain for the perfect afternoon nap.';

  @override
  String get storyCatWatchTitle => 'Midnight Watch';

  @override
  String get storyCatWatchChapter0 =>
      'Light a quiet path across the courtyard.';

  @override
  String get storyCatWatchChapter1 => 'Add a bell to hear every visitor.';

  @override
  String get storyCatWatchChapter2 =>
      'Watch the moon through a tiny telescope.';

  @override
  String get storyCatGardenTitle => 'Secret Garden';

  @override
  String get storyCatGardenChapter0 => 'Plant a hidden green corner.';

  @override
  String get storyCatGardenChapter1 => 'Invite bright butterflies to visit.';

  @override
  String get storyCatGardenChapter2 =>
      'Finish the garden with a murmuring fountain.';

  @override
  String get storyCatLibraryTitle => 'Little Library';

  @override
  String get storyCatLibraryChapter0 => 'Collect three favorite storybooks.';

  @override
  String get storyCatLibraryChapter1 => 'Spread a blanket beside the shelves.';

  @override
  String get storyCatLibraryChapter2 =>
      'Light a reading lamp for long evenings.';

  @override
  String get storyCatTeaTitle => 'Tea House Keeper';

  @override
  String get storyCatTeaChapter0 => 'Set out the first tiny teacup.';

  @override
  String get storyCatTeaChapter1 => 'Decorate the table with fresh flowers.';

  @override
  String get storyCatTeaChapter2 => 'Raise the tea-house banner for guests.';

  @override
  String get storyDogTrailTitle => 'Welcome Trail';

  @override
  String get storyDogTrailChapter0 => 'Mark a friendly trail through the yard.';

  @override
  String get storyDogTrailChapter1 => 'Leave fresh water for travelers.';

  @override
  String get storyDogTrailChapter2 =>
      'Put a ball at the finish for a joyful welcome.';

  @override
  String get storyDogBridgeTitle => 'Bridge Patrol';

  @override
  String get storyDogBridgeChapter0 =>
      'Secure the old bridge with a strong rope.';

  @override
  String get storyDogBridgeChapter1 => 'Hang a lantern for foggy mornings.';

  @override
  String get storyDogBridgeChapter2 =>
      'Earn the golden courtyard patrol badge.';

  @override
  String get storyDogPicnicTitle => 'Picnic Day';

  @override
  String get storyDogPicnicChapter0 => 'Pack a basket for every friend.';

  @override
  String get storyDogPicnicChapter1 => 'Choose a sunny place for the blanket.';

  @override
  String get storyDogPicnicChapter2 =>
      'Share the treats when everyone arrives.';

  @override
  String get storyDogKiteTitle => 'The Lost Kite';

  @override
  String get storyDogKiteChapter0 => 'Spot the kite beyond the hills.';

  @override
  String get storyDogKiteChapter1 => 'Follow the wind with a compass.';

  @override
  String get storyDogKiteChapter2 => 'Bring it home and tie on a new ribbon.';

  @override
  String get storyDogFestivalTitle => 'Festival Helper';

  @override
  String get storyDogFestivalChapter0 => 'Carry colorful flags to the square.';

  @override
  String get storyDogFestivalChapter1 => 'Lead the parade with a little drum.';

  @override
  String get storyDogFestivalChapter2 =>
      'Receive a medal for helping everyone.';

  @override
  String get storyRaccoonWorkshopTitle => 'Shiny Workshop';

  @override
  String get storyRaccoonWorkshopChapter0 =>
      'Open a toolbox of curious inventions.';

  @override
  String get storyRaccoonWorkshopChapter1 =>
      'Fit the brightest gears together.';

  @override
  String get storyRaccoonWorkshopChapter2 =>
      'Build a clock that chimes at sunset.';

  @override
  String get storyRaccoonMarketTitle => 'Moonlit Market';

  @override
  String get storyRaccoonMarketChapter0 => 'Weave a basket for unusual finds.';

  @override
  String get storyRaccoonMarketChapter1 => 'Light a stall beneath the moon.';

  @override
  String get storyRaccoonMarketChapter2 =>
      'Trade three shiny coins for a surprise.';

  @override
  String get storyRaccoonRiverTitle => 'River Treasure';

  @override
  String get storyRaccoonRiverChapter0 => 'Read the map hidden under a stone.';

  @override
  String get storyRaccoonRiverChapter1 => 'Patch a tiny boat for the crossing.';

  @override
  String get storyRaccoonRiverChapter2 =>
      'Find the singing shell on the far bank.';

  @override
  String get storyRaccoonRecycleTitle => 'Second-Chance Garden';

  @override
  String get storyRaccoonRecycleChapter0 => 'Turn an old crate into a planter.';

  @override
  String get storyRaccoonRecycleChapter1 => 'Repair a dented watering can.';

  @override
  String get storyRaccoonRecycleChapter2 =>
      'Build a windmill from forgotten pieces.';

  @override
  String get storyRaccoonCafeTitle => 'Night Café';

  @override
  String get storyRaccoonCafeChapter0 => 'Polish a mug for the first guest.';

  @override
  String get storyRaccoonCafeChapter1 => 'Bake a plate of moon-shaped cookies.';

  @override
  String get storyRaccoonCafeChapter2 => 'Hang the café sign before nightfall.';

  @override
  String get storyHamsterRailwayTitle => 'Tiny Railway';

  @override
  String get storyHamsterRailwayChapter0 => 'Lay tracks around the flower bed.';

  @override
  String get storyHamsterRailwayChapter1 => 'Build a cart just the right size.';

  @override
  String get storyHamsterRailwayChapter2 =>
      'Open the courtyard’s smallest station.';

  @override
  String get storyHamsterPantryTitle => 'Great Pantry';

  @override
  String get storyHamsterPantryChapter0 => 'Gather a winter bag of seeds.';

  @override
  String get storyHamsterPantryChapter1 => 'Build shelves from smooth twigs.';

  @override
  String get storyHamsterPantryChapter2 =>
      'Label the finest jar in the pantry.';

  @override
  String get storyHamsterCloudsTitle => 'Cloud Observatory';

  @override
  String get storyHamsterCloudsChapter0 =>
      'Raise a ladder above the tall grass.';

  @override
  String get storyHamsterCloudsChapter1 =>
      'Aim the telescope between the clouds.';

  @override
  String get storyHamsterCloudsChapter2 =>
      'Name a new star after the courtyard.';

  @override
  String get storyHamsterGardenTitle => 'Miniature Garden';

  @override
  String get storyHamsterGardenChapter0 => 'Plant a garden in a clay pot.';

  @override
  String get storyHamsterGardenChapter1 =>
      'Place a bridge over a pebble stream.';

  @override
  String get storyHamsterGardenChapter2 => 'Add a mushroom house for visitors.';

  @override
  String get storyHamsterBirthdayTitle => 'Birthday Parade';

  @override
  String get storyHamsterBirthdayChapter0 => 'Make the tiniest party hat.';

  @override
  String get storyHamsterBirthdayChapter1 => 'Bake a cake with three berries.';

  @override
  String get storyHamsterBirthdayChapter2 =>
      'Start the parade in a shower of confetti.';

  @override
  String get storyFoxCozyTitle => 'A Cozy Corner';

  @override
  String get storyFoxCozyChapter0 => 'Clear the leaves from a quiet corner.';

  @override
  String get storyFoxCozyChapter1 => 'Bring a soft bed for afternoon naps.';

  @override
  String get storyFoxCozyChapter2 => 'Choose a favorite toy and make it home.';

  @override
  String get storyFoxFirefliesTitle => 'Firefly Path';

  @override
  String get storyFoxFirefliesChapter0 => 'Place a lantern at the forest edge.';

  @override
  String get storyFoxFirefliesChapter1 => 'Plant night flowers along the path.';

  @override
  String get storyFoxFirefliesChapter2 =>
      'Welcome a sparkling cloud of fireflies.';

  @override
  String get storyFoxPostTitle => 'Forest Post';

  @override
  String get storyFoxPostChapter0 => 'Build a red mailbox beneath the oak.';

  @override
  String get storyFoxPostChapter1 => 'Sort letters for every courtyard friend.';

  @override
  String get storyFoxPostChapter2 =>
      'Carry the first delivery in a new satchel.';

  @override
  String get storyFoxStudioTitle => 'Autumn Studio';

  @override
  String get storyFoxStudioChapter0 => 'Set an easel among the golden leaves.';

  @override
  String get storyFoxStudioChapter1 => 'Mix colors for an autumn portrait.';

  @override
  String get storyFoxStudioChapter2 =>
      'Frame the painting for the courtyard house.';

  @override
  String get storyFoxCampTitle => 'Starry Camp';

  @override
  String get storyFoxCampChapter0 => 'Raise a tent beneath the pines.';

  @override
  String get storyFoxCampChapter1 => 'Light a warm and careful campfire.';

  @override
  String get storyFoxCampChapter2 => 'Stay awake to find a falling star.';

  @override
  String get petItemCushion => 'Cushion';

  @override
  String get petItemYarn => 'Yarn';

  @override
  String get petItemCurtain => 'Curtain';

  @override
  String get petItemLantern => 'Lantern';

  @override
  String get petItemBell => 'Bell';

  @override
  String get petItemTelescope => 'Telescope';

  @override
  String get petItemSeedling => 'Seedling';

  @override
  String get petItemButterflies => 'Butterflies';

  @override
  String get petItemFountain => 'Fountain';

  @override
  String get petItemBooks => 'Books';

  @override
  String get petItemBlanket => 'Blanket';

  @override
  String get petItemLamp => 'Reading lamp';

  @override
  String get petItemTeacup => 'Tea set';

  @override
  String get petItemFlowers => 'Flowers';

  @override
  String get petItemBanner => 'Banner';

  @override
  String get petItemSignpost => 'Signpost';

  @override
  String get petItemBowl => 'Water bowl';

  @override
  String get petItemBall => 'Ball';

  @override
  String get petItemRope => 'Strong rope';

  @override
  String get petItemBadge => 'Patrol badge';

  @override
  String get petItemBasket => 'Basket';

  @override
  String get petItemTreats => 'Treats';

  @override
  String get petItemKite => 'Kite';

  @override
  String get petItemCompass => 'Compass';

  @override
  String get petItemRibbon => 'Ribbon';

  @override
  String get petItemFlags => 'Festival flags';

  @override
  String get petItemDrum => 'Drum';

  @override
  String get petItemMedal => 'Medal';

  @override
  String get petItemToolbox => 'Toolbox';

  @override
  String get petItemGears => 'Gears';

  @override
  String get petItemClock => 'Clock';

  @override
  String get petItemCoins => 'Shiny coins';

  @override
  String get petItemMap => 'Treasure map';

  @override
  String get petItemBoat => 'Tiny boat';

  @override
  String get petItemShell => 'Singing shell';

  @override
  String get petItemCrate => 'Planter crate';

  @override
  String get petItemWateringCan => 'Watering can';

  @override
  String get petItemWindmill => 'Windmill';

  @override
  String get petItemMug => 'Café mug';

  @override
  String get petItemCookies => 'Cookies';

  @override
  String get petItemTracks => 'Railway tracks';

  @override
  String get petItemCart => 'Tiny cart';

  @override
  String get petItemStation => 'Station';

  @override
  String get petItemSeedBag => 'Seed bag';

  @override
  String get petItemShelf => 'Shelves';

  @override
  String get petItemJar => 'Pantry jar';

  @override
  String get petItemLadder => 'Ladder';

  @override
  String get petItemStar => 'New star';

  @override
  String get petItemPot => 'Garden pot';

  @override
  String get petItemBridge => 'Tiny bridge';

  @override
  String get petItemMushroom => 'Mushroom house';

  @override
  String get petItemHat => 'Party hat';

  @override
  String get petItemCake => 'Berry cake';

  @override
  String get petItemConfetti => 'Confetti';

  @override
  String get petItemClearing => 'Quiet clearing';

  @override
  String get petItemBed => 'Soft bed';

  @override
  String get petItemToy => 'Favorite toy';

  @override
  String get petItemFireflies => 'Fireflies';

  @override
  String get petItemMailbox => 'Mailbox';

  @override
  String get petItemLetters => 'Letters';

  @override
  String get petItemSatchel => 'Mail satchel';

  @override
  String get petItemEasel => 'Easel';

  @override
  String get petItemPaints => 'Paints';

  @override
  String get petItemFrame => 'Picture frame';

  @override
  String get petItemTent => 'Tent';

  @override
  String get petItemCampfire => 'Campfire';
}
