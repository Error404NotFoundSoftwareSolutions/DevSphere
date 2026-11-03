// User story: US-38 Fast start and detection (Sprint 9, MVP)
// Requirements: NFR-PERF-001, NFR-PERF-002
// Implemented here: startup and detection latency measurement

class StartupTimer {
  static DateTime? _start;

  static void markAppStart() {
    _start = DateTime.now();
  }

  static Duration get elapsed {
    if (_start == null) return Duration.zero;
    return DateTime.now().difference(_start!);
  }
}

