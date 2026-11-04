// Capability: CAP-COMPANION-EXT (ADR-019). Tests: TC-CMP-13-01..03
// Implemented here: the guide must live in the Secondary Side Bar (the chat area), never in the editor area
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const ROOT = path.resolve(__dirname, '../..');
const pkg = JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf8')) as Record<string, any>; // eslint-disable-line @typescript-eslint/no-explicit-any
const source = fs.readFileSync(path.join(ROOT, 'src/extension.ts'), 'utf8');

test('TC-CMP-13-01 the manifest contributes a view container to the Secondary Side Bar with one webview view', () => {
  const containers = pkg.contributes?.viewsContainers?.secondarySidebar as { id: string; title: string; icon: string }[];
  assert.equal(containers?.length, 1);
  assert.equal(containers[0]?.id, 'buildloop');
  const views = pkg.contributes?.views?.buildloop as { id: string; type: string }[];
  assert.equal(views?.length, 1);
  assert.equal(views[0]?.id, 'buildloop.guide');
  assert.equal(views[0]?.type, 'webview');
  assert.ok(fs.existsSync(path.join(ROOT, containers[0]!.icon)), 'icon file exists');
});

test('TC-CMP-13-02 the code registers a view provider and never opens a panel in the editor area', () => {
  assert.match(source, /const VIEW_ID = 'buildloop\.guide'/);
  assert.match(source, /registerWebviewViewProvider\(VIEW_ID/);
  assert.doesNotMatch(source, /createWebviewPanel/);
});

test('TC-CMP-13-03 the engine requirement matches the VS Code version this was verified on (1.144)', () => {
  assert.match(pkg.engines.vscode as string, /^\^1\.(1[4-9][0-9]|[2-9][0-9]{2})\.\d+$/);
});
