// Capability: CAP-LEARNING-PATH. Rules: TRU-01, AIR-01. Tests: TC-LP-01..
// Implemented here: a learning path the AI built for one person, kept with that person's own data. The outline comes
// first; each step is filled in when the person reaches it. A step is finished when every video was watched to at
// least 80% (as measured by the player), the quick check was passed (2 of 3) and the lab's checks all passed. Only then
// does the next step unlock. Everything read from the service or from disk is validated; anything off is dropped.

final _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
final _labId = RegExp(r'^[a-z0-9][a-z0-9_-]{2,63}$');
final _slug = RegExp(r'^[a-z0-9][a-z0-9-]{0,47}$');

String _s(Object? v, int max) {
  if (v is! String) return '';
  final t =
      v.replaceAll(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]'), '').trim();
  return t.length <= max ? t : t.substring(0, max);
}

List<String> _strings(Object? v, int maxItems, int maxLen) => [
      if (v is List)
        for (final x in v.take(maxItems))
          if (_s(x, maxLen).isNotEmpty) _s(x, maxLen)
    ];

List<T> _parsed<T>(Object? list, int max, T? Function(Object?) parse) => [
      if (list is List)
        for (final x in list.take(max))
          if (parse(x) != null) parse(x) as T
    ];

const videoGoal = 0.8; // a video counts as watched at 80%
const quizPassMark = 2; // of 3

class PathVideo {
  const PathVideo(
      {required this.videoId,
      required this.title,
      required this.channel,
      required this.durationS,
      this.why = ''});
  final String videoId;
  final String title;
  final String channel;
  final int durationS;
  final String why;

  static PathVideo? parse(Object? j) {
    if (j is! Map) return null;
    final id = j['video_id'] ?? j['videoId'];
    if (id is! String || !_videoId.hasMatch(id)) return null;
    final d = j['duration_s'] ?? j['durationS'];
    return PathVideo(
      videoId: id,
      title: _s(j['title'], 150),
      channel: _s(j['channel'], 80),
      durationS: d is num ? d.toInt().clamp(0, 36000) : 0,
      why: _s(j['why'], 240),
    );
  }

  Map<String, Object?> toJson() => {
        'videoId': videoId,
        'title': title,
        'channel': channel,
        'durationS': durationS,
        'why': why
      };
}

class QuizQuestion {
  const QuizQuestion(
      {required this.question,
      required this.options,
      required this.answerIndex,
      required this.explain});
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explain;

  static QuizQuestion? parse(Object? j) {
    if (j is! Map) return null;
    final options = _strings(j['options'], 4, 300);
    final a = j['answer_index'] ?? j['answerIndex'];
    final q = _s(j['question'], 300);
    if (q.isEmpty || options.length < 3 || a is! num) return null;
    final i = a.toInt();
    if (i < 0 || i >= options.length) return null;
    return QuizQuestion(
        question: q,
        options: options,
        answerIndex: i,
        explain: _s(j['explain'], 300));
  }

  Map<String, Object?> toJson() => {
        'question': question,
        'options': options,
        'answerIndex': answerIndex,
        'explain': explain
      };
}

/// What the step builder made for one step.
class StepDetail {
  const StepDetail({
    required this.introMd,
    required this.keyPoints,
    required this.videos,
    required this.videosAvailable,
    required this.quiz,
    required this.labKind,
    this.labId,
    this.labTopic,
    this.labTitle = '',
  });

  final String introMd;
  final List<String> keyPoints;
  final List<PathVideo> videos;

  /// False when no video could be found (or no YouTube key is set up). The step then needs no video.
  final bool videosAvailable;
  final List<QuizQuestion> quiz;

  /// `catalog` (a published lab) or `generate` (a lab the AI writes for this step).
  final String labKind;
  final String? labId;
  final String? labTopic;
  final String labTitle;

  static StepDetail? parse(Object? j) {
    if (j is! Map) return null;
    final intro = j['intro_md'] ?? j['introMd'];
    final quiz = _parsed<QuizQuestion>(j['quiz'], 3, QuizQuestion.parse);
    final lab = j['lab'];
    if (intro is! String || intro.isEmpty || quiz.length != 3 || lab is! Map) {
      return null;
    }
    final kind = lab['kind'];
    String? labId;
    String? topic;
    if (kind == 'catalog') {
      final id = lab['lab_id'] ?? lab['labId'];
      if (id is! String || !_labId.hasMatch(id)) return null;
      labId = id;
    } else if (kind == 'generate') {
      topic = _s(lab['topic'], 300);
      if (topic.length < 10) return null;
    } else {
      return null;
    }
    final videos = _parsed<PathVideo>(j['videos'], 2, PathVideo.parse);
    final available = j['videos_available'] ?? j['videosAvailable'];
    return StepDetail(
      introMd: _s(intro, 3000),
      keyPoints: _strings(j['key_points'] ?? j['keyPoints'], 5, 200),
      videos: videos,
      videosAvailable: available is bool ? available : videos.isNotEmpty,
      quiz: quiz,
      labKind: kind as String,
      labId: labId,
      labTopic: topic,
      labTitle: _s(lab['title'] ?? lab['labTitle'], 120),
    );
  }

  Map<String, Object?> toJson() => {
        'introMd': introMd,
        'keyPoints': keyPoints,
        'videos': [for (final v in videos) v.toJson()],
        'videosAvailable': videosAvailable,
        'quiz': [for (final q in quiz) q.toJson()],
        'lab': {
          'kind': labKind,
          if (labId != null) 'labId': labId,
          if (labTopic != null) 'topic': labTopic,
          'labTitle': labTitle,
        },
      };
}

class PathStep {
  const PathStep({
    required this.id,
    required this.title,
    required this.objective,
    this.skills = const [],
    this.minutes = 45,
    this.detail,
    this.watched = const {},
    this.selfReported = const {},
    this.quizBest = -1,
    this.installedLabId,
  });

  final String id;
  final String title;
  final String objective;
  final List<String> skills;
  final int minutes;
  final StepDetail? detail;

  /// Video id -> the share of the video really watched (0 to 1), as measured by the player.
  final Map<String, double> watched;

  /// Videos the person marked as watched because the player could not run on this computer.
  final Set<String> selfReported;

  /// Best quick-check score so far (0 to 3), -1 when not tried.
  final int quizBest;

  /// The lab DevPilot installed for a `generate` step (an `ai-` id).
  final String? installedLabId;

  /// The lab this step uses: the catalogue lab, or the one installed for it.
  String? get labId => detail == null
      ? null
      : (detail!.labKind == 'catalog' ? detail!.labId : installedLabId);

  bool videoDone(String videoId) =>
      (watched[videoId] ?? 0) >= videoGoal || selfReported.contains(videoId);

  bool get videosDone =>
      detail != null && detail!.videos.every((v) => videoDone(v.videoId));
  bool get quizDone => quizBest >= quizPassMark;

  PathStep copyWith({
    StepDetail? detail,
    Map<String, double>? watched,
    Set<String>? selfReported,
    int? quizBest,
    String? installedLabId,
  }) =>
      PathStep(
        id: id,
        title: title,
        objective: objective,
        skills: skills,
        minutes: minutes,
        detail: detail ?? this.detail,
        watched: watched ?? this.watched,
        selfReported: selfReported ?? this.selfReported,
        quizBest: quizBest ?? this.quizBest,
        installedLabId: installedLabId ?? this.installedLabId,
      );

  static PathStep? parse(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final title = _s(j['title'], 120);
    if (id is! String || !_slug.hasMatch(id) || title.isEmpty) return null;
    final minutes = j['minutes'];
    final watched = <String, double>{};
    final w = j['watched'];
    if (w is Map) {
      for (final e in w.entries.take(4)) {
        if (e.key is String &&
            _videoId.hasMatch(e.key as String) &&
            e.value is num) {
          watched[e.key as String] =
              (e.value as num).toDouble().clamp(0.0, 1.0);
        }
      }
    }
    final installed = j['installedLabId'];
    final best = j['quizBest'];
    return PathStep(
      id: id,
      title: title,
      objective: _s(j['objective'], 240),
      skills: _strings(j['skills'], 4, 40),
      minutes: minutes is num ? minutes.toInt().clamp(10, 240) : 45,
      detail: j['detail'] == null ? null : StepDetail.parse(j['detail']),
      watched: watched,
      selfReported: {
        for (final v in _strings(j['selfReported'], 4, 11))
          if (_videoId.hasMatch(v)) v
      },
      quizBest: best is num ? best.toInt().clamp(-1, 3) : -1,
      installedLabId: installed is String &&
              RegExp(r'^ai-[a-z0-9][a-z0-9-]{2,63}$').hasMatch(installed)
          ? installed
          : null,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'objective': objective,
        'skills': skills,
        'minutes': minutes,
        if (detail != null) 'detail': detail!.toJson(),
        'watched': watched,
        'selfReported': selfReported.toList(),
        'quizBest': quizBest,
        if (installedLabId != null) 'installedLabId': installedLabId,
      };
}

class StudyPath {
  const StudyPath({
    required this.id,
    required this.goal,
    required this.title,
    required this.summary,
    required this.level,
    required this.language,
    required this.createdAt,
    required this.steps,
  });

  static const maxSaved = 10;

  final String id;
  final String goal;
  final String title;
  final String summary;
  final String level;
  final String language;
  final String createdAt;
  final List<PathStep> steps;

  /// Reads the planner's answer. Null when it is not the expected shape.
  static StudyPath? fromApi(Object? raw,
      {required String id,
      required String goal,
      required String level,
      required String language,
      required DateTime now}) {
    if (raw is! Map) return null;
    final steps = _parsed<PathStep>(raw['steps'], 8, PathStep.parse);
    final title = _s(raw['title'], 120);
    if (title.isEmpty || steps.length < 3) return null;
    if (steps.map((s) => s.id).toSet().length != steps.length) return null;
    return StudyPath(
      id: id,
      goal: _s(goal, 600),
      title: title,
      summary: _s(raw['summary'], 400),
      level: level == 'intermediate' ? 'intermediate' : 'beginner',
      language: _s(language, 5).isEmpty ? 'en' : _s(language, 5),
      createdAt: now.toIso8601String(),
      steps: steps,
    );
  }

  static StudyPath? fromSaved(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String || !RegExp(r'^p[0-9]{6,20}$').hasMatch(id)) return null;
    final p = fromApi(raw,
        id: id,
        goal: _s(raw['goal'], 600),
        level: _s(raw['level'], 20),
        language: _s(raw['language'], 5),
        now: DateTime.now());
    if (p == null) return null;
    return StudyPath(
        id: p.id,
        goal: p.goal,
        title: p.title,
        summary: p.summary,
        level: p.level,
        language: p.language,
        createdAt: _s(raw['createdAt'], 40),
        steps: p.steps);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'goal': goal,
        'title': title,
        'summary': summary,
        'level': level,
        'language': language,
        'createdAt': createdAt,
        'steps': [for (final s in steps) s.toJson()],
      };

  StudyPath withStep(int index, PathStep step) => StudyPath(
        id: id,
        goal: goal,
        title: title,
        summary: summary,
        level: level,
        language: language,
        createdAt: createdAt,
        steps: [
          for (var i = 0; i < steps.length; i++) i == index ? step : steps[i]
        ],
      );

  /// A step is complete when its videos, quick check and lab are all done.
  /// [labDone] says whether a lab's checks have all passed (from the person's own lab progress).
  bool stepComplete(int i, bool Function(String labId) labDone) {
    final s = steps[i];
    final lab = s.labId;
    return s.detail != null &&
        s.videosDone &&
        s.quizDone &&
        lab != null &&
        labDone(lab);
  }

  /// Steps unlock one at a time: a step is open when every step before it is complete.
  bool unlocked(int i, bool Function(String labId) labDone) {
    for (var k = 0; k < i; k++) {
      if (!stepComplete(k, labDone)) return false;
    }
    return true;
  }

  int completedCount(bool Function(String labId) labDone) => [
        for (var i = 0; i < steps.length; i++) stepComplete(i, labDone)
      ].where((x) => x).length;

  /// The first step that is not complete, or -1 when the whole path is done.
  int currentIndex(bool Function(String labId) labDone) {
    for (var i = 0; i < steps.length; i++) {
      if (!stepComplete(i, labDone)) return i;
    }
    return -1;
  }
}
