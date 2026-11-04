// Capability: CAP-HOME-DASHBOARD, CAP-COURSE-PLAYER, CAP-COMPLETION. Rules: SEC-21..SEC-27, TRU-01, TRU-02.
// Implemented here: VS Code glue. Home window shows the dashboard; "Start" prepares the lab folder and
// opens it in a NEW window, where the guide panel runs practice checks and shows the completion screen.
// All decisions live in src/core (unit tested); this file only wires them to the VS Code API.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import * as vscode from 'vscode';
import { parseCatalogue, type Catalogue } from './core/catalogue';
import { NotConfiguredGrader, type GraderClient } from './core/grader';
import { isId } from './core/ids';
import { renderMarkdownSafe } from './core/markdown';
import { parseLabManifest, type LabManifest } from './core/manifest';
import { parseMessage, type WebviewMessage } from './core/messages';
import { badgeState, labSummary, recordPractice, type Progress } from './core/progress';
import { redact } from './core/redact';
import { buildPytestInvocation, minimalEnv, runLimited, summarisePytest } from './core/runner';
import { safeResolve } from './core/safePath';
import { prepareLab, resolveLabsRoot } from './host/labs';
import { ProgressStore } from './host/store';
import {
  clientScript, newNonce, pageShell, renderCompletion, renderGuide, renderHome,
  type GuideModel, type HomeModel,
} from './ui/html';

let log: vscode.OutputChannel;
const grader: GraderClient = new NotConfiguredGrader();

function createPanel(id: string, title: string, column: vscode.ViewColumn): vscode.WebviewPanel {
  return vscode.window.createWebviewPanel(id, title, column, {
    enableScripts: true,
    enableCommandUris: false,
    localResourceRoots: [],
    retainContextWhenHidden: false,
  });
}

function show(panel: vscode.WebviewPanel, title: string, body: string): void {
  panel.webview.html = pageShell({ title, body, nonce: newNonce(), cspSource: panel.webview.cspSource, script: clientScript() });
}

function loadCatalogue(ctx: vscode.ExtensionContext): Catalogue {
  const file = path.join(ctx.extensionPath, 'data', 'catalogue.sample.json');
  return parseCatalogue(JSON.parse(fs.readFileSync(file, 'utf8')) as unknown);
}

function contentRoot(ctx: vscode.ExtensionContext): string {
  return path.resolve(ctx.extensionPath, '..', '..', 'content', 'labs');
}

function readManifest(root: string, labId: string): LabManifest | undefined {
  try {
    return parseLabManifest(fs.readFileSync(safeResolve(root, `${labId}/lab.yaml`), 'utf8'));
  } catch {
    return undefined;
  }
}

// ---------------------------------------------------------------- Home
function buildHomeModel(ctx: vscode.ExtensionContext, progress: Progress): HomeModel {
  const cat = loadCatalogue(ctx);
  const root = contentRoot(ctx);
  const stepIds = new Map<string, string[]>();
  for (const c of cat.courses) {
    const m = c.available ? readManifest(root, c.id) : undefined;
    if (m) stepIds.set(c.id, m.steps.map((s) => s.id));
  }
  const status = (id: string): { status: 'not-started' | 'in-progress' | 'completed'; percent: number } => {
    const ids = stepIds.get(id) ?? [];
    const s = labSummary(progress, id, ids);
    if (s.total === 0 || s.passed === 0) return { status: 'not-started', percent: 0 };
    return { status: s.complete ? 'completed' : 'in-progress', percent: Math.round((s.passed / s.total) * 100) };
  };
  const done = (id: string): boolean => status(id).status === 'completed';
  return {
    learner: cat.learner,
    weeklyGoal: { target: cat.weeklyGoalTarget, done: cat.courses.filter((c) => done(c.id)).length },
    courses: cat.courses.map((c) => ({ ...c, ...status(c.id) })),
    roadmap: { title: cat.roadmap.title, steps: cat.roadmap.steps.map((s) => ({ ...s, done: done(s.courseId) })) },
    badges: cat.badges.map((b) => ({ id: b.id, title: b.title, state: badgeState(progress, b.courseId, stepIds.get(b.courseId) ?? []) })),
  };
}

let homePanel: vscode.WebviewPanel | undefined;

function openHome(ctx: vscode.ExtensionContext, store: ProgressStore): void {
  const render = (): void => {
    if (homePanel) show(homePanel, 'DevSphere Home', renderHome(buildHomeModel(ctx, store.load())));
  };
  if (homePanel) {
    homePanel.reveal();
    render();
    return;
  }
  homePanel = createPanel('devsphere.home', 'DevSphere Home', vscode.ViewColumn.One);
  homePanel.onDidDispose(() => { homePanel = undefined; });
  homePanel.webview.onDidReceiveMessage((raw: unknown) => {
    const msg = parseMessage(raw);
    if (!msg) { log.appendLine('dropped invalid webview message'); return; }
    if (msg.type === 'openCourse') void startCourse(ctx, msg.courseId);
    else if (msg.type === 'openHome') render();
  });
  // Lab windows are separate windows; refresh Home whenever it regains focus so new progress shows.
  ctx.subscriptions.push(vscode.window.onDidChangeWindowState((s) => { if (s.focused) render(); }));
  render();
}

async function startCourse(ctx: vscode.ExtensionContext, courseId: string): Promise<void> {
  try {
    const course = loadCatalogue(ctx).courses.find((c) => c.id === courseId);
    if (!course || !course.available) throw new Error('This course is not available yet');
    const cfg = vscode.workspace.getConfiguration('devsphere');
    const labsRoot = resolveLabsRoot(cfg.get<string>('labsFolder', ''), os.homedir());
    const { dest } = prepareLab(contentRoot(ctx), course.id, labsRoot);
    log.appendLine(`lab prepared: ${course.id}`);
    await vscode.commands.executeCommand('vscode.openFolder', vscode.Uri.file(dest), { forceNewWindow: true });
  } catch (e) {
    void vscode.window.showErrorMessage(`Could not start the course. ${(e as Error).message}`);
  }
}

// ---------------------------------------------------------------- Lab guide (lab window)
interface LabSession {
  root: string;
  manifest: LabManifest;
  current: string;
  lastCheck: GuideModel['lastCheck'];
}

function readLabSession(root: string): LabSession | undefined {
  try {
    const marker = JSON.parse(fs.readFileSync(safeResolve(root, '.devsphere/lab.json'), 'utf8')) as { labId?: unknown };
    if (!isId(marker.labId)) return undefined;
    const manifest = parseLabManifest(fs.readFileSync(safeResolve(root, '.devsphere/lab.yaml'), 'utf8'));
    if (manifest.id !== marker.labId) return undefined;
    return { root, manifest, current: manifest.steps[0]?.id ?? '', lastCheck: undefined };
  } catch {
    return undefined;
  }
}

function guideModel(s: LabSession, progress: Progress): GuideModel {
  const rec = progress.labs[s.manifest.id]?.steps ?? {};
  const step = s.manifest.steps.find((x) => x.id === s.current);
  let contentHtml = '';
  if (step) {
    try {
      contentHtml = renderMarkdownSafe(fs.readFileSync(safeResolve(s.root, `.devsphere/${step.contentRef}`), 'utf8'));
    } catch {
      contentHtml = '<p>This step could not be loaded.</p>';
    }
  }
  return {
    labTitle: s.manifest.title,
    steps: s.manifest.steps.map((x) => ({
      id: x.id, title: x.title, current: x.id === s.current,
      state: rec[x.id]?.practice === 'pass' ? 'pass' : rec[x.id]?.practice === 'fail' ? 'fail' : 'todo',
    })),
    current: step ? { id: step.id, title: step.title, contentHtml } : undefined,
    lastCheck: s.lastCheck,
    trusted: vscode.workspace.isTrusted,
  };
}

async function checkStep(s: LabSession, stepId: string, store: ProgressStore): Promise<void> {
  const step = s.manifest.steps.find((x) => x.id === stepId);
  if (!step) return;
  if (!vscode.workspace.isTrusted) {
    s.lastCheck = { passed: false, output: 'Trust this folder to run checks.', kind: 'Practice' };
    return;
  }
  let passed = true;
  let output = 'Marked as done.';
  if (step.practiceCheck) {
    try {
      const py = vscode.workspace.getConfiguration('devsphere').get<string>('pythonCommand', 'python3');
      const inv = buildPytestInvocation(s.root, py);
      const r = await runLimited(inv.file, inv.args, { cwd: inv.cwd, env: minimalEnv(process.env), timeoutMs: 30_000, maxBytes: 64 * 1024 });
      passed = r.code === 0 && !r.timedOut;
      const detail = r.timedOut ? 'The check took too long and was stopped.' : redact(`${r.stdout}\n${r.stderr}`.trim()).slice(0, 4000);
      output = `${summarisePytest(r.code, r.stdout, r.stderr)}\n\n${detail}`;
    } catch (e) {
      passed = false;
      output = (e as Error).message;
    }
  }
  s.lastCheck = { passed, output, kind: 'Practice' };
  store.save(recordPractice(store.load(), s.manifest.id, step.id, passed ? 'pass' : 'fail', new Date().toISOString()));
  log.appendLine(`practice check: ${s.manifest.id}/${step.id} ${passed ? 'pass' : 'fail'}`);
}

let guidePanel: vscode.WebviewPanel | undefined;

function openGuide(store: ProgressStore): void {
  const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  const session = folder ? readLabSession(folder) : undefined;
  if (!session) {
    void vscode.window.showInformationMessage('Open a DevSphere lab folder first (start a course from DevSphere Home).');
    return;
  }
  if (guidePanel) { guidePanel.reveal(); return; }
  const panel = createPanel('devsphere.guide', `Guide: ${session.manifest.title}`, vscode.ViewColumn.Beside);
  guidePanel = panel;
  panel.onDidDispose(() => { guidePanel = undefined; });
  const render = (): void => show(panel, 'Lab guide', renderGuide(guideModel(session, store.load())));
  panel.webview.onDidReceiveMessage((raw: unknown) => {
    const msg: WebviewMessage | undefined = parseMessage(raw);
    if (!msg) { log.appendLine('dropped invalid webview message'); return; }
    void handleGuideMessage(msg, session, store, panel, render);
  });
  render();
}

async function handleGuideMessage(msg: WebviewMessage, s: LabSession, store: ProgressStore, panel: vscode.WebviewPanel, render: () => void): Promise<void> {
  if (msg.type === 'goStep' && s.manifest.steps.some((x) => x.id === msg.stepId)) {
    s.current = msg.stepId; s.lastCheck = undefined; render();
  } else if (msg.type === 'checkStep') {
    await checkStep(s, msg.stepId, store); render();
  } else if (msg.type === 'finish') {
    const ids = s.manifest.steps.map((x) => x.id);
    const summary = labSummary(store.load(), s.manifest.id, ids);
    if (!summary.complete) return;
    const outcome = await grader.submit(s.manifest.id);
    show(panel, 'Lab complete', renderCompletion({
      labTitle: s.manifest.title,
      skills: s.manifest.steps.map((x) => x.title),
      verification: outcome.status === 'verified' ? 'verified' : outcome.status === 'failed' ? 'failed' : 'unavailable',
      message: outcome.message,
      practicePassed: summary.passed,
      total: summary.total,
    }));
  } else if (msg.type === 'openHome') {
    // Closing the lab window returns the learner to the Home window, which refreshes on focus.
    await vscode.commands.executeCommand('workbench.action.closeWindow');
  }
}

// ---------------------------------------------------------------- activation
export function activate(ctx: vscode.ExtensionContext): void {
  log = vscode.window.createOutputChannel('DevSphere');
  ctx.subscriptions.push(log);
  const store = new ProgressStore(ctx.globalStorageUri.fsPath);
  ctx.subscriptions.push(
    vscode.commands.registerCommand('devsphere.openHome', () => openHome(ctx, store)),
    vscode.commands.registerCommand('devsphere.openGuide', () => openGuide(store)),
  );
  const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (folder && readLabSession(folder)) openGuide(store);
  else if (!folder) openHome(ctx, store);
}

export function deactivate(): void {
  /* nothing to clean up: panels and the output channel are disposed through subscriptions */
}
