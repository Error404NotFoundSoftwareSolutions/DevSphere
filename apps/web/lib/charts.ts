// Deterministic chart data and smooth paths for the dashboard preview (the same numbers on every render).
export function series(n: number, seed: number, base: number, amp: number, trend: number): number[] {
  let s = seed * 7919 + 13;
  const r = () => ((s = (s * 9301 + 49297) % 233280) / 233280);
  return Array.from({ length: n }, (_, i) => base + (trend * i) / (n - 1) + Math.sin(i * 0.9 + seed) * amp * 0.5 + (r() - 0.5) * amp);
}

export type Pt = [number, number];

/** A smooth cubic path: each segment from q to p uses control points (mid-x, q.y) and (mid-x, p.y). */
export function smooth(pts: Pt[]): string {
  let d = `M${pts[0][0].toFixed(2)} ${pts[0][1].toFixed(2)}`;
  for (let i = 1; i < pts.length; i++) {
    const q = pts[i - 1], p = pts[i];
    const mx = (q[0] + p[0]) / 2;
    d += ` C${mx.toFixed(2)} ${q[1].toFixed(2)} ${mx.toFixed(2)} ${p[1].toFixed(2)} ${p[0].toFixed(2)} ${p[1].toFixed(2)}`;
  }
  return d;
}

export function sparkline(vals: number[]): { line: string; area: string } {
  const min = Math.min(...vals), max = Math.max(...vals);
  const pts: Pt[] = vals.map((v, i) => [(i * 200) / (vals.length - 1), 28 - ((v - min) / Math.max(1e-6, max - min)) * 24]);
  const line = smooth(pts);
  return { line, area: `${line} L200 30 L0 30 Z` };
}

export function areaChart(a: number[], b: number[]) {
  const max = Math.max(...a, ...b) + 10;
  const mk = (vals: number[]): Pt[] => vals.map((v, i) => [(i * 600) / (vals.length - 1), 190 - 12 - (v / max) * 160]);
  const pa = mk(a), pb = mk(b);
  const la = smooth(pa), lb = smooth(pb);
  return { la, lb, aa: `${la} L600 190 L0 190 Z`, ab: `${lb} L600 190 L0 190 Z`, marker: pa[22] };
}
