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

    final doc = _db!.collection(collection).doc(user.uid);
    final existing = await doc.get();
    final existingRating = existing.data()?['rating'] as int? ?? 0;

    if (rating < existingRating && !nameChanged) return;

    await doc.set({
      'name': profile.displayName,
      'rating': rating,
      'totalStars': progress.totalStars,
      'levelsUnlocked': progress.maxUnlocked,
      'sumBestScores': progress.sumBestScores,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await profile.markSynced(rating: rating, name: profile.displayName);
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
          : 'Игрок',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      totalStars: (data['totalStars'] as num?)?.toInt() ?? 0,
      levelsUnlocked: (data['levelsUnlocked'] as num?)?.toInt() ?? 1,
      isCurrentPlayer: doc.id == currentUid,
    );
  }
}
