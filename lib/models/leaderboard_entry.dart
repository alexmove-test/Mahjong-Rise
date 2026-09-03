/// Строка общего рейтинга.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalStars,
    required this.levelsUnlocked,
    required this.isCurrentPlayer,
  });

  final String id;
  final String name;
  final int rating;
  final int totalStars;
  final int levelsUnlocked;
  final bool isCurrentPlayer;
}
