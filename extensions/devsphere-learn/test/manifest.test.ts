// Capability: CAP-COURSE-PLAYER. Rules: SEC-06, SEC-26, SEC-27.
// Implemented here: TC-LRN-20-01..07 lab manifest validation (untrusted input)
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { parseLabManifest } from '../src/core/manifest';

const REAL = path.resolve(__dirname, '../../../../content/labs/python-hello-001/lab.yaml');

const base = `
schema_version: 1
id: python-hello-001
version: 1.0.0
title: Hello, Python
description: Write your first function.
difficulty: beginner
estimated_minutes: 45
guide:
  steps:
    - id: setup
      title: Open the starter file
      content_ref: guide/01-setup.md
    - id: greet
      title: Write greet
      content_ref: guide/02-greet.md
      practice_check: visible-greet
`;

test('TC-LRN-20-01 parses the real sample lab', () => {
  const m = parseLabManifest(fs.readFileSync(REAL, 'utf8'));
  assert.equal(m.id, 'python-hello-001');
  assert.equal(m.steps.length, 2);
  assert.equal(m.steps[1]?.practiceCheck, 'visible-greet');
});

test('TC-LRN-20-02 rejects bad ids', () => {
  for (const id of ['../x', 'A B', 'x', 'a'.repeat(80), '']) {
    assert.throws(() => parseLabManifest(base.replace('python-hello-001', id)), /manifest/i, id);
  }
});

test('TC-LRN-20-03 rejects content_ref traversal, absolute and non-markdown', () => {
  for (const ref of ['../../etc/passwd', '/etc/passwd', 'guide/a.sh', 'guide/../../a.md']) {
    assert.throws(() => parseLabManifest(base.replace('guide/02-greet.md', ref)), /manifest/i, ref);
  }
});

test('TC-LRN-20-04 rejects control characters and oversize titles', () => {
  assert.throws(() => parseLabManifest(base.replace('Hello, Python', '"Hi\\u0007"')), /manifest/i);
  assert.throws(() => parseLabManifest(base.replace('Hello, Python', 'x'.repeat(200))), /manifest/i);
});

test('TC-LRN-20-05 rejects oversize input and too many steps', () => {
  assert.throws(() => parseLabManifest('a: ' + 'x'.repeat(70_000)), /manifest/i);
  const many = Array.from({ length: 60 }, (_, i) => `    - {id: s${i}, title: t, content_ref: guide/${i}.md}`).join('\n');
  assert.throws(() => parseLabManifest(base.split('  steps:')[0] + '  steps:\n' + many), /manifest/i);
});

test('TC-LRN-20-06 rejects YAML aliases and non-mapping documents', () => {
  assert.throws(() => parseLabManifest('a: &x [1]\nb: *x\n'), /manifest/i);
  assert.throws(() => parseLabManifest('- a\n- b\n'), /manifest/i);
  assert.throws(() => parseLabManifest('::: not yaml :::\n\t- ['), /manifest/i);
});

test('TC-LRN-20-07 duplicate step ids are rejected', () => {
  assert.throws(() => parseLabManifest(base.replace('id: greet', 'id: setup')), /manifest/i);
});
