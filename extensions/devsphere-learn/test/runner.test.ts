// Capability: CAP-COURSE-PLAYER. Rules: SEC-02, SEC-10, SEC-22, SEC-23, SEC-25.
// Implemented here: TC-SEC-04-01..03 invocation building, TC-SEC-10-01..04 limits, TC-SEC-06-01..02 redaction
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { buildPytestInvocation, minimalEnv, runLimited, summarisePytest } from '../src/core/runner';
import { redact } from '../src/core/redact';

const CORPUS = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../../../fixtures/secrets/corpus.json'), 'utf8')) as {
  secrets: { name: string; secret: string; text: string }[]; clean: { name: string; text: string }[];
};

function lab(): string {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'dsr-'));
  fs.mkdirSync(path.join(d, 'tests', 'visible'), { recursive: true });
  return d;
}

test('TC-SEC-04-01 invocation is executable + argument array, never a shell string', () => {
  const inv = buildPytestInvocation(lab(), 'python3');
  assert.equal(inv.file, 'python3');
  assert.ok(Array.isArray(inv.args));
  assert.deepEqual(inv.args.slice(0, 2), ['-m', 'pytest']);
  assert.ok(inv.args.every((a) => !/[;&|`$<>\n]/.test(a)), 'no shell metacharacters');
});

test('TC-SEC-04-02 python command must be on the allow-list (names only)', () => {
  for (const bad of ['/usr/bin/python3', 'python3; rm -rf ~', 'bash', '../python', '']) {
    assert.throws(() => buildPytestInvocation(lab(), bad), /python/i, bad);
  }
});

test('TC-SEC-04-03 test directory must exist inside the lab root', () => {
  const empty = fs.mkdtempSync(path.join(os.tmpdir(), 'dsr-'));
  assert.throws(() => buildPytestInvocation(empty, 'python3'), /tests/i);
});

test('TC-SEC-10-01 environment is minimal and carries no secrets', () => {
  const env = minimalEnv({ PATH: '/usr/bin', HOME: '/h', AWS_SECRET_ACCESS_KEY: 'x', GITHUB_TOKEN: 'y', OPENAI_API_KEY: 'z', LANG: 'C' });
  assert.deepEqual(Object.keys(env).sort(), ['HOME', 'LANG', 'PATH', 'PYTHONDONTWRITEBYTECODE', 'PYTHONNOUSERSITE']);
});

test('TC-SEC-10-02 runLimited kills a process that exceeds the timeout', async () => {
  const r = await runLimited(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { cwd: os.tmpdir(), env: {}, timeoutMs: 300, maxBytes: 1000 });
  assert.equal(r.timedOut, true);
});

test('TC-SEC-10-03 runLimited caps output and flags truncation', async () => {
  const r = await runLimited(process.execPath, ['-e', 'console.log("a".repeat(100000))'], { cwd: os.tmpdir(), env: {}, timeoutMs: 5000, maxBytes: 2000 });
  assert.equal(r.truncated, true);
  assert.ok(r.stdout.length <= 2000);
});

test('TC-SEC-10-04 runLimited does not use a shell (metacharacters are inert arguments)', async () => {
  const r = await runLimited(process.execPath, ['-e', 'console.log(process.argv[1])', '$(echo pwned); `id`'], { cwd: os.tmpdir(), env: {}, timeoutMs: 5000, maxBytes: 1000 });
  assert.match(r.stdout, /\$\(echo pwned\); `id`/);
});

test('TC-SEC-10-05 a missing executable is reported, not thrown', async () => {
  const r = await runLimited('definitely-not-a-real-binary', [], { cwd: os.tmpdir(), env: {}, timeoutMs: 1000, maxBytes: 100 });
  assert.equal(r.code, null);
  assert.match(r.error ?? '', /ENOENT|not found/i);
});

test('TC-SEC-06-01 redact removes every secret in the shared corpus', () => {
  for (const s of CORPUS.secrets) {
    const out = redact(s.text);
    assert.ok(!out.includes(s.secret), s.name);
    assert.match(out, /\[REDACTED/);
  }
});

test('TC-SEC-06-02 redact leaves clean text unchanged', () => {
  for (const c of CORPUS.clean) assert.equal(redact(c.text), c.text, c.name);
});

test('TC-LRN-50-01 pytest output is summarised in plain language', () => {
  assert.match(summarisePytest(0, '1 passed in 0.01s', ''), /passed/i);
  assert.match(summarisePytest(1, 'FAILED tests/visible/test_greet.py::test_greet_simple\nassert None == "Hello, Asha!"', ''), /did not pass/i);
  assert.match(summarisePytest(1, '', 'No module named pytest'), /pytest.*install/i);
  assert.match(summarisePytest(null, '', ''), /could not run/i);
});
