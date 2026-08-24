import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';
import '../models/week_id.dart';
import 'firebase_bootstrap.dart';
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

    final user = await FirebaseBootstrap.ensureSignedIn();
    if (user == null) return;

    final weekId = progress.weekId;
    if (!WeekId.isValid(weekId)) return;

    final rating = WeeklyLeaderboardService.ratingFor(progress);
    final nameChanged = profile.displayName != profile.lastSyncedName;
    if (profile.lastSyncedWeekId == weekId &&
        rating <= profile.lastSyncedWeeklyRating &&
        !nameChanged) {
      return;
    }

    try {
      final doc = _players(weekId)!.doc(user.uid);
      final existing = await doc.get();
      final existingRating = _asInt(existing.data()?['rating']);

      if (rating < existingRating) {
        if (!nameChanged) return;
        await doc.set({
          'name': profile.displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await profile.markWeeklySynced(
          weekId: weekId,
          rating: existingRating,
          name: profile.displayName,
        );
        return;
      }

      await doc.set({
        'name': profile.displayName,
        'rating': rating,
        'weeklyStars': progress.weeklyStars,
        'weeklyClears': progress.weeklyClears,
        'weeklyDailies': progress.weeklyDailies,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await profile.markWeeklySynced(
        weekId: weekId,
        rating: rating,
        name: profile.displayName,
      );
    } catch (_) {}
  }

  static Future<List<LeaderboardEntry>> fetchTop({
    required ProgressStore progress,
    required PlayerProfileStore profile,
    DateTime? now,
  }) async {
    await progress.ensureWeek(now);
    if (!FirebaseBootstrap.enabled) {
      return WeeklyLeaderboardService.buildLocal(
        progress: progress,
        profile: profile,
      );
    }

    final user = await FirebaseBootstrap.ensureSignedIn();
    if (user == null) {
      return WeeklyLeaderboardService.buildLocal(
        progress: progress,
        profile: profile,
      );
    }

    await syncProgress(progress: progress, profile: profile, now: now);

    final snapshot = await _players(progress.weekId)!
        .orderBy('rating', descending: true)
        .limit(fetchLimit)
        .get();

    final entries = snapshot.docs
        .map((doc) => _entryFromDoc(doc, currentUid: user.uid))
        .toList();

    if (!entries.any((e) => e.isCurrentPlayer)) {
      entries.add(
        LeaderboardEntry(
          id: user.uid,
          name: profile.displayName,
          rating: WeeklyLeaderboardService.ratingFor(progress),
          totalStars: progress.weeklyStars,
          levelsUnlocked: progress.weeklyClears,
          weeklyDailies: progress.weeklyDailies,
          isCurrentPlayer: true,
        ),
      );
      entries.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        return a.name.compareTo(b.name);
      });
    }

    final rank = entries.indexWhere((e) => e.isCurrentPlayer);
    if (rank >= 0) {
      await progress.setWeeklyLastRank(rank + 1);
    }

    return entries;
  }

  static LeaderboardEntry _entryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUid,
  }) {
    final data = doc.data();
    return LeaderboardEntry(
      id: doc.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Player',
      rating: _asInt(data['rating']),
      totalStars: _asInt(data['weeklyStars']),
      levelsUnlocked: _asInt(data['weeklyClears']),
      weeklyDailies: _asInt(data['weeklyDailies']),
      isCurrentPlayer: doc.id == currentUid,
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
