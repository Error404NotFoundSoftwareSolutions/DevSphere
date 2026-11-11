// Capability: CAP-AI-CLIENT. Rules: NFR-SEC-004, SEC-10, AIR-01. Tests: TC-API-01..
// Implemented here: how the app talks to the DevPilot API (roadmap planner and tutor). The app never talks to
// Gemini or holds any Google AI credential: it sends the signed-in person's Firebase sign-in token to the API,
// and the API decides, redacts, limits and calls the model. Failures become plain sentences with a next step.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProblem implements Exception {
  const ApiProblem(this.message, {this.recovery = '', this.status = 0});

  /// What happened, in plain words.
  final String message;

  /// What the person can do next.
  final String recovery;
  final int status;

  @override
  String toString() => recovery.isEmpty ? message : '$message $recovery';
}

class TutorAnswer {
  const TutorAnswer({required this.answer, required this.level});
  final String answer;
  final int level;
}

abstract class DevPilotApi {
  /// Asks the planner for a roadmap. [kind] is `job_description` or `topic`.
  Future<Map<String, dynamic>> roadmap(
      {required String kind, required String text, String level = 'beginner'});

  /// Asks the interview coach for practice questions. [kind] is `job_description` or `topic`.
  Future<Map<String, dynamic>> interview(
      {required String kind, required String text, String level = 'beginner'});

  /// Asks Lab Forge to write a lab. The service checks it (the reference solution must pass, the starter must
  /// fail) before answering. Takes about 30 seconds.
  Future<Map<String, dynamic>> generateLab(
      {required String topic, String level = 'beginner'});

  /// Opens (or reuses) a server-side attempt for a lab, which the tutor needs.
  Future<String> attemptFor(String labId);

  Future<TutorAnswer> ask(
      {required String attemptId,
      required String question,
      String language = 'en',
      String? code});
}

/// Used when no API is wired (tests, or the service cannot be reached at all).
class OfflineDevPilotApi implements DevPilotApi {
  const OfflineDevPilotApi();

  static const _problem = ApiProblem(
    'DevPilot cannot reach its service.',
    recovery: 'Start it with ./start.sh, or check your internet connection.',
  );

  @override
  Future<Map<String, dynamic>> roadmap(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      Future.error(_problem);

  @override
  Future<Map<String, dynamic>> interview(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      Future.error(_problem);

  @override
  Future<Map<String, dynamic>> generateLab(
          {required String topic, String level = 'beginner'}) =>
      Future.error(_problem);

  @override
  Future<String> attemptFor(String labId) => Future.error(_problem);

  @override
  Future<TutorAnswer> ask(
          {required String attemptId,
          required String question,
          String language = 'en',
          String? code}) =>
      Future.error(_problem);
}

class HttpDevPilotApi implements DevPilotApi {
  HttpDevPilotApi(
      {required this.baseUrl, required this.token, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;

  /// Returns the signed-in person's current Firebase ID token, or null when nobody is signed in.
  final Future<String?> Function() token;
  final http.Client _client;
  final Map<String, String> _attempts = {};

  Future<Map<String, dynamic>> _post(String path, Object body,
      {Duration timeout = const Duration(seconds: 75)}) async {
    final t = await token();
    if (t == null || t.isEmpty) {
      throw const ApiProblem('You are not signed in.',
          recovery: 'Sign in again.', status: 401);
    }
    final http.Response r;
    try {
      r = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Authorization': 'Bearer $t',
              'Content-Type': 'application/json'
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiProblem('The service took too long to answer.',
          recovery: 'Try again in a moment.');
    } catch (_) {
      throw const ApiProblem('DevPilot cannot reach its service.',
          recovery:
              'Start it with ./start.sh, or check your internet connection.');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      decoded = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300 && decoded is Map)
      return decoded.cast<String, dynamic>();
    final detail = decoded is Map ? decoded['detail'] : null;
    if (detail is Map) {
      throw ApiProblem('${detail['message'] ?? 'Something went wrong.'}',
          recovery: '${detail['recovery'] ?? ''}', status: r.statusCode);
    }
    if (r.statusCode == 401) {
      throw const ApiProblem('Your sign-in has expired.',
          recovery: 'Sign out and sign in again.', status: 401);
    }
    throw ApiProblem('The service answered with an error (${r.statusCode}).',
        recovery: 'Try again later.', status: r.statusCode);
  }

  @override
  Future<Map<String, dynamic>> roadmap(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      _post('/v1/ai/roadmap', {'kind': kind, 'text': text, 'level': level});

  @override
  Future<Map<String, dynamic>> interview(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      _post('/v1/ai/interview', {'kind': kind, 'text': text, 'level': level});

  @override
  Future<Map<String, dynamic>> generateLab(
          {required String topic, String level = 'beginner'}) =>
      _post('/v1/ai/labs/generate', {'topic': topic, 'level': level},
          timeout: const Duration(seconds: 150));

  @override
  Future<String> attemptFor(String labId) async {
    final cached = _attempts[labId];
    if (cached != null) return cached;
    final r = await _post('/v1/attempts', {'lab_id': labId},
        timeout: const Duration(seconds: 20));
    final id = r['id'];
    if (id is! String || id.isEmpty)
      throw const ApiProblem('The service gave an unexpected answer.',
          recovery: 'Try again later.');
    return _attempts[labId] = id;
  }

  @override
  Future<TutorAnswer> ask(
      {required String attemptId,
      required String question,
      String language = 'en',
      String? code}) async {
    final r = await _post('/v1/tutor/messages', {
      'attempt_id': attemptId,
      'question': question,
      'level': 6, // the server lowers this to the lab's own cap
      'language': language,
      if (code != null) 'code': code,
    });
    final a = r['answer'];
    if (a is! String || a.isEmpty)
      throw const ApiProblem('The tutor gave no answer.',
          recovery: 'Try again.');
    return TutorAnswer(answer: a, level: (r['level'] as num?)?.toInt() ?? 0);
  }
}
