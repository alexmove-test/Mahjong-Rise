import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/week_event.dart';
import 'package:mahjong/models/week_id.dart';
import 'package:mahjong/models/weekly_score.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('weekly score is only this week’s activity', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = await ProgressStore.open();
    await progress.recordWin(
      level: Levels.byId(1),
      score: 1200,
      now: DateTime(2026, 8, 24),
    );
    await progress.recordDailyWin(now: DateTime(2026, 8, 24));

    expect(progress.weekId, '2026-W35');
    expect(progress.weeklyStars, 3);
    expect(progress.weeklyClears, 1);
    expect(progress.weeklyDailies, 1);
    expect(
      WeeklyScore.ratingFrom(
        weeklyStars: progress.weeklyStars,
        weeklyClears: progress.weeklyClears,
        weeklyDailies: progress.weeklyDailies,
      ),
      3 * 10000 + 1 * 2500 + 1 * 1000,
    );

    await progress.ensureWeek(DateTime(2026, 8, 31));
    expect(progress.weekId, '2026-W36');
    expect(progress.weeklyStars, 0);
    expect(progress.weeklyClears, 0);
    expect(progress.weeklyDailies, 0);
    final summary = progress.pendingSeasonSummary;
    expect(summary, isNotNull);
    expect(summary!.weekId, '2026-W35');
    expect(summary.stars, 3);
    expect(summary.clears, 1);
    expect(summary.dailies, 1);
    final consumed = await progress.consumeSeasonSheet();
    expect(consumed?.weekId, '2026-W35');
    expect(progress.pendingSeasonSummary, isNull);
  });

  test('daily table uses the week event style and extra boosts', () {
    final date = DateTime(2026, 8, 24);
    final event = WeekEvent.forWeek(WeekId.fromDate(date));
    final daily = Levels.dailyFor(date);
    final baseIndex =
        date.difference(DateTime(2024, 1, 1)).inDays.abs() % Levels.storyLength;
    final base = Levels.byId(baseIndex + 1);
    expect(daily.style, event.style);
    expect(daily.shuffles, base.shuffles + event.extraBoosts);
    expect(daily.hints, base.hints + event.extraBoosts);
    expect(daily.title, 'Today');
  });
}
