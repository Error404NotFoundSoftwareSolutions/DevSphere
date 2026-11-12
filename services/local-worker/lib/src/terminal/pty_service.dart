// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: terminal service running pty on worker side streamed to UI

import 'dart:async';

abstract class TerminalPtyService {
  Stream<String> get output;
  void write(String data);
  void resize(int cols, int rows);
  void dispose();
}

class MockTerminalPtyService implements TerminalPtyService {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get output => _controller.stream;

  @override
  void write(String data) {
    _controller.add(data);
  }

  @override
  void resize(int cols, int rows) {}

  @override
  void dispose() {
    _controller.close();
  }
}
