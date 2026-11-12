"use client";

// Real screenshots of the DevPilot desktop app (dark theme), rendered from the app itself with
// `SHOTS_DARK=1 SHOTS_DIR=... flutter test test/shots/shots_test.dart` in apps/desktop. Tabs switch the screen; it
// also moves on by itself every few seconds until someone picks a tab.
import { useEffect, useState } from "react";

const SCREENS = [
  { id: "dashboard", tab: "Dashboard", title: "Pick up where you left off", text: "Your current lab, this week's checks and your path, on one page." },
  { id: "paths", tab: "Learning paths", title: "Say what you want to learn", text: "Name a goal or paste a job description, and DevPilot builds the steps." },
  { id: "lab", tab: "Labs and tutor", title: "Practise in your own VS Code", text: "Labs open in VS Code; the tutor gives hints, never the finished answer." },
  { id: "credentials", tab: "Credentials", title: "Show what you can do", text: "Finished labs become credentials that say plainly how they were checked." },
] as const;

export default function AppShowcase() {
  const [i, setI] = useState(0);
  const [auto, setAuto] = useState(true);
  useEffect(() => {
    if (!auto || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const t = window.setInterval(() => setI((n) => (n + 1) % SCREENS.length), 5200);
    return () => window.clearInterval(t);
  }, [auto]);
  const s = SCREENS[i];
  return (
    <div className="dash appshow reveal" id="dash">
      <div className="dash-top">
        <span className="dots" aria-hidden="true"><i /><i /><i /></span>
        <span className="win-title">DevPilot</span>
        <div className="tabs" role="tablist" aria-label="Screens of the DevPilot app">
          {SCREENS.map((x, n) => (
            <button key={x.id} role="tab" aria-selected={n === i} className={n === i ? "on" : ""}
              onClick={() => { setI(n); setAuto(false); }}>{x.tab}</button>
          ))}
        </div>
      </div>
      <div className="shot">
        {SCREENS.map((x, n) => (
          // eslint-disable-next-line @next/next/no-img-element
          <img key={x.id} src={`/app/${x.id}.webp`} width={1440} height={872} alt={`The DevPilot app: ${x.tab}`}
            className={n === i ? "on" : ""} loading={n === 0 ? "eager" : "lazy"} decoding="async" />
        ))}
      </div>
      <div className="shot-cap" aria-live="polite"><b>{s.title}</b><span>{s.text}</span></div>
    </div>
  );
}
