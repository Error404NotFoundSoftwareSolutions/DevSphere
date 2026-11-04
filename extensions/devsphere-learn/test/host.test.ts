// Capability: CAP-COURSE-PLAYER. Rules: SEC-04, SEC-06, SEC-07, SEC-26.
// Implemented here: TC-LRN-10-04..06 lab preparation on disk, TC-LRN-40-07..08 progress store
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { prepareLab, resolveLabsRoot } from '../src/host/labs';
import { ProgressStore } from '../src/host/store';
import { emptyProgress, recordPractice } from '../src/core/progress';

function tmp(): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'dsh-'));
}

function makeContent(): string {
  const root = tmp();
  const lab = path.join(root, 'demo-lab-001');
  const w = (rel: string, body: string): void => {
    fs.mkdirSync(path.dirname(path.join(lab, rel)), { recursive: true });
    fs.writeFileSync(path.join(lab, rel), body);
  };
  w('lab.yaml', 'id: demo-lab-001\n');
  w('README.md', '# demo');
  w('guide/01.md', '# one');
  w('starter/hello.py', 'def greet(n):\n    return None\n');
  w('tests/visible/test_a.py', 'def test_a(): pass\n');
  w('tests/protected/test_secret.py', 'SECRET_PROTECTED\n');
  w('reference/hello.py', 'REFERENCE_SOLUTION\n');
  return root;
}

test('TC-LRN-10-04 prepareLab copies learner files and never protected or reference files', () => {
  const content = makeContent();
  const labs = tmp();
  const { dest } = prepareLab(content, 'demo-lab-001', labs);
  assert.ok(fs.existsSync(path.join(dest, 'hello.py')));
  assert.ok(fs.existsSync(path.join(dest, 'tests/visible/test_a.py')));
  assert.ok(fs.existsSync(path.join(dest, '.devsphere/guide/01.md')));
  assert.ok(fs.existsSync(path.join(dest, '.devsphere/lab.yaml')));
  assert.ok(fs.existsSync(path.join(dest, '.devsphere/lab.json')));
  const all: string[] = [];
  const walk = (d: string): void => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) walk(p); else all.push(p); } };
  walk(dest);
  for (const f of all) {
    const body = fs.readFileSync(f, 'utf8');
    assert.ok(!body.includes('SECRET_PROTECTED') && !body.includes('REFERENCE_SOLUTION'), f);
  }
});

test('TC-LRN-10-05 prepareLab never overwrites the learner\'s work', () => {
  const content = makeContent();
  const labs = tmp();
  const { dest } = prepareLab(content, 'demo-lab-001', labs);
  fs.writeFileSync(path.join(dest, 'hello.py'), 'MY WORK');
  prepareLab(content, 'demo-lab-001', labs);
  assert.equal(fs.readFileSync(path.join(dest, 'hello.py'), 'utf8'), 'MY WORK');
});

test('TC-LRN-10-06 prepareLab rejects bad ids and skips symlinks in the bundle', () => {
  const content = makeContent();
  const labs = tmp();
  for (const bad of ['../x', 'a/b', '', 'Demo']) assert.throws(() => prepareLab(content, bad, labs));
  const outside = tmp();
  fs.writeFileSync(path.join(outside, 'leak.py'), 'LEAK');
  fs.symlinkSync(path.join(outside, 'leak.py'), path.join(content, 'demo-lab-001', 'starter', 'link.py'));
  const { dest } = prepareLab(content, 'demo-lab-001', labs);
  assert.ok(!fs.existsSync(path.join(dest, 'link.py')));
});

test('TC-LRN-10-07 labs root must be absolute and not the filesystem root', () => {
  assert.throws(() => resolveLabsRoot('relative/dir', '/home/u'));
  assert.throws(() => resolveLabsRoot('/', '/home/u'));
  assert.equal(resolveLabsRoot('', '/home/u'), path.join('/home/u', 'DevSphereLabs'));
  assert.equal(resolveLabsRoot('/data/labs', '/home/u'), '/data/labs');
});

test('TC-LRN-40-07 store round-trips progress atomically', () => {
  const dir = tmp();
  const store = new ProgressStore(dir);
  assert.deepEqual(store.load(), emptyProgress());
  const p = recordPractice(emptyProgress(), 'lab-one', 'a', 'pass', '2026-11-04T10:00:00.000Z');
  store.save(p);
  assert.deepEqual(new ProgressStore(dir).load(), p);
  assert.deepEqual(fs.readdirSync(dir).filter((f) => f.includes('.tmp')), []);
});

test('TC-LRN-40-08 store backs up and resets a corrupt or tampered file', () => {
  const dir = tmp();
  fs.writeFileSync(path.join(dir, 'progress.json'), '{"version":1,"labs":{"../x":{"steps":{}}}}');
  const store = new ProgressStore(dir);
  assert.deepEqual(store.load(), emptyProgress());
  assert.ok(fs.readdirSync(dir).some((f) => f.startsWith('progress.json.corrupt-')));
  fs.writeFileSync(path.join(dir, 'progress.json'), 'not json');
  assert.deepEqual(store.load(), emptyProgress());
});
