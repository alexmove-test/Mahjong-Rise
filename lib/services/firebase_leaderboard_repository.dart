import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry.dart';
import 'firebase_bootstrap.dart';
import 'guest_name.dart';
import 'leaderboard_service.dart';
import 'player_profile_store.dart';
import 'progress_store.dart';

/// Онлайн-таблица рейтинга в Firestore.
class FirebaseLeaderboardRepository {
  FirebaseLeaderboardRepository._();

  static const collection = 'leaderboard';
  static const fetchLimit = 50;

  static FirebaseFirestore? get _db =>
      FirebaseBootstrap.enabled ? FirebaseFirestore.instance : null;

  static Future<void> syncProgress({
    required ProgressStore progress,
    required PlayerProfileStore profile,
  }) async {
    if (!FirebaseBootstrap.enabled) return;

    try {
      final user = await FirebaseBootstrap.ensureSignedIn();
      if (user == null) return;

      final name = GuestName.clamp(profile.displayName);
      final rating = LeaderboardService.ratingFor(progress);
      final lastSynced = profile.lastSyncedRating;
      final nameChanged = name != profile.lastSyncedName;

      final doc = _db!.collection(collection).doc(user.uid);
      final existing = await doc.get();
      final data = existing.data();
      if (existing.exists && rating <= lastSynced && !nameChanged) return;
      final existingRating = _asInt(data?['rating']);

      // Частичный merge (только name) падает на hasOnly в firestore.rules.
      if (rating < existingRating && data != null) {
        if (!nameChanged) return;
        final stars = _asInt(data['totalStars']);
        final unlocked = _asInt(
          data['levelsUnlocked'],
          fallback: 1,
        ).clamp(1, 240);
        final scores = _asInt(data['sumBestScores']);
        final keepRating = LeaderboardService.ratingFrom(
          totalStars: stars,
          sumBestScores: scores,
          levelsUnlocked: unlocked,
        );
        await doc.set(
          _payload(
            name: name,
            totalStars: stars,
            levelsUnlocked: unlocked,
            sumBestScores: scores,
          ),
          SetOptions(merge: true),
        );
        await profile.markSynced(rating: keepRating, name: name);
        return;
      }

      await doc.set(
        _payload(
          name: name,
          totalStars: progress.totalStars,
          levelsUnlocked: progress.maxUnlocked,
          sumBestScores: progress.sumBestScores,
        ),
        SetOptions(merge: true),
      );

      await profile.markSynced(rating: rating, name: name);
    } catch (error) {
      debugPrint('All-time leaderboard sync failed: $error');
    }
  }

  static Future<LeaderboardFetch> fetchTop({
    required ProgressStore progress,
    required PlayerProfileStore profile,
  }) async {
    List<LeaderboardEntry> local() =>
        LeaderboardService.buildLocal(progress: progress, profile: profile);

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

        await syncProgress(progress: progress, profile: profile);

        final snapshot = await _db!
            .collection(collection)
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
              name: GuestName.clamp(profile.displayName),
              rating: LeaderboardService.ratingFor(progress),
              totalStars: progress.totalStars,
              levelsUnlocked: progress.maxUnlocked,
              isCurrentPlayer: true,
            ),
          );
          entries.sort((a, b) {
            final byRating = b.rating.compareTo(a.rating);
            if (byRating != 0) return byRating;
            return a.name.compareTo(b.name);
          });
        }

        return entries;
      },
    );
  }

  static Map<String, dynamic> _payload({
    required String name,
    required int totalStars,
    required int levelsUnlocked,
    required int sumBestScores,
  }) {
    final stars = totalStars.clamp(0, 720);
    final unlocked = levelsUnlocked.clamp(1, 240);
    final scores = sumBestScores.clamp(0, 20000000);
    return {
      'name': GuestName.clamp(name),
      'rating': LeaderboardService.ratingFrom(
        totalStars: stars,
        sumBestScores: scores,
        levelsUnlocked: unlocked,
      ),
      'totalStars': stars,
      'levelsUnlocked': unlocked,
      'sumBestScores': scores,
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
      totalStars: _asInt(data['totalStars']),
      levelsUnlocked: _asInt(data['levelsUnlocked'], fallback: 1),
      isCurrentPlayer: doc.id == currentUid,
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
