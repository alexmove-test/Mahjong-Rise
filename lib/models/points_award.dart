/// Из чего сложились баллы за одну победу.
class PointsAward {
  const PointsAward({
    this.clear = 0,
    this.stars = 0,
    this.firstClear = 0,
    this.newBest = 0,
    this.streak = 0,
  });

  const PointsAward.none() : this();

  /// Базовое начисление за закрытый стол кампании.
  static const perClear = 25;

  /// За каждую звезду уровня.
  static const perStar = 15;

  /// Разовый бонус за первое прохождение уровня.
  static const perFirstClear = 50;

  /// Бонус за новый рекорд счёта на уровне.
  static const perNewBest = 20;

  /// Базовое начисление за ежедневный стол.
  static const perDaily = 40;

  /// За каждый день серии ежедневок.
  static const perStreakDay = 5;

  /// Серия перестаёт растить награду после недели.
  static const maxStreakDays = 7;

  final int clear;
  final int stars;
  final int firstClear;
  final int newBest;
  final int streak;

  int get total => clear + stars + firstClear + newBest + streak;

  bool get isEmpty => total == 0;

  factory PointsAward.campaignWin({
    required int stars,
    required bool firstClear,
    required bool isNewBest,
  }) {
    return PointsAward(
      clear: perClear,
      stars: stars.clamp(0, 3) * perStar,
      firstClear: firstClear ? perFirstClear : 0,
      newBest: isNewBest ? perNewBest : 0,
    );
  }

  /// Повтор ежедневки в тот же день ([counted] == false) баллов не приносит.
  factory PointsAward.dailyWin({required int streak, bool counted = true}) {
    if (!counted) return const PointsAward.none();
    return PointsAward(
      clear: perDaily,
      streak: streak.clamp(0, maxStreakDays) * perStreakDay,
    );
  }
}
