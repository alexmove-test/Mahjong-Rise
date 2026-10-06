import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('th'),
  ];

  /// Resumes the current activity.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @noShuffleMoves.
  ///
  /// In en, this message translates to:
  /// **'No pair available — try undo, a hint or a magnet'**
  String get noShuffleMoves;

  /// No description provided for @shuffleLockedChallenge.
  ///
  /// In en, this message translates to:
  /// **'Shuffling is disabled for this challenge'**
  String get shuffleLockedChallenge;

  /// Semantics name of a starred challenge tile.
  ///
  /// In en, this message translates to:
  /// **'Starred goal tile'**
  String get specialTile;

  /// No description provided for @continueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue · {title}'**
  String continueWith(String title);

  /// Semantics label for a courtyard plot that is not built yet.
  ///
  /// In en, this message translates to:
  /// **'New plot'**
  String get newPlot;

  /// Short interface label: Previous plot
  ///
  /// In en, this message translates to:
  /// **'Previous plot'**
  String get previousPlot;

  /// Short interface label: Next plot
  ///
  /// In en, this message translates to:
  /// **'Next plot'**
  String get nextPlot;

  /// No description provided for @plotLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Next wins will grow this plot'**
  String get plotLockedHint;

  /// No description provided for @neighborYard.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s courtyard'**
  String neighborYard(String name);

  /// No description provided for @neighborRating.
  ///
  /// In en, this message translates to:
  /// **'{name} · {rating}'**
  String neighborRating(String name, int rating);

  /// No description provided for @neighboringCourtyard.
  ///
  /// In en, this message translates to:
  /// **'A neighboring courtyard'**
  String get neighboringCourtyard;

  /// No description provided for @courtyardPanHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to look around the courtyard'**
  String get courtyardPanHint;

  /// No description provided for @houseStateTitle.
  ///
  /// In en, this message translates to:
  /// **'House · {state}/{total}'**
  String houseStateTitle(int state, int total);

  /// No description provided for @houseFullyUpgraded.
  ///
  /// In en, this message translates to:
  /// **'House fully upgraded'**
  String get houseFullyUpgraded;

  /// Expands the house upgrade details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get houseDetailsShow;

  /// Collapses the house upgrade details.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get houseDetailsHide;

  /// No description provided for @upgradeHouseForText.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for {price}'**
  String upgradeHouseForText(String price);

  /// No description provided for @pointsShortfallText.
  ///
  /// In en, this message translates to:
  /// **'{amount} points short'**
  String pointsShortfallText(String amount);

  /// No description provided for @houseUpgradeOfferText.
  ///
  /// In en, this message translates to:
  /// **'House upgrade · {cost}'**
  String houseUpgradeOfferText(String cost);

  /// Short interface label: Next house look
  ///
  /// In en, this message translates to:
  /// **'Next house look'**
  String get nextHouseLook;

  /// No description provided for @houseLookLine.
  ///
  /// In en, this message translates to:
  /// **'House looks built: {built} of {total}'**
  String houseLookLine(int built, int total);

  /// No description provided for @hubLevelUnlocksPet.
  ///
  /// In en, this message translates to:
  /// **'Level {id} unlocks a pet'**
  String hubLevelUnlocksPet(int id);

  /// No description provided for @hubQuestRewardReady.
  ///
  /// In en, this message translates to:
  /// **'Weekly reward is ready'**
  String get hubQuestRewardReady;

  /// No description provided for @hubThreeStarUntilReward.
  ///
  /// In en, this message translates to:
  /// **'A 3★ clear unlocks the reward'**
  String get hubThreeStarUntilReward;

  /// Label of the daily table.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Short interface label: Cleared today
  ///
  /// In en, this message translates to:
  /// **'Cleared today'**
  String get clearedToday;

  /// No description provided for @streakNights.
  ///
  /// In en, this message translates to:
  /// **'Day {n} of 3'**
  String streakNights(int n);

  /// No description provided for @streakKept.
  ///
  /// In en, this message translates to:
  /// **'Three nights kept'**
  String get streakKept;

  /// No description provided for @streakAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Goes out at midnight'**
  String get streakAtRisk;

  /// Short interface label: Keep the light
  ///
  /// In en, this message translates to:
  /// **'Keep the light'**
  String get keepTheLight;

  /// No description provided for @openedProgress.
  ///
  /// In en, this message translates to:
  /// **'{unlocked}/{total} open'**
  String openedProgress(int unlocked, int total);

  /// Button that leaves the table and returns to the courtyard.
  ///
  /// In en, this message translates to:
  /// **'Courtyard'**
  String get courtyard;

  /// Short interface label: How to play
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// Short interface label: Levels
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levels;

  /// Restarts the current level.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Starts the cleared level over.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// Button that advances to the next level.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Opens the in-game menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Dismisses a dialog or sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Abandons the current dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Saves the edited player name.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Returns to the previous screen.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Short interface label: Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Short interface label: Privacy settings
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get privacySettings;

  /// Short label for hiding the banner ad for a day.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get hideBannerButton;

  /// No description provided for @hideBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide the banner for 24 hours'**
  String get hideBannerTitle;

  /// No description provided for @hideBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad. It stays off on this device.'**
  String get hideBannerSubtitle;

  /// Short interface label: Watch ad
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get hideBannerWatch;

  /// Dismisses the hide-banner offer.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get hideBannerNotNow;

  /// Opens the build-info dialog.
  ///
  /// In en, this message translates to:
  /// **'About game'**
  String get aboutGame;

  /// No description provided for @builtAt.
  ///
  /// In en, this message translates to:
  /// **'Built: {time}'**
  String builtAt(String time);

  /// Opens the settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Toggle for sound effects.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// Toggle for background music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// Short interface label: Haptic feedback
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticFeedback;

  /// Settings name of the high-charge magnet mode.
  ///
  /// In en, this message translates to:
  /// **'Q mode'**
  String get qMode;

  /// No description provided for @qModeHint.
  ///
  /// In en, this message translates to:
  /// **'Magnet ads grant 50'**
  String get qModeHint;

  /// No description provided for @dimCoveredTiles.
  ///
  /// In en, this message translates to:
  /// **'Dim covered tiles'**
  String get dimCoveredTiles;

  /// No description provided for @dimCoveredTilesHint.
  ///
  /// In en, this message translates to:
  /// **'Gray out tiles you cannot pick'**
  String get dimCoveredTilesHint;

  /// Short interface label: Table look
  ///
  /// In en, this message translates to:
  /// **'Table look'**
  String get tableLook;

  /// Short interface label: Classic mahjong
  ///
  /// In en, this message translates to:
  /// **'Classic mahjong'**
  String get tableLookClassic;

  /// No description provided for @tableLookClassicHint.
  ///
  /// In en, this message translates to:
  /// **'3D tiles and copper buttons'**
  String get tableLookClassicHint;

  /// Short interface label: Bright match
  ///
  /// In en, this message translates to:
  /// **'Bright match'**
  String get tableLookCasual;

  /// No description provided for @tableLookCasualHint.
  ///
  /// In en, this message translates to:
  /// **'Flat tiles, green and gold'**
  String get tableLookCasualHint;

  /// Name of the newest table theme.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tableLookPremium;

  /// No description provided for @tableLookPremiumHint.
  ///
  /// In en, this message translates to:
  /// **'Ivory tiles, warm wood table'**
  String get tableLookPremiumHint;

  /// Short label for a table theme unlocked as a courtyard gift.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get tableLookGift;

  /// Selects a table theme.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get tableLookUse;

  /// No description provided for @tableLookLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Unlock as a courtyard gift'**
  String get tableLookLockedHint;

  /// No description provided for @tableLookSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'You can choose different table themes in the menu'**
  String get tableLookSettingsHint;

  /// Short interface label: Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Short interface label: System
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Toast when the player taps a covered tile.
  ///
  /// In en, this message translates to:
  /// **'Tile is locked'**
  String get tileLocked;

  /// Toast when the tray cannot take another tile.
  ///
  /// In en, this message translates to:
  /// **'Tray is full'**
  String get trayFull;

  /// No description provided for @trayFullHint.
  ///
  /// In en, this message translates to:
  /// **'No matching pair.'**
  String get trayFullHint;

  /// No description provided for @noMovesShuffle.
  ///
  /// In en, this message translates to:
  /// **'No moves — shuffle'**
  String get noMovesShuffle;

  /// Win headline on the result overlay.
  ///
  /// In en, this message translates to:
  /// **'You win!'**
  String get youWin;

  /// Short interface label: No free tiles
  ///
  /// In en, this message translates to:
  /// **'No free tiles'**
  String get noFreeTiles;

  /// Short interface label: Shuffled
  ///
  /// In en, this message translates to:
  /// **'Shuffled'**
  String get shuffled;

  /// Short interface label: Still no moves
  ///
  /// In en, this message translates to:
  /// **'Still no moves'**
  String get stillNoMoves;

  /// Short interface label: Loading ad…
  ///
  /// In en, this message translates to:
  /// **'Loading ad…'**
  String get loadingAd;

  /// No description provided for @rewardNotEarned.
  ///
  /// In en, this message translates to:
  /// **'Reward not earned'**
  String get rewardNotEarned;

  /// No description provided for @adUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load ad. Try again.'**
  String get adUnavailable;

  /// Short interface label: No useful moves
  ///
  /// In en, this message translates to:
  /// **'No useful moves'**
  String get noUsefulMoves;

  /// Short interface label: Continuing
  ///
  /// In en, this message translates to:
  /// **'Continuing'**
  String get continuing;

  /// Short interface label: Move undone
  ///
  /// In en, this message translates to:
  /// **'Move undone'**
  String get moveUndone;

  /// No description provided for @noMatchingTiles.
  ///
  /// In en, this message translates to:
  /// **'No matching tiles'**
  String get noMatchingTiles;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// Short interface label: Daily complete
  ///
  /// In en, this message translates to:
  /// **'Daily complete'**
  String get dailyComplete;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak: {n}'**
  String streakLabel(int n);

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score: {value}'**
  String score(int value);

  /// No description provided for @starsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} stars'**
  String starsCount(int n);

  /// No description provided for @dailyBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus: +1 hint and shuffle'**
  String get dailyBonus;

  /// Name of the soft currency.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @pointsBalanceText.
  ///
  /// In en, this message translates to:
  /// **'Points: {value}'**
  String pointsBalanceText(String value);

  /// Short interface label: Points
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsShopTitle;

  /// No description provided for @pointsShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earned on every cleared table. Top up any time.'**
  String get pointsShopSubtitle;

  /// No description provided for @pointsEarnRuleText.
  ///
  /// In en, this message translates to:
  /// **'Clear a level: +{perClear}, plus +{perStar} per star.'**
  String pointsEarnRuleText(int perClear, int perStar);

  /// No description provided for @pointsPackBonus.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% bonus'**
  String pointsPackBonus(int percent);

  /// Short interface label: Most taken
  ///
  /// In en, this message translates to:
  /// **'Most taken'**
  String get pointsPackPopular;

  /// Short interface label: Best value
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get pointsPackBest;

  /// Buys a points pack.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get pointsBuy;

  /// No description provided for @pointsCreditedText.
  ///
  /// In en, this message translates to:
  /// **'Credited +{value}'**
  String pointsCreditedText(String value);

  /// No description provided for @pointsPurchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled'**
  String get pointsPurchaseCancelled;

  /// No description provided for @pointsPurchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store is unavailable'**
  String get pointsPurchaseUnavailable;

  /// No description provided for @pointsDemoNote.
  ///
  /// In en, this message translates to:
  /// **'Payments are not wired up yet — the pack lands right away.'**
  String get pointsDemoNote;

  /// Short interface label: Watch ad
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get pointsWatchAd;

  /// No description provided for @pointsWatchAdRewardText.
  ///
  /// In en, this message translates to:
  /// **'Free +{value}'**
  String pointsWatchAdRewardText(String value);

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {id}'**
  String level(int id);

  /// Win headline after a campaign clear.
  ///
  /// In en, this message translates to:
  /// **'Another level cleared'**
  String get anotherLevelCleared;

  /// Shown when the score beats the previous best.
  ///
  /// In en, this message translates to:
  /// **'New best!'**
  String get newBest;

  /// No description provided for @levelUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Level {id} unlocked'**
  String levelUnlocked(int id);

  /// Booster that rearranges the board.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// Booster that pulls a match off the board.
  ///
  /// In en, this message translates to:
  /// **'Magnet'**
  String get magnet;

  /// Booster that highlights a matching pair.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// Booster that takes back the last move. Also the cancel verb in some dialogs.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad → {name}'**
  String watchAd(String name);

  /// No description provided for @boostEarnedText.
  ///
  /// In en, this message translates to:
  /// **'+{count} {name}'**
  String boostEarnedText(int count, String name);

  /// Tooltip when a booster has no charges and ads are unavailable.
  ///
  /// In en, this message translates to:
  /// **'none left'**
  String get noneLeft;

  /// No description provided for @coachTapFree.
  ///
  /// In en, this message translates to:
  /// **'Take a free tile — open on top and one side'**
  String get coachTapFree;

  /// No description provided for @coachMatchPair.
  ///
  /// In en, this message translates to:
  /// **'A pair in the tray clears'**
  String get coachMatchPair;

  /// No description provided for @coachTrayLimit.
  ///
  /// In en, this message translates to:
  /// **'The tray holds 4 — fill it with no pair and you lose'**
  String get coachTrayLimit;

  /// Difficulty label for the first campaign levels.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// Difficulty label for mid-early campaign levels.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// Difficulty label for later campaign levels.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// Difficulty label for the hardest campaign levels.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// Leaderboard label for the local player.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Fallback name before the player chooses one.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// Short interface label: Your name
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// Short interface label: You climbed!
  ///
  /// In en, this message translates to:
  /// **'You climbed!'**
  String get youClimbed;

  /// No description provided for @rankClimbPlaces.
  ///
  /// In en, this message translates to:
  /// **'Place {from} → {to}'**
  String rankClimbPlaces(int from, int to);

  /// Short interface label: Leaderboard
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// Reloads the online leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Short interface label: Change name
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get changeName;

  /// No description provided for @nameNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'That name isn’t allowed. Choose another.'**
  String get nameNotAllowed;

  /// No description provided for @rankingNamesNote.
  ///
  /// In en, this message translates to:
  /// **'Names are chosen by players. Report or hide anyone who breaks the rules.'**
  String get rankingNamesNote;

  /// Short interface label: Report or hide
  ///
  /// In en, this message translates to:
  /// **'Report or hide'**
  String get reportPlayer;

  /// Short interface label: Report this name
  ///
  /// In en, this message translates to:
  /// **'Report this name'**
  String get reportName;

  /// Short interface label: Hide this player
  ///
  /// In en, this message translates to:
  /// **'Hide this player'**
  String get hidePlayer;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We’ll review this name.'**
  String get reportThanks;

  /// No description provided for @playerHidden.
  ///
  /// In en, this message translates to:
  /// **'This player is hidden on your device.'**
  String get playerHidden;

  /// Column header for a leaderboard name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @onlineRanking.
  ///
  /// In en, this message translates to:
  /// **'Online ranking · top {top}'**
  String onlineRanking(int top);

  /// No description provided for @offlineRanking.
  ///
  /// In en, this message translates to:
  /// **'Offline: only your result is shown.'**
  String get offlineRanking;

  /// No description provided for @rankingFormula.
  ///
  /// In en, this message translates to:
  /// **'Rating: stars × 100,000 + best scores + campaign progress.'**
  String get rankingFormula;

  /// Leaderboard legend pairing score with courtyard plots.
  ///
  /// In en, this message translates to:
  /// **'Score : plots'**
  String get scorePlotsLegend;

  /// No description provided for @loadRankingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the online ranking'**
  String get loadRankingFailed;

  /// No description provided for @starsLevel.
  ///
  /// In en, this message translates to:
  /// **'{stars} ★ · lv. {unlocked}'**
  String starsLevel(int stars, int unlocked);

  /// Short badge on the simulated advertisement.
  ///
  /// In en, this message translates to:
  /// **'AD'**
  String get ad;

  /// Finishes the simulated ad.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @closeWithoutReward.
  ///
  /// In en, this message translates to:
  /// **'Close without reward'**
  String get closeWithoutReward;

  /// Short interface label: Simulated ad
  ///
  /// In en, this message translates to:
  /// **'Simulated ad'**
  String get simulatedAd;

  /// No description provided for @watchClipForBoost.
  ///
  /// In en, this message translates to:
  /// **'Watch the clip to earn a boost'**
  String get watchClipForBoost;

  /// Short interface label: Claim reward
  ///
  /// In en, this message translates to:
  /// **'Claim reward'**
  String get claimReward;

  /// Short interface label: Watching ad…
  ///
  /// In en, this message translates to:
  /// **'Watching ad…'**
  String get watchingAd;

  /// Short interface label: Weekly quests
  ///
  /// In en, this message translates to:
  /// **'Weekly quests'**
  String get weeklyQuests;

  /// Collects a completed weekly quest reward.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// Shown after a weekly quest reward was collected.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get claimed;

  /// No description provided for @questBonus.
  ///
  /// In en, this message translates to:
  /// **'+1 hint and shuffle'**
  String get questBonus;

  /// No description provided for @extraBoostThisWeek.
  ///
  /// In en, this message translates to:
  /// **'+1 boost on today’s table'**
  String get extraBoostThisWeek;

  /// Short interface label: Season closed
  ///
  /// In en, this message translates to:
  /// **'Season closed'**
  String get seasonClosed;

  /// No description provided for @lastWeekPlace.
  ///
  /// In en, this message translates to:
  /// **'Last week: place {rank}'**
  String lastWeekPlace(int rank);

  /// No description provided for @lastWeekScore.
  ///
  /// In en, this message translates to:
  /// **'Score {rating}'**
  String lastWeekScore(String rating);

  /// Short interface label: Daily reminders
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get reminders;

  /// No description provided for @reminderDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your courtyard is waiting'**
  String get reminderDailyTitle;

  /// No description provided for @reminderDailyBody.
  ///
  /// In en, this message translates to:
  /// **'A new table is ready today.'**
  String get reminderDailyBody;

  /// No description provided for @reminderStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak is at risk'**
  String get reminderStreakTitle;

  /// No description provided for @reminderStreakBody.
  ///
  /// In en, this message translates to:
  /// **'The third lantern goes out at midnight.'**
  String get reminderStreakBody;

  /// No description provided for @reminderWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'A new courtyard season'**
  String get reminderWeekTitle;

  /// No description provided for @reminderWeekBody.
  ///
  /// In en, this message translates to:
  /// **'Weekly quests and ranking have reset.'**
  String get reminderWeekBody;

  /// Singular label for one companion.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get pet;

  /// Label for more than one companion.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get pets;

  /// No description provided for @chooseAPet.
  ///
  /// In en, this message translates to:
  /// **'Choose a companion'**
  String get chooseAPet;

  /// Short interface label: Add a companion
  ///
  /// In en, this message translates to:
  /// **'Add a companion'**
  String get addPet;

  /// No description provided for @petInviteAdopt.
  ///
  /// In en, this message translates to:
  /// **'A friend is waiting'**
  String get petInviteAdopt;

  /// Short interface label: Show pets
  ///
  /// In en, this message translates to:
  /// **'Show pets'**
  String get petInviteShow;

  /// No description provided for @petYardStartAdventure.
  ///
  /// In en, this message translates to:
  /// **'Start an adventure'**
  String get petYardStartAdventure;

  /// Short interface label: Visit the den
  ///
  /// In en, this message translates to:
  /// **'Visit the den'**
  String get petYardVisit;

  /// Short interface label: Show in yard
  ///
  /// In en, this message translates to:
  /// **'Show in yard'**
  String get petYardShow;

  /// Short interface label: In the yard
  ///
  /// In en, this message translates to:
  /// **'In the yard'**
  String get petYardShowing;

  /// No description provided for @petYardShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show everyone in the yard'**
  String get petYardShowAll;

  /// No description provided for @petCareHint.
  ///
  /// In en, this message translates to:
  /// **'Wins help them play and rest. Feed harvested plants from the warehouse.'**
  String get petCareHint;

  /// No description provided for @petStarvingLine.
  ///
  /// In en, this message translates to:
  /// **'They are starving. Feed a harvested plant from the warehouse.'**
  String get petStarvingLine;

  /// No description provided for @petRemindersPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Hungry reminders?'**
  String get petRemindersPromptTitle;

  /// No description provided for @petRemindersPromptBody.
  ///
  /// In en, this message translates to:
  /// **'We can ping you when they get hungry.'**
  String get petRemindersPromptBody;

  /// Short interface label: Remind me
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get petRemindersYes;

  /// Dismisses the hungry-pet reminder prompt.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get petRemindersLater;

  /// No description provided for @reminderPetHungerTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is hungry'**
  String reminderPetHungerTitle(String name);

  /// No description provided for @reminderPetHungerBody.
  ///
  /// In en, this message translates to:
  /// **'Feed a harvested plant from the warehouse.'**
  String get reminderPetHungerBody;

  /// No description provided for @reminderPetPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to play'**
  String reminderPetPlayTitle(String name);

  /// No description provided for @reminderPetPlayBody.
  ///
  /// In en, this message translates to:
  /// **'Clear a table to play with them.'**
  String get reminderPetPlayBody;

  /// No description provided for @reminderPetRestTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to rest'**
  String reminderPetRestTitle(String name);

  /// No description provided for @reminderPetRestBody.
  ///
  /// In en, this message translates to:
  /// **'Clear a table so they can rest.'**
  String get reminderPetRestBody;

  /// No description provided for @reminderPetStarveTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is starving'**
  String reminderPetStarveTitle(String name);

  /// No description provided for @reminderPetStarveBody.
  ///
  /// In en, this message translates to:
  /// **'Feed a harvested plant from the warehouse.'**
  String get reminderPetStarveBody;

  /// No description provided for @petLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String petLevelLabel(int level);

  /// No description provided for @petLevelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String petLevelShort(int level);

  /// Short interface label: Maximum level
  ///
  /// In en, this message translates to:
  /// **'Maximum level'**
  String get petMaxLevel;

  /// No description provided for @petXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience {xp} / {need}'**
  String petXpLabel(int xp, int need);

  /// No description provided for @petStrengthLineText.
  ///
  /// In en, this message translates to:
  /// **'{stat} {total} = base {base} + item {main} + accessory {accessory}'**
  String petStrengthLineText(
    String stat,
    int total,
    int base,
    int main,
    int accessory,
  );

  /// No description provided for @petLevelChange.
  ///
  /// In en, this message translates to:
  /// **'Level {from} → {to}'**
  String petLevelChange(int from, int to);

  /// No description provided for @petStatChange.
  ///
  /// In en, this message translates to:
  /// **'{stat} {from} → {to}'**
  String petStatChange(String stat, int from, int to);

  /// Opens the plant feeding sheet.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get petFeed;

  /// Short interface label: Choose a plant
  ///
  /// In en, this message translates to:
  /// **'Choose a plant'**
  String get petFeedTitle;

  /// No description provided for @petFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No harvested plants in the warehouse.'**
  String get petFeedEmpty;

  /// No description provided for @petFeedPointless.
  ///
  /// In en, this message translates to:
  /// **'Fully fed, and already at maximum level.'**
  String get petFeedPointless;

  /// No description provided for @petFeedXp.
  ///
  /// In en, this message translates to:
  /// **'Experience: {xp}'**
  String petFeedXp(int xp);

  /// No description provided for @petFeedSatiety.
  ///
  /// In en, this message translates to:
  /// **'Restores hunger. Strength will not grow.'**
  String get petFeedSatiety;

  /// Short interface label: Feed this plant
  ///
  /// In en, this message translates to:
  /// **'Feed this plant'**
  String get petFeedConfirm;

  /// No description provided for @petFedReaction.
  ///
  /// In en, this message translates to:
  /// **'{name} enjoys the meal.'**
  String petFedReaction(String name);

  /// No description provided for @petFeedFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. The plant was not spent.'**
  String get petFeedFailed;

  /// No description provided for @petFeedMissing.
  ///
  /// In en, this message translates to:
  /// **'That plant is no longer in the warehouse.'**
  String get petFeedMissing;

  /// Short interface label: Empty
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get petSlotEmpty;

  /// Short interface label: Guard the garden
  ///
  /// In en, this message translates to:
  /// **'Guard the garden'**
  String get petGuardAction;

  /// No description provided for @petGuarding.
  ///
  /// In en, this message translates to:
  /// **'Guarding the garden'**
  String get petGuarding;

  /// Short interface label: Stop guarding
  ///
  /// In en, this message translates to:
  /// **'Stop guarding'**
  String get petStopGuard;

  /// Short interface label: Choose for raids
  ///
  /// In en, this message translates to:
  /// **'Choose for raids'**
  String get petRaidAction;

  /// Short interface label: Chosen for raids
  ///
  /// In en, this message translates to:
  /// **'Chosen for raids'**
  String get petRaiding;

  /// No description provided for @petStopRaid.
  ///
  /// In en, this message translates to:
  /// **'Clear raid choice'**
  String get petStopRaid;

  /// No description provided for @gearBonus.
  ///
  /// In en, this message translates to:
  /// **'+{bonus} strength'**
  String gearBonus(int bonus);

  /// No description provided for @gearPriceText.
  ///
  /// In en, this message translates to:
  /// **'{price} points'**
  String gearPriceText(String price);

  /// No description provided for @gearLevelRequired.
  ///
  /// In en, this message translates to:
  /// **'Requires level {level}'**
  String gearLevelRequired(int level);

  /// No description provided for @gearIfEquipped.
  ///
  /// In en, this message translates to:
  /// **'If equipped: {stat} {from} → {to}'**
  String gearIfEquipped(String stat, int from, int to);

  /// Buys a pet item.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get gearBuy;

  /// Equips an owned pet item.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get gearEquip;

  /// Removes an equipped pet item.
  ///
  /// In en, this message translates to:
  /// **'Take off'**
  String get gearUnequip;

  /// No description provided for @gearWornBy.
  ///
  /// In en, this message translates to:
  /// **'Worn by {name}'**
  String gearWornBy(String name);

  /// No description provided for @gearShortfallText.
  ///
  /// In en, this message translates to:
  /// **'Need {shortfall} more points'**
  String gearShortfallText(String shortfall);

  /// No description provided for @gearBuyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Points were not spent.'**
  String get gearBuyFailed;

  /// No description provided for @gardenGuardLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} guards the garden. Defense {power}'**
  String gardenGuardLabel(String name, int power);

  /// Short interface label: No defender yet
  ///
  /// In en, this message translates to:
  /// **'No defender yet'**
  String get gardenNoDefender;

  /// No description provided for @gardenUnguarded.
  ///
  /// In en, this message translates to:
  /// **'Garden is unguarded'**
  String get gardenUnguarded;

  /// Short interface label: Board
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardSemantic;

  /// No description provided for @traySemantic.
  ///
  /// In en, this message translates to:
  /// **'Tray, {filled} of {capacity}'**
  String traySemantic(int filled, int capacity);

  /// Short interface label: Empty slot
  ///
  /// In en, this message translates to:
  /// **'Empty slot'**
  String get trayEmptySlot;

  /// No description provided for @trayAlmostFull.
  ///
  /// In en, this message translates to:
  /// **'One space left — find a pair'**
  String get trayAlmostFull;

  /// Short interface label: House
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get houseCardTitle;

  /// Short interface label: Seeds
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seedsHeading;

  /// No description provided for @seedsButton.
  ///
  /// In en, this message translates to:
  /// **'Seeds · {count}'**
  String seedsButton(int count);

  /// No description provided for @seedPowerStep.
  ///
  /// In en, this message translates to:
  /// **'Seed power: {from} → {to}'**
  String seedPowerStep(int from, int to);

  /// No description provided for @seedCostStep.
  ///
  /// In en, this message translates to:
  /// **'Production cost: {from} → {to} points'**
  String seedCostStep(int from, int to);

  /// No description provided for @seedSpeciesUnlock.
  ///
  /// In en, this message translates to:
  /// **'New seed: {name}'**
  String seedSpeciesUnlock(String name);

  /// No description provided for @seedDurationStep.
  ///
  /// In en, this message translates to:
  /// **'Production time: {from} → {to}'**
  String seedDurationStep(String from, String to);

  /// No description provided for @seedChanceStep.
  ///
  /// In en, this message translates to:
  /// **'Chances: {summary}'**
  String seedChanceStep(String summary);

  /// Seed class whose plants grow quickly and feed for 10 experience.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get seedClassCommon;

  /// Seed class whose plants grow longer and feed for 25 experience.
  ///
  /// In en, this message translates to:
  /// **'Nutrient'**
  String get seedClassNutrient;

  /// Seed class whose plants grow longest and feed for 60 experience.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get seedClassRare;

  /// No description provided for @seedClassLine.
  ///
  /// In en, this message translates to:
  /// **'{name} {percent}%'**
  String seedClassLine(String name, int percent);

  /// No description provided for @seedSpan.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String seedSpan(int minutes, int seconds);

  /// No description provided for @seedPowerLabel.
  ///
  /// In en, this message translates to:
  /// **'Feed: {power}'**
  String seedPowerLabel(int power);

  /// No description provided for @seedPowerPending.
  ///
  /// In en, this message translates to:
  /// **'Expected seed power: {power}'**
  String seedPowerPending(int power);

  /// No description provided for @seedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String seedMinutes(int minutes);

  /// Short interface label: Possible seeds
  ///
  /// In en, this message translates to:
  /// **'Possible seeds'**
  String get seedSpeciesHeading;

  /// Short interface label: Equal chance
  ///
  /// In en, this message translates to:
  /// **'Both species in a class are equally likely'**
  String get seedEqualChance;

  /// No description provided for @produceSeedForText.
  ///
  /// In en, this message translates to:
  /// **'Produce a seed · {price} points'**
  String produceSeedForText(String price);

  /// Short interface label: Collect seed
  ///
  /// In en, this message translates to:
  /// **'Collect seed'**
  String get claimSeed;

  /// No description provided for @seedAdded.
  ///
  /// In en, this message translates to:
  /// **'Seed added to storage'**
  String get seedAdded;

  /// Short interface label: Open storage
  ///
  /// In en, this message translates to:
  /// **'Open storage'**
  String get openSeedStorage;

  /// No description provided for @seedPurpose.
  ///
  /// In en, this message translates to:
  /// **'A plant can be grown from this seed.'**
  String get seedPurpose;

  /// No description provided for @seedHouseLevel.
  ///
  /// In en, this message translates to:
  /// **'Grown by house level {level}'**
  String seedHouseLevel(int level);

  /// No description provided for @seedReceived.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String seedReceived(String date);

  /// No description provided for @seedGroupCount.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String seedGroupCount(int count);

  /// Short interface label: By power
  ///
  /// In en, this message translates to:
  /// **'By feed'**
  String get seedSortPower;

  /// Short interface label: By time received
  ///
  /// In en, this message translates to:
  /// **'By time received'**
  String get seedSortTime;

  /// No description provided for @seedProducing.
  ///
  /// In en, this message translates to:
  /// **'A seed is growing'**
  String get seedProducing;

  /// No description provided for @seedReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'The seed is ready'**
  String get seedReadyTitle;

  /// Short interface label: Unknown seed
  ///
  /// In en, this message translates to:
  /// **'Unknown seed'**
  String get seedUnknown;

  /// No description provided for @seedTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec left'**
  String seedTimeLeft(int minutes, int seconds);

  /// No description provided for @seedBadgeIdle.
  ///
  /// In en, this message translates to:
  /// **'Seed production is available'**
  String get seedBadgeIdle;

  /// No description provided for @seedBadgeProducing.
  ///
  /// In en, this message translates to:
  /// **'Seed growing, {time} left'**
  String seedBadgeProducing(String time);

  /// No description provided for @seedBadgeReady.
  ///
  /// In en, this message translates to:
  /// **'Seed ready to collect'**
  String get seedBadgeReady;

  /// Badge shown when a seed can be collected.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get seedReadyMark;

  /// Short interface label: Play mahjong
  ///
  /// In en, this message translates to:
  /// **'Play mahjong'**
  String get seedPlayMahjong;

  /// No description provided for @produceFirstSeed.
  ///
  /// In en, this message translates to:
  /// **'Produce the first seed'**
  String get produceFirstSeed;

  /// No description provided for @seedsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The house has not produced a seed yet.'**
  String get seedsEmptyBody;

  /// No description provided for @seedStackLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, feed {power}, {count}'**
  String seedStackLabel(String name, int power, int count);

  /// Short interface label: Seed production
  ///
  /// In en, this message translates to:
  /// **'Seed production'**
  String get seedProductionTitle;

  /// No description provided for @plantsButton.
  ///
  /// In en, this message translates to:
  /// **'Plants · {count}'**
  String plantsButton(int count);

  /// Short interface label: Warehouse
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouseTitle;

  /// No description provided for @warehouseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Warehouse, {count} plants'**
  String warehouseSemantic(int count);

  /// No description provided for @warehouseEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Harvested plants will be kept here'**
  String get warehouseEmptyBody;

  /// Short interface label: Open the garden
  ///
  /// In en, this message translates to:
  /// **'Open the garden'**
  String get openGarden;

  /// No description provided for @plantActionText.
  ///
  /// In en, this message translates to:
  /// **'Plant · {seeds} seed + {points} points'**
  String plantActionText(int seeds, String points);

  /// Short interface label: Choose a seed
  ///
  /// In en, this message translates to:
  /// **'Choose a seed'**
  String get chooseSeedTitle;

  /// No description provided for @noSeedsBody.
  ///
  /// In en, this message translates to:
  /// **'There are no seeds yet. Produce one in the house.'**
  String get noSeedsBody;

  /// Short interface label: Open production
  ///
  /// In en, this message translates to:
  /// **'Open production'**
  String get openHouseProduction;

  /// No description provided for @gardenBedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Bed {number}, empty'**
  String gardenBedEmpty(int number);

  /// No description provided for @bedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bed {number}'**
  String bedTitle(int number);

  /// Collects a ripe garden plant.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get harvestAction;

  /// Short badge on a ripe garden bed.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get harvestMark;

  /// No description provided for @plantPower.
  ///
  /// In en, this message translates to:
  /// **'Feed: {power}'**
  String plantPower(int power);

  /// No description provided for @plantCostLabelText.
  ///
  /// In en, this message translates to:
  /// **'Planting cost: {points} points'**
  String plantCostLabelText(String points);

  /// No description provided for @growDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Growing time: {minutes} min'**
  String growDurationLabel(int minutes);

  /// No description provided for @seedsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String seedsAvailable(int count);

  /// Short interface label: Future plant
  ///
  /// In en, this message translates to:
  /// **'Future plant'**
  String get plantPreviewLabel;

  /// No description provided for @plantVariant.
  ///
  /// In en, this message translates to:
  /// **'Look: {variant}'**
  String plantVariant(String variant);

  /// No description provided for @plantedOn.
  ///
  /// In en, this message translates to:
  /// **'Planted {date}'**
  String plantedOn(String date);

  /// No description provided for @maturedOn.
  ///
  /// In en, this message translates to:
  /// **'Matured {date}'**
  String maturedOn(String date);

  /// No description provided for @harvestedOn.
  ///
  /// In en, this message translates to:
  /// **'Collected {date}'**
  String harvestedOn(String date);

  /// No description provided for @gardenSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Nothing was spent.'**
  String get gardenSaveFailed;

  /// Short interface label: Not ready yet
  ///
  /// In en, this message translates to:
  /// **'Not ready yet'**
  String get gardenNotReady;

  /// Language name shown in the picker. Stays English in every locale.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language name shown in the picker. Stays Russian in every locale.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// Language name shown in the picker. Stays Thai in every locale.
  ///
  /// In en, this message translates to:
  /// **'ไทย'**
  String get languageThai;

  /// Goal for the compact tower challenge.
  ///
  /// In en, this message translates to:
  /// **'Tower: clear every layer'**
  String get challengeCompactTower;

  /// Goal while the two starred tiles are still on the board.
  ///
  /// In en, this message translates to:
  /// **'Remove the two starred tiles · {cleared}/2'**
  String challengeSpecialPair(int cleared);

  /// Goal for the no-shuffle challenge.
  ///
  /// In en, this message translates to:
  /// **'Clear the board without shuffling'**
  String get challengeNoShuffle;

  /// Display name of a courtyard plot.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, house{House} pond{Pond} pets{Pets} guest{Guest house} other{House}}'**
  String plotKindTitle(String kind);

  /// Plot name used inside a sentence, including the Russian genitive.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, house{House} pond{Pond} pets{Pets} guest{Guest house} other{House}}'**
  String plotKindTitleToward(String kind);

  /// The courtyard plot art has reached its last look.
  ///
  /// In en, this message translates to:
  /// **'{name} is complete'**
  String plotLookComplete(String name);

  /// Exactly one level remains before the plot art changes.
  ///
  /// In en, this message translates to:
  /// **'1 level until the next {name} look'**
  String plotLookNextOne(String name);

  /// How many levels remain before the plot art changes. Used when more than one level remains.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} levels until the next {name} look}}'**
  String plotLookProgressText(int count, String name);

  /// Shown when exactly one win remains before the house look changes.
  ///
  /// In en, this message translates to:
  /// **'Your next win upgrades the house'**
  String get nextWinUpgradesHouse;

  /// Wins remaining before the house look changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} win until the house upgrade} other{{count} wins until the house upgrade}}'**
  String winsUntilHouseUpgradeText(int count);

  /// Shown when exactly one win remains before the pond look changes.
  ///
  /// In en, this message translates to:
  /// **'Your next win improves the pond'**
  String get nextWinImprovesPond;

  /// Wins remaining before the pond look changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} win until the pond grows} other{{count} wins until the pond grows}}'**
  String winsUntilPondUpgradeText(int count);

  /// Heading for the upcoming pond art.
  ///
  /// In en, this message translates to:
  /// **'Next pond look'**
  String get nextPondLook;

  /// Stars remaining before the next courtyard plot unlocks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{1 more star until the {dest}} =1{1 more star until the {dest}} other{{count} more stars until the {dest}}}'**
  String hubStarsUntilPlotText(int count, String dest);

  /// Shown when one or fewer daily clears remain before a reward.
  ///
  /// In en, this message translates to:
  /// **'One daily until the reward'**
  String get oneDailyUntilReward;

  /// Daily clears remaining before a reward.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} daily until the reward} other{{count} dailies until the reward}}'**
  String hubDailiesUntilRewardText(int count);

  /// Shown when one or fewer campaign levels remain before a reward.
  ///
  /// In en, this message translates to:
  /// **'One level until the reward'**
  String get oneLevelUntilReward;

  /// Campaign levels remaining before a reward.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} level until the reward} other{{count} levels until the reward}}'**
  String hubLevelsUntilRewardText(int count);

  /// First-time clears remaining before a courtyard gift.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{One level until a courtyard gift} =1{One level until a courtyard gift} other{{count} levels until a courtyard gift}}'**
  String courtyardLevelsUntilGift(int count);

  /// Stars remaining before the weekly reward.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{1 more star until the reward} =1{1 more star until the reward} other{{count} more stars until the reward}}'**
  String hubStarsUntilReward(int count);

  /// Points just earned, with the currency word inflected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{+{amount} point} other{+{amount} points}}'**
  String pointsRewardText(int count, String amount);

  /// Tile-set name on a level card.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get styleFruit;

  /// Tile-set name on a level card.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get styleNature;

  /// Tile-set name on a level card.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get styleCourt;

  /// Tile-set name on a level card.
  ///
  /// In en, this message translates to:
  /// **'Myth'**
  String get styleMyth;

  /// Tile-set name on a level card.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get styleClassic;

  /// Tile-set name on a level card.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get styleShape;

  /// Tile-set name on a level card.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get styleNumber;

  /// Tile-set name when the style is unknown.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get styleMix;

  /// Weekly quest title.
  ///
  /// In en, this message translates to:
  /// **'Clear daily 3 times'**
  String get questDaily3;

  /// Weekly quest title.
  ///
  /// In en, this message translates to:
  /// **'Earn 8 stars'**
  String get questStars8;

  /// Weekly quest title.
  ///
  /// In en, this message translates to:
  /// **'Clear 4 campaign levels'**
  String get questClears4;

  /// Weekly quest title.
  ///
  /// In en, this message translates to:
  /// **'Score 3★ on a level'**
  String get questThreeStar1;

  /// Weekly quest title.
  ///
  /// In en, this message translates to:
  /// **'Keep three nights lit'**
  String get questStreak3;

  /// Name of the garden week event.
  ///
  /// In en, this message translates to:
  /// **'Garden week'**
  String get weekGarden;

  /// Name of the courtyard week event.
  ///
  /// In en, this message translates to:
  /// **'Courtyard week'**
  String get weekCourt;

  /// Name of the lantern week event.
  ///
  /// In en, this message translates to:
  /// **'Lantern week'**
  String get weekLanterns;

  /// Name of the myth week event.
  ///
  /// In en, this message translates to:
  /// **'Myth week'**
  String get weekMyth;

  /// Name of the harvest week event.
  ///
  /// In en, this message translates to:
  /// **'Harvest week'**
  String get weekHarvest;

  /// Fallback name of the weekly table.
  ///
  /// In en, this message translates to:
  /// **'This week’s table'**
  String get weekDefault;

  /// Companion name.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get petCat;

  /// Companion name.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get petDog;

  /// Companion name.
  ///
  /// In en, this message translates to:
  /// **'Raccoon'**
  String get petRaccoon;

  /// Companion name.
  ///
  /// In en, this message translates to:
  /// **'Hamster'**
  String get petHamster;

  /// Companion name.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get petFox;

  /// Pet need name.
  ///
  /// In en, this message translates to:
  /// **'Hunger'**
  String get petNeedHunger;

  /// Pet need name. Not the play button.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get petNeedPlay;

  /// Pet need name.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get petNeedRest;

  /// Pet status when nothing is needed.
  ///
  /// In en, this message translates to:
  /// **'{name} is content.'**
  String petMoodContent(String name);

  /// Pet status when a need is waiting.
  ///
  /// In en, this message translates to:
  /// **'{name} needs you.'**
  String petMoodAsking(String name);

  /// Pet status when hunger is critical.
  ///
  /// In en, this message translates to:
  /// **'{name} is starving.'**
  String petMoodStarving(String name);

  /// Result line after feeding.
  ///
  /// In en, this message translates to:
  /// **'You fed {name}.'**
  String petCareHunger(String name);

  /// Result line after playing.
  ///
  /// In en, this message translates to:
  /// **'You played with {name}.'**
  String petCarePlay(String name);

  /// Result line after rest.
  ///
  /// In en, this message translates to:
  /// **'{name} rested.'**
  String petCareRest(String name);

  /// Pet combat role.
  ///
  /// In en, this message translates to:
  /// **'Attacker'**
  String get petRoleAttacker;

  /// Pet combat role.
  ///
  /// In en, this message translates to:
  /// **'Defender'**
  String get petRoleDefender;

  /// Attack stat name.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get petStatAttack;

  /// Defense stat name.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get petStatDefense;

  /// Primary gear slot.
  ///
  /// In en, this message translates to:
  /// **'Main item'**
  String get gearSlotMain;

  /// Secondary gear slot.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get gearSlotAccessory;

  /// Garden stage after planting.
  ///
  /// In en, this message translates to:
  /// **'Seed planted'**
  String get growthSown;

  /// Garden stage when the plant has sprouted.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get growthSprout;

  /// Garden stage while the plant is growing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get growthGrowing;

  /// Garden stage when the plant can be harvested.
  ///
  /// In en, this message translates to:
  /// **'Ready to collect'**
  String get growthRipe;

  /// Seed species name.
  ///
  /// In en, this message translates to:
  /// **'Amber Bell'**
  String get seedAmberbell;

  /// Seed species name.
  ///
  /// In en, this message translates to:
  /// **'Mist Fern'**
  String get seedMistfern;

  /// Seed species name.
  ///
  /// In en, this message translates to:
  /// **'Glass Reed'**
  String get seedGlassreed;

  /// Seed species name.
  ///
  /// In en, this message translates to:
  /// **'Crimson Plum'**
  String get seedCrimsonplum;

  /// Seed species name.
  ///
  /// In en, this message translates to:
  /// **'Night Lotus'**
  String get seedNightlotus;

  /// Seed species name.
  ///
  /// In en, this message translates to:
  /// **'Star Bamboo'**
  String get seedStarbamboo;

  /// Short description of Amber Bell.
  ///
  /// In en, this message translates to:
  /// **'A warm seed with a tiny bell inside.'**
  String get seedBlurbAmberbell;

  /// Short description of Mist Fern.
  ///
  /// In en, this message translates to:
  /// **'A pale frond folded into a seed.'**
  String get seedBlurbMistfern;

  /// Short description of Glass Reed.
  ///
  /// In en, this message translates to:
  /// **'A clear reed that rings when the light hits it.'**
  String get seedBlurbGlassreed;

  /// Short description of Crimson Plum.
  ///
  /// In en, this message translates to:
  /// **'A dark sweet stone from a courtyard plum.'**
  String get seedBlurbCrimsonplum;

  /// Short description of Night Lotus.
  ///
  /// In en, this message translates to:
  /// **'A violet bud that opens only after dusk.'**
  String get seedBlurbNightlotus;

  /// Short description of Star Bamboo.
  ///
  /// In en, this message translates to:
  /// **'A jointed grain with a spark at the tip.'**
  String get seedBlurbStarbamboo;

  /// Where a seed came from when the house produced it.
  ///
  /// In en, this message translates to:
  /// **'Origin: house production'**
  String get plantOriginHouse;

  /// Where a seed came from when the source is not the house.
  ///
  /// In en, this message translates to:
  /// **'Origin: {source}'**
  String plantOriginOther(String source);

  /// First-win line for the house plot.
  ///
  /// In en, this message translates to:
  /// **'The next house look is bought with points.'**
  String get firstPhraseHouse;

  /// First-win line for the pond plot.
  ///
  /// In en, this message translates to:
  /// **'This pond fills as you play.'**
  String get firstPhrasePond;

  /// First-win line for the pet plot.
  ///
  /// In en, this message translates to:
  /// **'This pet house grows as you play.'**
  String get firstPhrasePets;

  /// First-win line for the guest plot.
  ///
  /// In en, this message translates to:
  /// **'This yard comes online as you play.'**
  String get firstPhraseGuest;

  /// Line when the house gains life without a new build step.
  ///
  /// In en, this message translates to:
  /// **'The house feels warmer.'**
  String get pathLifeHouse;

  /// Line when the pond gains life.
  ///
  /// In en, this message translates to:
  /// **'The pond feels alive.'**
  String get pathLifePond;

  /// Line when the pet house gains life.
  ///
  /// In en, this message translates to:
  /// **'The pet house feels warmer.'**
  String get pathLifePets;

  /// Line when the guest yard gains life.
  ///
  /// In en, this message translates to:
  /// **'The yard hums a little.'**
  String get pathLifeGuest;

  /// Name of the pond courtyard gift.
  ///
  /// In en, this message translates to:
  /// **'Little pond'**
  String get rewardPond;

  /// Name of the swing courtyard gift.
  ///
  /// In en, this message translates to:
  /// **'Garden swing'**
  String get rewardSwing;

  /// Name of the flower bed courtyard gift.
  ///
  /// In en, this message translates to:
  /// **'Flower bed'**
  String get rewardFlowerBed;

  /// Tile state: it can be picked.
  ///
  /// In en, this message translates to:
  /// **'free'**
  String get tileStateFree;

  /// Tile state: it is covered.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get tileStateLocked;

  /// Semantics while a matched tile is leaving.
  ///
  /// In en, this message translates to:
  /// **'{name}, matching'**
  String tileRemoving(String name);

  /// Semantics for a hinted tile in the tray.
  ///
  /// In en, this message translates to:
  /// **'{name} in tray, hinted'**
  String tileInTrayHinted(String name);

  /// Semantics for a tile sitting in the tray.
  ///
  /// In en, this message translates to:
  /// **'{name} in tray'**
  String tileInTray(String name);

  /// Semantics for a free hinted tile on the board.
  ///
  /// In en, this message translates to:
  /// **'{name}, free, hinted'**
  String tileFreeHinted(String name);

  /// Semantics for a covered hinted tile.
  ///
  /// In en, this message translates to:
  /// **'{name}, locked, hinted'**
  String tileLockedHinted(String name);

  /// Semantics for a free tile.
  ///
  /// In en, this message translates to:
  /// **'{name}, free'**
  String tileFreeState(String name);

  /// Semantics for a covered tile.
  ///
  /// In en, this message translates to:
  /// **'{name}, locked'**
  String tileLockedState(String name);

  /// Semantics for a locked level card.
  ///
  /// In en, this message translates to:
  /// **'Level {id}, locked'**
  String levelCardLocked(int id);

  /// Semantics for an unlocked level card.
  ///
  /// In en, this message translates to:
  /// **'Level {id}, {title}, {stars}{progress}'**
  String levelCardOpen(int id, String title, String stars, String progress);

  /// Level card semantics when no stars were earned.
  ///
  /// In en, this message translates to:
  /// **'no stars'**
  String get levelStarsNone;

  /// Level card semantics for a star count. Russian keeps the star mark.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String levelStarsSome(int count);

  /// Suffix when a level was started and not finished.
  ///
  /// In en, this message translates to:
  /// **', in progress'**
  String get levelInProgress;

  /// Semantics when a booster still has charges.
  ///
  /// In en, this message translates to:
  /// **'{name}, {count} left'**
  String boostLeft(String name, int count);

  /// Semantics when a booster is exhausted.
  ///
  /// In en, this message translates to:
  /// **'{name}, none left'**
  String boostNone(String name);

  /// Semantics when a pet needs attention.
  ///
  /// In en, this message translates to:
  /// **'Pets, need care'**
  String get petsNeedCare;

  /// Semantics for the daily button, joining the day label and streak status.
  ///
  /// In en, this message translates to:
  /// **'{today}. {status}'**
  String dailyButtonSemanticText(String today, String status);

  /// Semantics for a plot on the courtyard map.
  ///
  /// In en, this message translates to:
  /// **'{name} courtyard'**
  String courtyardSemanticText(String name);

  /// Semantics for a ripe garden bed.
  ///
  /// In en, this message translates to:
  /// **'Bed {number}, {name}, ready to collect'**
  String gardenBedReady(int number, String name);

  /// Semantics for a growing garden bed.
  ///
  /// In en, this message translates to:
  /// **'Bed {number}, {name}, {stage}, {time} left'**
  String gardenBedGrowing(int number, String name, String stage, String time);

  /// Names the next collectible in a pet adventure.
  ///
  /// In en, this message translates to:
  /// **'Next: {item}'**
  String storyNextItem(String item);

  /// Headline of a newly earned story item.
  ///
  /// In en, this message translates to:
  /// **'New gift: {item}'**
  String newGiftItem(String item);

  /// Active story title with chapter progress.
  ///
  /// In en, this message translates to:
  /// **'{title} · {progress}/3'**
  String storyProgressLine(String title, int progress);

  /// Yard label when a story chapter is waiting.
  ///
  /// In en, this message translates to:
  /// **'New chapter · {progress}/3'**
  String newChapterProgress(int progress);

  /// Legacy fox story label when a scene is ready.
  ///
  /// In en, this message translates to:
  /// **'Story ready · {stage}/3'**
  String storyReadyProgress(int stage);

  /// Legacy fox story progress.
  ///
  /// In en, this message translates to:
  /// **'Fox’s story · {stage}/3'**
  String foxStoryProgress(int stage);

  /// Gear shop line joining the role and the slot.
  ///
  /// In en, this message translates to:
  /// **'{role} · {slot}'**
  String gearOfferText(String role, String slot);

  /// Compact pet badge joining role and level.
  ///
  /// In en, this message translates to:
  /// **'{role}, {level}'**
  String petBadgeText(String role, String level);

  /// Empty pet yard prompt. Infinitive, unlike the sheet title.
  ///
  /// In en, this message translates to:
  /// **'Choose a companion'**
  String get chooseAPetYard;

  /// Status line when the yard has no pet yet.
  ///
  /// In en, this message translates to:
  /// **'Choose a pet'**
  String get chooseAPetStatus;

  /// Semantics label for the house on the map. Not the plot name used in sentences.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeSemantic;

  /// Yard label before a story is chosen.
  ///
  /// In en, this message translates to:
  /// **'Pet adventures'**
  String get petAdventures;

  /// Section title on the pet page.
  ///
  /// In en, this message translates to:
  /// **'Adventures'**
  String get adventures;

  /// Status when all three chapters of a story are done.
  ///
  /// In en, this message translates to:
  /// **'Adventure complete'**
  String get adventureComplete;

  /// Button after the last story gift.
  ///
  /// In en, this message translates to:
  /// **'Adventure complete!'**
  String get adventureCompleteBang;

  /// Starts the campaign from the active pet story.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Locked story row.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous story'**
  String get storyLocked;

  /// Caption under a pet that has five stories.
  ///
  /// In en, this message translates to:
  /// **'5 adventures'**
  String get fiveAdventures;

  /// Title of the legacy fox story.
  ///
  /// In en, this message translates to:
  /// **'A cozy corner for Fox'**
  String get foxTitle;

  /// Fox story goal before the first win.
  ///
  /// In en, this message translates to:
  /// **'One win to prepare a spot'**
  String get foxGoal0;

  /// Fox story goal before the second win.
  ///
  /// In en, this message translates to:
  /// **'One win to make a bed'**
  String get foxGoal1;

  /// Fox story goal before the third win.
  ///
  /// In en, this message translates to:
  /// **'One win to bring a toy'**
  String get foxGoal2;

  /// Fox story goal after the corner is finished.
  ///
  /// In en, this message translates to:
  /// **'Fox feels at home!'**
  String get foxGoalDone;

  /// Fox banner when a new scene is waiting.
  ///
  /// In en, this message translates to:
  /// **'See what changed!'**
  String get foxSeeWhatChanged;

  /// Fox banner before the story starts.
  ///
  /// In en, this message translates to:
  /// **'Help Fox settle in · 3 wins'**
  String get foxHelpSettle;

  /// Error when the fox story fails to save.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get foxSaveFailed;

  /// Opening text of the fox story.
  ///
  /// In en, this message translates to:
  /// **'Fox found a quiet spot in your courtyard. Three campaign wins will turn it into a home.'**
  String get foxIntro;

  /// Fox story text for the first chapter.
  ///
  /// In en, this message translates to:
  /// **'Let’s clear the leaves. Win a campaign level to prepare the spot.'**
  String get foxStage0;

  /// Fox story text for the second chapter.
  ///
  /// In en, this message translates to:
  /// **'The spot is ready! One more win will bring a soft bed.'**
  String get foxStage1;

  /// Fox story text for the color choice.
  ///
  /// In en, this message translates to:
  /// **'A soft bed! Pick a color. One more win will bring a toy.'**
  String get foxStage2;

  /// Fox story text after the corner is complete.
  ///
  /// In en, this message translates to:
  /// **'Fox feels at home! Tap Fox to play. This corner stays in your courtyard.'**
  String get foxStageDone;

  /// Bed color choice.
  ///
  /// In en, this message translates to:
  /// **'Honey'**
  String get foxHoney;

  /// Bed color choice.
  ///
  /// In en, this message translates to:
  /// **'Sky blue'**
  String get foxSkyBlue;

  /// Toy choice in the fox story.
  ///
  /// In en, this message translates to:
  /// **'Ball'**
  String get foxBall;

  /// Toy choice in the fox story.
  ///
  /// In en, this message translates to:
  /// **'Plush toy'**
  String get foxPlushToy;

  /// Closes the fox story for now.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Button that starts the fox story.
  ///
  /// In en, this message translates to:
  /// **'Help · 3 stages'**
  String get foxHelpStages;

  /// Button after the fox story is complete.
  ///
  /// In en, this message translates to:
  /// **'Lovely!'**
  String get foxLovely;

  /// Yard label when the fox story is finished.
  ///
  /// In en, this message translates to:
  /// **'Fox is home · 3/3'**
  String get foxIsHome;

  /// Yard label for the fox story before it starts.
  ///
  /// In en, this message translates to:
  /// **'Fox’s story'**
  String get foxStory;

  /// Tile name.
  ///
  /// In en, this message translates to:
  /// **'East wind'**
  String get windEast;

  /// Tile name.
  ///
  /// In en, this message translates to:
  /// **'South wind'**
  String get windSouth;

  /// Tile name.
  ///
  /// In en, this message translates to:
  /// **'West wind'**
  String get windWest;

  /// Tile name.
  ///
  /// In en, this message translates to:
  /// **'North wind'**
  String get windNorth;

  /// Singular tile family. Not the level style name.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get familyFruit;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get familyFlower;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get familyAnimal;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Bamboo'**
  String get familyBamboo;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get familyCharacter;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Dot'**
  String get familyDot;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Dragon'**
  String get familyDragon;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get familyWind;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get familySeason;

  /// Singular tile family. Not the level style name.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get familyNumber;

  /// Singular tile family. Not the level style name.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get familyShape;

  /// Generic tile family.
  ///
  /// In en, this message translates to:
  /// **'Tile'**
  String get familyTile;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get familyArt;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Clown'**
  String get familyClown;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Emperor'**
  String get familyEmperor;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Joker'**
  String get familyJoker;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get familyProfession;

  /// Tile family.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get familyQueen;

  /// Wind direction on a tile.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get familyEast;

  /// Wind direction on a tile.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get familySouth;

  /// Wind direction on a tile.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get familyWest;

  /// Wind direction on a tile.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get familyNorth;

  /// Season on a tile.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get familySpring;

  /// Season on a tile.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get familySummer;

  /// Season on a tile.
  ///
  /// In en, this message translates to:
  /// **'Autumn'**
  String get familyAutumn;

  /// Season on a tile.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get familyWinter;

  /// Pet item name for id attacker_main_1.
  ///
  /// In en, this message translates to:
  /// **'Silk Sash'**
  String get gearAttackerMain1;

  /// Pet item name for id attacker_main_2.
  ///
  /// In en, this message translates to:
  /// **'Night Claw'**
  String get gearAttackerMain2;

  /// Pet item name for id attacker_main_3.
  ///
  /// In en, this message translates to:
  /// **'Raid Lantern'**
  String get gearAttackerMain3;

  /// Pet item name for id attacker_accessory_1.
  ///
  /// In en, this message translates to:
  /// **'Scout Bell'**
  String get gearAttackerAccessory1;

  /// Pet item name for id attacker_accessory_2.
  ///
  /// In en, this message translates to:
  /// **'Prowl Pouch'**
  String get gearAttackerAccessory2;

  /// Pet item name for id attacker_accessory_3.
  ///
  /// In en, this message translates to:
  /// **'Moon Charm'**
  String get gearAttackerAccessory3;

  /// Pet item name for id defender_main_1.
  ///
  /// In en, this message translates to:
  /// **'Padded Vest'**
  String get gearDefenderMain1;

  /// Pet item name for id defender_main_2.
  ///
  /// In en, this message translates to:
  /// **'Guard Vest'**
  String get gearDefenderMain2;

  /// Pet item name for id defender_main_3.
  ///
  /// In en, this message translates to:
  /// **'Lantern Plate'**
  String get gearDefenderMain3;

  /// Pet item name for id defender_accessory_1.
  ///
  /// In en, this message translates to:
  /// **'Leather Collar'**
  String get gearDefenderAccessory1;

  /// Pet item name for id defender_accessory_2.
  ///
  /// In en, this message translates to:
  /// **'Watch Band'**
  String get gearDefenderAccessory2;

  /// Pet item name for id defender_accessory_3.
  ///
  /// In en, this message translates to:
  /// **'Gate Charm'**
  String get gearDefenderAccessory3;

  /// Campaign chapter name 1.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get storyCampaign0;

  /// Campaign chapter name 2.
  ///
  /// In en, this message translates to:
  /// **'Bud'**
  String get storyCampaign1;

  /// Campaign chapter name 3.
  ///
  /// In en, this message translates to:
  /// **'Bloom'**
  String get storyCampaign2;

  /// Campaign chapter name 4.
  ///
  /// In en, this message translates to:
  /// **'Glade'**
  String get storyCampaign3;

  /// Campaign chapter name 5.
  ///
  /// In en, this message translates to:
  /// **'Lawn'**
  String get storyCampaign4;

  /// Campaign chapter name 6.
  ///
  /// In en, this message translates to:
  /// **'Grove'**
  String get storyCampaign5;

  /// Campaign chapter name 7.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get storyCampaign6;

  /// Campaign chapter name 8.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get storyCampaign7;

  /// Campaign chapter name 9.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get storyCampaign8;

  /// Campaign chapter name 10.
  ///
  /// In en, this message translates to:
  /// **'Gazebo'**
  String get storyCampaign9;

  /// Campaign chapter name 11.
  ///
  /// In en, this message translates to:
  /// **'Fan'**
  String get storyCampaign10;

  /// Campaign chapter name 12.
  ///
  /// In en, this message translates to:
  /// **'Peacock Fan'**
  String get storyCampaign11;

  /// Campaign chapter name 13.
  ///
  /// In en, this message translates to:
  /// **'Lotus'**
  String get storyCampaign12;

  /// Campaign chapter name 14.
  ///
  /// In en, this message translates to:
  /// **'Pond'**
  String get storyCampaign13;

  /// Campaign chapter name 15.
  ///
  /// In en, this message translates to:
  /// **'Carp'**
  String get storyCampaign14;

  /// Campaign chapter name 16.
  ///
  /// In en, this message translates to:
  /// **'Lake'**
  String get storyCampaign15;

  /// Campaign chapter name 17.
  ///
  /// In en, this message translates to:
  /// **'Vine'**
  String get storyCampaign16;

  /// Campaign chapter name 18.
  ///
  /// In en, this message translates to:
  /// **'Ivy'**
  String get storyCampaign17;

  /// Campaign chapter name 19.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get storyCampaign18;

  /// Campaign chapter name 20.
  ///
  /// In en, this message translates to:
  /// **'Lanterns'**
  String get storyCampaign19;

  /// Campaign chapter name 21.
  ///
  /// In en, this message translates to:
  /// **'Pavilion'**
  String get storyCampaign20;

  /// Campaign chapter name 22.
  ///
  /// In en, this message translates to:
  /// **'Wind Temple'**
  String get storyCampaign21;

  /// Campaign chapter name 23.
  ///
  /// In en, this message translates to:
  /// **'Dragon'**
  String get storyCampaign22;

  /// Campaign chapter name 24.
  ///
  /// In en, this message translates to:
  /// **'Sky Dragon'**
  String get storyCampaign23;

  /// Era name 1 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Clearing'**
  String get houseEraName0;

  /// Era narration 1 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'A house will stand here.'**
  String get houseEraPhrase0;

  /// Era name 2 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Shack'**
  String get houseEraName1;

  /// Era narration 2 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'A shack leans on the plot.'**
  String get houseEraPhrase1;

  /// Era name 3 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Hut'**
  String get houseEraName2;

  /// Era narration 3 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The hut has a door.'**
  String get houseEraPhrase2;

  /// Era name 4 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Cabin'**
  String get houseEraName3;

  /// Era narration 4 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The cabin is timber now.'**
  String get houseEraPhrase3;

  /// Era name 5 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get houseEraName4;

  /// Era narration 5 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'A real house stands here.'**
  String get houseEraPhrase4;

  /// Era name 6 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Cottage'**
  String get houseEraName5;

  /// Era narration 6 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The cottage has two floors.'**
  String get houseEraPhrase5;

  /// Era name 7 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Estate'**
  String get houseEraName6;

  /// Era narration 7 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The estate spreads its wings.'**
  String get houseEraPhrase6;

  /// Era name 8 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Mansion'**
  String get houseEraName7;

  /// Era narration 8 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The mansion is stone.'**
  String get houseEraPhrase7;

  /// Era name 9 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get houseEraName8;

  /// Era narration 9 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The walls become a keep.'**
  String get houseEraPhrase8;

  /// Era name 10 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Castle'**
  String get houseEraName9;

  /// Era narration 10 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'A castle rises.'**
  String get houseEraPhrase9;

  /// Era name 11 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Grand castle'**
  String get houseEraName10;

  /// Era narration 11 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The castle fills the hill.'**
  String get houseEraPhrase10;

  /// Era name 12 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'Residence'**
  String get houseEraName11;

  /// Era narration 12 of the house plot.
  ///
  /// In en, this message translates to:
  /// **'The residence is complete.'**
  String get houseEraPhrase11;

  /// Era name 1 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Hollow'**
  String get pondEraName0;

  /// Era narration 1 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'A pond will fill this hollow.'**
  String get pondEraPhrase0;

  /// Era name 2 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Puddle'**
  String get pondEraName1;

  /// Era narration 2 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The puddle holds.'**
  String get pondEraPhrase1;

  /// Era name 3 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Pond'**
  String get pondEraName2;

  /// Era narration 3 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Reeds take the shore.'**
  String get pondEraPhrase2;

  /// Era name 4 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Walkway'**
  String get pondEraName3;

  /// Era narration 4 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The walkway is down.'**
  String get pondEraPhrase3;

  /// Era name 5 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Koi pond'**
  String get pondEraName4;

  /// Era narration 5 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Koi have a home.'**
  String get pondEraPhrase4;

  /// Era name 6 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Pavilion'**
  String get pondEraName5;

  /// Era narration 6 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'A pavilion watches the water.'**
  String get pondEraPhrase5;

  /// Era name 7 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Water garden'**
  String get pondEraName6;

  /// Era narration 7 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The pond is a garden.'**
  String get pondEraPhrase6;

  /// Era name 8 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Stone banks'**
  String get pondEraName7;

  /// Era narration 8 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Stone banks and lanterns.'**
  String get pondEraPhrase7;

  /// Era name 9 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get pondEraName8;

  /// Era narration 9 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'A bridge crosses the water.'**
  String get pondEraPhrase8;

  /// Era name 10 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Water court'**
  String get pondEraName9;

  /// Era narration 10 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The water court is walled.'**
  String get pondEraPhrase9;

  /// Era name 11 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Palace pond'**
  String get pondEraName10;

  /// Era narration 11 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Palace gardens reach the pond.'**
  String get pondEraPhrase10;

  /// Era name 12 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'Water garden complete'**
  String get pondEraName11;

  /// Era narration 12 of the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The water garden is complete.'**
  String get pondEraPhrase11;

  /// Era name 1 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Yard'**
  String get petsEraName0;

  /// Era narration 1 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'A pet house will stand here.'**
  String get petsEraPhrase0;

  /// Era name 2 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Bowls'**
  String get petsEraName1;

  /// Era narration 2 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Bowls wait in the grass.'**
  String get petsEraPhrase1;

  /// Era name 3 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Kennel'**
  String get petsEraName2;

  /// Era narration 3 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'A kennel leans on the plot.'**
  String get petsEraPhrase2;

  /// Era name 4 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Hutch'**
  String get petsEraName3;

  /// Era narration 4 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The hutch has a door.'**
  String get petsEraPhrase3;

  /// Era name 5 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Pet house'**
  String get petsEraName4;

  /// Era narration 5 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The pets have a house.'**
  String get petsEraPhrase4;

  /// Era name 6 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Play yard'**
  String get petsEraName5;

  /// Era narration 6 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'A play yard opens.'**
  String get petsEraPhrase5;

  /// Era name 7 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get petsEraName6;

  /// Era narration 7 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The garden is theirs.'**
  String get petsEraPhrase6;

  /// Era name 8 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Den'**
  String get petsEraName7;

  /// Era narration 8 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'A den is lined.'**
  String get petsEraPhrase7;

  /// Era name 9 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Lodge'**
  String get petsEraName8;

  /// Era narration 9 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The lodge is warm.'**
  String get petsEraPhrase8;

  /// Era name 10 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Menagerie'**
  String get petsEraName9;

  /// Era narration 10 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'A menagerie gathers.'**
  String get petsEraPhrase9;

  /// Era name 11 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Sanctuary'**
  String get petsEraName10;

  /// Era narration 11 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The sanctuary is fenced.'**
  String get petsEraPhrase10;

  /// Era name 12 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'Pet home complete'**
  String get petsEraName11;

  /// Era narration 12 of the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The pet house is complete.'**
  String get petsEraPhrase11;

  /// Era name 1 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Quiet yard'**
  String get guestEraName0;

  /// Era narration 1 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'A signal will reach this yard.'**
  String get guestEraPhrase0;

  /// Era name 2 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Pole'**
  String get guestEraName1;

  /// Era narration 2 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The pole holds the line.'**
  String get guestEraPhrase1;

  /// Era name 3 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get guestEraName2;

  /// Era narration 3 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Cable finds the house.'**
  String get guestEraPhrase2;

  /// Era name 4 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Dish'**
  String get guestEraName3;

  /// Era narration 4 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The dish is up.'**
  String get guestEraPhrase3;

  /// Era name 5 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Screens'**
  String get guestEraName4;

  /// Era narration 5 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Screens glow in the yard.'**
  String get guestEraPhrase4;

  /// Era name 6 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Line lamp'**
  String get guestEraName5;

  /// Era narration 6 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'A lamp of the line.'**
  String get guestEraPhrase5;

  /// Era name 7 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Far talk'**
  String get guestEraName6;

  /// Era narration 7 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The yard talks farther.'**
  String get guestEraPhrase6;

  /// Era name 8 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Signal tower'**
  String get guestEraName7;

  /// Era narration 8 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'A tower of the signal.'**
  String get guestEraPhrase7;

  /// Era name 9 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Observatory'**
  String get guestEraName8;

  /// Era narration 9 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The observatory rises.'**
  String get guestEraPhrase8;

  /// Era name 10 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Crystal line'**
  String get guestEraName9;

  /// Era narration 10 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Crystal and wire.'**
  String get guestEraPhrase9;

  /// Era name 11 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Beacon'**
  String get guestEraName10;

  /// Era narration 11 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'A beacon on the hill.'**
  String get guestEraPhrase10;

  /// Era name 12 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'Yard online'**
  String get guestEraName11;

  /// Era narration 12 of the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The yard is fully online.'**
  String get guestEraPhrase11;

  /// Small progress line 1 for the house plot.
  ///
  /// In en, this message translates to:
  /// **'Another step along the path.'**
  String get houseWarm0;

  /// Small progress line 2 for the house plot.
  ///
  /// In en, this message translates to:
  /// **'The plot is yours now.'**
  String get houseWarm1;

  /// Small progress line 3 for the house plot.
  ///
  /// In en, this message translates to:
  /// **'The house is a little closer.'**
  String get houseWarm2;

  /// Small progress line 1 for the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The water rose a little.'**
  String get pondWarm0;

  /// Small progress line 2 for the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The pond is more yours now.'**
  String get pondWarm1;

  /// Small progress line 3 for the pond plot.
  ///
  /// In en, this message translates to:
  /// **'The banks sit closer.'**
  String get pondWarm2;

  /// Small progress line 1 for the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The pet house grew a little.'**
  String get petsWarm0;

  /// Small progress line 2 for the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The yard is more theirs now.'**
  String get petsWarm1;

  /// Small progress line 3 for the pets plot.
  ///
  /// In en, this message translates to:
  /// **'The kennel sits closer.'**
  String get petsWarm2;

  /// Small progress line 1 for the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The signal grew a little.'**
  String get guestWarm0;

  /// Small progress line 2 for the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The yard is more connected.'**
  String get guestWarm1;

  /// Small progress line 3 for the guest plot.
  ///
  /// In en, this message translates to:
  /// **'The line sits closer.'**
  String get guestWarm2;

  /// Title of pet story cat_window.
  ///
  /// In en, this message translates to:
  /// **'Sunny Windowsill'**
  String get storyCatWindowTitle;

  /// Chapter 1 of pet story cat_window.
  ///
  /// In en, this message translates to:
  /// **'Find the warmest patch of sunlight.'**
  String get storyCatWindowChapter0;

  /// Chapter 2 of pet story cat_window.
  ///
  /// In en, this message translates to:
  /// **'Bring a soft cushion and a ball of yarn.'**
  String get storyCatWindowChapter1;

  /// Chapter 3 of pet story cat_window.
  ///
  /// In en, this message translates to:
  /// **'Hang a curtain for the perfect afternoon nap.'**
  String get storyCatWindowChapter2;

  /// Title of pet story cat_watch.
  ///
  /// In en, this message translates to:
  /// **'Midnight Watch'**
  String get storyCatWatchTitle;

  /// Chapter 1 of pet story cat_watch.
  ///
  /// In en, this message translates to:
  /// **'Light a quiet path across the courtyard.'**
  String get storyCatWatchChapter0;

  /// Chapter 2 of pet story cat_watch.
  ///
  /// In en, this message translates to:
  /// **'Add a bell to hear every visitor.'**
  String get storyCatWatchChapter1;

  /// Chapter 3 of pet story cat_watch.
  ///
  /// In en, this message translates to:
  /// **'Watch the moon through a tiny telescope.'**
  String get storyCatWatchChapter2;

  /// Title of pet story cat_garden.
  ///
  /// In en, this message translates to:
  /// **'Secret Garden'**
  String get storyCatGardenTitle;

  /// Chapter 1 of pet story cat_garden.
  ///
  /// In en, this message translates to:
  /// **'Plant a hidden green corner.'**
  String get storyCatGardenChapter0;

  /// Chapter 2 of pet story cat_garden.
  ///
  /// In en, this message translates to:
  /// **'Invite bright butterflies to visit.'**
  String get storyCatGardenChapter1;

  /// Chapter 3 of pet story cat_garden.
  ///
  /// In en, this message translates to:
  /// **'Finish the garden with a murmuring fountain.'**
  String get storyCatGardenChapter2;

  /// Title of pet story cat_library.
  ///
  /// In en, this message translates to:
  /// **'Little Library'**
  String get storyCatLibraryTitle;

  /// Chapter 1 of pet story cat_library.
  ///
  /// In en, this message translates to:
  /// **'Collect three favorite storybooks.'**
  String get storyCatLibraryChapter0;

  /// Chapter 2 of pet story cat_library.
  ///
  /// In en, this message translates to:
  /// **'Spread a blanket beside the shelves.'**
  String get storyCatLibraryChapter1;

  /// Chapter 3 of pet story cat_library.
  ///
  /// In en, this message translates to:
  /// **'Light a reading lamp for long evenings.'**
  String get storyCatLibraryChapter2;

  /// Title of pet story cat_tea.
  ///
  /// In en, this message translates to:
  /// **'Tea House Keeper'**
  String get storyCatTeaTitle;

  /// Chapter 1 of pet story cat_tea.
  ///
  /// In en, this message translates to:
  /// **'Set out the first tiny teacup.'**
  String get storyCatTeaChapter0;

  /// Chapter 2 of pet story cat_tea.
  ///
  /// In en, this message translates to:
  /// **'Decorate the table with fresh flowers.'**
  String get storyCatTeaChapter1;

  /// Chapter 3 of pet story cat_tea.
  ///
  /// In en, this message translates to:
  /// **'Raise the tea-house banner for guests.'**
  String get storyCatTeaChapter2;

  /// Title of pet story dog_trail.
  ///
  /// In en, this message translates to:
  /// **'Welcome Trail'**
  String get storyDogTrailTitle;

  /// Chapter 1 of pet story dog_trail.
  ///
  /// In en, this message translates to:
  /// **'Mark a friendly trail through the yard.'**
  String get storyDogTrailChapter0;

  /// Chapter 2 of pet story dog_trail.
  ///
  /// In en, this message translates to:
  /// **'Leave fresh water for travelers.'**
  String get storyDogTrailChapter1;

  /// Chapter 3 of pet story dog_trail.
  ///
  /// In en, this message translates to:
  /// **'Put a ball at the finish for a joyful welcome.'**
  String get storyDogTrailChapter2;

  /// Title of pet story dog_bridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge Patrol'**
  String get storyDogBridgeTitle;

  /// Chapter 1 of pet story dog_bridge.
  ///
  /// In en, this message translates to:
  /// **'Secure the old bridge with a strong rope.'**
  String get storyDogBridgeChapter0;

  /// Chapter 2 of pet story dog_bridge.
  ///
  /// In en, this message translates to:
  /// **'Hang a lantern for foggy mornings.'**
  String get storyDogBridgeChapter1;

  /// Chapter 3 of pet story dog_bridge.
  ///
  /// In en, this message translates to:
  /// **'Earn the golden courtyard patrol badge.'**
  String get storyDogBridgeChapter2;

  /// Title of pet story dog_picnic.
  ///
  /// In en, this message translates to:
  /// **'Picnic Day'**
  String get storyDogPicnicTitle;

  /// Chapter 1 of pet story dog_picnic.
  ///
  /// In en, this message translates to:
  /// **'Pack a basket for every friend.'**
  String get storyDogPicnicChapter0;

  /// Chapter 2 of pet story dog_picnic.
  ///
  /// In en, this message translates to:
  /// **'Choose a sunny place for the blanket.'**
  String get storyDogPicnicChapter1;

  /// Chapter 3 of pet story dog_picnic.
  ///
  /// In en, this message translates to:
  /// **'Share the treats when everyone arrives.'**
  String get storyDogPicnicChapter2;

  /// Title of pet story dog_kite.
  ///
  /// In en, this message translates to:
  /// **'The Lost Kite'**
  String get storyDogKiteTitle;

  /// Chapter 1 of pet story dog_kite.
  ///
  /// In en, this message translates to:
  /// **'Spot the kite beyond the hills.'**
  String get storyDogKiteChapter0;

  /// Chapter 2 of pet story dog_kite.
  ///
  /// In en, this message translates to:
  /// **'Follow the wind with a compass.'**
  String get storyDogKiteChapter1;

  /// Chapter 3 of pet story dog_kite.
  ///
  /// In en, this message translates to:
  /// **'Bring it home and tie on a new ribbon.'**
  String get storyDogKiteChapter2;

  /// Title of pet story dog_festival.
  ///
  /// In en, this message translates to:
  /// **'Festival Helper'**
  String get storyDogFestivalTitle;

  /// Chapter 1 of pet story dog_festival.
  ///
  /// In en, this message translates to:
  /// **'Carry colorful flags to the square.'**
  String get storyDogFestivalChapter0;

  /// Chapter 2 of pet story dog_festival.
  ///
  /// In en, this message translates to:
  /// **'Lead the parade with a little drum.'**
  String get storyDogFestivalChapter1;

  /// Chapter 3 of pet story dog_festival.
  ///
  /// In en, this message translates to:
  /// **'Receive a medal for helping everyone.'**
  String get storyDogFestivalChapter2;

  /// Title of pet story raccoon_workshop.
  ///
  /// In en, this message translates to:
  /// **'Shiny Workshop'**
  String get storyRaccoonWorkshopTitle;

  /// Chapter 1 of pet story raccoon_workshop.
  ///
  /// In en, this message translates to:
  /// **'Open a toolbox of curious inventions.'**
  String get storyRaccoonWorkshopChapter0;

  /// Chapter 2 of pet story raccoon_workshop.
  ///
  /// In en, this message translates to:
  /// **'Fit the brightest gears together.'**
  String get storyRaccoonWorkshopChapter1;

  /// Chapter 3 of pet story raccoon_workshop.
  ///
  /// In en, this message translates to:
  /// **'Build a clock that chimes at sunset.'**
  String get storyRaccoonWorkshopChapter2;

  /// Title of pet story raccoon_market.
  ///
  /// In en, this message translates to:
  /// **'Moonlit Market'**
  String get storyRaccoonMarketTitle;

  /// Chapter 1 of pet story raccoon_market.
  ///
  /// In en, this message translates to:
  /// **'Weave a basket for unusual finds.'**
  String get storyRaccoonMarketChapter0;

  /// Chapter 2 of pet story raccoon_market.
  ///
  /// In en, this message translates to:
  /// **'Light a stall beneath the moon.'**
  String get storyRaccoonMarketChapter1;

  /// Chapter 3 of pet story raccoon_market.
  ///
  /// In en, this message translates to:
  /// **'Trade three shiny coins for a surprise.'**
  String get storyRaccoonMarketChapter2;

  /// Title of pet story raccoon_river.
  ///
  /// In en, this message translates to:
  /// **'River Treasure'**
  String get storyRaccoonRiverTitle;

  /// Chapter 1 of pet story raccoon_river.
  ///
  /// In en, this message translates to:
  /// **'Read the map hidden under a stone.'**
  String get storyRaccoonRiverChapter0;

  /// Chapter 2 of pet story raccoon_river.
  ///
  /// In en, this message translates to:
  /// **'Patch a tiny boat for the crossing.'**
  String get storyRaccoonRiverChapter1;

  /// Chapter 3 of pet story raccoon_river.
  ///
  /// In en, this message translates to:
  /// **'Find the singing shell on the far bank.'**
  String get storyRaccoonRiverChapter2;

  /// Title of pet story raccoon_recycle.
  ///
  /// In en, this message translates to:
  /// **'Second-Chance Garden'**
  String get storyRaccoonRecycleTitle;

  /// Chapter 1 of pet story raccoon_recycle.
  ///
  /// In en, this message translates to:
  /// **'Turn an old crate into a planter.'**
  String get storyRaccoonRecycleChapter0;

  /// Chapter 2 of pet story raccoon_recycle.
  ///
  /// In en, this message translates to:
  /// **'Repair a dented watering can.'**
  String get storyRaccoonRecycleChapter1;

  /// Chapter 3 of pet story raccoon_recycle.
  ///
  /// In en, this message translates to:
  /// **'Build a windmill from forgotten pieces.'**
  String get storyRaccoonRecycleChapter2;

  /// Title of pet story raccoon_cafe.
  ///
  /// In en, this message translates to:
  /// **'Night Café'**
  String get storyRaccoonCafeTitle;

  /// Chapter 1 of pet story raccoon_cafe.
  ///
  /// In en, this message translates to:
  /// **'Polish a mug for the first guest.'**
  String get storyRaccoonCafeChapter0;

  /// Chapter 2 of pet story raccoon_cafe.
  ///
  /// In en, this message translates to:
  /// **'Bake a plate of moon-shaped cookies.'**
  String get storyRaccoonCafeChapter1;

  /// Chapter 3 of pet story raccoon_cafe.
  ///
  /// In en, this message translates to:
  /// **'Hang the café sign before nightfall.'**
  String get storyRaccoonCafeChapter2;

  /// Title of pet story hamster_railway.
  ///
  /// In en, this message translates to:
  /// **'Tiny Railway'**
  String get storyHamsterRailwayTitle;

  /// Chapter 1 of pet story hamster_railway.
  ///
  /// In en, this message translates to:
  /// **'Lay tracks around the flower bed.'**
  String get storyHamsterRailwayChapter0;

  /// Chapter 2 of pet story hamster_railway.
  ///
  /// In en, this message translates to:
  /// **'Build a cart just the right size.'**
  String get storyHamsterRailwayChapter1;

  /// Chapter 3 of pet story hamster_railway.
  ///
  /// In en, this message translates to:
  /// **'Open the courtyard’s smallest station.'**
  String get storyHamsterRailwayChapter2;

  /// Title of pet story hamster_pantry.
  ///
  /// In en, this message translates to:
  /// **'Great Pantry'**
  String get storyHamsterPantryTitle;

  /// Chapter 1 of pet story hamster_pantry.
  ///
  /// In en, this message translates to:
  /// **'Gather a winter bag of seeds.'**
  String get storyHamsterPantryChapter0;

  /// Chapter 2 of pet story hamster_pantry.
  ///
  /// In en, this message translates to:
  /// **'Build shelves from smooth twigs.'**
  String get storyHamsterPantryChapter1;

  /// Chapter 3 of pet story hamster_pantry.
  ///
  /// In en, this message translates to:
  /// **'Label the finest jar in the pantry.'**
  String get storyHamsterPantryChapter2;

  /// Title of pet story hamster_clouds.
  ///
  /// In en, this message translates to:
  /// **'Cloud Observatory'**
  String get storyHamsterCloudsTitle;

  /// Chapter 1 of pet story hamster_clouds.
  ///
  /// In en, this message translates to:
  /// **'Raise a ladder above the tall grass.'**
  String get storyHamsterCloudsChapter0;

  /// Chapter 2 of pet story hamster_clouds.
  ///
  /// In en, this message translates to:
  /// **'Aim the telescope between the clouds.'**
  String get storyHamsterCloudsChapter1;

  /// Chapter 3 of pet story hamster_clouds.
  ///
  /// In en, this message translates to:
  /// **'Name a new star after the courtyard.'**
  String get storyHamsterCloudsChapter2;

  /// Title of pet story hamster_garden.
  ///
  /// In en, this message translates to:
  /// **'Miniature Garden'**
  String get storyHamsterGardenTitle;

  /// Chapter 1 of pet story hamster_garden.
  ///
  /// In en, this message translates to:
  /// **'Plant a garden in a clay pot.'**
  String get storyHamsterGardenChapter0;

  /// Chapter 2 of pet story hamster_garden.
  ///
  /// In en, this message translates to:
  /// **'Place a bridge over a pebble stream.'**
  String get storyHamsterGardenChapter1;

  /// Chapter 3 of pet story hamster_garden.
  ///
  /// In en, this message translates to:
  /// **'Add a mushroom house for visitors.'**
  String get storyHamsterGardenChapter2;

  /// Title of pet story hamster_birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday Parade'**
  String get storyHamsterBirthdayTitle;

  /// Chapter 1 of pet story hamster_birthday.
  ///
  /// In en, this message translates to:
  /// **'Make the tiniest party hat.'**
  String get storyHamsterBirthdayChapter0;

  /// Chapter 2 of pet story hamster_birthday.
  ///
  /// In en, this message translates to:
  /// **'Bake a cake with three berries.'**
  String get storyHamsterBirthdayChapter1;

  /// Chapter 3 of pet story hamster_birthday.
  ///
  /// In en, this message translates to:
  /// **'Start the parade in a shower of confetti.'**
  String get storyHamsterBirthdayChapter2;

  /// Title of pet story fox_cozy.
  ///
  /// In en, this message translates to:
  /// **'A Cozy Corner'**
  String get storyFoxCozyTitle;

  /// Chapter 1 of pet story fox_cozy.
  ///
  /// In en, this message translates to:
  /// **'Clear the leaves from a quiet corner.'**
  String get storyFoxCozyChapter0;

  /// Chapter 2 of pet story fox_cozy.
  ///
  /// In en, this message translates to:
  /// **'Bring a soft bed for afternoon naps.'**
  String get storyFoxCozyChapter1;

  /// Chapter 3 of pet story fox_cozy.
  ///
  /// In en, this message translates to:
  /// **'Choose a favorite toy and make it home.'**
  String get storyFoxCozyChapter2;

  /// Title of pet story fox_fireflies.
  ///
  /// In en, this message translates to:
  /// **'Firefly Path'**
  String get storyFoxFirefliesTitle;

  /// Chapter 1 of pet story fox_fireflies.
  ///
  /// In en, this message translates to:
  /// **'Place a lantern at the forest edge.'**
  String get storyFoxFirefliesChapter0;

  /// Chapter 2 of pet story fox_fireflies.
  ///
  /// In en, this message translates to:
  /// **'Plant night flowers along the path.'**
  String get storyFoxFirefliesChapter1;

  /// Chapter 3 of pet story fox_fireflies.
  ///
  /// In en, this message translates to:
  /// **'Welcome a sparkling cloud of fireflies.'**
  String get storyFoxFirefliesChapter2;

  /// Title of pet story fox_post.
  ///
  /// In en, this message translates to:
  /// **'Forest Post'**
  String get storyFoxPostTitle;

  /// Chapter 1 of pet story fox_post.
  ///
  /// In en, this message translates to:
  /// **'Build a red mailbox beneath the oak.'**
  String get storyFoxPostChapter0;

  /// Chapter 2 of pet story fox_post.
  ///
  /// In en, this message translates to:
  /// **'Sort letters for every courtyard friend.'**
  String get storyFoxPostChapter1;

  /// Chapter 3 of pet story fox_post.
  ///
  /// In en, this message translates to:
  /// **'Carry the first delivery in a new satchel.'**
  String get storyFoxPostChapter2;

  /// Title of pet story fox_studio.
  ///
  /// In en, this message translates to:
  /// **'Autumn Studio'**
  String get storyFoxStudioTitle;

  /// Chapter 1 of pet story fox_studio.
  ///
  /// In en, this message translates to:
  /// **'Set an easel among the golden leaves.'**
  String get storyFoxStudioChapter0;

  /// Chapter 2 of pet story fox_studio.
  ///
  /// In en, this message translates to:
  /// **'Mix colors for an autumn portrait.'**
  String get storyFoxStudioChapter1;

  /// Chapter 3 of pet story fox_studio.
  ///
  /// In en, this message translates to:
  /// **'Frame the painting for the courtyard house.'**
  String get storyFoxStudioChapter2;

  /// Title of pet story fox_camp.
  ///
  /// In en, this message translates to:
  /// **'Starry Camp'**
  String get storyFoxCampTitle;

  /// Chapter 1 of pet story fox_camp.
  ///
  /// In en, this message translates to:
  /// **'Raise a tent beneath the pines.'**
  String get storyFoxCampChapter0;

  /// Chapter 2 of pet story fox_camp.
  ///
  /// In en, this message translates to:
  /// **'Light a warm and careful campfire.'**
  String get storyFoxCampChapter1;

  /// Chapter 3 of pet story fox_camp.
  ///
  /// In en, this message translates to:
  /// **'Stay awake to find a falling star.'**
  String get storyFoxCampChapter2;

  /// Collectible name for cushion.
  ///
  /// In en, this message translates to:
  /// **'Cushion'**
  String get petItemCushion;

  /// Collectible name for yarn.
  ///
  /// In en, this message translates to:
  /// **'Yarn'**
  String get petItemYarn;

  /// Collectible name for curtain.
  ///
  /// In en, this message translates to:
  /// **'Curtain'**
  String get petItemCurtain;

  /// Collectible name for lantern.
  ///
  /// In en, this message translates to:
  /// **'Lantern'**
  String get petItemLantern;

  /// Collectible name for bell.
  ///
  /// In en, this message translates to:
  /// **'Bell'**
  String get petItemBell;

  /// Collectible name for telescope.
  ///
  /// In en, this message translates to:
  /// **'Telescope'**
  String get petItemTelescope;

  /// Collectible name for seedling.
  ///
  /// In en, this message translates to:
  /// **'Seedling'**
  String get petItemSeedling;

  /// Collectible name for butterflies.
  ///
  /// In en, this message translates to:
  /// **'Butterflies'**
  String get petItemButterflies;

  /// Collectible name for fountain.
  ///
  /// In en, this message translates to:
  /// **'Fountain'**
  String get petItemFountain;

  /// Collectible name for books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get petItemBooks;

  /// Collectible name for blanket.
  ///
  /// In en, this message translates to:
  /// **'Blanket'**
  String get petItemBlanket;

  /// Collectible name for lamp.
  ///
  /// In en, this message translates to:
  /// **'Reading lamp'**
  String get petItemLamp;

  /// Collectible name for teacup.
  ///
  /// In en, this message translates to:
  /// **'Tea set'**
  String get petItemTeacup;

  /// Collectible name for flowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get petItemFlowers;

  /// Collectible name for banner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get petItemBanner;

  /// Collectible name for signpost.
  ///
  /// In en, this message translates to:
  /// **'Signpost'**
  String get petItemSignpost;

  /// Collectible name for bowl.
  ///
  /// In en, this message translates to:
  /// **'Water bowl'**
  String get petItemBowl;

  /// Collectible name for ball.
  ///
  /// In en, this message translates to:
  /// **'Ball'**
  String get petItemBall;

  /// Collectible name for rope.
  ///
  /// In en, this message translates to:
  /// **'Strong rope'**
  String get petItemRope;

  /// Collectible name for badge.
  ///
  /// In en, this message translates to:
  /// **'Patrol badge'**
  String get petItemBadge;

  /// Collectible name for basket.
  ///
  /// In en, this message translates to:
  /// **'Basket'**
  String get petItemBasket;

  /// Collectible name for treats.
  ///
  /// In en, this message translates to:
  /// **'Treats'**
  String get petItemTreats;

  /// Collectible name for kite.
  ///
  /// In en, this message translates to:
  /// **'Kite'**
  String get petItemKite;

  /// Collectible name for compass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get petItemCompass;

  /// Collectible name for ribbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get petItemRibbon;

  /// Collectible name for flags.
  ///
  /// In en, this message translates to:
  /// **'Festival flags'**
  String get petItemFlags;

  /// Collectible name for drum.
  ///
  /// In en, this message translates to:
  /// **'Drum'**
  String get petItemDrum;

  /// Collectible name for medal.
  ///
  /// In en, this message translates to:
  /// **'Medal'**
  String get petItemMedal;

  /// Collectible name for toolbox.
  ///
  /// In en, this message translates to:
  /// **'Toolbox'**
  String get petItemToolbox;

  /// Collectible name for gears.
  ///
  /// In en, this message translates to:
  /// **'Gears'**
  String get petItemGears;

  /// Collectible name for clock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get petItemClock;

  /// Collectible name for coins.
  ///
  /// In en, this message translates to:
  /// **'Shiny coins'**
  String get petItemCoins;

  /// Collectible name for map.
  ///
  /// In en, this message translates to:
  /// **'Treasure map'**
  String get petItemMap;

  /// Collectible name for boat.
  ///
  /// In en, this message translates to:
  /// **'Tiny boat'**
  String get petItemBoat;

  /// Collectible name for shell.
  ///
  /// In en, this message translates to:
  /// **'Singing shell'**
  String get petItemShell;

  /// Collectible name for crate.
  ///
  /// In en, this message translates to:
  /// **'Planter crate'**
  String get petItemCrate;

  /// Collectible name for wateringCan.
  ///
  /// In en, this message translates to:
  /// **'Watering can'**
  String get petItemWateringCan;

  /// Collectible name for windmill.
  ///
  /// In en, this message translates to:
  /// **'Windmill'**
  String get petItemWindmill;

  /// Collectible name for mug.
  ///
  /// In en, this message translates to:
  /// **'Café mug'**
  String get petItemMug;

  /// Collectible name for cookies.
  ///
  /// In en, this message translates to:
  /// **'Cookies'**
  String get petItemCookies;

  /// Collectible name for tracks.
  ///
  /// In en, this message translates to:
  /// **'Railway tracks'**
  String get petItemTracks;

  /// Collectible name for cart.
  ///
  /// In en, this message translates to:
  /// **'Tiny cart'**
  String get petItemCart;

  /// Collectible name for station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get petItemStation;

  /// Collectible name for seedBag.
  ///
  /// In en, this message translates to:
  /// **'Seed bag'**
  String get petItemSeedBag;

  /// Collectible name for shelf.
  ///
  /// In en, this message translates to:
  /// **'Shelves'**
  String get petItemShelf;

  /// Collectible name for jar.
  ///
  /// In en, this message translates to:
  /// **'Pantry jar'**
  String get petItemJar;

  /// Collectible name for ladder.
  ///
  /// In en, this message translates to:
  /// **'Ladder'**
  String get petItemLadder;

  /// Collectible name for star.
  ///
  /// In en, this message translates to:
  /// **'New star'**
  String get petItemStar;

  /// Collectible name for pot.
  ///
  /// In en, this message translates to:
  /// **'Garden pot'**
  String get petItemPot;

  /// Collectible name for bridge.
  ///
  /// In en, this message translates to:
  /// **'Tiny bridge'**
  String get petItemBridge;

  /// Collectible name for mushroom.
  ///
  /// In en, this message translates to:
  /// **'Mushroom house'**
  String get petItemMushroom;

  /// Collectible name for hat.
  ///
  /// In en, this message translates to:
  /// **'Party hat'**
  String get petItemHat;

  /// Collectible name for cake.
  ///
  /// In en, this message translates to:
  /// **'Berry cake'**
  String get petItemCake;

  /// Collectible name for confetti.
  ///
  /// In en, this message translates to:
  /// **'Confetti'**
  String get petItemConfetti;

  /// Collectible name for clearing.
  ///
  /// In en, this message translates to:
  /// **'Quiet clearing'**
  String get petItemClearing;

  /// Collectible name for bed.
  ///
  /// In en, this message translates to:
  /// **'Soft bed'**
  String get petItemBed;

  /// Collectible name for toy.
  ///
  /// In en, this message translates to:
  /// **'Favorite toy'**
  String get petItemToy;

  /// Collectible name for fireflies.
  ///
  /// In en, this message translates to:
  /// **'Fireflies'**
  String get petItemFireflies;

  /// Collectible name for mailbox.
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get petItemMailbox;

  /// Collectible name for letters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get petItemLetters;

  /// Collectible name for satchel.
  ///
  /// In en, this message translates to:
  /// **'Mail satchel'**
  String get petItemSatchel;

  /// Collectible name for easel.
  ///
  /// In en, this message translates to:
  /// **'Easel'**
  String get petItemEasel;

  /// Collectible name for paints.
  ///
  /// In en, this message translates to:
  /// **'Paints'**
  String get petItemPaints;

  /// Collectible name for frame.
  ///
  /// In en, this message translates to:
  /// **'Picture frame'**
  String get petItemFrame;

  /// Collectible name for tent.
  ///
  /// In en, this message translates to:
  /// **'Tent'**
  String get petItemTent;

  /// Collectible name for campfire.
  ///
  /// In en, this message translates to:
  /// **'Campfire'**
  String get petItemCampfire;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
