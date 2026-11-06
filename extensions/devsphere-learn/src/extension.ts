// Capability: CAP-COMPANION-EXT, CAP-COMPLETION. Rules: SEC-21..SEC-27, TRU-01, TRU-02, ADR-019. Tests: TC-CMP-13-xx
// Implemented here: VS Code glue for the DevPilot Guide. The guide is a webview VIEW in the Secondary Side
// Bar (the chat area, like Copilot Chat), never a tab in the editor area. In a lab folder it finds the app's
// private session, connects to the channel and renders the guide from the worker's events. It never runs the
// learner's code, stores progress or holds credentials: it only asks the app (Check my work, next step,
// finish) and shows what the app answers. Results are Practice; Verified is the app's job.
import fs from 'node:fs';
import * as vscode from 'vscode';
import { renderMarkdownSafe } from './core/markdown';
import { parseMessage } from './core/messages';
import { requests, type LabStateStep, type WorkerEvent } from './core/protocol';
import { safeResolve } from './core/safePath';
import { ChannelClient } from './host/channel';
import { defaultRuntimeDir, discoverSession } from './host/session';
import { clientScript, escapeHtml, newNonce, pageShell, renderCompletion, renderGuide, type GuideModel } from './ui/html';

const VIEW_ID = 'devpilot.guide';

interface Model {
  labTitle: string;
  steps: LabStateStep[];
  current: string;
  lastCheck: GuideModel['lastCheck'];
  finished: boolean;
  notice: string | undefined;
}

let log: vscode.OutputChannel;

class GuideView implements vscode.WebviewViewProvider {
  private view: vscode.WebviewView | undefined;
  private client: ChannelClient | undefined;
  private started = false;
  private readonly model: Model = { labTitle: 'DevPilot lab', steps: [], current: '', lastCheck: undefined, finished: false, notice: undefined };

  constructor(private readonly version: string) {}

  resolveWebviewView(view: vscode.WebviewView): void {
    this.view = view;
    view.webview.options = { enableScripts: true, enableCommandUris: false, localResourceRoots: [] };
    view.onDidDispose(() => { this.view = undefined; });
    view.webview.onDidReceiveMessage((raw: unknown) => this.onWebviewMessage(raw));
    this.render();
    void this.start();
  }

  dispose(): void { this.client?.close(); }

  private folder(): string | undefined { return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath; }

  private show(title: string, body: string): void {
    const v = this.view;
    if (!v) return;
    v.webview.html = pageShell({ title, body, nonce: newNonce(), cspSource: v.webview.cspSource, script: clientScript() });
  }

  private guideBody(folder: string): string {
    const m = this.model;
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
      current: step ? { id: step.id, title: step.title, contentHtml, showTitle: !contentHtml.trimStart().startsWith('<h1>') } : undefined,
      lastCheck: m.lastCheck,
      trusted: vscode.workspace.isTrusted && m.notice === undefined,
    };
    const notice = m.notice ? `<p class="result fail">${escapeHtml(m.notice)}</p>` : '';
    return notice + renderGuide(model);
  }

  render(): void {
    const folder = this.folder();
    const m = this.model;
    if (!folder) { this.show('Lab guide', '<p>Open a DevPilot lab folder to see its guide.</p>'); return; }
    if (m.finished && m.steps.length > 0 && m.steps.every((s) => s.state === 'pass')) {
      this.show('Lab complete', renderCompletion({
        labTitle: m.labTitle,
        skills: m.steps.map((s) => s.title),
        verification: 'unavailable',
        message: 'Go back to the DevPilot app to submit for a Verified result. Practice results alone do not earn a badge.',
        practicePassed: m.steps.length,
        total: m.steps.length,
      }));
    } else {
      this.show('Lab guide', this.guideBody(folder));
    }
  }

  async start(): Promise<void> {
    if (this.started) return;
    this.started = true;
    const folder = this.folder();
    if (!folder) return;
    const session = discoverSession(folder, defaultRuntimeDir());
    if (!session) {
      this.model.notice = 'DevPilot is not running for this lab. Open the lab again from the DevPilot app.';
      this.render();
      return;
    }
    const c = new ChannelClient(session, this.version);
    this.client = c;
    c.onEvent((e) => this.onEvent(e));
    c.onClose(() => { this.model.notice = 'The connection to DevPilot ended. Open the lab again from DevPilot.'; this.render(); });
    try {
      await c.connect();
      log.appendLine('connected to the DevPilot app');
      c.send(requests.getLabState());
    } catch (e) {
      this.model.notice = (e as Error).message;
      this.render();
    }
  }

  private onEvent(e: WorkerEvent): void {
    const m = this.model;
    if (e.type === 'labState') {
      m.labTitle = e.title; m.steps = e.steps; m.current = e.currentStepId;
    } else if (e.type === 'checkResult') {
      m.lastCheck = { passed: e.passed, output: `${e.summary}\n\n${e.output}`.trim(), kind: 'Practice' };
    } else if (e.type === 'error') {
      m.lastCheck = { passed: false, output: e.message, kind: 'Practice' };
    } else if (e.type === 'sessionClosed') {
      m.notice = 'The DevPilot app closed this lab session. Open the lab again from DevPilot.';
    }
    this.render();
  }

  private onWebviewMessage(raw: unknown): void {
    const msg = parseMessage(raw);
    const c = this.client;
    if (!msg) { log.appendLine('dropped invalid webview message'); return; }
    if (msg.type === 'openHome') { void vscode.commands.executeCommand('workbench.action.closeWindow'); return; }
    if (!c) return;
    try {
      if (msg.type === 'goStep') c.send(requests.goStep(msg.stepId));
      else if (msg.type === 'checkStep') { if (vscode.workspace.isTrusted) c.send(requests.runCheck(msg.stepId)); }
      else if (msg.type === 'finish') { this.model.finished = true; c.send(requests.finishLab()); }
    } catch (e) {
      this.model.notice = (e as Error).message;
      this.render();
    }
  }
}

export function activate(ctx: vscode.ExtensionContext): void {
  log = vscode.window.createOutputChannel('DevPilot Guide');
  const provider = new GuideView((ctx.extension.packageJSON as { version: string }).version);
  ctx.subscriptions.push(
    log,
    { dispose: () => provider.dispose() },
    vscode.window.registerWebviewViewProvider(VIEW_ID, provider, { webviewOptions: { retainContextWhenHidden: false } }),
    vscode.commands.registerCommand('devsphere.openGuide', () => void vscode.commands.executeCommand(`${VIEW_ID}.focus`)),
  );
  // In a lab folder, show the guide straight away (this opens the Secondary Side Bar).
  const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (folder) void vscode.commands.executeCommand(`${VIEW_ID}.focus`);
}

export function deactivate(): void { /* disposables are released through subscriptions */ }
