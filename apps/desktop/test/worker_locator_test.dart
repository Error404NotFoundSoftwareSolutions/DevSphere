// User story: US-16 Run lab tasks with limits (Sprint 4, MVP)
// Requirements: FR-EXEC-001..003, NFR-SEC-002
// Capability: CAP-VSCODE-LAUNCHER (ADR-019). Test IDs: TC-LNK-30..33
// Implemented here: where the app looks for its worker, lab content and guide extension

import 'package:desktop/worker/worker_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const exeDir = '/opt/buildloop/bundle';

  test('TC-LNK-30 the worker is found next to the app, or by an explicit variable', () {
    final fs = {'/opt/buildloop/bundle/worker'};
    expect(locateAppPaths(exeDir: exeDir, env: {}, exists: fs.contains).worker, '/opt/buildloop/bundle/worker');
    final env = {'BUILDLOOP_WORKER': '/custom/worker'};
    expect(locateAppPaths(exeDir: exeDir, env: env, exists: {...fs, '/custom/worker'}.contains).worker, '/custom/worker');
    expect(locateAppPaths(exeDir: exeDir, env: {}, exists: (_) => false).worker, isNull);
  });

  test('TC-LNK-31 the guide folder is the bundled one and must contain the metadata file', () {
    final ok = {'/opt/buildloop/bundle/guide/buildloop-guide.json'};
    expect(locateAppPaths(exeDir: exeDir, env: {}, exists: ok.contains).guideDir, '/opt/buildloop/bundle/guide');
    expect(locateAppPaths(exeDir: exeDir, env: {}, exists: (_) => false).guideDir, isNull);
  });

  test('TC-LNK-32 lab content: variable first, then next to the app, then up the folders (development builds)', () {
    expect(locateAppPaths(exeDir: exeDir, env: {'BUILDLOOP_CONTENT_ROOT': '/data/labs'}, exists: {'/data/labs'}.contains).contentRoot, '/data/labs');
    expect(locateAppPaths(exeDir: exeDir, env: {}, exists: {'/opt/buildloop/bundle/content/labs'}.contains).contentRoot, '/opt/buildloop/bundle/content/labs');
    const dev = '/home/u/repo/apps/desktop/build/linux/x64/release/bundle';
    expect(locateAppPaths(exeDir: dev, env: {}, exists: {'/home/u/repo/content/labs'}.contains).contentRoot, '/home/u/repo/content/labs');
    expect(locateAppPaths(exeDir: exeDir, env: {}, exists: (_) => false).contentRoot, isNull);
  });

  test('TC-LNK-33 relative or empty variables are ignored', () {
    expect(locateAppPaths(exeDir: exeDir, env: {'BUILDLOOP_WORKER': 'worker'}, exists: (_) => true).worker, '/opt/buildloop/bundle/worker');
    expect(locateAppPaths(exeDir: exeDir, env: {'BUILDLOOP_CONTENT_ROOT': ''}, exists: (_) => false).contentRoot, isNull);
  });

  test('TC-LNK-34 worker arguments carry only the discovered folders', () {
    final args = workerArgs(const AppPaths(worker: '/w', guideDir: '/g', contentRoot: '/c'));
    expect(args, ['--content-root=/c', '--guide-dir=/g']);
    expect(workerArgs(const AppPaths(worker: '/w')), isEmpty);
  });

  test('TC-LNK-35 in development builds worker and guide are discovered by walking up folders', () {
    const devExe = '/home/u/repo/apps/desktop/build/linux/x64/debug/intermediates_do_not_run';
    final fs = {
      '/home/u/repo/release/guide-build/worker',
      '/home/u/repo/release/guide-build/buildloop-guide.json',
      '/home/u/repo/content/labs',
    };
    final paths = locateAppPaths(exeDir: devExe, env: {}, exists: fs.contains);
    expect(paths.worker, '/home/u/repo/release/guide-build/worker');
    expect(paths.guideDir, '/home/u/repo/release/guide-build');
    expect(paths.contentRoot, '/home/u/repo/content/labs');
  });
}
