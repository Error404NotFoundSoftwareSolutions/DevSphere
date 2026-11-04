// Capability: CAP-COMPANION-EXT, CAP-COMPLETION. Rules: SEC-21, SEC-27, TRU-02.
// Tests: TC-SEC-05-01..06. Implemented here: webview pages. Every dynamic value is escaped; the page
// has a nonce-based CSP, no inline event handlers, no remote resources, no innerHTML.
import { randomBytes } from 'node:crypto';
import { escapeText } from '../core/escape';

export const escapeHtml = escapeText;

export function newNonce(): string {
  return randomBytes(16).toString('base64url');
}

export interface ShellInput {
  title: string;
  body: string;
  nonce: string;
  cspSource: string;
  script: string;
}

const STYLE = `
:root{color-scheme:light dark}
body{font-family:var(--vscode-font-family);color:var(--vscode-foreground);background:var(--vscode-editor-background);padding:16px 20px;line-height:1.5}
h1{font-size:1.5em;margin:.2em 0 .6em}h2{font-size:1.15em;margin:1.2em 0 .4em}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:12px}
.card{border:1px solid var(--vscode-panel-border);border-radius:6px;padding:12px;background:var(--vscode-sideBar-background)}
.muted{opacity:.75;font-size:.9em}
button{font:inherit;padding:6px 12px;border:0;border-radius:4px;cursor:pointer;color:var(--vscode-button-foreground);background:var(--vscode-button-background)}
button:hover{background:var(--vscode-button-hoverBackground)}
button[disabled]{opacity:.5;cursor:not-allowed}
button.link{background:none;color:var(--vscode-textLink-foreground);padding:2px 0;text-align:left}
.tag{display:inline-block;border:1px solid var(--vscode-panel-border);border-radius:10px;padding:0 8px;font-size:.8em;margin-right:6px}
progress{width:100%;height:8px}
.layout{display:grid;grid-template-columns:220px 1fr;gap:20px}@media(max-width:700px){.layout{grid-template-columns:1fr}}
ol.steps{list-style:none;padding:0;margin:0}ol.steps li{margin:4px 0}
pre{background:var(--vscode-textCodeBlock-background);padding:10px;border-radius:4px;overflow:auto;white-space:pre-wrap}
.result{border-left:4px solid var(--vscode-panel-border);padding:6px 12px;margin-top:12px}
.pass{border-color:var(--vscode-testing-iconPassed)}.fail{border-color:var(--vscode-testing-iconFailed)}
`;

const CLIENT_SCRIPT = `
const vscode = acquireVsCodeApi();
document.addEventListener('click', (event) => {
  const target = event.target instanceof Element ? event.target.closest('[data-action]') : null;
  if (!target || target.hasAttribute('disabled')) return;
  const action = target.getAttribute('data-action');
  const id = target.getAttribute('data-id');
  if (action === 'openCourse') vscode.postMessage({ type: 'openCourse', courseId: id });
  else if (action === 'checkStep') vscode.postMessage({ type: 'checkStep', stepId: id });
  else if (action === 'goStep') vscode.postMessage({ type: 'goStep', stepId: id });
  else if (action === 'openHome') vscode.postMessage({ type: 'openHome' });
  else if (action === 'finish') vscode.postMessage({ type: 'finish' });
});
`;

export function clientScript(): string {
  return CLIENT_SCRIPT;
}

export function pageShell(input: ShellInput): string {
  const { title, body, nonce, cspSource, script } = input;
  const csp = [
    "default-src 'none'",
    `img-src ${cspSource} data:`,
    `style-src ${cspSource} 'nonce-${nonce}'`,
    `script-src 'nonce-${nonce}'`,
  ].join('; ');
  return `<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="${csp}">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${escapeHtml(title)}</title>
<style nonce="${nonce}">${STYLE}</style></head>
<body>${body}
<script nonce="${nonce}">${script}</script></body></html>`;
}

// ---------- Guide ----------
export interface GuideModel {
  labTitle: string;
  steps: { id: string; title: string; state: 'todo' | 'pass' | 'fail'; current: boolean }[];
  current: { id: string; title: string; contentHtml: string } | undefined;
  lastCheck: { passed: boolean; output: string; kind: 'Practice' } | undefined;
  trusted: boolean;
}

const STEP_MARK = { todo: 'To do', pass: 'Passed', fail: 'Not yet' } as const;

export function renderGuide(m: GuideModel): string {
  const e = escapeHtml;
  const list = m.steps.map((s) => `<li><button class="link" data-action="goStep" data-id="${e(s.id)}">${s.current ? '> ' : ''}${e(s.title)}</button> <span class="muted">${STEP_MARK[s.state]}</span></li>`).join('');
  const allPass = m.steps.length > 0 && m.steps.every((s) => s.state === 'pass');
  const cur = m.current
    ? `<h1>${e(m.current.title)}</h1><div>${m.current.contentHtml}</div>
<p><button data-action="checkStep" data-id="${e(m.current.id)}"${m.trusted ? '' : ' disabled'}>Check my work</button></p>`
    : '<p>Select a step.</p>';
  const trust = m.trusted ? '' : '<p class="result fail">This folder is not trusted, so checks are turned off. Trust the folder to run them.</p>';
  const check = m.lastCheck
    ? `<div class="result ${m.lastCheck.passed ? 'pass' : 'fail'}"><strong>${e(m.lastCheck.kind)} result:</strong> ${m.lastCheck.passed ? 'passed' : 'not passed yet'}<pre>${e(m.lastCheck.output)}</pre></div>`
    : '';
  return `
<div class="muted">${e(m.labTitle)}</div>
<div class="layout"><nav><ol class="steps">${list}</ol>
<p><button data-action="finish"${allPass ? '' : ' disabled'}>Finish lab</button></p>
<p><button class="link" data-action="openHome">Back to Home</button></p></nav>
<main>${trust}${cur}${check}</main></div>`;
}

// ---------- Completion ----------
export interface CompletionModel {
  labTitle: string;
  skills: string[];
  verification: 'verified' | 'unavailable' | 'failed';
  message: string;
  practicePassed: number;
  total: number;
}

export function renderCompletion(m: CompletionModel): string {
  const e = escapeHtml;
  const badge = m.verification === 'verified'
    ? '<h2>Badge earned</h2><p>Your Verified result was accepted by the server.</p>'
    : '<h2>Badge pending verification</h2><p>You completed the practice checks. The badge is awarded after a Verified result from the server.</p>';
  const skills = m.skills.map((s) => `<li>${e(s)}</li>`).join('');
  return `
<h1>Destination reached: ${e(m.labTitle)}</h1>
<p>Practice checks passed: ${Number(m.practicePassed) || 0} of ${Number(m.total) || 0}</p>
${badge}
<p class="muted">${e(m.message)}</p>
<h2>Skills practised</h2><ul>${skills}</ul>
<p><button data-action="openHome">Back to Home</button></p>`;
}
