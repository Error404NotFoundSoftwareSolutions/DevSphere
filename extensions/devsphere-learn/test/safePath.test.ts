// Capability: CAP-COURSE-PLAYER. Rules: SEC-07, SEC-26.
// Implemented here: TC-SEC-03-01..05 path confinement, TC-LRN-10-01..03 lab file selection
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { safeResolve, selectLabFiles } from '../src/core/safePath';

function tmp(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'dsl-'));
}

test('TC-SEC-03-01 accepts a normal relative path inside the root', () => {
  const root = tmp();
  assert.equal(safeResolve(root, 'guide/01.md'), path.join(fs.realpathSync(root), 'guide', '01.md'));
});

test('TC-SEC-03-02 rejects traversal, absolute, empty and NUL paths', () => {
  const root = tmp();
  for (const bad of ['../x', 'a/../../x', '/etc/passwd', 'C:\\Windows\\x', '', 'a\0b', '..', 'a/../..']) {
    assert.throws(() => safeResolve(root, bad), /path/i, JSON.stringify(bad));
  }
});

test('TC-SEC-03-03 rejects a symlink that escapes the root', () => {
  const root = tmp();
  const outside = tmp();
  fs.writeFileSync(path.join(outside, 'secret.txt'), 'x');
  fs.symlinkSync(outside, path.join(root, 'link'));
  assert.throws(() => safeResolve(root, 'link/secret.txt'), /path/i);
});

test('TC-SEC-03-04 allows a symlink that stays inside the root', () => {
  const root = tmp();
  fs.mkdirSync(path.join(root, 'real'));
  fs.writeFileSync(path.join(root, 'real', 'a.txt'), 'x');
  fs.symlinkSync(path.join(root, 'real'), path.join(root, 'alias'));
  assert.doesNotThrow(() => safeResolve(root, 'alias/a.txt'));
});

test('TC-SEC-03-05 non-existing target inside root is allowed (for writes)', () => {
  const root = tmp();
  assert.doesNotThrow(() => safeResolve(root, 'new/dir/file.py'));
});

test('TC-LRN-10-01 lab copy plan includes learner files and maps starter to the root', () => {
  const plan = selectLabFiles([
    'lab.yaml', 'README.md', 'guide/01-setup.md', 'starter/hello.py', 'starter/pyproject.toml',
    'tests/visible/test_greet.py',
  ]);
  const targets = new Map(plan.map((p) => [p.from, p.to]));
  assert.equal(targets.get('starter/hello.py'), 'hello.py');
  assert.equal(targets.get('tests/visible/test_greet.py'), 'tests/visible/test_greet.py');
  assert.equal(targets.get('guide/01-setup.md'), '.devsphere/guide/01-setup.md');
});

test('TC-LRN-10-02 protected tests and reference solutions are never copied (SEC-04)', () => {
  const plan = selectLabFiles([
    'tests/protected/test_greet_edge.py', 'reference/hello.py', 'starter/reference/x.py',
    'starter/protected/x.py', 'tests/Protected/y.py', 'REFERENCE/z.py',
  ]);
  assert.deepEqual(plan, []);
});

test('TC-LRN-10-03 unknown files and traversal entries are ignored', () => {
  assert.deepEqual(selectLabFiles(['../evil', '/abs', 'other/file.txt', 'starter/../../x']), []);
});
