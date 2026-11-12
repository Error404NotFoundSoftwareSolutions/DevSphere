"use client";

import { useEffect } from "react";

const EASE = "cubic-bezier(.2,.75,.2,1)";
const STEPS: Array<[string, Keyframe, number, number]> = [
  ["nav", { opacity: 0, transform: "translateY(-14px)" }, 0, 900],
  ["l1", { opacity: 0, transform: "translateY(105%)" }, 250, 1100],
  ["l2", { opacity: 0, transform: "translateY(105%)" }, 370, 1100],
  ["sub", { opacity: 0, transform: "translateY(12px)" }, 620, 900],
  ["btns", { opacity: 0, transform: "translateY(14px)" }, 740, 900],
  ["card", { opacity: 0, transform: "translateY(40px) scale(.96)" }, 880, 1100],
];

/** Runs the hero entrance once, then lifts the "anim" guard that keeps [data-in] elements hidden until it starts. */
export default function Entrance() {
  useEffect(() => {
    const root = document.documentElement;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      root.classList.remove("anim");
      return;
    }
    for (const [name, from, delay, duration] of STEPS) {
      const el = document.querySelector<HTMLElement>(`[data-in="${name}"]`);
      el?.animate([from, { opacity: 1, transform: "none" }], { delay, duration, easing: EASE, fill: "backwards" });
    }
    const raf = requestAnimationFrame(() => root.classList.remove("anim"));
    const fail = window.setTimeout(() => root.classList.remove("anim"), 3000);
    return () => {
      cancelAnimationFrame(raf);
      window.clearTimeout(fail);
    };
  }, []);
  return null;
}
