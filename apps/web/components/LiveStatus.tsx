"use client";

import { useEffect, useState } from "react";
import { links } from "@/lib/assets";

/** A small live check of the online learning service: "Service online" or "Status unavailable". */
export default function LiveStatus() {
  const [state, setState] = useState<"checking" | "up" | "down">("checking");
  useEffect(() => {
    const c = new AbortController();
    const t = window.setTimeout(() => c.abort(), 8000);
    // no-cors: we only need to know the service answered, not read what it said
    fetch(`${links.api}/health`, { mode: "no-cors", signal: c.signal })
      .then(() => setState("up"))
      .catch(() => setState("down"))
      .finally(() => clearTimeout(t));
    return () => { c.abort(); clearTimeout(t); };
  }, []);
  const label = state === "up" ? "Learning service online" : state === "down" ? "Status unavailable" : "Checking status";
  return <span className={`chip ${state === "up" ? "live" : ""}`}>{label}</span>;
}
