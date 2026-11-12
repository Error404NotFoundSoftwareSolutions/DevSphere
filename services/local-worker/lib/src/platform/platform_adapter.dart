// User story: US-14 Work on Windows and a second OS (Sprint 3, MVP)
// Requirements: NFR-PORT-001..003, NFR-PORT-005
// Implemented here: all OS differences live behind this folder, not in lab content (NFR-PORT-002)

import 'dart:io';

enum PlatformName { windows, linux, macos }

PlatformName currentPlatform() {
  if (Platform.isWindows) return PlatformName.windows;
  if (Platform.isMacOS) return PlatformName.macos;
  return PlatformName.linux;
}

List<String> lookupCommand(String tool) {
  if (Platform.isWindows) {
    return ['where', tool];
  }
  return ['which', tool];
}

List<String> killTreeArgs(int pid) {
  if (Platform.isWindows) {
    return ['taskkill', '/F', '/T', '/PID', '$pid'];
  }
  return ['kill', '-9', '-$pid'];
}
