// Capability: CAP-LEARNING-PATH. Rules: PRIV-01. Tests: TC-LP-20..
// Implemented here: the Watch panel. The video plays inside the app: an embedded Chromium (CEF, the webview_cef plugin)
// draws the DevPilot player page into a Flutter texture, so it is an ordinary widget (dialogs can draw over it and it
// never fights Flutter for the graphics card; a native WebKit view did, and turned the window black on Linux). The
// player page measures the seconds really watched and reports them to the DevPilot API under a random session; this
// panel reads them back every few seconds and passes them on as `progress` messages. If the embedded player cannot
// start, the panel falls back to the DevPilot player window (a small app-mode browser window).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import 'package:webview_cef/webview_cef.dart' as cef;
import '../../api.dart';
import '../../services/devpilot_api.dart';

/// A message for the Watch tab: `progress` (watched seconds and duration) or `unavailable`.
typedef PlayerMessage = Map<String, dynamic>;

typedef VideoViewBuilder = Widget Function(
    {required Key key,
    required String videoId,
    required void Function(PlayerMessage) onMessage});

/// Opens a player page in its own window. main.dart wires the real one (services/player_launcher.dart).
final playerLauncherProvider =
    Provider<Future<bool> Function(Uri url)>((ref) => (url) async => false);

/// Builds the video panel. Tests replace it.
final videoViewBuilderProvider = Provider<VideoViewBuilder>((ref) => (
        {required Key key,
        required String videoId,
        required void Function(PlayerMessage) onMessage}) =>
    EmbeddedVideoView(key: key, videoId: videoId, onMessage: onMessage));

/// True when the embedded player reported an error (for example a video format this browser cannot play) or the
/// video has not started 30 seconds after loading. The Watch tab then uses the player window for this video.
bool embeddedPlaybackFailed(Map<String, dynamic> progress, Duration sinceLoad) {
  if (progress['error'] != null) return true;
  final duration = progress['duration'];
  return (duration is! num || duration <= 0) &&
      sinceLoad > const Duration(seconds: 30);
}

/// Chromium is started once for the whole app, the first time a video is shown.
Future<void>? _cefReady;
Future<void> _ensureCef() => _cefReady ??= cef.WebviewManager().initialize();

/// Starts the embedded browser. Tests replace it (the real one needs the native plugin).
final embeddedBrowserStarterProvider =
    Provider<Future<void> Function()>((ref) => _ensureCef);

/// The video inside the app. Falls back to [PlayerWindowPanel] when the embedded player cannot start.
class EmbeddedVideoView extends ConsumerStatefulWidget {
  const EmbeddedVideoView(
      {super.key,
      required this.videoId,
      required this.onMessage,
      this.poll = const Duration(seconds: 3)});
  final String videoId;
  final void Function(PlayerMessage) onMessage;
  final Duration poll;

  @override
  ConsumerState<EmbeddedVideoView> createState() => _EmbeddedVideoViewState();
}

class _EmbeddedVideoViewState extends ConsumerState<EmbeddedVideoView> {
  cef.WebViewController? _controller;
  String? _session;
  bool _fallback = false;
  String? _note;
  DateTime _loadedAt = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final api = ref.read(devPilotApiProvider);
    try {
      final session = await api.startPlayerSession(widget.videoId);
      // If Chromium does not start within 20 seconds, fall back to the player window.
      await ref
          .read(embeddedBrowserStarterProvider)()
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final c = cef.WebviewManager().createWebView(
        loading:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
      _controller = c;
      await c
          .initialize(
              api.playerUrl(widget.videoId, session: session).toString())
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      _loadedAt = DateTime.now();
      setState(() => _session = session);
      _timer = Timer.periodic(widget.poll, (_) => _poll());
    } catch (_) {
      // No session (service down) or no embedded browser: the player window panel explains and offers a way on.
      if (mounted) setState(() => _fallback = true);
    }
  }

  Future<void> _poll() async {
    final s = _session;
    if (s == null || !mounted) return;
    try {
      final r = await ref.read(devPilotApiProvider).playerProgress(s);
      if (!mounted) return;
      if (embeddedPlaybackFailed(r, DateTime.now().difference(_loadedAt))) {
        // Some videos use a format the embedded browser cannot play (or it never starts): use the player window.
        _timer?.cancel();
        setState(() {
          _fallback = true;
          _note =
              'This video cannot play inside the app, so it opens in the DevPilot player window.';
        });
        return;
      }
      widget.onMessage({
        'type': 'progress',
        'watched': r['watched'],
        'duration': r['duration'],
        'ended': r['ended'] == true
      });
    } catch (_) {
      // a missed poll is fine; the next one catches up
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fallback) {
      return PlayerWindowPanel(
          videoId: widget.videoId,
          onMessage: widget.onMessage,
          poll: widget.poll,
          note: _note);
    }
    final c = _controller;
    if (c == null || _session == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }
    return Container(
      key: const Key('embedded-player'),
      color: Colors.black,
      // The plugin draws Chromium's hover hints into the nearest Overlay and does not always remove them. A local
      // Overlay keeps any hint inside the video area and removes it together with the player.
      child: ClipRect(
        child: Overlay(initialEntries: [
          OverlayEntry(
            builder: (_) => ValueListenableBuilder<bool>(
              valueListenable: c,
              builder: (_, ready, __) =>
                  ready ? c.webviewWidget : c.loadingWidget,
            ),
          ),
        ]),
      ),
    );
  }
}

class PlayerWindowPanel extends ConsumerStatefulWidget {
  const PlayerWindowPanel(
      {super.key,
      required this.videoId,
      required this.onMessage,
      this.poll = const Duration(seconds: 3),
      this.note});
  final String videoId;
  final void Function(PlayerMessage) onMessage;
  final Duration poll;

  /// Why the video is shown here instead of inside the app, when that is the case.
  final String? note;

  @override
  ConsumerState<PlayerWindowPanel> createState() => _PlayerWindowPanelState();
}

class _PlayerWindowPanelState extends ConsumerState<PlayerWindowPanel> {
  String? _session;
  bool _opening = false;
  String? _problem;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _problem = null;
    });
    final api = ref.read(devPilotApiProvider);
    try {
      final session = _session ?? await api.startPlayerSession(widget.videoId);
      final ok = await ref.read(playerLauncherProvider)(
          api.playerUrl(widget.videoId, session: session));
      if (!mounted) return;
      if (!ok) {
        setState(() => _problem =
            'The player window could not be opened on this computer.');
        widget.onMessage({'type': 'unavailable'});
        return;
      }
      setState(() => _session = session);
      _timer ??= Timer.periodic(widget.poll, (_) => _poll());
    } on ApiProblem catch (e) {
      if (mounted) setState(() => _problem = e.toString());
      widget.onMessage({'type': 'unavailable'});
    } catch (_) {
      if (mounted)
        setState(
            () => _problem = 'The player could not be started. Try again.');
      widget.onMessage({'type': 'unavailable'});
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _poll() async {
    final s = _session;
    if (s == null || !mounted) return;
    try {
      final r = await ref.read(devPilotApiProvider).playerProgress(s);
      if (!mounted) return;
      widget.onMessage({
        'type': 'progress',
        'watched': r['watched'],
        'duration': r['duration'],
        'ended': r['ended'] == true
      });
    } catch (_) {
      // a missed poll is fine; the next one catches up
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = _session != null;
    return Container(
      key: const Key('player-panel'),
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        Opacity(
          opacity: open ? 0.25 : 0.55,
          child: Image.network(
            'https://i.ytimg.com/vi/${widget.videoId}/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(BL.space6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton.icon(
                key: const Key('player-open'),
                onPressed: _opening ? null : _open,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16)),
                icon: _opening
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(open ? Icons.open_in_new : Icons.play_arrow,
                        size: 22),
                label: Text(open
                    ? 'Open the player again'
                    : 'Play in the DevPilot player'),
              ),
              const SizedBox(height: BL.space3),
              Text(
                open
                    ? 'Playing in its own window. Your progress updates here every few seconds.'
                    : 'The video opens in a small player window. Only the parts you really watch count.',
                key: const Key('player-hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
              if (widget.note != null && !open)
                Padding(
                  padding: const EdgeInsets.only(top: BL.space2),
                  child: Text(widget.note!,
                      key: const Key('player-note'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFFFE08A), fontSize: 13)),
                ),
              if (_problem != null)
                Padding(
                  padding: const EdgeInsets.only(top: BL.space2),
                  child: Text(_problem!,
                      key: const Key('player-problem'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFFFB4B4), fontSize: 13)),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
