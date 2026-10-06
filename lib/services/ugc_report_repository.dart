import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';
import 'guest_name.dart';

/// Player reports of public leaderboard names.
abstract final class UgcReportRepository {
  static const collection = 'ugc_reports';

  static const reasonName = 'name';
  static const reasonAbuse = 'abuse';
  static const reasonOther = 'other';

  static Future<bool> submit({
    required String targetUid,
    required String targetName,
    required String reason,
  }) async {
    if (!FirebaseBootstrap.enabled) return false;
    final uid = targetUid.trim();
    if (uid.isEmpty) return false;
    try {
      final user = await FirebaseBootstrap.ensureSignedIn();
      if (user == null || user.uid == uid) return false;
      await FirebaseFirestore.instance.collection(collection).add({
        'reporterUid': user.uid,
        'targetUid': uid,
        'targetName': GuestName.clamp(targetName),
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      debugPrint('UGC report failed: $error');
      return false;
    }
  }
}
