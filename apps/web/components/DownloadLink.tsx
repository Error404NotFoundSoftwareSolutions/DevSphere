"use client";

// The Download button: it links to the Windows package for visitors on Windows and to the Linux package for everyone
// else (macOS has no build yet, so those visitors get the release page). The static page starts as "Linux" and
// switches after load.
import { useEffect, useState } from "react";
import { links } from "@/lib/assets";

type Target = { href: string; label: string };
const LINUX: Target = { href: links.download, label: "Linux" };
const WINDOWS: Target = { href: links.downloadWindows, label: "Windows" };

export default function DownloadLink({ className, plain }: { className: string; plain?: boolean }) {
  const [t, setT] = useState<Target>(LINUX);
  useEffect(() => {
    const ua = navigator.userAgent || "";
    if (/windows/i.test(ua)) setT(WINDOWS);
  }, []);
  return (
    <a className={className} href={t.href}>
      {plain ? "Download" : `Download for ${t.label}`}
    </a>
  );
}
