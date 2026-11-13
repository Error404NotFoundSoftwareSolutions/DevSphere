// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-SEC-002, NFR-SEC-003
// Capability: CAP-APP-EXT-CHANNEL (ADR-022). Spec: docs/EXTENSION_PROTOCOL.md. Tests: TC-CMP-04-xx. Threats T19, T20
// Implemented here: the local channel server. Linux and macOS: a Unix socket in a private directory (0700, socket
// 0600). Windows (PL-CMP-09): Dart cannot serve Windows named pipes, so the server listens on 127.0.0.1 with a free
// port instead, and the address is written to the session file as `tcp:127.0.0.1:<port>`. Other programs on the same
// PC could connect to a loopback port, so the session id (128 random bits, only in the user-private session file)
// must be said in the first message, and a client that does not say hello in time is dropped (handshakeTimeout).
// One client at a time, handshake first, strict parsing, three invalid messages and out you go, rate limit, idle
// timeout. The client is untrusted: the handler decides everything.

import 'dart:async';
import 'dart:io';
import 'protocol.dart';

abstract class RequestHandler {
  Map<String, Object?> welcome();
  Future<List<Map<String, Object?>>> handle(ExtensionRequest request);
}

/// Make `path` usable by the current Windows user only (no inherited access for others). Throws if it cannot.
void _windowsPrivate(String path, {required bool directory}) {
  final user = Platform.environment['USERNAME'] ?? '';
  final domain = Platform.environment['USERDOMAIN'] ?? '';
  if (user.isEmpty || RegExp(r'[:()\\/"<>|?*]').hasMatch(user)) {
    throw FileSystemException(
        'Could not tell which Windows user this is', path);
  }
  final who = domain.isEmpty || RegExp(r'[:()\\/"<>|?*]').hasMatch(domain)
      ? user
      : '$domain\\$user';
  final grant = directory ? '$who:(OI)(CI)F' : '$who:F';
  final r = Process.runSync(
      'icacls', [path, '/inheritance:r', '/grant:r', grant],
      runInShell: false);
  if (r.exitCode != 0) {
    throw FileSystemException(
        directory
            ? 'Could not make the runtime folder private'
            : 'Could not make the file private',
        path);
  }
}

/// Create `path` (and parents) and make the leaf private to the current user. Throws if it cannot be proven private.
void ensurePrivateDir(String path) {
  Directory(path).createSync(recursive: true);
  if (Platform.isWindows) {
    _windowsPrivate(path, directory: true);
    return;
  }
  final r = Process.runSync('chmod', ['700', path], runInShell: false);
  if (r.exitCode != 0 || (FileStat.statSync(path).mode & 0x3F) != 0) {
    throw FileSystemException(
        'Could not make the runtime folder private', path);
  }
}

void _chmod600(String path) {
  if (Platform.isWindows) {
    _windowsPrivate(path, directory: false);
    return;
  }
  final r = Process.runSync('chmod', ['600', path], runInShell: false);
  if (r.exitCode != 0 || (FileStat.statSync(path).mode & 0x3F) != 0) {
    throw FileSystemException('Could not make the file private', path);
  }
}

void makePrivateFile(String path) => _chmod600(path);

/// How the extension reaches the worker.
enum ChannelTransport {
  /// A Unix socket on Linux and macOS, a loopback port on Windows.
  auto,
  unixSocket,

  /// 127.0.0.1 and a free port. The default on Windows; selectable elsewhere so it can be tested on any system.
  loopbackTcp,
}

class ChannelServer {
  ChannelServer({
    required this.runtimeDir,
    required this.sessionId,
    required this.handler,
    this.idleTimeout = const Duration(minutes: 30),
    this.maxRequestsPerSecond = 30,
    this.maxInvalid = 3,
    this.transport = ChannelTransport.auto,
    this.handshakeTimeout,
  });

  final String runtimeDir;
  final String sessionId;
  final RequestHandler handler;
  final Duration idleTimeout;
  final int maxRequestsPerSecond;
  final int maxInvalid;
  final ChannelTransport transport;

  /// A client that has not said a valid hello within this time is dropped, so nobody can hold the single slot.
  /// Used on the loopback transport, where any program on the PC can connect.
  final Duration? handshakeTimeout;

  bool get _tcp =>
      transport == ChannelTransport.loopbackTcp ||
      (transport == ChannelTransport.auto && Platform.isWindows);

  late final String socketPath = '$runtimeDir/session-$sessionId.sock';
  ServerSocket? _server;
  Socket? _active;
  Timer? _idle;

  Future<String> start() async {
    ensurePrivateDir(runtimeDir);
    if (_tcp) {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _endpoint = 'tcp:127.0.0.1:${_server!.port}';
    } else {
      final stale = File(socketPath);
      if (stale.existsSync()) stale.deleteSync();
      _server = await ServerSocket.bind(
          InternetAddress(socketPath, type: InternetAddressType.unix), 0);
      _chmod600(socketPath);
      _endpoint = socketPath;
    }
    _server!.listen(_onConnection, onError: (_) {});
    return _endpoint;
  }

  String _endpoint = '';

  void _send(Socket s, Map<String, Object?> event) {
    try {
      s.add(encodeFrame(event));
    } catch (_) {
      // The client went away; nothing more to say.
    }
  }

  Future<void> _closeClient(Socket s) async {
    try {
      await s.flush();
      await s.close();
    } catch (_) {
      s.destroy();
    }
  }

  void _onConnection(Socket s) {
    if (_active != null) {
      _send(
          s,
          errorEvent('busy',
              'DevPilot is already connected to another VS Code window for this lab.'));
      unawaited(_closeClient(s));
      return;
    }
    _active = s;
    final gate = SessionGate(sessionId);
    final decoder = FrameDecoder();
    final stamps = <DateTime>[];
    var invalid = 0;
    var closing = false;
    var chain = Future<void>.value();
    Timer? helloTimer;

    void armIdle() {
      _idle?.cancel();
      _idle = Timer(idleTimeout, () {
        _send(s, {'type': 'sessionClosed'});
        closing = true;
        unawaited(_closeClient(s));
      });
    }

    Future<void> endWith(Map<String, Object?>? event) async {
      if (event != null) _send(s, event);
      closing = true;
      await _closeClient(s);
    }

    Future<void> process(Object? raw) async {
      if (closing) return;
      final request = parseRequest(raw);
      if (request == null) {
        invalid++;
        if (invalid >= maxInvalid) {
          await endWith(errorEvent('invalid-message',
              'DevPilot did not understand that message and closed the connection.'));
        } else {
          _send(
              s,
              errorEvent('invalid-message',
                  'DevPilot did not understand that message.'));
        }
        return;
      }
      switch (gate.check(request)) {
        case GateDecision.needHello:
          _send(s, errorEvent('need-hello', 'Say hello first.'));
        case GateDecision.wrongSession:
          await endWith(errorEvent('wrong-session',
              'This is not the session DevPilot started for this lab.'));
        case GateDecision.protocolMismatch:
          await endWith(errorEvent('protocol-mismatch',
              'The DevPilot Guide and DevPilot need to be the same version. Update DevPilot.'));
        case GateDecision.duplicateHello:
          _send(s, errorEvent('duplicate-hello', 'Already connected.'));
        case GateDecision.allow:
          if (request is HelloRequest) {
            helloTimer?.cancel();
            _send(s, handler.welcome());
          } else {
            try {
              for (final e in await handler.handle(request)) {
                _send(s, e);
              }
            } catch (_) {
              _send(
                  s,
                  errorEvent('invalid-message',
                      'DevPilot could not handle that request.'));
            }
          }
      }
    }

    armIdle();
    final limit = handshakeTimeout;
    if (limit != null) {
      helloTimer = Timer(limit, () {
        // never said hello: cut it off and free the slot right away (it may be a program squatting on the port)
        closing = true;
        _idle?.cancel();
        if (identical(_active, s)) _active = null;
        s.destroy();
      });
    }
    s.listen(
      (data) {
        if (closing) return;
        armIdle();
        final List<Object?> messages;
        try {
          messages = decoder.add(data);
        } on ProtocolError {
          closing = true;
          s.destroy();
          return;
        }
        for (final m in messages) {
          final now = DateTime.now();
          stamps.removeWhere(
              (t) => now.difference(t) > const Duration(seconds: 1));
          stamps.add(now);
          if (stamps.length > maxRequestsPerSecond) {
            chain = chain.then((_) => endWith(errorEvent(
                'busy', 'Too many requests. The connection was closed.')));
            return;
          }
          chain = chain.then((_) => process(m));
        }
      },
      onDone: () {
        helloTimer?.cancel();
        _idle?.cancel();
        if (identical(_active, s)) _active = null;
        s.destroy();
      },
      onError: (_) {
        helloTimer?.cancel();
        _idle?.cancel();
        if (identical(_active, s)) _active = null;
        s.destroy();
      },
    );
  }

  Future<void> close() async {
    _idle?.cancel();
    final s = _active;
    if (s != null) {
      _send(s, {'type': 'sessionClosed'});
      await _closeClient(s);
      _active = null;
    }
    await _server?.close();
    _server = null;
    if (!_tcp) {
      final f = File(socketPath);
      if (f.existsSync()) f.deleteSync();
    }
  }
}
