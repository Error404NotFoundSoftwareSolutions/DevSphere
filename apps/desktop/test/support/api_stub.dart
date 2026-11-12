// Test helper: a DevPilotApi whose every call fails as "not used in this test". Fakes extend it and override only
// what their test needs, so adding a call to the API does not break every fake.
import 'package:desktop/services/devpilot_api.dart';

class DevPilotApiStub implements DevPilotApi {
  Never _unused() => throw UnimplementedError('not used in this test');

  @override
  Future<Map<String, dynamic>> roadmap(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      _unused();
  @override
  Future<Map<String, dynamic>> interview(
          {required String kind,
          required String text,
          String level = 'beginner'}) =>
      _unused();
  @override
  Future<Map<String, dynamic>> generateLab(
          {required String topic, String level = 'beginner'}) =>
      _unused();
  @override
  Future<String> attemptFor(String labId) => _unused();
  @override
  Future<TutorAnswer> ask(
          {required String attemptId,
          required String question,
          String language = 'en',
          String? code}) =>
      _unused();
  @override
  Future<Map<String, dynamic>> explainError(
          {required String errorText, String? code, String language = 'en'}) =>
      _unused();
  @override
  Future<Map<String, dynamic>> reviewCode(
          {required String code,
          String filename = '',
          String goal = '',
          String language = 'en'}) =>
      _unused();
  @override
  Future<Map<String, dynamic>> createPath(
          {required String goal,
          String level = 'beginner',
          String language = 'en'}) =>
      _unused();
  @override
  Future<Map<String, dynamic>> buildPathStep({
    required String goal,
    required String pathTitle,
    required Map<String, Object?> step,
    List<String> previous = const [],
    String level = 'beginner',
    String language = 'en',
  }) =>
      _unused();
  @override
  Uri playerUrl(String videoId, {String? session}) => Uri.parse(
      'https://example.test/player?v=$videoId${session == null ? '' : '&s=$session'}');
  @override
  Future<String> startPlayerSession(String videoId) => _unused();
  @override
  Future<Map<String, dynamic>> playerProgress(String session) => _unused();
  @override
  Future<List<Credential>> credentials() => _unused();
  @override
  Future<Credential> claimCredential(
          {required String labId,
          required Map<String, bool> checks,
          required String startedAt,
          required String completedAt}) =>
      _unused();
  @override
  Future<Credential> setSharing(String id,
          {required bool isPublic, String displayName = ''}) =>
      _unused();
  @override
  String publicLink(String id) => '';
  @override
  bool get isLocalService => true;
}
