"use client";

import { useEffect, useRef } from "react";

/** Types `text` one character at a time (22 ms each, 120 ms after a newline), waits 3.2 s, and starts again. */
export default function Typing({ text, label }: { text: string; label: string }) {
  const ref = useRef<HTMLPreElement>(null);
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const pre = ref.current!;
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const caret = document.createElement("span");
    caret.className = "caret";
    if (reduced) {
      pre.textContent = text;
      return;
    }
    let timer = 0, i = 0, started = false, stopped = false;
    const type = () => {
      if (stopped) return;
      pre.textContent = text.slice(0, i);
      pre.appendChild(caret);
      if (i >= text.length) {
        timer = window.setTimeout(() => { i = 0; type(); }, 3200);
        return;
      }
      const ch = text[i++];
      timer = window.setTimeout(type, ch === "\n" ? 120 : 22);
    };
    const io = new IntersectionObserver((en) => {
      if (!started && en[0].isIntersecting) { started = true; type(); io.disconnect(); }
    }, { threshold: 0.3 });
    io.observe(box.current!);
    return () => { stopped = true; clearTimeout(timer); io.disconnect(); };
  }, [text]);
  return (
    <div ref={box} aria-label={label} role="img">
      <pre ref={ref} className="code" />
    </div>
  );
}
