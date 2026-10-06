import 'leaderboard_entry.dart';

/// Подъём в таблице после победы: кого обогнали и куда пришли.
class RankClimb {
  const RankClimb({
    required this.rankFrom,
    required this.rankTo,
    required this.ratingFrom,
    required this.ratingTo,
    required this.player,
    this.passed = const [],
    this.stillAbove = const [],
    this.below = const [],
  });

  /// Реальное место до победы (1 — вершина).
  final int rankFrom;

  /// Реальное место после победы.
  final int rankTo;

  final int ratingFrom;
  final int ratingTo;
  final LeaderboardEntry player;

  /// Кого обгоняем в анимации, сверху вниз: сначала ближайшие к новому месту.
  final List<LeaderboardEntry> passed;

  /// Кто остался выше после подъёма — для контекста списка.
  final List<LeaderboardEntry> stillAbove;

  /// Кто уже был ниже — нижний край окна.
  final List<LeaderboardEntry> below;

  bool get rose => rankTo > 0 && rankTo < rankFrom;

  /// Место игрока в окне анимации до первого обгона.
  int get displayRankFrom => rankTo + passed.length;
}
