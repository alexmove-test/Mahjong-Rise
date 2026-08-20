import 'dart:convert';
import 'dart:io';

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
  try {
    final payload = jsonEncode({
      'sessionId': '18033e',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint(payload);
    // File + ingest only on the Windows host. On Android, 127.0.0.1 is the
    // phone itself and each request waited ~400ms — that was the hitch.
    if (!Platform.isWindows) return;
    File(r'C:\Code\Mahjong\debug-18033e.log').writeAsStringSync(
      '$payload\n',
      mode: FileMode.append,
      flush: true,
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 400);
    client
        .postUrl(
          Uri.parse(
            'http://127.0.0.1:7346/ingest/0ef73c2b-305e-49d0-be79-213084e67fb5',
          ),
        )
        .then((req) {
          req.headers.set('Content-Type', 'application/json');
          req.headers.set('X-Debug-Session-Id', '18033e');
          req.add(utf8.encode(payload));
          return req.close();
        })
        .catchError((_) => null)
        .whenComplete(client.close);
  } catch (_) {}
  // #endregion
}
