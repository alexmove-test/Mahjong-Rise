import 'dart:convert';

import 'package:flutter/foundation.dart';

void agentDbg({
  required String location,
  required String message,
  required Map<String, Object?> data,
  required String hypothesisId,
  String runId = 'post-fix',
}) {
  // #region agent log
  if (!kDebugMode) return;
  debugPrint(
    jsonEncode({
      'sessionId': '18033e',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }),
  );
  // #endregion
}
