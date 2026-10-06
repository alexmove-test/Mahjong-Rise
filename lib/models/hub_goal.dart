import 'plot_kind.dart';
import 'weekly_quests.dart';

/// Один ближайший шаг мета-игры на главном экране.
enum HubGoalKind {
  questClaim,
  dailyReward,
  questRemain,
  plotUnlock,
  petUnlock,
  plotLook,
}

class HubGoal {
  const HubGoal({
    required this.kind,
    required this.remaining,
    this.plot,
    this.levelId,
    this.quest,
    this.pointsCost,
    this.pointsShort,
  });

  final HubGoalKind kind;
  final int remaining;
  final PlotKind? plot;
  final int? levelId;
  final QuestProgress? quest;

  /// Цена следующего облика дома и сколько поинтов не хватает.
  final int? pointsCost;
  final int? pointsShort;

  int get _priority => switch (kind) {
    HubGoalKind.questClaim => 0,
    HubGoalKind.dailyReward => 1,
    HubGoalKind.questRemain => 2,
    HubGoalKind.plotUnlock => 3,
    HubGoalKind.petUnlock => 4,
    HubGoalKind.plotLook => 5,
  };

  bool nearerThan(HubGoal other) {
    if (remaining != other.remaining) return remaining < other.remaining;
    return _priority < other._priority;
  }

  @override
  bool operator ==(Object other) {
    return other is HubGoal &&
        other.kind == kind &&
        other.remaining == remaining &&
        other.plot == plot &&
        other.levelId == levelId &&
        other.quest?.def.id == quest?.def.id &&
        other.pointsCost == pointsCost &&
        other.pointsShort == pointsShort;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    remaining,
    plot,
    levelId,
    quest?.def.id,
    pointsCost,
    pointsShort,
  );
}
