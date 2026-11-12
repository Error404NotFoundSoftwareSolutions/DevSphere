// Capability: CAP-LEARNING-PATH. Tests: TC-LP-30..
// Implemented here: opens the DevPilot player in its own small window. A Chromium-based browser (Chrome, Chromium,
// Edge, Brave) in "app mode" shows only the video, with no tabs or address bar. Without one, the default browser
// opens the same page. Only DevPilot's own player address is ever opened.

import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

const _linux = [
  'google-chrome',
  'google-chrome-stable',
  'chromium',
  'chromium-browser',
  'microsoft-edge',
  'brave-browser'
];
const _mac = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
];

List<String> _windows() {
  final pf = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
  final pf86 =
      Platform.environment['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
  final local = Platform.environment['LOCALAPPDATA'] ?? '';
  return [
    '$pf\\Google\\Chrome\\Application\\chrome.exe',
    '$pf86\\Google\\Chrome\\Application\\chrome.exe',
    if (local.isNotEmpty) '$local\\Google\\Chrome\\Application\\chrome.exe',
    '$pf86\\Microsoft\\Edge\\Application\\msedge.exe',
    '$pf\\Microsoft\\Edge\\Application\\msedge.exe',
  ];
}

String? _which(String name) {
  for (final dir in (Platform.environment['PATH'] ?? '').split(':')) {
    if (dir.isEmpty) continue;
    final f = File('$dir/$name');
    if (f.existsSync()) return f.path;
  }
  return null;
}

/// Opens [url] (a DevPilot player page) in a small app-mode window. Returns false when nothing could be opened.
Future<bool> openPlayerWindow(Uri url) async {
  if (url.path != '/player' || !(url.scheme == 'http' || url.scheme == 'https'))
    return false;
  String? browser;
  if (Platform.isLinux) {
    for (final b in _linux) {
      browser = _which(b);
      if (browser != null) break;
    }
  } else if (Platform.isMacOS) {
    browser = _mac.where((p) => File(p).existsSync()).firstOrNull;
  } else if (Platform.isWindows) {
    browser = _windows().where((p) => File(p).existsSync()).firstOrNull;
  }
  if (browser != null) {
    try {
      await Process.start(
        browser,
        [
          '--app=$url',
          '--window-size=1120,680',
          '--new-window',
          '--disable-extensions'
        ],
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (_) {
      // fall through to the default browser
    }
  }
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
