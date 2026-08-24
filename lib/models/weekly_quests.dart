import 'dart:math';

import 'week_id.dart';

enum QuestKind { dailyWins, stars, campaignClears, threeStar, streakHold }

/// One weekly mission. Ids are stable for prefs and l10n.
class QuestDef {
  const QuestDef({
    required this.id,
    required this.kind,
    required this.target,
  });

  final String id;
  final QuestKind kind;
  final int target;

  static const pool = <QuestDef>[
    QuestDef(id: 'daily3', kind: QuestKind.dailyWins, target: 3),
    QuestDef(id: 'stars8', kind: QuestKind.stars, target: 8),
    QuestDef(id: 'clears4', kind: QuestKind.campaignClears, target: 4),
    QuestDef(id: 'threeStar1', kind: QuestKind.threeStar, target: 1),
    QuestDef(id: 'streak3', kind: QuestKind.streakHold, target: 3),
  ];

  static QuestDef? byId(String id) {
    for (final quest in pool) {
      if (quest.id == id) return quest;
    }
    return null;
  }
}

/// Three quests for a week, shuffled from the pool with a stable seed.
abstract final class WeeklyQuests {
  WeeklyQuests._();

  static const perWeek = 3;

  static List<QuestDef> forWeek(WeekId week) {
    final pool = List<QuestDef>.from(QuestDef.pool);
    pool.shuffle(Random(week.seed));
    return pool.take(perWeek).toList(growable: false);
  }
}

class QuestProgress {
  const QuestProgress({
    required this.def,
    required this.current,
    required this.claimed,
  });

  final QuestDef def;
  final int current;
  final bool claimed;

  int get target => def.target;

  bool get complete => current >= target;

  bool get canClaim => complete && !claimed;
}
