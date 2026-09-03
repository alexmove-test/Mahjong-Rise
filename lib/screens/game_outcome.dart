import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/levels.dart';
import '../services/analytics_service.dart';
import '../services/firebase_leaderboard_repository.dart';
import '../services/local_reminder_service.dart';
import '../services/pet_store.dart';
import '../services/player_profile_store.dart';
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
    final estateFrom = CourtyardEstate.fromStore(
      progress,
      streak: progress.visibleStreak(),
    );
    final result = await progress.recordWin(level: level, score: score);
    final reveal = CourtyardWinReveal(
      estateFrom: estateFrom,
      estateTo: CourtyardEstate.fromStore(
        progress,
        streak: progress.visibleStreak(),
      ),
      cycle: cycle,
      focusKind: progress.plotKindForLevel(level.id),
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
    VoidCallback? onProgressChanged,
  }) async {
    final cycle = Levels.cycleOf(progress.lastPlayedLevel);
    final estateFrom = CourtyardEstate.fromStore(
      progress,
      streak: progress.visibleStreak(),
    );
    final result = await progress.recordDailyWin();
    final reveal = CourtyardWinReveal(
      estateFrom: estateFrom,
      estateTo: CourtyardEstate.fromStore(
        progress,
        streak: progress.visibleStreak(),
      ),
      cycle: cycle,
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

  static Future<void> _afterWin({
    required BuildContext context,
    required ProgressStore progress,
    required Future<void> Function(QuestStore quests) credit,
    VoidCallback? onProgressChanged,
  }) async {
    final quests = await QuestStore.open();
    await credit(quests);
    final pets = await PetStore.open();
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
    await LocalReminderService.resync(l10n: L10n.of(context));
  }
}
