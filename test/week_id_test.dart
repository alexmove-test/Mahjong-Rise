import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/week_event.dart';
import 'package:mahjong/models/week_id.dart';
import 'package:mahjong/models/weekly_quests.dart';
import 'package:mahjong/models/weekly_score.dart';

void main() {
  test('ISO week id uses Monday weeks and the Thursday year', () {
    expect(WeekId.fromDate(DateTime(2026, 1, 1)).value, '2026-W01');
    expect(WeekId.fromDate(DateTime(2025, 12, 29)).value, '2026-W01');
    expect(WeekId.fromDate(DateTime(2026, 8, 24)).value, '2026-W35');
    expect(WeekId.isValid('2026-W35'), isTrue);
    expect(WeekId.isValid('2026-W5'), isFalse);
  });

  test('week seed is stable for quest and event rotation', () {
    final week = WeekId.fromDate(DateTime(2026, 8, 24));
    expect(week.seed, 202635);
    expect(WeeklyQuests.forWeek(week), WeeklyQuests.forWeek(week));
    expect(WeeklyQuests.forWeek(week), hasLength(3));
    expect(WeeklyQuests.forWeek(week).map((q) => q.id).toSet(), hasLength(3));
    expect(WeekEvent.forWeek(week).id, WeekEvent.forWeek(week).id);
  });

  test('adjacent weeks pick a different quest set or order', () {
    final a = WeeklyQuests.forWeek(WeekId.fromDate(DateTime(2026, 8, 24)));
    final b = WeeklyQuests.forWeek(WeekId.fromDate(DateTime(2026, 8, 31)));
    expect(a.map((q) => q.id).join(','), isNot(b.map((q) => q.id).join(',')));
  });

  test('weekly rating matches firestore formula and caps', () {
    expect(
      WeeklyScore.ratingFrom(
        weeklyStars: 8,
        weeklyClears: 4,
        weeklyDailies: 3,
      ),
      8 * 10000 + 4 * 2500 + 3 * 1000,
    );
    expect(WeeklyScore.maxRating, 2207000);
    expect(
      WeeklyScore.ratingFrom(
        weeklyStars: WeeklyScore.maxStars,
        weeklyClears: WeeklyScore.maxClears,
        weeklyDailies: WeeklyScore.maxDailies,
      ),
      WeeklyScore.maxRating,
    );
  });
}
