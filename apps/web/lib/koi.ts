// The 3D model that swims through every section. Position, size and heading follow the scroll; its body bends in a
// swimming wave. With no GLB supplied it is a crystal paper plane built here, so the page needs no downloaded model.
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";
import { pointer } from "./pointer";
import { buildRobot, buildRocket, type Mascot } from "./mascot";

export type MascotKind = "robot" | "rocket" | "plane";

type Pose = { x: number; y: number; s: number; yaw: number; pitch: number; roll: number };
const ORDER = ["hero", "statement", "dash", "packs", "uses", "end", "foot"] as const;
type Key = (typeof ORDER)[number];

const POSES: Record<Key, Pose> = {
  hero: { x: 0.02, y: 0.16, s: 0.72, yaw: 0.18, pitch: -0.92, roll: 0.05 },
  statement: { x: -0.66, y: -0.6, s: 0.42, yaw: 0.5, pitch: 0.2, roll: -0.1 },
  dash: { x: 0.5, y: -0.5, s: 0.46, yaw: -0.35, pitch: 0.32, roll: 0.1 },
  packs: { x: 0.4, y: -0.78, s: 0.5, yaw: 0.55, pitch: -0.05, roll: 0.08 },
  uses: { x: -0.42, y: -0.42, s: 0.6, yaw: 3.0, pitch: 0.12, roll: -0.06 },
  end: { x: -0.7, y: 0.56, s: 0.48, yaw: 0.3, pitch: -0.14, roll: 0.05 },
  foot: { x: -0.7, y: 0.56, s: 0.48, yaw: 0.3, pitch: -0.14, roll: 0.05 },
};
const PHONE: Record<Key, Partial<Pose>> = {
  hero: { x: 0.12, y: 0.38, s: 0.46 },
  statement: { x: 0.42, y: -0.72, s: 0.3 },
  dash: { x: -0.35, y: -0.74, s: 0.3 },
  packs: { x: 0.38, y: -0.74, s: 0.3 },
  uses: { x: -0.3, y: -0.76, s: 0.32 },
  end: { x: 0.3, y: -0.74, s: 0.32 },
  foot: { x: 0.3, y: -0.74, s: 0.32 },
};

// Where the robot / rocket sits in each section (x, y in -1..1 of the viewport, s = height as a share of the viewport).
const CHAR: Record<Key, Pose> = {
  hero: { x: 0.74, y: 0.4, s: 0.3, yaw: 0, pitch: 0, roll: 0 },
  statement: { x: 0.84, y: -0.4, s: 0.26, yaw: 0, pitch: 0, roll: 0 },
  dash: { x: 0.8, y: -0.78, s: 0.17, yaw: 0, pitch: 0, roll: 0 },
  packs: { x: 0.02, y: 0.2, s: 0.26, yaw: 0, pitch: 0, roll: 0 },
  uses: { x: 0.78, y: -0.14, s: 0.24, yaw: 0, pitch: 0, roll: 0 },
  end: { x: -0.8, y: -0.05, s: 0.3, yaw: 0, pitch: 0, roll: 0 },
  // while the footer is on screen, rest over the big ghost wordmark where there is no text
  foot: { x: 0.0, y: -0.7, s: 0.27, yaw: 0, pitch: 0, roll: 0 },
};
const CHAR_PHONE: Record<Key, Partial<Pose>> = {
  hero: { x: 0.62, y: 0.62, s: 0.2 },
  statement: { x: 0.7, y: -0.78, s: 0.14 },
  dash: { x: 0.7, y: -0.78, s: 0.14 },
  packs: { x: 0.7, y: -0.78, s: 0.14 },
  uses: { x: 0.7, y: -0.78, s: 0.14 },
  end: { x: 0.7, y: -0.78, s: 0.16 },
  foot: { x: 0.7, y: -0.78, s: 0.16 },
};

const clamp = (v: number, a = 0, b = 1) => Math.min(b, Math.max(a, v));
const ease = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

/** A folded paper plane along +X (nose at +X), length 1, finely divided along its length so it can bend. */
function paperPlane(): THREE.BufferGeometry {
  const N = 56, M = 16;
  const pos: number[] = [], uv: number[] = [], idx: number[] = [];
  for (let i = 0; i <= N; i++) {
    const t = i / N; // 0 nose .. 1 tail
    const x = 0.5 - t;
    const w = 0.02 + 0.34 * Math.pow(t, 0.85); // half-width grows towards the tail
    for (let j = 0; j <= M; j++) {
      const s = (j / M) * 2 - 1;
      const z = s * w;
      const y = -Math.abs(s) * w * 0.5 + (1 - t) * 0.012; // a shallow V, like a folded wing
      pos.push(x, y, z);
      uv.push(t, j / M);
    }
  }
  for (let i = 0; i < N; i++) {
    for (let j = 0; j < M; j++) {
      const a = i * (M + 1) + j, b = a + 1, c = a + (M + 1), d = c + 1;
      idx.push(a, c, b, b, c, d);
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}

function normalise(root: THREE.Object3D): THREE.BufferGeometry | null {
  // bake each mesh's world transform into its geometry, merge into one geometry
  root.updateMatrixWorld(true);
  const geoms: THREE.BufferGeometry[] = [];
  root.traverse((o) => {
    const m = o as THREE.Mesh;
    if (m.isMesh) {
      const g = m.geometry.clone();
      g.applyMatrix4(m.matrixWorld);
      geoms.push(g);
    }
  });
  if (!geoms.length) return null;
  const g = geoms[0];
  const box = new THREE.Box3().setFromBufferAttribute(g.getAttribute("position") as THREE.BufferAttribute);
  const size = new THREE.Vector3();
  box.getSize(size);
  if (size.z >= size.x && size.z >= size.y) g.rotateY(Math.PI / 2);
  else if (size.y >= size.x && size.y >= size.z) g.rotateZ(-Math.PI / 2);
  g.rotateY(Math.PI); // the model's nose must point to +X
  g.computeBoundingBox();
  const b2 = g.boundingBox!;
  const c = new THREE.Vector3();
  b2.getCenter(c);
  g.translate(-c.x, -c.y, -c.z);
  const len = Math.max(b2.max.x - b2.min.x, 1e-6);
  g.scale(1 / len, 1 / len, 1 / len);
  g.computeVertexNormals();
  return g;
}

export function startKoi(canvas: HTMLCanvasElement, opts: { modelUrl: string; mascot: MascotKind; reduced: boolean; phone: () => boolean }): () => void {
  const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true, powerPreference: "high-performance" });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 0.95;

  const scene = new THREE.Scene();
  const pmrem = new THREE.PMREMGenerator(renderer);
  scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
  scene.environmentIntensity = 0.75;
  scene.add(new THREE.HemisphereLight(0xc6b2ff, 0x2a1c80, 0.7));
  const key = new THREE.DirectionalLight(0xffc8f0, 1.6);
  key.position.set(3, 5, 6);
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x8c7bff, 2.8);
  rim.position.set(-5, -1, -4);
  scene.add(rim);

  const camera = new THREE.PerspectiveCamera(30, 1, 0.1, 100);
  camera.position.set(0, 0, 10);

  const uniforms = { uTime: { value: 0 }, uFreq: { value: 5.2 }, uSpeed: { value: 6.5 }, uAmp: { value: 0.075 } };
  const makeMaterial = (map: THREE.Texture | null) => {
    const m = new THREE.MeshPhysicalMaterial({
      color: map ? 0xc9b4ff : 0xb8a4ff,
      map: map ?? null,
      roughness: 0.18,
      metalness: 0.15,
      clearcoat: 1,
      clearcoatRoughness: 0.1,
      iridescence: 0.85,
      iridescenceIOR: 1.4,
      iridescenceThicknessRange: [260, 700],
      emissive: 0x7a46ff,
      emissiveIntensity: 0.55,
      emissiveMap: map ?? null,
      sheen: 0.25,
      sheenColor: new THREE.Color(0xff9ce6),
      transparent: true,
      opacity: 0.95,
      envMapIntensity: 0.75,
      side: THREE.DoubleSide,
    });
    m.onBeforeCompile = (shader) => {
      Object.assign(shader.uniforms, uniforms);
      shader.vertexShader = shader.vertexShader
        .replace("#include <common>", "#include <common>\nuniform float uTime; uniform float uFreq; uniform float uSpeed; uniform float uAmp;")
        .replace(
          "#include <begin_vertex>",
          `vec3 transformed = vec3(position);
           float tailF = clamp((0.32 - position.x) / 0.82, 0.0, 1.0);
           transformed.z += sin(position.x * uFreq - uTime * uSpeed) * uAmp * (0.15 + 1.6 * tailF * tailF);
           transformed.y += cos(position.x * uFreq * 0.5 - uTime * uSpeed * 0.5) * uAmp * 0.12 * tailF;`,
        );
    };
    return m;
  };

  const rig = new THREE.Group();
  const body = new THREE.Group();
  rig.add(body);
  scene.add(rig);
  rig.visible = false;

  const mount = (geo: THREE.BufferGeometry, map: THREE.Texture | null) => {
    const mesh = new THREE.Mesh(geo, makeMaterial(map));
    mesh.frustumCulled = false; // the shader moves the vertices
    body.add(mesh);
    rig.visible = true;
  };
  // a robot or rocket stands in for the fish when no model file is supplied
  let ch: Mascot | null = null;
  if (!opts.modelUrl && opts.mascot !== "plane") {
    ch = opts.mascot === "rocket" ? buildRocket() : buildRobot();
    rig.add(ch.group);
    rig.visible = true;
  } else if (opts.modelUrl) {
    new GLTFLoader().load(
      opts.modelUrl,
      (gltf) => {
        let map: THREE.Texture | null = null;
        gltf.scene.traverse((o) => {
          const m = o as THREE.Mesh;
          if (m.isMesh && !map) map = ((m.material as THREE.MeshStandardMaterial).map as THREE.Texture) ?? null;
        });
        if (map) (map as THREE.Texture).colorSpace = THREE.SRGBColorSpace;
        const g = normalise(gltf.scene);
        if (g) mount(g, map);
        else mount(paperPlane(), null);
      },
      undefined,
      () => mount(paperPlane(), null),
    );
  } else {
    mount(paperPlane(), null);
  }
  if (ch) renderer.toneMappingExposure = 1.05;

  // click or tap anywhere: a happy hop
  let hopT = 1;
  const onDown = () => { if (ch && hopT >= 1) hopT = 0; };
  window.addEventListener("pointerdown", onDown, { passive: true });

  // layout: section tops are page-absolute
  let tops: Record<string, number> = {};
  let dashH = 0;
  let maxScroll = 1;
  const measure = () => {
    const get = (id: string) => {
      const el = document.getElementById(id);
      return el ? el.getBoundingClientRect().top + window.scrollY : 0;
    };
    const h = window.innerHeight;
    tops = { studio: get("studio"), dash: get("dash"), packs: get("packs"), uses: get("uses"), end: get("end") };
    const d = document.getElementById("dash");
    dashH = d ? d.getBoundingClientRect().height : 0;
    maxScroll = Math.max(1, document.documentElement.scrollHeight - h);
  };
  const size = () => {
    renderer.setSize(window.innerWidth, window.innerHeight, false);
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    measure();
  };
  size();

  const anchors = () => {
    const h = window.innerHeight;
    return [
      0,
      tops.studio + 0.2 * h,
      tops.dash + dashH / 2 - 0.5 * h,
      tops.packs + 0.3 * h,
      tops.uses + 0.3 * h,
      Math.min(tops.end, maxScroll),
      maxScroll,
    ];
  };
  const target = (y: number): Pose => {
    const a = anchors();
    const phone = opts.phone();
    const base = ch ? CHAR : POSES;
    const small = ch ? CHAR_PHONE : PHONE;
    const P = (k: Key): Pose => ({ ...base[k], ...(phone ? small[k] : {}) });
    if (y <= a[0]) return P(ORDER[0]);
    for (let i = 0; i < a.length - 1; i++) {
      if (y <= a[i + 1]) {
        const span = Math.max(1, a[i + 1] - a[i]);
        const t = ease(clamp((y - a[i]) / span));
        const p = P(ORDER[i]), q = P(ORDER[i + 1]);
        return {
          x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t, s: p.s + (q.s - p.s) * t,
          yaw: p.yaw + (q.yaw - p.yaw) * t, pitch: p.pitch + (q.pitch - p.pitch) * t, roll: p.roll + (q.roll - p.roll) * t,
        };
      }
    }
    return P(ORDER[ORDER.length - 1]);
  };

  let cur: Pose = { ...target(window.scrollY) };
  let vel = 0, lastY = window.scrollY, lastT = performance.now();
  let tTime = 0, tilt = { x: 0, y: 0 };
  const chase = { x: 0, y: 0 }, lastN = { x: cur.x, y: cur.y }, sv = { x: 0, y: 0 };
  const fh = () => 2 * Math.tan((15 * Math.PI) / 180) * 10;

  const apply = (dt: number, t: number, snap: boolean) => {
    const y = window.scrollY;
    const tg = target(y);
    const k = snap ? 1 : 1 - Math.exp(-3.2 * dt);
    (Object.keys(tg) as (keyof Pose)[]).forEach((key2) => (cur[key2] += (tg[key2] - cur[key2]) * k));
    const H = fh(), W = H * camera.aspect;
    if (ch) {
      // the character drifts a little towards the pointer and looks at it
      const near = pointer.inside ? clamp(1 - Math.hypot(pointer.tx - cur.x, -pointer.ty - cur.y) / 0.7) : 0;
      const want = pointer.inside && !snap ? { x: clamp((pointer.tx - cur.x) * 0.1, -0.12, 0.12), y: clamp((-pointer.ty - cur.y) * 0.1, -0.12, 0.12) } : { x: 0, y: 0 };
      chase.x += (want.x - chase.x) * (snap ? 1 : 1 - Math.exp(-2.5 * dt));
      chase.y += (want.y - chase.y) * (snap ? 1 : 1 - Math.exp(-2.5 * dt));
      const nx = cur.x + chase.x, ny = cur.y + chase.y;
      const px = (nx * W) / 2, py = (ny * H) / 2;
      const vxs = snap ? 0 : (nx - lastN.x) / Math.max(dt, 1e-3);
      const vys = snap ? 0 : (ny - lastN.y) / Math.max(dt, 1e-3);
      lastN.x = nx; lastN.y = ny;
      sv.x += (vxs - sv.x) * 0.15; sv.y += (vys - sv.y) * 0.15;
      if (hopT < 1) hopT = Math.min(1, hopT + dt / 0.9);
      rig.position.set(px, py, 0);
      rig.rotation.set(0, 0, 0);
      rig.scale.setScalar(cur.s * H);
      ch.update({
        t, dt: snap ? 0.016 : dt, near,
        look: { x: clamp((pointer.tx - nx) * 1.4, -1, 1), y: clamp((-pointer.ty - ny) * 1.4, -1, 1) },
        vx: sv.x, vy: sv.y, hop: hopT < 1 ? hopT : 0,
      });
      renderer.render(scene, camera);
      return;
    }
    const bob = snap ? 0 : Math.sin(0.9 * t) * 0.018;
    rig.position.set((cur.x * W) / 2, ((cur.y + bob) * H) / 2, 0);
    rig.rotation.set(cur.roll + (snap ? 0 : Math.sin(0.7 * t) * 0.04), cur.yaw + (snap ? 0 : Math.sin(0.5 * t) * 0.06), cur.pitch, "XYZ");
    rig.scale.setScalar(cur.s * H);
    const kk = snap ? 1 : 1 - Math.exp(-dt / 0.1);
    tilt.x += (-pointer.tx * 0.01745 - tilt.x) * kk;
    tilt.y += (pointer.ty * 0.01745 - tilt.y) * kk;
    camera.rotation.y = tilt.x;
    camera.rotation.x = tilt.y;
    renderer.render(scene, camera);
  };

  let raf = 0;
  const frame = (now: number) => {
    raf = requestAnimationFrame(frame);
    const dt = Math.min((now - lastT) / 1000, 0.05);
    lastT = now;
    const y = window.scrollY;
    const inst = Math.abs((y - lastY) / Math.max(dt, 1e-3));
    lastY = y;
    vel += (inst - vel) * 0.1;
    const speedUp = Math.min(vel / 1800, 1.4);
    tTime += dt * (1 + speedUp);
    uniforms.uTime.value = tTime;
    uniforms.uAmp.value = 0.07 + 0.03 * speedUp;
    apply(dt, now / 1000, false);
  };
  const onceRender = () => apply(0.016, 0, true);
  const onResize = () => { size(); if (opts.reduced) onceRender(); };
  window.addEventListener("resize", onResize);
  const ro = new ResizeObserver(() => measure());
  ro.observe(document.body);
  if (opts.reduced) {
    window.addEventListener("scroll", onceRender, { passive: true });
    onceRender();
  } else {
    raf = requestAnimationFrame(frame);
  }
  // fonts and images change the layout after load
  const late = window.setTimeout(measure, 1200);
  return () => {
    cancelAnimationFrame(raf);
    window.clearTimeout(late);
    window.removeEventListener("resize", onResize);
    window.removeEventListener("scroll", onceRender);
    window.removeEventListener("pointerdown", onDown);
    ch?.dispose();
    ro.disconnect();
    renderer.dispose();
  };
}
