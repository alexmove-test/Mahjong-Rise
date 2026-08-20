import 'dart:convert';
import 'dart:html' as html;

void agentDbg({
  required String location,
  required String message,
  required Map<String, Object?> data,
  required String hypothesisId,
  String runId = 'post-fix',
}) {
  // #region agent log
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
    html.HttpRequest.request(
      'http://127.0.0.1:7346/ingest/0ef73c2b-305e-49d0-be79-213084e67fb5',
      method: 'POST',
      sendData: payload,
      requestHeaders: const {
        'Content-Type': 'application/json',
        'X-Debug-Session-Id': '18033e',
      },
    ).timeout(const Duration(milliseconds: 250), onTimeout: () => html.HttpRequest());
  } catch (_) {}
  // #endregion
}
