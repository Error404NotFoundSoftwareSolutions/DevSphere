"use client";

import { useEffect, useRef } from "react";
import { assets } from "@/lib/assets";
import { pointer, wirePointer } from "@/lib/pointer";
import { makeDuskPlate, startLens } from "@/lib/lens";
import { startKoi, type MascotKind } from "@/lib/koi";

const smooth = (a: number, b: number, v: number) => {
  const t = Math.min(1, Math.max(0, (v - a) / (b - a)));
  return t * t * (3 - 2 * t);
};

/** The fixed full-viewport scene behind the page: day plate (with the ripple lens), violet gradient, night plate, 3D model. */
export default function Scene() {
  const day = useRef<HTMLDivElement>(null);
  const violet = useRef<HTMLDivElement>(null);
  const night = useRef<HTMLDivElement>(null);
  const video = useRef<HTMLVideoElement>(null);
  const nvideo = useRef<HTMLVideoElement>(null);
  const fx = useRef<HTMLCanvasElement>(null);
  const koi = useRef<HTMLCanvasElement>(null);
  const mascot = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    wirePointer();
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const stops: Array<() => void> = [];

    // --- unit: u = content width / 1440 (or / 390 on small screens)
    const setUnit = () => {
      const w = document.documentElement.clientWidth;
      document.documentElement.style.setProperty("--u", `${w / (w > 820 ? 1440 : 390)}px`);
    };
    setUnit();
    window.addEventListener("resize", setUnit);
    stops.push(() => window.removeEventListener("resize", setUnit));

    // --- the plates: supplied images, or generated ones
    if (!assets.dayPlate && day.current) day.current.style.backgroundImage = `url(${makeDuskPlate(false).toDataURL("image/jpeg", 0.85)})`;
    if (!assets.nightPlate && night.current) night.current.style.backgroundImage = `url(${makeDuskPlate(true).toDataURL("image/jpeg", 0.85)})`;

    // --- the ripple lens over the video, a still, or a generated plate
    const v = video.current!;
    const canvas = fx.current!;
    let lensStop: (() => void) | null = null;
    const reveal = () => canvas.classList.add("on");
    if (!reduced) {
      if (assets.video) {
        v.src = assets.video;
        v.play().catch(() => {});
        lensStop = startLens(canvas, { kind: "video", el: v }, reveal);
        if (!lensStop) v.classList.add("on"); // no WebGL: show the plain video
      } else {
        const make = (el: HTMLCanvasElement | HTMLImageElement) => {
          lensStop = startLens(canvas, { kind: "still", el: el as never }, reveal);
        };
        if (assets.dayPlate) {
          const img = new Image();
          img.crossOrigin = "anonymous";
          img.onload = () => make(img);
          img.src = assets.dayPlate;
        } else {
          make(makeDuskPlate(false));
        }
      }
    }
    stops.push(() => lensStop?.());

    // --- the crossfade on scroll
    const nav = document.getElementById("nav");
    const onScroll = () => {
      const h = window.innerHeight, y = window.scrollY;
      const end = document.getElementById("end");
      const endTop = end ? end.getBoundingClientRect().top + y : 1e9;
      const toViolet = smooth(0.15 * h, 1.05 * h, y);
      const toNight = smooth(endTop - 1.1 * h, endTop - 0.1 * h, y);
      if (day.current) {
        day.current.style.opacity = String(1 - toViolet);
        day.current.style.transform = `scale(${1 + 0.08 * toViolet}) translateY(${-0.06 * y}px)`;
      }
      if (violet.current) violet.current.style.opacity = String(toViolet * (1 - toNight));
      if (night.current) night.current.style.opacity = String(toNight);
      // the night video only loads and plays while the night scene is visible
      const nv = nvideo.current;
      if (nv && assets.nightVideo && !reduced) {
        if (toNight > 0.01) {
          if (!nv.getAttribute("src")) nv.src = assets.nightVideo;
          if (nv.paused) nv.play().catch(() => {});
        } else if (!nv.paused) nv.pause();
      }
      nav?.classList.toggle("scrolled", y > 0.5 * h);
      if (assets.video) {
        if (toViolet < 0.999) { if (v.paused && !reduced) v.play().catch(() => {}); } else if (!v.paused) v.pause();
      }
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    stops.push(() => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
    });

    // --- the 3D model
    let koiStop: (() => void) | null = null;
    try {
      // a supplied model swims behind the glass; the robot / rocket stand-in flies in front of the page
      const asked = new URLSearchParams(window.location.search).get("mascot") ?? assets.mascot;
      const kind: MascotKind = asked === "rocket" || asked === "plane" ? asked : "robot";
      const useModel = !!assets.model;
      const canvas = useModel || kind === "plane" ? koi.current! : mascot.current!;
      (canvas === koi.current ? mascot.current! : koi.current!).style.display = "none";
      koiStop = startKoi(canvas, { modelUrl: assets.model, mascot: kind, reduced, phone: () => document.documentElement.clientWidth <= 820 });
    } catch {
      /* no WebGL: the page still works without the model */
    }
    stops.push(() => koiStop?.());
    void pointer;
    return () => stops.forEach((s) => s());
  }, []);

  return (
    <>
    <div className="scene" aria-hidden="true">
      <div className="plate day" ref={day} style={assets.dayPlate ? { backgroundImage: `url("${assets.dayPlate}")` } : undefined}>
        <video ref={video} className="pondvid" muted loop playsInline preload="auto" crossOrigin="anonymous" />
        <canvas ref={fx} className="pondfx" />
      </div>
      <div className="plate violet" ref={violet} />
      <div className="plate nightp" ref={night} style={assets.nightPlate ? { backgroundImage: `url("${assets.nightPlate}")` } : undefined}>
        <video ref={nvideo} className="nightvid" muted loop playsInline preload="none" onPlaying={(e) => e.currentTarget.classList.add("on")} />
      </div>
      <canvas ref={koi} className="koi" />
    </div>
    <canvas ref={mascot} className="mascot" aria-hidden="true" />
    </>
  );
}
