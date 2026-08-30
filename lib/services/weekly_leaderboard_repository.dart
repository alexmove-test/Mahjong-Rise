import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry.dart';
import '../models/week_id.dart';
import '../models/weekly_score.dart';
import 'firebase_bootstrap.dart';
import 'guest_name.dart';
import 'leaderboard_service.dart';
import 'player_profile_store.dart';
import 'progress_store.dart';
import 'weekly_leaderboard_service.dart';

/// Недельная таблица: `weekly/{weekId}/players/{uid}`.
class WeeklyLeaderboardRepository {
  WeeklyLeaderboardRepository._();

  static const collection = 'weekly';
  static const players = 'players';
  static const fetchLimit = 50;

  static FirebaseFirestore? get _db =>
      FirebaseBootstrap.enabled ? FirebaseFirestore.instance : null;

  static CollectionReference<Map<String, dynamic>>? _players(String weekId) {
    final db = _db;
    if (db == null) return null;
    return db.collection(collection).doc(weekId).collection(players);
  }

  static Future<void> syncProgress({
    required ProgressStore progress,
    required PlayerProfileStore profile,
    DateTime? now,
  }) async {
    if (!FirebaseBootstrap.enabled) return;
    await progress.ensureWeek(now);

    try {
      final user = await FirebaseBootstrap.ensureSignedIn();
      if (user == null) return;

      final weekId = progress.weekId;
      if (!WeekId.isValid(weekId)) return;

      final name = GuestName.clamp(profile.displayName);
      final rating = WeeklyLeaderboardService.ratingFor(progress);
      final nameChanged = name != profile.lastSyncedName;
      if (profile.lastSyncedWeekId == weekId &&
          rating <= profile.lastSyncedWeeklyRating &&
          !nameChanged) {
        return;
      }

      final doc = _players(weekId)!.doc(user.uid);
      Map<String, dynamic>? data;
      try {
        data = (await doc.get()).data();
      } catch (error) {
        debugPrint('Weekly leaderboard pre-read failed: $error');
      }
      final existingRating = _asInt(data?['rating']);

      if (data != null && rating < existingRating) {
        if (!nameChanged) return;
        final stars = _asInt(data['weeklyStars']).clamp(0, WeeklyScore.maxStars);
        final clears = _asInt(data['weeklyClears']).clamp(0, WeeklyScore.maxClears);
        final dailies = _asInt(data['weeklyDailies']).clamp(0, WeeklyScore.maxDailies);
        final keepRating = WeeklyScore.ratingFrom(
          weeklyStars: stars,
          weeklyClears: clears,
          weeklyDailies: dailies,
        );
        await doc.set(
          _payload(
            name: name,
            weeklyStars: stars,
            weeklyClears: clears,
            weeklyDailies: dailies,
          ),
        );
        await profile.markWeeklySynced(
          weekId: weekId,
          rating: keepRating,
          name: name,
        );
        return;
      }

      await doc.set(
        _payload(
          name: name,
          weeklyStars: progress.weeklyStars,
          weeklyClears: progress.weeklyClears,
          weeklyDailies: progress.weeklyDailies,
        ),
      );

      await profile.markWeeklySynced(
        weekId: weekId,
        rating: rating,
        name: name,
      );
    } catch (error) {
      debugPrint('Weekly leaderboard sync failed: $error');
    }
  }

  static Future<LeaderboardFetch> fetchTop({
    required ProgressStore progress,
    required PlayerProfileStore profile,
    DateTime? now,
  }) async {
    await progress.ensureWeek(now);
    List<LeaderboardEntry> local() => WeeklyLeaderboardService.buildLocal(
      progress: progress,
      profile: profile,
    );

    if (!FirebaseBootstrap.enabled) {
      return LeaderboardFetch(entries: local(), online: false);
    }

    return LeaderboardFetch.guard(
      fallback: local,
      load: () async {
        final user = await FirebaseBootstrap.ensureSignedIn();
        if (user == null) {
          throw StateError('Anonymous sign-in returned no user');
        }

        await syncProgress(progress: progress, profile: profile, now: now);

        final snapshot = await _fetchRanked(progress.weekId);
        final entries = snapshot.docs
            .map((doc) => _entryFromDoc(doc, currentUid: user.uid))
            .toList();
        _sortByRating(entries);

        if (!entries.any((e) => e.isCurrentPlayer)) {
          entries.add(
            LeaderboardEntry(
              id: user.uid,
              name: GuestName.clamp(profile.displayName),
              rating: WeeklyLeaderboardService.ratingFor(progress),
              totalStars: progress.weeklyStars,
              levelsUnlocked: progress.weeklyClears,
              weeklyDailies: progress.weeklyDailies,
              isCurrentPlayer: true,
            ),
          );
          _sortByRating(entries);
        }

        final rank = entries.indexWhere((e) => e.isCurrentPlayer);
        if (rank >= 0) {
          await progress.setWeeklyLastRank(rank + 1);
        }

        return entries;
      },
    );
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> _fetchRanked(
    String weekId,
  ) async {
    final col = _players(weekId)!;
    try {
      return await col
          .orderBy('rating', descending: true)
          .limit(fetchLimit)
          .get();
    } catch (error) {
      // Нет индекса или SDK вернул не FirebaseException — читаем без
      // orderBy и сортируем на клиенте. permission-denied здесь тоже
      // упадёт и уйдёт в LeaderboardFetch.guard.
      debugPrint('Weekly leaderboard ordered query failed: $error');
      return col.limit(fetchLimit).get();
    }
  }

  static void _sortByRating(List<LeaderboardEntry> entries) {
    entries.sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) return byRating;
      return a.name.compareTo(b.name);
    });
  }

  static LeaderboardEntry _entryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUid,
  }) {
    final data = doc.data();
    return LeaderboardEntry(
      id: doc.id,
      name: GuestName.clamp(
        (data['name'] as String?)?.trim().isNotEmpty == true
            ? data['name'] as String
            : 'Player',
      ),
      rating: _asInt(data['rating']),
      totalStars: _asInt(data['weeklyStars']),
      levelsUnlocked: _asInt(data['weeklyClears']),
      weeklyDailies: _asInt(data['weeklyDailies']),
      isCurrentPlayer: doc.id == currentUid,
    );
  }

  static Map<String, dynamic> _payload({
    required String name,
    required int weeklyStars,
    required int weeklyClears,
    required int weeklyDailies,
  }) {
    final stars = weeklyStars.clamp(0, WeeklyScore.maxStars);
    final clears = weeklyClears.clamp(0, WeeklyScore.maxClears);
    final dailies = weeklyDailies.clamp(0, WeeklyScore.maxDailies);
    return {
      'name': GuestName.clamp(name),
      'rating': WeeklyScore.ratingFrom(
        weeklyStars: stars,
        weeklyClears: clears,
        weeklyDailies: dailies,
      ),
      'weeklyStars': stars,
      'weeklyClears': clears,
      'weeklyDailies': dailies,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
