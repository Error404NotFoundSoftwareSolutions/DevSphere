"use client";

// "On this page": the page's headings, with the one being read highlighted.
import { useEffect, useState } from "react";

export default function DocsToc({ headings }: { headings: { id: string; text: string; depth: number }[] }) {
  const [active, setActive] = useState(headings[0]?.id ?? "");
  useEffect(() => {
    const els = headings.map((h) => document.getElementById(h.id)).filter((e): e is HTMLElement => !!e);
    if (!els.length) return;
    const io = new IntersectionObserver(
      (entries) => {
        const seen = entries.filter((e) => e.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
        if (seen) setActive(seen.target.id);
      },
      { rootMargin: "-80px 0px -70% 0px" },
    );
    els.forEach((e) => io.observe(e));
    return () => io.disconnect();
  }, [headings]);
  if (headings.length < 2) return null;
  return (
    <nav className="docs-toc" aria-label="On this page">
      <h4>On this page</h4>
      <ul>
        {headings.map((h) => (
          <li key={h.id} className={h.depth === 3 ? "deep" : undefined}>
            <a href={`#${h.id}`} className={h.id === active ? "on" : undefined}>{h.text}</a>
          </li>
        ))}
      </ul>
    </nav>
  );
}
