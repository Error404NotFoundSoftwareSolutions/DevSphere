// One shared pointer state for the ripple lens and the 3D model (client only).
export const pointer = { u: 0.5, v: 0.5, tx: 0, ty: 0, inside: false };

let wired = false;
export function wirePointer() {
  if (wired || typeof window === "undefined") return;
  wired = true;
  window.addEventListener(
    "pointermove",
    (e) => {
      pointer.u = e.clientX / window.innerWidth;
      pointer.v = e.clientY / window.innerHeight;
      pointer.tx = pointer.u * 2 - 1;
      pointer.ty = pointer.v * 2 - 1;
      pointer.inside = true;
    },
    { passive: true },
  );
  document.documentElement.addEventListener("pointerleave", () => {
    pointer.inside = false;
    pointer.tx = 0;
    pointer.ty = 0;
  });
}
