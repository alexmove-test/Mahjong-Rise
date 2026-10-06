import '../models/house_upgrade.dart';
import '../models/hub_goal.dart';
import '../models/levels.dart';
import '../models/plot_kind.dart';
import '../models/weekly_quests.dart';
import 'progress_store.dart';

/// Выбор одной очевидной цели из двора, квестов и питомцев.
abstract final class HubGoals {
  HubGoals._();

  static HubGoal? pick({
    required ProgressStore progress,
    List<QuestProgress> quests = const [],
    bool hasPet = true,
    DateTime? now,
    int houseState = HouseUpgrade.firstState,
    int pointsBalance = 0,
  }) {
    HubGoal? best;

    void consider(HubGoal? next) {
      if (next == null) return;
      if (best == null || next.nearerThan(best!)) best = next;
    }

    consider(_plotUnlock(progress, hasPet));
    consider(_houseUpgrade(houseState, pointsBalance));
    for (final quest in quests) {
      consider(_quest(quest));
    }
    return best;
  }

  /// Старые четыре лота на хабе не обещаем: пруд и гостевой дом — не отдельные
  /// дворы. Питомец по-прежнему открывается на своём круге кампании.
  static HubGoal? _plotUnlock(ProgressStore progress, bool hasPet) {
    if (hasPet) return null;
    if (progress.plotReached(PlotKind.pets)) return null;
    if (Levels.nextLockedPlot(progress.maxUnlocked) != PlotKind.pets) {
      return null;
    }
    final start = Levels.plotStartId(PlotKind.pets);
    final remaining = (start - progress.maxUnlocked).clamp(
      1,
      Levels.maxLevelId,
    );
    return HubGoal(
      kind: HubGoalKind.petUnlock,
      remaining: remaining,
      plot: PlotKind.pets,
      levelId: start,
    );
  }

  /// Цель дома — цена следующего облика или нехватка поинтов, не число уровней.
  /// Максимальный дом не переключает баннер на покупку пруда.
  static HubGoal? _houseUpgrade(int houseState, int pointsBalance) {
    final state = HouseUpgrade.clampState(houseState);
    if (!HouseUpgrade.canAdvance(state)) return null;
    final price = HouseUpgrade.priceAfter(state);
    final shortfall = (price - pointsBalance).clamp(0, price);
    return HubGoal(
      kind: HubGoalKind.plotLook,
      remaining: shortfall,
      plot: PlotKind.house,
      pointsCost: price,
      pointsShort: shortfall,
    );
  }

  static HubGoal? _quest(QuestProgress quest) {
    if (quest.claimed) return null;
    if (quest.def.kind == QuestKind.dailyWins ||
        quest.def.kind == QuestKind.streakHold) {
      return null;
    }
    if (quest.canClaim) {
      return HubGoal(kind: HubGoalKind.questClaim, remaining: 0, quest: quest);
    }
    final left = (quest.target - quest.current).clamp(0, quest.target);
    if (left <= 0) return null;
    return HubGoal(
      kind: HubGoalKind.questRemain,
      remaining: left,
      quest: quest,
    );
  }
}
