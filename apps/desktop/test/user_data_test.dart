// Capability: CAP-PROFILE-DATA. Tests: TC-USR-01..14
// Implemented here: each person's own data: progress, streaks, saved safely, never mixed between people
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop/data/file_user_store.dart';
import 'package:desktop/data/user_controller.dart';
import 'package:desktop/data/user_data.dart';
import 'package:desktop/data/user_store.dart';
import 'package:desktop/features/auth/auth_session.dart';

List<StepProgress> steps(List<String> states) => [
      for (var i = 0; i < states.length; i++)
        StepProgress(id: 's$i', title: 'Step $i', state: states[i]),
    ];

UserData record(UserData d, List<String> states, DateTime now,
        {String lab = 'lab-a'}) =>
    d.withLabState(
        labId: lab,
        title: 'Lab A',
        labRoot: '/labs/$lab',
        steps: steps(states),
        now: now);

void main() {
  final mon = DateTime(2026, 11, 9); // a Monday

  group('progress', () {
    test('TC-USR-01 recording a lab keeps its steps and counts each pass once',
        () {
      var d = const UserData(uid: 'u1');
      d = record(d, ['todo', 'todo'], mon);
      expect(d.statusOf('lab-a'), LabStatus.inProgress);
      expect(d.passes, isEmpty);
      d = record(d, ['pass', 'todo'], mon);
      d = record(d, ['pass', 'fail'], mon.add(const Duration(hours: 1)));
      expect(d.passes.length, 1,
          reason: 'the same pass is never counted twice');
      expect(d.lab('lab-a')!.score, 50);
    });

    test(
        'TC-USR-02 a lab with every step passed is Practice complete, never a badge',
        () {
      var d = record(const UserData(uid: 'u1'), ['pass', 'pass'], mon);
      expect(d.statusOf('lab-a'), LabStatus.practiceComplete);
      expect(d.lab('lab-a')!.completedAt, isNotNull);
      expect(d.completed.single.labId, 'lab-a');
      expect(d.toJson().toString().toLowerCase(), isNot(contains('badge')));
    });

    test(
        'TC-USR-03 an unchanged state returns the same object so nothing is saved needlessly',
        () {
      final d = record(const UserData(uid: 'u1'), ['pass', 'todo'], mon);
      expect(
          identical(
              record(d, ['pass', 'todo'], mon.add(const Duration(minutes: 5))),
              d),
          isTrue);
    });

    test('TC-USR-04 resume points at the most recently used unfinished lab',
        () {
      var d = record(const UserData(uid: 'u1'), ['pass', 'todo'], mon,
          lab: 'lab-a');
      d = record(d, ['todo'], mon.add(const Duration(days: 1)), lab: 'lab-b');
      d = record(d, ['pass'], mon.add(const Duration(days: 2)), lab: 'lab-c');
      expect(d.resumable!.labId, 'lab-b');
    });
  });

  group('streak and week', () {
    UserData withPassDays(List<DateTime> days) => UserData(uid: 'u', passes: [
          for (var i = 0; i < days.length; i++)
            PassEvent(labId: 'l', stepId: 's$i', day: UserData.dayKey(days[i])),
        ]);

    test(
        'TC-USR-05 weeks in a row count back from this week, and an empty new week does not end the streak',
        () {
      final d = withPassDays([
        mon.subtract(const Duration(days: 7)),
        mon.subtract(const Duration(days: 14))
      ]);
      expect(d.streakWeeks(mon), 2,
          reason:
              'this week has no pass yet but last week and the one before do');
      expect(d.streakWeeks(mon.add(const Duration(days: 7))), 0,
          reason: 'a whole week without a pass ends it');
      expect(withPassDays([]).streakWeeks(mon), 0);
    });

    test(
        'TC-USR-06 the week strip and the weekly goal use the last 7 days only',
        () {
      final wed = DateTime(2026, 11, 11);
      final d = withPassDays([
        wed,
        wed,
        wed.subtract(const Duration(days: 2)),
        wed.subtract(const Duration(days: 9))
      ]);
      expect(d.weeklyDone(wed), 3);
      final flags = d.weekFlags(wed);
      expect(flags.length, 7);
      expect(flags.last, isTrue);
      expect(flags[4], isTrue);
      expect(flags.where((f) => f).length, 2);
      expect(d.weekLabels(wed).last, 'Wed');
    });
  });

  group('saved file', () {
    test(
        'TC-USR-07 a file for another person, a wrong version or junk is ignored',
        () {
      final good =
          jsonEncode(record(const UserData(uid: 'u1'), ['pass'], mon).toJson());
      expect(UserData.fromJson(jsonDecode(good), uid: 'u1').labs, isNotEmpty);
      expect(UserData.fromJson(jsonDecode(good), uid: 'u2').labs, isEmpty,
          reason: 'different person');
      expect(UserData.fromJson({'version': 99, 'uid': 'u1'}, uid: 'u1').labs,
          isEmpty);
      expect(UserData.fromJson('not a map', uid: 'u1').labs, isEmpty);
      expect(UserData.fromJson(null, uid: 'u1').labs, isEmpty);
    });

    test(
        'TC-USR-08 wrong types, bad ids and oversize lists are dropped without throwing',
        () {
      final d = UserData.fromJson({
        'version': 1,
        'uid': 'u1',
        'profile': {
          'displayName': 5,
          'interests': ['ok', 7, 'x' * 100]
        },
        'labs': [
          {'labId': '../../etc', 'steps': []},
          {
            'labId': 'good-lab',
            'title': 'T',
            'steps': [
              {'id': 'a', 'title': 'A', 'state': 'weird'}
            ]
          },
          'junk',
        ],
        'passes': [
          {'labId': 'good-lab', 'stepId': 'a', 'day': 'yesterday'},
          {'labId': 'good-lab', 'stepId': 'a', 'day': '2026-11-09'},
        ],
      }, uid: 'u1');
      expect(d.profile.displayName, '');
      expect(d.profile.interests, ['ok']);
      expect(d.labs.keys, ['good-lab']);
      expect(d.lab('good-lab')!.steps.single.state, 'todo');
      expect(d.passes.length, 1);
    });

    test(
        'TC-USR-09 the data carries no token, password, email or date of birth',
        () {
      final text =
          jsonEncode(record(const UserData(uid: 'u1'), ['pass'], mon).toJson())
              .toLowerCase();
      for (final word in ['token', 'password', 'email', 'birth', 'dob']) {
        expect(text, isNot(contains(word)));
      }
    });
  });

  group('file store', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('devpilot-users-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test(
        'TC-USR-10 data round-trips, and two people on one computer never see each other',
        () async {
      final store = FileUserStore(dir.path);
      await store.save(
          record(const UserData(uid: 'alice-uid'), ['pass', 'pass'], mon));
      await store.save(
          record(const UserData(uid: 'bob-uid'), ['todo'], mon, lab: 'lab-b'));
      expect((await store.load('alice-uid')).statusOf('lab-a'),
          LabStatus.practiceComplete);
      expect((await store.load('alice-uid')).lab('lab-b'), isNull);
      expect((await store.load('bob-uid')).lab('lab-a'), isNull);
      expect((await store.load('someone-new')).labs, isEmpty);
    });

    test(
        'TC-USR-11 file names are hashes: no user id in the name or the folder',
        () async {
      final store = FileUserStore(dir.path);
      await store.save(const UserData(uid: 'alice-uid'));
      final names = [for (final f in dir.listSync(recursive: true)) f.path];
      expect(names.any((n) => n.contains('alice')), isFalse);
      expect(names.any((n) => n.endsWith('.tmp')), isFalse,
          reason: 'the temp file is renamed away');
    });

    test(
        'TC-USR-12 a damaged file gives empty data instead of a crash, and the folder is private',
        () async {
      final store = FileUserStore(dir.path);
      await store.save(const UserData(uid: 'u1'));
      final file = dir.listSync(recursive: true).whereType<File>().single;
      file.writeAsStringSync('{ this is not json');
      expect((await store.load('u1')).labs, isEmpty);
      if (!Platform.isWindows) {
        expect(Directory('${dir.path}/users').statSync().mode & 0x1ff, 0x1c0,
            reason: '0700');
        expect(file.statSync().mode & 0x1ff, 0x180, reason: '0600');
      }
    });
  });

  group('controller', () {
    final session = AuthSession.instance;
    setUp(session.signOut);
    tearDown(session.signOut);

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test(
        'TC-USR-13 data follows the signed-in person and is cleared on sign-out',
        () async {
      final store = MemoryUserStore();
      await store.save(record(const UserData(uid: 'u1'), ['pass'], mon));
      final c = UserDataController(store, clock: () => mon);
      expect(c.data, isNull, reason: 'nobody is signed in');
      session.signIn(const AuthUser(
          uid: 'u1', email: 'a@example.com', displayName: 'Asha'));
      await settle();
      expect(c.data!.uid, 'u1');
      expect(c.data!.profile.displayName, 'Asha',
          reason: 'name is taken from the sign-in on first use');
      expect(c.data!.lab('lab-a'), isNotNull);
      session.signIn(const AuthUser(uid: 'u2', email: 'b@example.com'));
      await settle();
      expect(c.data!.uid, 'u2');
      expect(c.data!.labs, isEmpty,
          reason: 'the next person starts with their own empty data');
      session.signOut();
      expect(c.data, isNull);
      c.dispose();
    });

    test('TC-USR-14 recording and profile edits are saved for that person only',
        () async {
      final store = MemoryUserStore();
      final c = UserDataController(store, clock: () => mon);
      c.recordLab(
          labId: 'lab-a', title: 'A', labRoot: '', steps: steps(['pass']));
      expect((await store.load('u1')).labs, isEmpty,
          reason: 'ignored when nobody is signed in');
      session.signIn(const AuthUser(uid: 'u1', email: 'a@example.com'));
      await settle();
      c.recordLab(
          labId: 'lab-a',
          title: 'A',
          labRoot: '/x',
          steps: steps(['pass', 'todo']));
      c.saveProfile(const UserProfile(displayName: 'Asha R', college: 'PES'));
      await c.flush();
      final saved = await store.load('u1');
      expect(saved.lab('lab-a')!.passed, 1);
      expect(saved.profile.college, 'PES');
      expect((await store.load('u2')).labs, isEmpty);
      c.dispose();
    });
  });
}
