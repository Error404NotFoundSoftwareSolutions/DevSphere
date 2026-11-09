// Capability: CAP-PROFILE-DATA. Rules: TRU-01, NFR-SEC-004, FR-PROF-010. Tests: TC-USR-01..08
// Implemented here: everything the app remembers about ONE signed-in person: their profile, lab progress
// and activity. Pure Dart (no files, no network) so it can be tested and shown anywhere. It holds no
// tokens, no password, no email and no date of birth. Results are Practice; a badge needs a Verified result.

enum LabStatus { notStarted, inProgress, practiceComplete }

class StepProgress {
  const StepProgress({required this.id, required this.title, required this.state});
  final String id;
  final String title;

  /// `pass`, `fail` or `todo` as reported by the lab session.
  final String state;
  bool get passed => state == 'pass';

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'state': state};
}

class LabProgress {
  const LabProgress({
    required this.labId,
    required this.title,
    required this.startedAt,
    required this.lastActivity,
    this.labRoot = '',
    this.steps = const [],
    this.completedAt,
  });

  final String labId;
  final String title;
  final String startedAt;
  final String lastActivity;
  final String labRoot;
  final List<StepProgress> steps;
  final String? completedAt;

  int get total => steps.length;
  int get passed => steps.where((s) => s.passed).length;
  int get score => total == 0 ? 0 : ((passed / total) * 100).round();
  LabStatus get status => total > 0 && passed == total
      ? LabStatus.practiceComplete
      : LabStatus.inProgress;

  LabProgress copyWith({String? lastActivity, String? labRoot, List<StepProgress>? steps, String? completedAt}) =>
      LabProgress(
        labId: labId,
        title: title,
        startedAt: startedAt,
        lastActivity: lastActivity ?? this.lastActivity,
        labRoot: labRoot ?? this.labRoot,
        steps: steps ?? this.steps,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, Object?> toJson() => {
        'labId': labId,
        'title': title,
        'startedAt': startedAt,
        'lastActivity': lastActivity,
        'labRoot': labRoot,
        'steps': [for (final s in steps) s.toJson()],
        if (completedAt != null) 'completedAt': completedAt,
      };
}

class UserProfile {
  const UserProfile({this.displayName = '', this.college = '', this.course = '', this.academicYear = '', this.interests = const []});
  final String displayName;
  final String college;
  final String course;
  final String academicYear;
  final List<String> interests;

  Map<String, Object?> toJson() => {
        'displayName': displayName,
        'college': college,
        'course': course,
        'academicYear': academicYear,
        'interests': interests,
      };
}

/// A check that passed for the first time, kept to build the streak and the weekly goal.
class PassEvent {
  const PassEvent({required this.labId, required this.stepId, required this.day});
  final String labId;
  final String stepId;

  /// `YYYY-MM-DD` in the learner's local time.
  final String day;
}

class UserData {
  const UserData({
    required this.uid,
    this.profile = const UserProfile(),
    this.labs = const {},
    this.passes = const [],
    this.weeklyTarget = 5,
  });

  static const int version = 1;
  static const int maxLabs = 200;
  static const int maxPasses = 2000;

  final String uid;
  final UserProfile profile;
  final Map<String, LabProgress> labs;
  final List<PassEvent> passes;
  final int weeklyTarget;

  LabProgress? lab(String id) => labs[id];

  LabStatus statusOf(String labId) => labs[labId]?.status ?? LabStatus.notStarted;

  /// The most recently used lab that is not finished, for the Resume button.
  LabProgress? get resumable {
    final open = labs.values.where((l) => l.status == LabStatus.inProgress).toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return open.isEmpty ? null : open.first;
  }

  List<LabProgress> get completed =>
      labs.values.where((l) => l.status == LabStatus.practiceComplete).toList()
        ..sort((a, b) => (b.completedAt ?? '').compareTo(a.completedAt ?? ''));

  Set<String> get activeDays => {for (final p in passes) p.day};

  /// Checks passed in the 7 days that end on [today].
  int weeklyDone(DateTime today) {
    final from = dayKey(today.subtract(const Duration(days: 6)));
    final to = dayKey(today);
    return passes.where((p) => p.day.compareTo(from) >= 0 && p.day.compareTo(to) <= 0).length;
  }

  /// Seven flags, oldest first, ending on [today]: was there at least one pass that day?
  List<bool> weekFlags(DateTime today) {
    final days = activeDays;
    return [for (var i = 6; i >= 0; i--) days.contains(dayKey(today.subtract(Duration(days: i))))];
  }

  List<String> weekLabels(DateTime today) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return [for (var i = 6; i >= 0; i--) names[today.subtract(Duration(days: i)).weekday - 1]];
  }

  /// Consecutive weeks (Monday to Sunday) with at least one pass, counting back from this week.
  /// An empty current week does not break the streak until the week is over.
  int streakWeeks(DateTime today) {
    final weeks = {for (final d in activeDays) _weekStart(DateTime.tryParse(d) ?? today)};
    var cursor = _weekStart(today);
    if (!weeks.contains(cursor)) cursor = cursor.subtract(const Duration(days: 7));
    var n = 0;
    while (weeks.contains(cursor)) {
      n++;
      cursor = cursor.subtract(const Duration(days: 7));
    }
    return n;
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  UserData copyWith({UserProfile? profile, Map<String, LabProgress>? labs, List<PassEvent>? passes}) =>
      UserData(uid: uid, profile: profile ?? this.profile, labs: labs ?? this.labs, passes: passes ?? this.passes, weeklyTarget: weeklyTarget);

  Map<String, Object?> toJson() => {
        'version': version,
        'uid': uid,
        'profile': profile.toJson(),
        'weeklyTarget': weeklyTarget,
        'labs': [for (final l in labs.values) l.toJson()],
        'passes': [
          for (final p in passes) {'labId': p.labId, 'stepId': p.stepId, 'day': p.day}
        ],
      };

  /// Reads a saved file. The file is untrusted input: wrong types and oversize lists are dropped, never thrown.
  static UserData fromJson(Object? raw, {required String uid}) {
    if (raw is! Map || raw['version'] != version || raw['uid'] != uid) return UserData(uid: uid);
    String s(Object? v, [int max = 200]) => v is String && v.length <= max ? v : '';
    final p = raw['profile'];
    final profile = p is Map
        ? UserProfile(
            displayName: s(p['displayName'], 120),
            college: s(p['college'], 160),
            course: s(p['course'], 160),
            academicYear: s(p['academicYear'], 40),
            interests: p['interests'] is List
                ? [for (final i in (p['interests'] as List).take(20)) if (i is String && i.length <= 60) i]
                : const [],
          )
        : const UserProfile();
    final labs = <String, LabProgress>{};
    final rawLabs = raw['labs'];
    if (rawLabs is List) {
      for (final l in rawLabs.take(maxLabs)) {
        if (l is! Map) continue;
        final id = s(l['labId'], 64);
        if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(id)) continue;
        final steps = <StepProgress>[];
        if (l['steps'] is List) {
          for (final st in (l['steps'] as List).take(50)) {
            if (st is! Map) continue;
            final state = s(st['state'], 10);
            steps.add(StepProgress(id: s(st['id'], 64), title: s(st['title'], 120), state: const {'pass', 'fail', 'todo'}.contains(state) ? state : 'todo'));
          }
        }
        labs[id] = LabProgress(
          labId: id,
          title: s(l['title'], 160),
          startedAt: s(l['startedAt'], 40),
          lastActivity: s(l['lastActivity'], 40),
          labRoot: s(l['labRoot'], 500),
          steps: steps,
          completedAt: l['completedAt'] is String ? s(l['completedAt'], 40) : null,
        );
      }
    }
    final passes = <PassEvent>[];
    final rawPasses = raw['passes'];
    if (rawPasses is List) {
      for (final e in rawPasses.take(maxPasses)) {
        if (e is Map && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s(e['day'], 10))) {
          passes.add(PassEvent(labId: s(e['labId'], 64), stepId: s(e['stepId'], 64), day: s(e['day'], 10)));
        }
      }
    }
    return UserData(uid: uid, profile: profile, labs: labs, passes: passes);
  }

  /// Applies the latest state of a lab session. Returns the same object when nothing changed.
  UserData withLabState({
    required String labId,
    required String title,
    required String labRoot,
    required List<StepProgress> steps,
    required DateTime now,
  }) {
    final old = labs[labId];
    final nowIso = now.toIso8601String();
    final stepsSame = old != null &&
        old.steps.length == steps.length &&
        [for (var i = 0; i < steps.length; i++) old.steps[i].state == steps[i].state && old.steps[i].id == steps[i].id].every((x) => x);
    if (old != null && stepsSame && (labRoot.isEmpty || old.labRoot == labRoot)) return this;
    if (old == null && labs.length >= maxLabs) return this;

    final already = {for (final p in passes) '${p.labId}/${p.stepId}'};
    final fresh = [
      for (final s in steps)
        if (s.passed && !already.contains('$labId/${s.id}')) PassEvent(labId: labId, stepId: s.id, day: dayKey(now))
    ];
    final updated = (old ?? LabProgress(labId: labId, title: title, startedAt: nowIso, lastActivity: nowIso))
        .copyWith(lastActivity: nowIso, labRoot: labRoot.isEmpty ? null : labRoot, steps: steps);
    final done = updated.total > 0 && updated.passed == updated.total;
    final withDone = done && updated.completedAt == null ? updated.copyWith(completedAt: nowIso) : updated;
    final nextPasses = [...passes, ...fresh];
    return copyWith(
      labs: {...labs, labId: withDone},
      passes: nextPasses.length > maxPasses ? nextPasses.sublist(nextPasses.length - maxPasses) : nextPasses,
    );
  }
}
