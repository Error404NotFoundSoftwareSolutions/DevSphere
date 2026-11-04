// Capability: CAP-HOME-DASHBOARD, CAP-COURSE-PLAYER, CAP-COMPLETION. Rules: SEC-21, SEC-27.
// Implemented here: TC-SEC-05-01..06 webview HTML safety, TC-LRN-30-01..02 safe markdown
import assert from 'node:assert/strict';
import test from 'node:test';
import { escapeHtml, newNonce, pageShell, renderCompletion, renderGuide } from '../src/ui/html';
import { renderMarkdownSafe } from '../src/core/markdown';

const XSS = [
  '<script>alert(1)</script>', '"><img src=x onerror=alert(1)>', "' onmouseover='alert(1)",
  '<svg onload=alert(1)>', 'javascript:alert(1)', '</style><script>x</script>',
];

test('TC-SEC-05-01 escapeHtml neutralises markup characters', () => {
  assert.equal(escapeHtml(`<a href="x">&'</a>`), '&lt;a href=&quot;x&quot;&gt;&amp;&#39;&lt;/a&gt;');
});

test('TC-SEC-05-02 nonce is random, long and url-safe', () => {
  const a = newNonce(); const b = newNonce();
  assert.notEqual(a, b);
  assert.match(a, /^[A-Za-z0-9_-]{22,}$/);
});

test('TC-SEC-05-03 shell has strict CSP with nonce and no unsafe sources', () => {
  const html = pageShell({ title: 'T', body: '<p>x</p>', nonce: 'abc', cspSource: 'vscode-webview://x', script: 'void 0;' });
  const csp = /Content-Security-Policy" content="([^"]+)"/.exec(html)?.[1] ?? '';
  assert.match(csp, /default-src 'none'/);
  assert.match(csp, /script-src 'nonce-abc'/);
  assert.doesNotMatch(csp, /unsafe-|https?:|\*/);
  assert.match(html, /<script nonce="abc">/);
  assert.doesNotMatch(html, / on[a-z]+=/i);
});

function assertSafe(html: string, payload: string): void {
  if (/[<>"']/.test(payload)) assert.ok(!html.includes(payload), `raw payload present: ${payload}`);
  assert.doesNotMatch(html, /<(script|img|svg|iframe|style)\b/i, payload);
}

test('TC-SEC-05-05 guide and completion views escape dynamic fields and label Practice', () => {
  for (const x of XSS) {
    const g = renderGuide({
      labTitle: x, steps: [{ id: 'a', title: x, state: 'todo', current: true }],
      current: { id: 'a', title: x, contentHtml: renderMarkdownSafe(x) },
      lastCheck: { passed: false, output: x, kind: 'Practice' }, trusted: true,
    });
    const c = renderCompletion({ labTitle: x, skills: [x], verification: 'unavailable', message: x, practicePassed: 1, total: 1 });
    for (const html of [g, c]) assertSafe(html, x);
  }
  const g = renderGuide({ labTitle: 'L', steps: [], current: undefined, lastCheck: { passed: true, output: 'ok', kind: 'Practice' }, trusted: true });
  assert.match(g, /Practice/);
});

test('TC-SEC-05-06 completion never claims a badge without Verified result (TRU-01/02)', () => {
  const c = renderCompletion({ labTitle: 'L', skills: ['s'], verification: 'unavailable', message: 'm', practicePassed: 1, total: 1 });
  assert.match(c, /pending verification/i);
  assert.doesNotMatch(c, /badge earned/i);
  const v = renderCompletion({ labTitle: 'L', skills: ['s'], verification: 'verified', message: 'm', practicePassed: 1, total: 1 });
  assert.match(v, /badge earned/i);
});

test('TC-LRN-30-01 markdown renders text, code and headings but never raw HTML', () => {
  const html = renderMarkdownSafe('<!-- c -->\n# Title\n\nHello **bold** `code` <b>raw</b>\n\n```python\nprint("<x>")\n```\n');
  assert.match(html, /<h1>Title<\/h1>/);
  assert.match(html, /<strong>bold<\/strong>/);
  assert.match(html, /<code>code<\/code>/);
  assert.match(html, /&lt;b&gt;raw&lt;\/b&gt;/);
  assert.match(html, /<pre><code>print\(&quot;&lt;x&gt;&quot;\)\n<\/code><\/pre>/);
  assert.doesNotMatch(html, /<!--|<b>/);
});

test('TC-LRN-30-02 markdown links are shown as inert text', () => {
  const html = renderMarkdownSafe('[click](javascript:alert(1)) and [ok](https://example.com)');
  assert.doesNotMatch(html, /<a |href=/i);
  assert.match(html, /click/);
});
