import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/house_upgrade.dart';
import '../models/levels.dart';
import '../models/points_award.dart';
import '../models/rank_climb.dart';
import '../services/analytics_service.dart';
import '../services/courtyard_reward_store.dart';
import '../services/firebase_leaderboard_repository.dart';
import '../services/leaderboard_service.dart';
import '../services/local_reminder_service.dart';
import '../services/pet_store.dart';
import '../services/player_profile_store.dart';
import '../services/points_controller.dart';
import '../services/progress_store.dart';
import '../services/quest_store.dart';
import '../widgets/courtyard/courtyard_estate.dart';
import '../widgets/courtyard/courtyard_win_overlay.dart';
import '../widgets/tray_full_dialog.dart';

/// Победа, дейли и проигрыш — без оркестрации полётов.
abstract final class GameOutcome {
  static Future<CourtyardWinReveal> showCampaignWin({
    required BuildContext context,
    required LevelDef level,
    required ProgressStore progress,
    required int score,
    VoidCallback? onProgressChanged,
  }) async {
    final cycle = Levels.cycleOf(level.id);
    final ratingFrom = LeaderboardService.ratingFor(progress);
    final before = CourtyardEstate.fromStore(
      progress,
      streak: progress.visibleStreak(),
    );
    final home = _frozenHome(context, before);
    final estateFrom = CourtyardEstate.fromStore(
      progress,
      streak: progress.visibleStreak(),
      purchasedHome: home,
    );
    final result = await progress.recordWin(level: level, score: score);
    if (result.firstClear) {
      final rewards = await CourtyardRewardStore.open();
      await rewards.recordFirstClear(level.id);
    }
    final ratingTo = LeaderboardService.ratingFor(progress);
    final award = PointsAward.campaignWin(
      stars: result.earnedStars,
      firstClear: result.firstClear,
      isNewBest: result.isNewBest,
    );
    final upgradeNote = context.mounted ? _upgradeNote(context, award) : null;
    if (context.mounted) PointsScope.credit(context, award);
    final reveal = CourtyardWinReveal(
      estateFrom: estateFrom,
      estateTo: CourtyardEstate.fromStore(
        progress,
        streak: progress.visibleStreak(),
        purchasedHome: home,
      ),
      houseUpgradeNote: upgradeNote,
      cycle: cycle,
      focusKind: progress.plotKindForLevel(level.id),
      score: score,
      stars: result.earnedStars,
      isNewBest: result.isNewBest,
      pointsAward: award,
      climb: ratingTo > ratingFrom
          ? loadRankClimb(
              progress: progress,
              ratingFrom: ratingFrom,
              ratingTo: ratingTo,
            )
          : null,
    );
    unawaited(
      _afterWin(
        context: context,
        progress: progress,
        onProgressChanged: onProgressChanged,
        credit: (quests) => quests.creditCampaignWin(
          starsGained: result.starsGained,
          firstClear: result.firstClear,
          threeStar: result.earnedStars >= 3,
        ),
      ),
    );
    return reveal;
  }

  static Future<CourtyardWinReveal> showDailyWin({
    required BuildContext context,
    required ProgressStore progress,
    required int score,
    int stars = 0,
    VoidCallback? onProgressChanged,
  }) async {
    final cycle = Levels.cycleOf(progress.lastPlayedLevel);
    final before = CourtyardEstate.fromStore(
      progress,
      streak: progress.visibleStreak(),
    );
    final home = _frozenHome(context, before);
    final estateFrom = CourtyardEstate.fromStore(
      progress,
      streak: progress.visibleStreak(),
      purchasedHome: home,
    );
    final result = await progress.recordDailyWin();
    final award = PointsAward.dailyWin(
      streak: result.streak,
      counted: result.counted,
    );
    final upgradeNote = context.mounted ? _upgradeNote(context, award) : null;
    if (context.mounted) PointsScope.credit(context, award);
    final reveal = CourtyardWinReveal(
      estateFrom: estateFrom,
      estateTo: CourtyardEstate.fromStore(
        progress,
        streak: progress.visibleStreak(),
        purchasedHome: home,
      ),
      houseUpgradeNote: upgradeNote,
      cycle: cycle,
      score: score,
      stars: stars,
      pointsAward: award,
    );
    unawaited(
      _afterWin(
        context: context,
        progress: progress,
        onProgressChanged: onProgressChanged,
        credit: (quests) async {
          if (!result.counted) return;
          await quests.creditDailyWin(streak: result.streak);
          await AnalyticsService.log('daily_win', {'streak': result.streak});
        },
      ),
    );
    return reveal;
  }

  static int _frozenHome(BuildContext context, CourtyardEstate before) {
    final points = PointsScope.read(context);
    return CourtyardEstate.frozenHome(
      before: before,
      houseMigrated: points?.houseMigrated ?? false,
      purchasedState: points?.houseState ?? HouseUpgrade.firstState,
    );
  }

  /// Стоимость следующего облика с учётом баллов, которые победа ещё принесёт.
  static String? _upgradeNote(BuildContext context, PointsAward award) {
    final points = PointsScope.read(context);
    if (points == null || !HouseUpgrade.canAdvance(points.houseState)) {
      return null;
    }
    final cost = HouseUpgrade.priceAfter(points.houseState);
    final projected = points.balance + award.total;
    final shortfall = (cost - projected).clamp(0, cost);
    return AppLocalizations.of(
      context,
    ).houseUpgradeStatus(cost: cost, shortfall: shortfall);
  }

  static Future<void> _afterWin({
    required BuildContext context,
    required ProgressStore progress,
    required Future<void> Function(QuestStore quests) credit,
    VoidCallback? onProgressChanged,
  }) async {
    final quests = await QuestStore.open();
    await credit(quests);
    final pets = await PetStore.open();
    // Сытость больше не приходит с победы: её восстанавливает растение со склада.
    await pets.satisfyMostUrgent();
    onProgressChanged?.call();
    if (!context.mounted) return;
    unawaited(syncLeaderboard(context: context, progress: progress));
  }

  static Future<void> showLose({
    required BuildContext context,
    required String levelTitle,
    required int score,
    required bool canContinue,
    required void Function(BuildContext dialogContext) onContinue,
    required VoidCallback onRetry,
    required VoidCallback onMap,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return TrayFullDialog(
          levelTitle: levelTitle,
          score: score,
          canContinue: canContinue,
          onContinue: () => onContinue(dialogContext),
          onRetry: onRetry,
          onMap: onMap,
        );
      },
    );
  }

  static Future<void> syncLeaderboard({
    required BuildContext context,
    required ProgressStore progress,
  }) async {
    final profile = await PlayerProfileStore.open();
    await FirebaseLeaderboardRepository.syncProgress(
      progress: progress,
      profile: profile,
    );
    if (!context.mounted) return;
    await LocalReminderService.resync(l10n: AppLocalizations.of(context));
  }

  /// Таблица после синка: кого обогнали новым рейтингом.
  static Future<RankClimb?> loadRankClimb({
    required ProgressStore progress,
    required int ratingFrom,
    required int ratingTo,
  }) async {
    if (ratingTo <= ratingFrom) return null;
    final profile = await PlayerProfileStore.open();
    final fetch = await FirebaseLeaderboardRepository.fetchTop(
      progress: progress,
      profile: profile,
    );
    if (!fetch.online && fetch.entries.length <= 1) return null;
    return LeaderboardService.climb(
      entries: fetch.entries,
      ratingFrom: ratingFrom,
      ratingTo: ratingTo,
    );
  }
}
