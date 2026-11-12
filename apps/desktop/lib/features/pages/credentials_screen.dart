// Capability: CAP-CREDENTIALS. Rules: TRU-01, TRU-02. Tests: TC-PGS-04..
// Implemented here: the signed-in person's own credentials. A badge is only ever awarded from a Verified result from
// the server, and verification is not connected in this version, so this page shows Practice results honestly:
// finished labs are "Pending verification" and the badge count is 0. Laid out like `git status` and `git log`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import '../../api.dart';
import '../../data/user_data.dart';
import '../../services/devpilot_api.dart';
import '../../ui/kit.dart';
import '../../ui/motion.dart';
import '../auth/auth_session.dart';
import '../dashboard/dashboard_data.dart';
import 'shared.dart';

String practiceLevel(int completedLabs) {
  if (completedLabs >= 3) return 'Practitioner (practice)';
  if (completedLabs >= 1) return 'Foundations (practice)';
  return 'Getting started';
}

/// Skills from the finished labs, without repeats, in the order they were earned.
List<String> practisedSkills(UserData? data) {
  final out = <String>[];
  for (final l in data?.completed.reversed ?? const <LabProgress>[]) {
    for (final s in SampleData.find(l.labId)?.skills ?? const <String>[]) {
      if (!out.contains(s)) out.add(s);
    }
  }
  return out;
}

class CredentialsScreen extends ConsumerStatefulWidget {
  const CredentialsScreen({super.key});

  @override
  ConsumerState<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends ConsumerState<CredentialsScreen> {
  /// Credentials the service holds for this person, by lab id. Null until loaded (or when the service is not reachable).
  Map<String, Credential>? _creds;
  final Set<String> _claiming = {};
  final Map<String, String> _problems = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(devPilotApiProvider).credentials();
      if (mounted) setState(() => _creds = {for (final c in list) c.labId: c});
    } catch (_) {
      // Not signed in to the service, or it cannot be reached: the page still shows the local results.
    }
  }

  Future<void> _claim(LabProgress l) async {
    setState(() {
      _claiming.add(l.labId);
      _problems.remove(l.labId);
    });
    try {
      final c = await ref.read(devPilotApiProvider).claimCredential(
            labId: l.labId,
            checks: {for (final s in l.steps) s.id: s.passed},
            startedAt: l.startedAt,
            completedAt: l.completedAt ?? l.lastActivity,
          );
      if (mounted) setState(() => (_creds ??= {})[l.labId] = c);
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _problems[l.labId] = e.toString());
    } finally {
      if (mounted) setState(() => _claiming.remove(l.labId));
    }
  }

  Future<void> _share(Credential c) async {
    final api = ref.read(devPilotApiProvider);
    final updated = await showDialog<Credential>(
      context: context,
      builder: (_) => ShareCredentialDialog(
        credential: c,
        api: api,
        suggestedName: AuthSession.instance.user?.displayName ?? '',
      ),
    );
    if (updated != null && mounted)
      setState(() => (_creds ??= {})[c.labId] = updated);
  }

  List<Widget> _credentialActions(LabProgress l) {
    final c = _creds?[l.labId];
    final busy = _claiming.contains(l.labId);
    if (c == null) {
      return [
        if (_problems[l.labId] != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(_problems[l.labId]!,
                key: Key('claim-problem-${l.labId}'),
                style: TextStyle(color: BL.danger, fontSize: 12)),
          ),
        const SizedBox(width: BL.space3),
        const Tag('Not claimed yet', tone: Tone.warn),
        const SizedBox(width: BL.space3),
        FilledButton(
          key: Key('claim-${l.labId}'),
          onPressed: busy ? null : () => _claim(l),
          child: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Claim credential'),
        ),
      ];
    }
    return [
      Tag(c.verified ? 'Verified' : 'Completed on your computer',
          key: Key('tier-${l.labId}'),
          tone: c.verified ? Tone.accent : Tone.info),
      const SizedBox(width: BL.space3),
      OutlinedButton.icon(
        key: Key('share-${l.labId}'),
        onPressed: () => _share(c),
        icon: Icon(c.isPublic ? Icons.public : Icons.ios_share, size: 16),
        label: Text(c.isPublic ? 'Shared' : 'Share'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final data = ref.watch(userDataProvider).data;
    final user = AuthSession.instance.user;
    final text = Theme.of(context).textTheme;
    final done = data?.completed ?? const <LabProgress>[];
    final skills = practisedSkills(data);
    final inProgress = (data?.labs.values
            .where((l) => l.status == LabStatus.inProgress)
            .toList() ??
        [])
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    Widget stat(String key, IconData icon, Color tint, Color color,
            String label, Widget value,
            {String? note}) =>
        Panel(
          key: Key(key),
          padding: const EdgeInsets.all(BL.space4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon: icon, tint: tint, color: color, size: 40),
            const SizedBox(height: BL.space3),
            value,
            const SizedBox(height: 2),
            Text(label, style: text.titleSmall),
            if (note != null)
              Text(note, style: BL.mono(size: 11.5, color: BL.textSecondary)),
          ]),
        );
    Widget number(int n) =>
        CountUp(value: n, style: text.headlineMedium?.copyWith(fontSize: 30));
    return PageFrame(
      slug: 'credentials',
      title: 'Credentials',
      subtitle: user == null
          ? 'Your badges and skill levels.'
          : 'Credentials of ${user.label}. Only you can see this page.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth >= 900 ? 4 : 2;
              final w = (box.maxWidth - BL.space4 * (cols - 1)) / cols;
              Widget at(Widget c) => SizedBox(width: w, child: c);
              return Wrap(spacing: BL.space4, runSpacing: BL.space4, children: [
                at(stat(
                    'stat-level',
                    Icons.trending_up,
                    BL.tintBlue,
                    BL.blue,
                    'Practice level',
                    Text(practiceLevel(done.length),
                        style: text.titleLarge
                            ?.copyWith(fontSize: 20, height: 1.3)),
                    note: 'from your finished labs')),
                at(stat(
                    'stat-badges',
                    Icons.workspace_premium_outlined,
                    BL.tintViolet,
                    BL.violet,
                    'Verified credentials',
                    number(_creds?.values.where((c) => c.verified).length ?? 0),
                    note: 'checked by the server itself')),
                at(stat('stat-completed', Icons.task_alt, BL.tintTeal, BL.teal,
                    'Labs completed', number(done.length),
                    note: 'practice results')),
                at(stat('stat-skills', Icons.insights_outlined, BL.tintAmber,
                    BL.amber, 'Skills practised', number(skills.length),
                    note: 'from finished labs')),
              ]);
            }),
          ),
          const SizedBox(height: BL.space6),
          Reveal(
            index: 1,
            child: Container(
              key: const Key('verification-note'),
              padding: const EdgeInsets.all(BL.space4),
              decoration: BoxDecoration(
                  color: BL.primarySoft,
                  borderRadius: BorderRadius.circular(BL.radiusLg)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: BL.primary, size: 20),
                const SizedBox(width: BL.space3),
                Expanded(
                  child: Text(
                    'When all of a lab\'s checks pass, you can claim a credential. Its checks ran on your own computer, so it says '
                    '"Completed, checked on your computer". "Verified" is kept for results the DevPilot server checks itself, and is never given for self-run checks.',
                    style: text.bodyMedium,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: BL.space12),
          Reveal(
            index: 2,
            child: Section(
              label: 'Completed labs',
              child: done.isEmpty
                  ? Panel(
                      key: const Key('credentials-empty'),
                      child: Row(children: [
                        Expanded(
                            child: Text(
                                "You have not completed a lab yet. When all of a lab's checks pass, it appears here.",
                                style: text.bodyMedium)),
                        const SizedBox(width: BL.space4),
                        OutlinedButton(
                            onPressed: () => context.go('/catalog'),
                            child: const Text('Browse the catalog')),
                      ]),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          for (final l in done) ...[
                            Panel(
                              key: Key('completed-${l.labId}'),
                              padding: const EdgeInsets.all(BL.space4),
                              child: Row(children: [
                                IconTile(
                                    icon: Icons.check_circle_outline,
                                    tint: BL.tintTeal,
                                    color: BL.success,
                                    size: 40),
                                const SizedBox(width: BL.space4),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            SampleData.find(l.labId)?.title ??
                                                l.title,
                                            style: text.titleSmall),
                                        Text(
                                            '${l.labId}  ·  score ${l.score}%  ·  ${shortDate(l.completedAt ?? l.lastActivity)}',
                                            style: BL.mono(size: 12)),
                                      ]),
                                ),
                                ..._credentialActions(l),
                              ]),
                            ),
                            const SizedBox(height: BL.space3),
                          ],
                        ]),
            ),
          ),
          if (inProgress.isNotEmpty) ...[
            const SizedBox(height: BL.space8),
            Reveal(
              index: 3,
              child: Section(
                label: 'In progress',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final l in inProgress) ...[
                        Panel(
                          key: Key('inprogress-${l.labId}'),
                          padding: const EdgeInsets.all(BL.space4),
                          child: Row(children: [
                            IconTile(
                                icon: Icons.timelapse,
                                tint: BL.tintBlue,
                                color: BL.blue,
                                size: 40),
                            const SizedBox(width: BL.space4),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        SampleData.find(l.labId)?.title ??
                                            l.title,
                                        style: text.titleSmall),
                                    Text(
                                        '${l.passed} of ${l.total} checks passed',
                                        style: BL.mono(size: 12)),
                                  ]),
                            ),
                            SizedBox(
                                width: 160,
                                child: AsciiBar(
                                    value:
                                        l.total == 0 ? 0 : l.passed / l.total)),
                            const SizedBox(width: BL.space4),
                            FilledButton(
                                onPressed: () =>
                                    context.go('/course/${l.labId}'),
                                child: const Text('Resume')),
                          ]),
                        ),
                        const SizedBox(height: BL.space3),
                      ],
                    ]),
              ),
            ),
          ],
          const SizedBox(height: BL.space8),
          Reveal(
            index: 4,
            child: Section(
              label: 'Skills practised',
              child: skills.isEmpty
                  ? Text('Skills appear here after you complete a lab.',
                      style: text.bodyMedium)
                  : Wrap(spacing: BL.space2, runSpacing: BL.space2, children: [
                      for (final s in skills) Tag(s, tone: Tone.info)
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the person choose a name and share one credential through a public link, or stop sharing it.
class ShareCredentialDialog extends StatefulWidget {
  const ShareCredentialDialog(
      {super.key,
      required this.credential,
      required this.api,
      this.suggestedName = ''});
  final Credential credential;
  final DevPilotApi api;
  final String suggestedName;

  @override
  State<ShareCredentialDialog> createState() => _ShareCredentialDialogState();
}

class _ShareCredentialDialogState extends State<ShareCredentialDialog> {
  late final TextEditingController _name = TextEditingController(
      text: widget.credential.displayName.isNotEmpty
          ? widget.credential.displayName
          : widget.suggestedName);
  late Credential _c = widget.credential;
  bool _busy = false;
  String? _problem;
  bool _copied = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _set(bool pub) async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final c = await widget.api
          .setSharing(_c.id, isPublic: pub, displayName: _name.text.trim());
      if (mounted) setState(() => _c = c);
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _problem = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final link = widget.api.publicLink(_c.id);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BL.space6),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share this credential', style: text.titleLarge),
                const SizedBox(height: BL.space2),
                Text(_c.title, style: text.bodySmall),
                const SizedBox(height: BL.space4),
                Text(
                  'Anyone with the link sees the name below, the lab and the date, and whether it was checked on your computer or by the service. '
                  'Not your email. You can stop sharing at any time.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: BL.space4),
                TextField(
                  key: const Key('share-name'),
                  controller: _name,
                  enabled: !_busy && !_c.isPublic,
                  maxLength: 60,
                  decoration: const InputDecoration(
                      labelText: 'Name to show', counterText: ''),
                ),
                if (_c.isPublic) ...[
                  const SizedBox(height: BL.space3),
                  Container(
                    key: const Key('share-link'),
                    padding: const EdgeInsets.all(BL.space3),
                    decoration: BoxDecoration(
                        color: BL.surfaceMuted,
                        borderRadius: BorderRadius.circular(BL.radiusMd),
                        border: Border.all(color: BL.border)),
                    child: Row(children: [
                      Expanded(
                          child:
                              SelectableText(link, style: BL.mono(size: 12.5))),
                      IconButton(
                        key: const Key('share-copy'),
                        tooltip: 'Copy the link',
                        icon:
                            Icon(_copied ? Icons.check : Icons.copy, size: 18),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: link));
                          if (mounted) setState(() => _copied = true);
                        },
                      ),
                    ]),
                  ),
                  if (widget.api.isLocalService)
                    Padding(
                      padding: const EdgeInsets.only(top: BL.space2),
                      child: Text(
                          'This link points at the service on this computer, so only you can open it. Use the hosted service to share it with others.',
                          key: const Key('share-local-note'),
                          style: TextStyle(color: BL.warning, fontSize: 12.5)),
                    ),
                ],
                if (_problem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: BL.space2),
                    child: Text(_problem!,
                        key: const Key('share-problem'),
                        style: TextStyle(color: BL.danger, fontSize: 12.5)),
                  ),
                const SizedBox(height: BL.space6),
                Wrap(
                    alignment: WrapAlignment.end,
                    spacing: BL.space2,
                    runSpacing: BL.space2,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(_c),
                          child: const Text('Close')),
                      if (_c.isPublic)
                        OutlinedButton(
                            key: const Key('share-stop'),
                            onPressed: _busy ? null : () => _set(false),
                            child: const Text('Stop sharing'))
                      else
                        FilledButton(
                            key: const Key('share-start'),
                            onPressed: _busy ? null : () => _set(true),
                            child: const Text('Make public')),
                    ]),
              ]),
        ),
      ),
    );
  }
}
