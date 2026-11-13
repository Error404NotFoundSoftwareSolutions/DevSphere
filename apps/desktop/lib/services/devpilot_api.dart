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

/// A credential the person earned from a finished lab. `attested` means the checks ran on their own computer and
/// the service validated the result; `verified` means the service checked it itself.
class Credential {
  const Credential({
    required this.id,
    required this.labId,
    required this.title,
    required this.tier,
    required this.issuedAt,
    this.isPublic = false,
    this.displayName = '',
  });

  final String id;
  final String labId;
  final String title;
  final String tier;
  final String issuedAt;
  final bool isPublic;
  final String displayName;

  bool get verified => tier == 'verified';

  static Credential? tryParse(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], lab = j['lab_id'], title = j['lab_title'];
    if (id is! String || lab is! String || title is! String) return null;
    return Credential(
      id: id,
      labId: lab,
      title: title,
      tier: j['tier'] == 'verified' ? 'verified' : 'attested',
      issuedAt: '${j['issued_at'] ?? ''}',
      isPublic: j['public'] == true,
      displayName: '${j['display_name'] ?? ''}',
    );
  }
}

abstract class DevPilotApi {
  /// Asks the planner for a roadmap. [kind] is `job_description` or `topic`.
  Future<Map<String, dynamic>> roadmap(
      {required String kind, required String text, String level = 'beginner'});

  /// Asks the interview coach for practice questions. [kind] is `job_description` or `topic`.
  Future<Map<String, dynamic>> interview(
      {required String kind, required String text, String level = 'beginner'});

  /// Asks Lab Forge to write a lab. The service only WRITES it (status `needs_check`, with the reference answer and the
  /// protected tests in `check`); the app proves it works on this computer before installing it. [feedback] is the report
  /// of a failed check, so the model can fix the lab. Takes about 20 seconds.
  Future<Map<String, dynamic>> generateLab(
      {required String topic,
      String level = 'beginner',
      String feedback = ''});

  /// Opens (or reuses) a server-side attempt for a lab, which the tutor needs.
  Future<String> attemptFor(String labId);

  /// Explains a pasted error in plain words: meaning, likely cause, things to try. Advice only.
  Future<Map<String, dynamic>> explainError(
      {required String errorText, String? code, String language = 'en'});

  /// Gives mentor-style feedback on a small piece of code. Advice only: no mark, no badge.
  Future<Map<String, dynamic>> reviewCode(
      {required String code,
      String filename = '',
      String goal = '',
      String language = 'en'});

  /// Stage 1 of a learning path: the outline (title, summary, 3 to 8 steps) for a goal.
  Future<Map<String, dynamic>> createPath(
      {required String goal,
      String level = 'beginner',
      String language = 'en'});

  /// Stage 2: one step filled in (explanation, real videos, quick check, lab).
  Future<Map<String, dynamic>> buildPathStep({
    required String goal,
    required String pathTitle,
    required Map<String, Object?> step,
    List<String> previous = const [],
    String level = 'beginner',
    String language = 'en',
  });

  /// The address of the DevPilot player page for one video, reporting under [session] when given.
  Uri playerUrl(String videoId, {String? session});

  /// Starts a player session for one video; the player window reports how much was watched under it.
  Future<String> startPlayerSession(String videoId);

  /// How much of the video was really watched in the player window: `watched` and `duration` in seconds, `ended`.
  Future<Map<String, dynamic>> playerProgress(String session);

  /// The person's own credentials.
  Future<List<Credential>> credentials();

  /// Claims the credential for a finished lab. [checks] maps each check id to whether it passed.
  Future<Credential> claimCredential(
      {required String labId,
      required Map<String, bool> checks,
      required String startedAt,
      required String completedAt});

  /// Makes a credential public (with the name to show) or private again.
  Future<Credential> setSharing(String id,
      {required bool isPublic, String displayName = ''});

  /// The address of a credential's public page.
  String publicLink(String id);

  /// True when the service is on this computer, so a public link would not work for anyone else.
  bool get isLocalService;

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
          {required String topic,
          String level = 'beginner',
          String feedback = ''}) =>
      Future.error(_problem);

  @override
  Future<String> attemptFor(String labId) => Future.error(_problem);

  @override
  Future<Map<String, dynamic>> explainError(
          {required String errorText, String? code, String language = 'en'}) =>
      Future.error(_problem);

  @override
  Future<Map<String, dynamic>> reviewCode(
          {required String code,
          String filename = '',
          String goal = '',
          String language = 'en'}) =>
      Future.error(_problem);

  @override
  Future<Map<String, dynamic>> createPath(
          {required String goal,
          String level = 'beginner',
          String language = 'en'}) =>
      Future.error(_problem);

  @override
  Future<Map<String, dynamic>> buildPathStep({
    required String goal,
    required String pathTitle,
    required Map<String, Object?> step,
    List<String> previous = const [],
    String level = 'beginner',
    String language = 'en',
  }) =>
      Future.error(_problem);

  @override
  Uri playerUrl(String videoId, {String? session}) => Uri.parse(
      'http://127.0.0.1:8787/player?v=$videoId${session == null ? '' : '&s=$session'}');

  @override
  Future<String> startPlayerSession(String videoId) => Future.error(_problem);

  @override
  Future<Map<String, dynamic>> playerProgress(String session) =>
      Future.error(_problem);

  @override
  Future<List<Credential>> credentials() => Future.error(_problem);

  @override
  Future<Credential> claimCredential(
          {required String labId,
          required Map<String, bool> checks,
          required String startedAt,
          required String completedAt}) =>
      Future.error(_problem);

  @override
  Future<Credential> setSharing(String id,
          {required bool isPublic, String displayName = ''}) =>
      Future.error(_problem);

  @override
  String publicLink(String id) => '';

  @override
  bool get isLocalService => true;

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
          {Duration timeout = const Duration(seconds: 75)}) =>
      _send('POST', path, body: body, timeout: timeout);

  Future<Map<String, dynamic>> _send(String method, String path,
      {Object? body, Duration timeout = const Duration(seconds: 75)}) async {
    final t = await token();
    if (t == null || t.isEmpty) {
      throw const ApiProblem('You are not signed in.',
          recovery: 'Sign in again.', status: 401);
    }
    final http.Response r;
    try {
      final headers = {
        'Authorization': 'Bearer $t',
        'Content-Type': 'application/json'
      };
      final uri = Uri.parse('$baseUrl$path');
      r = await (method == 'GET'
              ? _client.get(uri, headers: headers)
              : _client.post(uri, headers: headers, body: jsonEncode(body)))
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
          {required String topic,
          String level = 'beginner',
          String feedback = ''}) =>
      _post(
          '/v1/ai/labs/generate',
          {
            'topic': topic,
            'level': level,
            'check': 'app',
            if (feedback.isNotEmpty) 'feedback': feedback,
          },
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
  Future<Map<String, dynamic>> explainError(
          {required String errorText, String? code, String language = 'en'}) =>
      _post(
          '/v1/ai/explain-error',
          {
            'error_text': errorText,
            if (code != null && code.isNotEmpty) 'code': code,
            'language': language
          },
          timeout: const Duration(seconds: 100));

  @override
  Future<Map<String, dynamic>> reviewCode(
          {required String code,
          String filename = '',
          String goal = '',
          String language = 'en'}) =>
      _post(
          '/v1/ai/review-code',
          {
            'code': code,
            if (filename.isNotEmpty) 'filename': filename,
            if (goal.isNotEmpty) 'goal': goal,
            'language': language
          },
          timeout: const Duration(seconds: 100));

  @override
  Future<Map<String, dynamic>> createPath(
          {required String goal,
          String level = 'beginner',
          String language = 'en'}) =>
      _post(
          '/v1/ai/paths', {'goal': goal, 'level': level, 'language': language},
          timeout: const Duration(seconds: 90));

  @override
  Future<Map<String, dynamic>> buildPathStep({
    required String goal,
    required String pathTitle,
    required Map<String, Object?> step,
    List<String> previous = const [],
    String level = 'beginner',
    String language = 'en',
  }) =>
      _post(
          '/v1/ai/paths/step',
          {
            'goal': goal,
            'path_title': pathTitle,
            'step': step,
            'previous': previous.take(8).toList(),
            'level': level,
            'language': language,
          },
          timeout: const Duration(seconds: 100));

  @override
  Uri playerUrl(String videoId, {String? session}) =>
      Uri.parse('$baseUrl/player').replace(queryParameters: {
        'v': videoId,
        if (session != null) 's': session,
      });

  @override
  Future<String> startPlayerSession(String videoId) async {
    final r = await _post('/v1/player/sessions', {'video_id': videoId},
        timeout: const Duration(seconds: 20));
    final s = r['session'];
    if (s is! String || !RegExp(r'^[0-9a-f]{32}$').hasMatch(s)) {
      throw const ApiProblem('The service gave an unexpected answer.',
          recovery: 'Try again.');
    }
    return s;
  }

  @override
  Future<Map<String, dynamic>> playerProgress(String session) =>
      _send('GET', '/v1/player/sessions/$session',
          timeout: const Duration(seconds: 15));

  @override
  Future<List<Credential>> credentials() async {
    final r = await _send('GET', '/v1/credentials',
        timeout: const Duration(seconds: 20));
    final list = r['credentials'];
    return [
      if (list is List)
        for (final j in list)
          if (Credential.tryParse(j) != null) Credential.tryParse(j)!
    ];
  }

  Credential _credential(Map<String, dynamic> r) =>
      Credential.tryParse(r) ??
      (throw const ApiProblem('The service gave an unexpected answer.',
          recovery: 'Try again later.'));

  @override
  Future<Credential> claimCredential(
      {required String labId,
      required Map<String, bool> checks,
      required String startedAt,
      required String completedAt}) async {
    return _credential(await _post(
        '/v1/credentials/claim',
        {
          'lab_id': labId,
          'checks': [
            for (final e in checks.entries) {'id': e.key, 'passed': e.value}
          ],
          'started_at': startedAt,
          'completed_at': completedAt,
        },
        timeout: const Duration(seconds: 20)));
  }

  @override
  Future<Credential> setSharing(String id,
      {required bool isPublic, String displayName = ''}) async {
    return _credential(await _post('/v1/credentials/$id/sharing',
        {'public': isPublic, 'display_name': displayName},
        timeout: const Duration(seconds: 20)));
  }

  @override
  String publicLink(String id) => '$baseUrl/c/$id';

  @override
  bool get isLocalService {
    final h = Uri.tryParse(baseUrl)?.host ?? '';
    return h == 'localhost' || h == '127.0.0.1' || h == '::1';
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
