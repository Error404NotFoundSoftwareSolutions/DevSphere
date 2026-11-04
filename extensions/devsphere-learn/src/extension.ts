// Capability: CAP-COMPANION-EXT, CAP-COMPLETION. Rules: SEC-21..SEC-27, TRU-01, TRU-02, ADR-019
// Implemented here: VS Code glue for the BuildLoop Guide. In a lab folder it finds the app's private
// session, connects to the channel and shows the guide panel from the worker's events. It never runs
// the learner's code, stores progress or holds credentials: it only asks the app (Check my work, next
// step, finish) and shows what the app answers. Results are Practice; Verified is the app's job.
import fs from 'node:fs';
import * as vscode from 'vscode';
import { renderMarkdownSafe } from './core/markdown';
import { parseMessage } from './core/messages';
import { requests, type LabStateStep, type WorkerEvent } from './core/protocol';
import { safeResolve } from './core/safePath';
import { ChannelClient } from './host/channel';
import { defaultRuntimeDir, discoverSession } from './host/session';
import { clientScript, escapeHtml, newNonce, pageShell, renderCompletion, renderGuide, type GuideModel } from './ui/html';

interface Model {
  labTitle: string;
  steps: LabStateStep[];
  current: string;
  lastCheck: GuideModel['lastCheck'];
  finished: boolean;
  notice: string | undefined;
}

let log: vscode.OutputChannel;
let panel: vscode.WebviewPanel | undefined;
let client: ChannelClient | undefined;

function show(p: vscode.WebviewPanel, title: string, body: string): void {
  p.webview.html = pageShell({ title, body, nonce: newNonce(), cspSource: p.webview.cspSource, script: clientScript() });
}

function guideBody(folder: string, m: Model): string {
  const step = m.steps.find((s) => s.id === m.current);
  let contentHtml = '<p>This step could not be loaded.</p>';
  if (step) {
    try {
      contentHtml = renderMarkdownSafe(fs.readFileSync(safeResolve(folder, `.devsphere/${step.contentRef}`), 'utf8'));
    } catch { /* keep the plain fallback */ }
  }
  const model: GuideModel = {
    labTitle: m.labTitle,
    steps: m.steps.map((s) => ({ id: s.id, title: s.title, state: s.state, current: s.id === m.current })),
    current: step ? { id: step.id, title: step.title, contentHtml } : undefined,
    lastCheck: m.lastCheck,
    trusted: vscode.workspace.isTrusted && m.notice === undefined,
  };
  const notice = m.notice ? `<p class="result fail">${escapeHtml(m.notice)}</p>` : '';
  return notice + renderGuide(model);
}

async function start(ctx: vscode.ExtensionContext): Promise<void> {
  const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!folder) return;
  if (panel) { panel.reveal(); return; }
  const session = discoverSession(folder, defaultRuntimeDir());
  const model: Model = { labTitle: 'BuildLoop lab', steps: [], current: '', lastCheck: undefined, finished: false, notice: undefined };
  const p = vscode.window.createWebviewPanel('buildloop.guide', 'BuildLoop Guide', { viewColumn: vscode.ViewColumn.Beside, preserveFocus: true }, {
    enableScripts: true, enableCommandUris: false, localResourceRoots: [], retainContextWhenHidden: false,
  });
  panel = p;
  p.onDidDispose(() => { panel = undefined; client?.close(); client = undefined; });
  const render = (): void => {
    if (model.finished && model.steps.length > 0 && model.steps.every((s) => s.state === 'pass')) {
      show(p, 'Lab complete', renderCompletion({
        labTitle: model.labTitle,
        skills: model.steps.map((s) => s.title),
        verification: 'unavailable',
        message: 'Go back to the BuildLoop app to submit for a Verified result. Practice results alone do not earn a badge.',
        practicePassed: model.steps.length,
        total: model.steps.length,
      }));
    } else {
      show(p, 'Lab guide', guideBody(folder, model));
    }
  };
  if (!session) {
    model.notice = 'BuildLoop is not running for this lab. Open the lab again from the BuildLoop app.';
    render();
    return;
  }
  const version = (ctx.extension.packageJSON as { version: string }).version;
  const c = new ChannelClient(session, version);
  client = c;
  const onEvent = (e: WorkerEvent): void => {
    if (e.type === 'labState') {
      model.labTitle = e.title; model.steps = e.steps; model.current = e.currentStepId;
    } else if (e.type === 'checkResult') {
      model.lastCheck = { passed: e.passed, output: `${e.summary}\n\n${e.output}`.trim(), kind: 'Practice' };
    } else if (e.type === 'error') {
      model.lastCheck = { passed: false, output: e.message, kind: 'Practice' };
    } else if (e.type === 'sessionClosed') {
      model.notice = 'The BuildLoop app closed this lab session. Open the lab again from BuildLoop.';
    }
    render();
  };
  c.onEvent(onEvent);
  c.onClose(() => { model.notice = 'The connection to BuildLoop ended. Open the lab again from BuildLoop.'; render(); });
  try {
    await c.connect();
    log.appendLine('connected to the BuildLoop app');
    c.send(requests.getLabState());
  } catch (e) {
    model.notice = (e as Error).message;
    render();
  }
  p.webview.onDidReceiveMessage((raw: unknown) => {
    const msg = parseMessage(raw);
    if (!msg) { log.appendLine('dropped invalid webview message'); return; }
    try {
      if (msg.type === 'goStep') c.send(requests.goStep(msg.stepId));
      else if (msg.type === 'checkStep') { if (vscode.workspace.isTrusted) c.send(requests.runCheck(msg.stepId)); }
      else if (msg.type === 'finish') { model.finished = true; c.send(requests.finishLab()); }
      else if (msg.type === 'openHome') void vscode.commands.executeCommand('workbench.action.closeWindow');
    } catch (e) {
      model.notice = (e as Error).message;
      render();
    }
  });
  render();
}

export function activate(ctx: vscode.ExtensionContext): void {
  log = vscode.window.createOutputChannel('BuildLoop Guide');
  ctx.subscriptions.push(log, vscode.commands.registerCommand('devsphere.openGuide', () => void start(ctx)));
  void start(ctx);
}

export function deactivate(): void {
  client?.close();
}
