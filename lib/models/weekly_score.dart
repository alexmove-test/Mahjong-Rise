/// Очки активности текущей ISO-недели. Формула совпадает с `firestore.rules`.
abstract final class WeeklyScore {
  WeeklyScore._();

  static const starWeight = 10000;
  static const clearWeight = 2500;
  static const dailyWeight = 1000;

  static const maxStars = 200;
  static const maxClears = 80;
  static const maxDailies = 7;

  static const maxRating =
      maxStars * starWeight + maxClears * clearWeight + maxDailies * dailyWeight;

  static int ratingFrom({
    required int weeklyStars,
    required int weeklyClears,
    required int weeklyDailies,
  }) {
    return weeklyStars * starWeight +
        weeklyClears * clearWeight +
        weeklyDailies * dailyWeight;
  }
}

/// Итог прошлой недели для шита «сезон закрыт».
class WeekSeasonSummary {
  const WeekSeasonSummary({
    required this.weekId,
    required this.rating,
    required this.stars,
    required this.clears,
    required this.dailies,
    this.rank,
  });

  final String weekId;
  final int rating;
  final int stars;
  final int clears;
  final int dailies;
  final int? rank;
}
