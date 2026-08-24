/// ISO 8601 week id, e.g. `2026-W35`. Weeks start Monday.
class WeekId {
  const WeekId(this.value);

  final String value;

  factory WeekId.fromDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final isoYear = thursday.year;
    final jan4 = DateTime(isoYear, 1, 4);
    final week1Monday = jan4.subtract(
      Duration(days: jan4.weekday - DateTime.monday),
    );
    final week = 1 + thursday.difference(week1Monday).inDays ~/ 7;
    return WeekId('$isoYear-W${week.toString().padLeft(2, '0')}');
  }

  /// Stable seed for quest/event rotation.
  int get seed {
    final parts = value.split('-W');
    return int.parse(parts[0]) * 100 + int.parse(parts[1]);
  }

  /// Monday 00:00 of this ISO week.
  DateTime get monday {
    final parts = value.split('-W');
    final isoYear = int.parse(parts[0]);
    final week = int.parse(parts[1]);
    final jan4 = DateTime(isoYear, 1, 4);
    final week1Monday = jan4.subtract(
      Duration(days: jan4.weekday - DateTime.monday),
    );
    return week1Monday.add(Duration(days: (week - 1) * 7));
  }

  /// Next Monday 00:00.
  DateTime get nextMonday => monday.add(const Duration(days: 7));

  static bool isValid(String raw) {
    return RegExp(r'^\d{4}-W\d{2}$').hasMatch(raw);
  }

  @override
  bool operator ==(Object other) => other is WeekId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
