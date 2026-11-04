// Capability: CAP-COURSE-PLAYER. Rules: SEC-07, SEC-26.
// Implemented here: TC-SEC-03-01..05 path confinement
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { safeResolve } from '../src/core/safePath';

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
