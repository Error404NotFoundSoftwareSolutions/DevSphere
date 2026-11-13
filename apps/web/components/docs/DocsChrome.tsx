"use client";

// The frame around every docs page: top bar with search, the sidebar (a drawer on phones), and the content.
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { links } from "@/lib/assets";

export type NavSection = { title: string; items: { title: string; href: string }[] };
type Entry = { title: string; href: string; section: string; text: string };
type Hit = { title: string; href: string; section: string; snippet: string };

function search(index: Entry[], q: string): Hit[] {
  const tokens = q.toLowerCase().split(/\s+/).filter(Boolean);
  if (!tokens.length) return [];
  const hits: (Hit & { score: number })[] = [];
  for (const e of index) {
    const title = e.title.toLowerCase();
    const text = e.text.toLowerCase();
    if (!tokens.every((t) => title.includes(t) || text.includes(t))) continue;
    let score = 0;
    for (const t of tokens) score += (title.includes(t) ? 12 : 0) + Math.min(6, text.split(t).length - 1);
    const at = Math.max(0, text.indexOf(tokens[0]!));
    const from = Math.max(0, at - 40);
    const snippet = (from > 0 ? "…" : "") + e.text.slice(from, from + 150) + (from + 150 < e.text.length ? "…" : "");
    hits.push({ title: e.title, href: e.href, section: e.section, snippet, score });
  }
  return hits.sort((a, b) => b.score - a.score).slice(0, 8);
}

export default function DocsChrome({ nav, children }: { nav: NavSection[]; children: React.ReactNode }) {
  const pathname = usePathname().replace(/\/$/, "") || "/";
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [focus, setFocus] = useState(false);
  const [index, setIndex] = useState<Entry[] | null>(null);
  const input = useRef<HTMLInputElement>(null);

  useEffect(() => setOpen(false), [pathname]);

  // copy buttons on code blocks, and "/" focuses the search
  useEffect(() => {
    const click = (e: MouseEvent) => {
      const btn = (e.target as HTMLElement).closest<HTMLButtonElement>(".code-copy");
      if (!btn) return;
      const code = btn.closest(".dcode")?.querySelector("code")?.textContent ?? "";
      navigator.clipboard?.writeText(code).then(() => {
        btn.textContent = "Copied";
        window.setTimeout(() => (btn.textContent = "Copy"), 1500);
      }).catch(() => undefined);
    };
    const key = (e: KeyboardEvent) => {
      const tag = (e.target as HTMLElement).tagName;
      if (e.key === "/" && tag !== "INPUT" && tag !== "TEXTAREA") { e.preventDefault(); input.current?.focus(); }
      if (e.key === "Escape") { setFocus(false); input.current?.blur(); }
    };
    document.addEventListener("click", click);
    document.addEventListener("keydown", key);
    return () => { document.removeEventListener("click", click); document.removeEventListener("keydown", key); };
  }, []);

  const load = () => {
    if (index) return;
    fetch("/docs/search-index.json").then((r) => r.json()).then(setIndex).catch(() => setIndex([]));
  };
  const hits = index && q.trim() ? search(index, q) : [];

  return (
    <div className="docs-root">
      <header className="docs-top">
        <button type="button" className="docs-burger" aria-label="Menu" aria-expanded={open} onClick={() => setOpen((v) => !v)}>
          <span /><span /><span />
        </button>
        <Link href="/" className="docs-logo"><i className="orb orb-s" />DevPilot</Link>
        <Link href="/docs" className="docs-tag">Docs</Link>
        <div className="docs-search">
          <input
            ref={input}
            type="search"
            value={q}
            placeholder="Search the docs"
            aria-label="Search the docs"
            onChange={(e) => setQ(e.target.value)}
            onFocus={() => { setFocus(true); load(); }}
            onBlur={() => window.setTimeout(() => setFocus(false), 150)}
          />
          <kbd aria-hidden="true">/</kbd>
          {focus && q.trim() && (
            <div className="docs-results" role="listbox">
              {hits.length === 0 && <p className="docs-none">{index ? "No pages match." : "Loading…"}</p>}
              {hits.map((h) => (
                <Link key={h.href} href={h.href} className="docs-hit" onClick={() => { setQ(""); setFocus(false); }}>
                  <b>{h.title}</b><small>{h.section}</small><span>{h.snippet}</span>
                </Link>
              ))}
            </div>
          )}
        </div>
        <nav className="docs-links" aria-label="Site">
          <Link href="/">Home</Link>
          <a href={links.releases} target="_blank" rel="noopener noreferrer">Releases</a>
          <a href={links.download} className="docs-cta">Download</a>
        </nav>
      </header>
      <div className="docs-body">
        <aside className={`docs-side${open ? " open" : ""}`} aria-label="Documentation">
          {nav.map((s) => (
            <div key={s.title} className="docs-group">
              <h4>{s.title}</h4>
              <ul>
                {s.items.map((i) => (
                  <li key={i.href}>
                    <Link href={i.href} className={i.href === pathname ? "on" : undefined} aria-current={i.href === pathname ? "page" : undefined}>{i.title}</Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </aside>
        {open && <button type="button" className="docs-scrim" aria-label="Close menu" onClick={() => setOpen(false)} />}
        <div className="docs-main">{children}</div>
      </div>
    </div>
  );
}
