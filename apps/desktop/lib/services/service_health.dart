// Capability: CAP-STATUS. Tests: TC-STATUS-01..
// Implemented here: one quick, unauthenticated "is the DevPilot service up?" check for the status bar. It never sends
// a token or any personal data.

import 'dart:async';
import 'package:http/http.dart' as http;

Future<bool> checkService(String baseUrl, {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final r = await c
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 3));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    if (client == null) c.close();
  }
}
