// Capability: CAP-HOME-DASHBOARD. Rules: SEC-06. Tests: TC-LRN-41-01.
// Implemented here: validation of the course catalogue (bundled sample now, server data later).
import { isId, isPlainText } from './ids';

export class CatalogueError extends Error {
  constructor(reason: string) {
    super(`Invalid catalogue: ${reason}`);
    this.name = 'CatalogueError';
  }
}

export interface CatalogueCourse {
  id: string;
  title: string;
  topic: string;
  minutes: number;
  level: 'beginner' | 'intermediate' | 'professional';
  available: boolean;
}
export interface Catalogue {
  learner: string;
  weeklyGoalTarget: number;
  courses: CatalogueCourse[];
  roadmap: { title: string; steps: { courseId: string; title: string }[] };
  badges: { id: string; title: string; courseId: string }[];
}

const LEVELS = ['beginner', 'intermediate', 'professional'] as const;

function rec(v: unknown, what: string): Record<string, unknown> {
  if (typeof v !== 'object' || v === null || Array.isArray(v)) throw new CatalogueError(what);
  return v as Record<string, unknown>;
}
function list(v: unknown, what: string, max: number): unknown[] {
  if (!Array.isArray(v) || v.length > max) throw new CatalogueError(what);
  return v;
}
function text(v: unknown, what: string, max: number): string {
  if (!isPlainText(v, max)) throw new CatalogueError(what);
  return v;
}
function id(v: unknown, what: string): string {
  if (!isId(v)) throw new CatalogueError(what);
  return v;
}

export function parseCatalogue(raw: unknown): Catalogue {
  const r = rec(raw, 'root');
  if (r.version !== 1) throw new CatalogueError('version');
  const goal = rec(r.weeklyGoal, 'weeklyGoal');
  const target = goal.target;
  if (typeof target !== 'number' || !Number.isInteger(target) || target < 1 || target > 50) throw new CatalogueError('weeklyGoal.target');
  const courses = list(r.courses, 'courses', 100).map((c): CatalogueCourse => {
    const o = rec(c, 'course');
    const level = LEVELS.find((l) => l === o.level);
    const minutes = o.minutes;
    if (!level || typeof o.available !== 'boolean') throw new CatalogueError('course level/available');
    if (typeof minutes !== 'number' || !Number.isInteger(minutes) || minutes < 1 || minutes > 1000) throw new CatalogueError('course minutes');
    return { id: id(o.id, 'course id'), title: text(o.title, 'course title', 120), topic: text(o.topic, 'course topic', 60), minutes, level, available: o.available };
  });
  const rm = rec(r.roadmap, 'roadmap');
  const steps = list(rm.steps, 'roadmap steps', 50).map((s) => {
    const o = rec(s, 'roadmap step');
    return { courseId: id(o.courseId, 'roadmap courseId'), title: text(o.title, 'roadmap step title', 120) };
  });
  const badges = list(r.badges, 'badges', 100).map((b) => {
    const o = rec(b, 'badge');
    return { id: id(o.id, 'badge id'), title: text(o.title, 'badge title', 80), courseId: id(o.courseId, 'badge courseId') };
  });
  return {
    learner: text(r.learner, 'learner', 60),
    weeklyGoalTarget: target,
    courses,
    roadmap: { title: text(rm.title, 'roadmap title', 120), steps },
    badges,
  };
}
