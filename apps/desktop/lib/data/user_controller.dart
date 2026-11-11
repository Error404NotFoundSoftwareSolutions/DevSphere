// Capability: CAP-PROFILE-DATA. Tests: TC-USR-13..
// Implemented here: the signed-in person's data as shared app state. It loads when someone signs in, is
// emptied when they sign out, and saves after each change. Screens read it; labs feed it.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/auth/auth_session.dart';
import '../worker/worker_client.dart';
import 'user_data.dart';
import 'user_store.dart';

class UserDataController extends ChangeNotifier {
  UserDataController(this._store,
      {AuthSession? session, DateTime Function()? clock})
      : _session = session ?? AuthSession.instance,
        _clock = clock ?? DateTime.now {
    _session.addListener(_onAuth);
    _onAuth();
  }

  final UserStore _store;
  final AuthSession _session;
  final DateTime Function() _clock;
  UserData? _data;
  Future<void> _saving = Future.value();
  bool _disposed = false;

  /// The signed-in person's data, or null when nobody is signed in or it is still loading.
  UserData? get data => _data;
  DateTime get today => _clock();

  Future<void> _onAuth() async {
    final user = _session.user;
    if (user == null) {
      if (_data != null) {
        _data = null;
        _notify();
      }
      return;
    }
    if (_data?.uid == user.uid) return;
    _data = null;
    final loaded = await _store.load(user.uid);
    if (_session.user?.uid != user.uid)
      return; // someone else signed in while we were loading
    final name = loaded.profile.displayName;
    _data = name.isEmpty && (user.displayName ?? '').isNotEmpty
        ? loaded.copyWith(
            profile: UserProfile(
                displayName: user.displayName!,
                college: loaded.profile.college,
                course: loaded.profile.course,
                academicYear: loaded.profile.academicYear,
                interests: loaded.profile.interests))
        : loaded;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _persist(UserData d) {
    _data = d;
    _notify();
    _saving = _saving.then((_) => _store.save(d)).catchError((Object _) {});
  }

  /// Waits until every queued save has finished. For tests and for shutdown.
  Future<void> flush() => _saving;

  void recordLab(
      {required String labId,
      required String title,
      required String labRoot,
      required List<StepProgress> steps}) {
    final d = _data;
    if (d == null) return;
    final next = d.withLabState(
        labId: labId,
        title: title,
        labRoot: labRoot,
        steps: steps,
        now: _clock());
    if (!identical(next, d)) _persist(next);
  }

  void saveRoadmap(SavedRoadmap roadmap) {
    final d = _data;
    if (d == null) return;
    _persist(d.copyWith(roadmap: roadmap));
  }

  void saveInterview(SavedInterview interview) {
    final d = _data;
    if (d == null) return;
    _persist(d.copyWith(interview: interview));
  }

  void setPractised(int index, bool done) {
    final d = _data;
    final i = d?.interview;
    if (d == null || i == null) return;
    _persist(d.copyWith(interview: i.withPractised(index, done)));
  }

  void addGeneratedLab(GeneratedLabRef ref) {
    final d = _data;
    if (d == null) return;
    final others = d.generatedLabs.where((g) => g.labId != ref.labId).toList();
    _persist(d.copyWith(generatedLabs: [ref, ...others].take(50).toList()));
  }

  void clearInterview() {
    final d = _data;
    if (d == null) return;
    _persist(d.copyWith(clearInterview: true));
  }

  void clearRoadmap() {
    final d = _data;
    if (d == null) return;
    _persist(d.copyWith(clearRoadmap: true));
  }

  void saveProfile(UserProfile profile) {
    final d = _data;
    if (d == null) return;
    _persist(d.copyWith(profile: profile));
  }

  /// Asks the worker for the state of every lab this person has opened and records it, so progress made in
  /// VS Code shows up even when the lab page is closed.
  Future<void> syncSessions(WorkerClient client) async {
    final d = _data;
    if (d == null) return;
    for (final id in d.labs.keys.toList()) {
      try {
        final r = await client.send('companion:sessionState', {'labId': id});
        final steps = r['steps'];
        if (r['active'] != true || steps is! List) continue;
        recordLab(
          labId: id,
          title: d.labs[id]!.title,
          labRoot: '${r['labRoot'] ?? ''}',
          steps: [
            for (final s in steps)
              if (s is Map)
                StepProgress(
                    id: '${s['id']}',
                    title: '${s['title']}',
                    state: '${s['state']}')
          ],
        );
      } on WorkerException {
        // The worker is not running or the lab is closed: keep what we know.
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _session.removeListener(_onAuth);
    super.dispose();
  }
}
