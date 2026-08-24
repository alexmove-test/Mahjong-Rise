import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';
import 'firebase_bootstrap.dart';
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

    final user = await FirebaseBootstrap.ensureSignedIn();
    if (user == null) return;

    final rating = LeaderboardService.ratingFor(progress);
    final lastSynced = profile.lastSyncedRating;
    final nameChanged = profile.displayName != profile.lastSyncedName;
    if (rating <= lastSynced && !nameChanged) return;

    try {
      final doc = _db!.collection(collection).doc(user.uid);
      final existing = await doc.get();
      final existingRating = _asInt(existing.data()?['rating']);

      if (rating < existingRating) {
        if (!nameChanged) return;
        await doc.set({
          'name': profile.displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await profile.markSynced(
          rating: existingRating,
          name: profile.displayName,
        );
        return;
      }

      await doc.set({
        'name': profile.displayName,
        'rating': rating,
        'totalStars': progress.totalStars,
        'levelsUnlocked': progress.maxUnlocked,
        'sumBestScores': progress.sumBestScores,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await profile.markSynced(rating: rating, name: profile.displayName);
    } catch (_) {
      // Read of the table must still work if a write is rejected.
    }
  }

  static Future<List<LeaderboardEntry>> fetchTop({
    required ProgressStore progress,
    required PlayerProfileStore profile,
  }) async {
    if (!FirebaseBootstrap.enabled) {
      return LeaderboardService.buildLocal(
        progress: progress,
        profile: profile,
      );
    }

    final user = await FirebaseBootstrap.ensureSignedIn();
    if (user == null) {
      return LeaderboardService.buildLocal(
        progress: progress,
        profile: profile,
      );
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
          name: profile.displayName,
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
