// Stand-in 3D characters built from shapes, so the page needs no downloaded model: a smiling robot that follows the
// mouse, and a rocket that points the way it flies. Both are about one unit tall and centred on the origin.
import * as THREE from "three";
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";

export type MascotInput = {
  t: number; // seconds
  dt: number;
  look: { x: number; y: number }; // where the pointer is, relative to the character, -1..1 (y up)
  vx: number; // screen-space velocity, in half-viewports per second
  vy: number;
  near: number; // 0..1, how close the pointer is
  hop: number; // 0..1 progress of a click "happy hop", 0 when idle
};
export type Mascot = { group: THREE.Group; update(i: MascotInput): void; dispose(): void };

const clamp = (v: number, a = 0, b = 1) => Math.min(b, Math.max(a, v));
const easeInOut = (t: number) => (t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2);

function shell(color = 0xf6f2ff) {
  return new THREE.MeshPhysicalMaterial({ color, roughness: 0.26, metalness: 0.04, clearcoat: 1, clearcoatRoughness: 0.1, envMapIntensity: 1.1 });
}
function accent(color: number, glow = 0.45) {
  return new THREE.MeshStandardMaterial({ color, roughness: 0.32, metalness: 0.35, emissive: color, emissiveIntensity: glow, envMapIntensity: 0.9 });
}
const glowMat = (color: number, opacity = 1) =>
  new THREE.MeshBasicMaterial({ color, transparent: opacity < 1, opacity, toneMapped: false });

/** Collect geometries and materials so the character can be freed when the page closes. */
function tracker() {
  const geos: THREE.BufferGeometry[] = [];
  const mats: THREE.Material[] = [];
  const mesh = <G extends THREE.BufferGeometry>(g: G, m: THREE.Material) => {
    geos.push(g);
    if (!mats.includes(m)) mats.push(m);
    return new THREE.Mesh(g, m);
  };
  const texs: THREE.Texture[] = [];
  const track = (m: THREE.Material) => { if (!mats.includes(m)) mats.push(m); };
  const trackGeo = (g: THREE.BufferGeometry) => { geos.push(g); };
  const trackTex = (t: THREE.Texture) => { texs.push(t); };
  return { mesh, track, trackGeo, trackTex, dispose: () => { geos.forEach((g) => g.dispose()); mats.forEach((m) => m.dispose()); texs.forEach((t) => t.dispose()); shellCache.clear(); furNoise?.dispose(); furNoise = null; } };
}

// --- plush fur: many thin "shells" of the same mesh, each pushed a little further out along its normals, each keeping
// fewer random strands (an alpha-tested noise map). Seen together they read as soft fur with a fuzzy outline.
const furTime = { value: 0 };
let furNoise: THREE.CanvasTexture | null = null;
function noiseTexture(): THREE.CanvasTexture {
  if (furNoise) return furNoise;
  const n = 96;
  const c = document.createElement("canvas");
  c.width = c.height = n;
  const ctx = c.getContext("2d")!;
  const img = ctx.createImageData(n, n);
  for (let i = 0; i < n * n; i++) {
    // strand length: mostly short with a few long ones, so the tips look wispy
    const v = Math.pow(Math.random(), 0.8) * 255;
    img.data[i * 4] = img.data[i * 4 + 1] = img.data[i * 4 + 2] = v;
    img.data[i * 4 + 3] = 255;
  }
  ctx.putImageData(img, 0, 0);
  furNoise = new THREE.CanvasTexture(c);
  furNoise.wrapS = furNoise.wrapT = THREE.RepeatWrapping;
  furNoise.repeat.set(1.7, 1.7);
  furNoise.anisotropy = 4;
  return furNoise;
}
const SHELLS = 20;
type FurSpec = { tip: number; root: number; len: number };
const shellCache = new Map<string, THREE.MeshStandardMaterial>();
function shellMaterial(spec: FurSpec, layer: number, track: (m: THREE.Material) => void): THREE.MeshStandardMaterial {
  const key = `${spec.tip}-${spec.root}-${spec.len}-${layer}`;
  const hit = shellCache.get(key);
  if (hit) return hit;
  const h = layer / SHELLS;
  const color = new THREE.Color(spec.root).lerp(new THREE.Color(spec.tip), Math.pow(h, 0.65)); // darker at the roots
  const m = new THREE.MeshStandardMaterial({ color, roughness: 0.92, metalness: 0, alphaMap: noiseTexture(), alphaTest: 0.08 + 0.84 * h * h, envMapIntensity: 0.55 });
  const off = { value: spec.len * h };
  m.onBeforeCompile = (shader) => {
    shader.uniforms.uOff = off;
    shader.uniforms.uT = furTime;
    shader.vertexShader = shader.vertexShader
      .replace("#include <common>", "#include <common>\nuniform float uOff; uniform float uT;")
      .replace(
        "#include <begin_vertex>",
        `vec3 transformed = position + normal * uOff;
         float sway = uOff * uOff * 9.0;
         transformed.x += sin(uT * 1.7 + position.y * 11.0) * sway;
         transformed.z += cos(uT * 1.3 + position.x * 11.0) * sway * 0.6;
         transformed.y -= uOff * uOff * 3.0;`,
      );
  };
  m.customProgramCacheKey = () => "fur-shell";
  shellCache.set(key, m);
  track(m);
  return m;
}

// --- a natural jet flame: soft teardrop layers with a hot core, a glow, and drifting sparks. Palettes: blue (robot), warm (rocket).
type Palette = { outer: number; outerHot: number; mid: number; midHot: number; core: number; glow: number; spark: number };
const BLUE: Palette = { outer: 0x2457ff, outerHot: 0x8db8ff, mid: 0x33c4ff, midHot: 0xd9f7ff, core: 0xc4f1ff, glow: 0x4a86ff, spark: 0x8fe0ff };
const WARM: Palette = { outer: 0xff5a1f, outerHot: 0xffb067, mid: 0xffa826, midHot: 0xfff0c4, core: 0xfff4d6, glow: 0xff8a3a, spark: 0xffd08a };
const jetTime = { value: 0 };
const FLAME_VERT = `
  uniform float uTime; uniform float uLen; varying float vT; varying vec3 vN; varying vec3 vV;
  void main() {
    vT = clamp(-position.y / uLen, 0.0, 1.0);
    vec3 p = position;
    float w = sin(position.y * 22.0 - uTime * 34.0 + position.x * 40.0) * 0.012 * vT + sin(position.y * 11.0 - uTime * 21.0) * 0.01 * vT;
    p.x += w; p.z += w * 0.7;
    p.y *= 1.0 + 0.05 * sin(uTime * 45.0);
    vec4 mv = modelViewMatrix * vec4(p, 1.0);
    vV = -mv.xyz; vN = normalize(normalMatrix * normal);
    gl_Position = projectionMatrix * mv;
  }`;
const FLAME_FRAG = `
  uniform vec3 uColor; uniform vec3 uHot; uniform float uOpacity; uniform float uTime; varying float vT; varying vec3 vN; varying vec3 vV;
  void main() {
    float f = abs(dot(normalize(vN), normalize(vV)));
    float edge = pow(f, 1.3);
    float fade = pow(1.0 - vT, 1.3);
    float flick = 0.88 + 0.12 * sin(uTime * 52.0 + vT * 9.0);
    vec3 col = mix(uHot, uColor, smoothstep(0.0, 0.75, vT));
    gl_FragColor = vec4(col * 1.35, uOpacity * edge * fade * flick);
  }`;
function radial(color: number): THREE.CanvasTexture {
  const c = document.createElement("canvas");
  c.width = c.height = 64;
  const g = c.getContext("2d")!;
  const col = new THREE.Color(color);
  const rgb = `${Math.round(col.r * 255)},${Math.round(col.g * 255)},${Math.round(col.b * 255)}`;
  const grd = g.createRadialGradient(32, 32, 0, 32, 32, 32);
  grd.addColorStop(0, `rgba(${rgb},1)`);
  grd.addColorStop(0.35, `rgba(${rgb},0.45)`);
  grd.addColorStop(1, `rgba(${rgb},0)`);
  g.fillStyle = grd;
  g.fillRect(0, 0, 64, 64);
  return new THREE.CanvasTexture(c);
}
function makeJet(T: ReturnType<typeof tracker>, len: number, r: number, pal: Palette) {
  const group = new THREE.Group();
  const layer = (l: number, rr: number, color: number, hot: number, opacity: number) => {
    const pts: THREE.Vector2[] = [];
    const n = 20;
    for (let i = 0; i <= n; i++) {
      const t = i / n;
      pts.push(new THREE.Vector2(rr * Math.pow(1 - t, 0.85) * (1 + 0.3 * Math.sin(Math.PI * Math.min(1, t * 1.4))), -l * t));
    }
    const geo = new THREE.LatheGeometry(pts, 28);
    const mat = new THREE.ShaderMaterial({
      uniforms: { uTime: jetTime, uLen: { value: l }, uColor: { value: new THREE.Color(color) }, uHot: { value: new THREE.Color(hot) }, uOpacity: { value: opacity } },
      vertexShader: FLAME_VERT, fragmentShader: FLAME_FRAG,
      transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide, toneMapped: false,
    });
    const m = T.mesh(geo, mat);
    m.frustumCulled = false;
    group.add(m);
  };
  layer(len, r, pal.outer, pal.outerHot, 0.8);
  layer(len * 0.76, r * 0.62, pal.mid, pal.midHot, 0.9);
  layer(len * 0.48, r * 0.32, pal.core, 0xffffff, 1);
  // glow at the nozzle
  const glowTex = radial(pal.glow);
  T.trackTex(glowTex);
  const glowMat2 = new THREE.SpriteMaterial({ map: glowTex, blending: THREE.AdditiveBlending, depthWrite: false, transparent: true, opacity: 0.6, toneMapped: false });
  T.track(glowMat2);
  const glow = new THREE.Sprite(glowMat2);
  glow.position.y = -len * 0.12;
  glow.scale.setScalar(r * 6);
  group.add(glow);
  // sparks drifting away
  const COUNT = 26;
  const pos = new Float32Array(COUNT * 3);
  const colr = new Float32Array(COUNT * 3);
  const pg = new THREE.BufferGeometry();
  pg.setAttribute("position", new THREE.BufferAttribute(pos, 3));
  pg.setAttribute("color", new THREE.BufferAttribute(colr, 3));
  T.trackGeo(pg);
  const sparkTex = radial(0xffffff);
  T.trackTex(sparkTex);
  const pm = new THREE.PointsMaterial({ size: r * 0.5, map: sparkTex, vertexColors: true, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false, sizeAttenuation: true });
  T.track(pm);
  const sparks = new THREE.Points(pg, pm);
  sparks.frustumCulled = false;
  group.add(sparks);
  const sc = new THREE.Color(pal.spark);
  const update = (t: number, stretch: number) => {
    jetTime.value = t;
    group.scale.set(1 + Math.sin(t * 31) * 0.04, stretch, 1 + Math.cos(t * 29) * 0.04);
    glowMat2.opacity = 0.5 + 0.12 * Math.sin(t * 37) + 0.06 * Math.sin(t * 17);
    for (let i = 0; i < COUNT; i++) {
      const ph = (t * 0.9 + i / COUNT) % 1;
      const a = i * 2.399;
      const spread = r * (0.3 + ph * 1.5);
      pos[i * 3] = Math.cos(a) * spread;
      pos[i * 3 + 1] = -len * (0.35 + ph * 1.0);
      pos[i * 3 + 2] = Math.sin(a) * spread;
      const k = Math.pow(1 - ph, 1.4);
      colr[i * 3] = sc.r * k; colr[i * 3 + 1] = sc.g * k; colr[i * 3 + 2] = sc.b * k;
    }
    pg.attributes.position.needsUpdate = true;
    pg.attributes.color.needsUpdate = true;
  };
  return { group, update };
}

/** A friendly robot: white shell, dark glass face with glowing eyes and a smile, antenna, waving arms, jet flame. */
export function buildRobot(): Mascot {
  const T = tracker();
  const white = shell();
  const violet = accent(0x7a5cff, 0.5);
  const pink = accent(0xff8ad8, 0.6);
  const glass = new THREE.MeshPhysicalMaterial({ color: 0x140d42, roughness: 0.06, metalness: 0.25, clearcoat: 1, clearcoatRoughness: 0.03, envMapIntensity: 1.2 });
  const eyeMat = glowMat(0x8ff0ff);
  const smileMat = glowMat(0x8ff0ff);
  const WHITE: FurSpec = { tip: 0xf4efff, root: 0x7f6ed0, len: 0.042 };
  const VIOLET: FurSpec = { tip: 0xb8a2ff, root: 0x3a22c0, len: 0.032 };
  /** A furry mesh: an opaque root layer plus SHELLS fur layers sharing its geometry. */
  const furry = (geo: THREE.BufferGeometry, spec: FurSpec) => {
    const rootMat = new THREE.MeshStandardMaterial({ color: spec.root, roughness: 1, metalness: 0, envMapIntensity: 0.4 });
    const base = T.mesh(geo, rootMat);
    for (let i = 1; i <= SHELLS; i++) {
      const sh = new THREE.Mesh(geo, shellMaterial(spec, i, T.track));
      sh.frustumCulled = false;
      base.add(sh);
    }
    return base;
  };

  const group = new THREE.Group();
  const root = new THREE.Group(); // bobs and tilts as a whole
  group.add(root);

  // --- body
  const body = furry(new RoundedBoxGeometry(0.42, 0.36, 0.32, 5, 0.12), WHITE);
  body.position.y = -0.17;
  root.add(body);
  const heart = T.mesh(new THREE.CircleGeometry(0.05, 28), glowMat(0xff8ad8));
  heart.position.set(0, -0.14, 0.232);
  root.add(heart);

  // --- head
  const head = new THREE.Group();
  head.position.y = 0.2;
  root.add(head);
  head.add(furry(new RoundedBoxGeometry(0.56, 0.42, 0.4, 6, 0.15), WHITE));
  const screen = T.mesh(new RoundedBoxGeometry(0.44, 0.29, 0.04, 4, 0.06), glass);
  screen.position.z = 0.236;
  head.add(screen);
  const face = new THREE.Group(); // slides a little towards the pointer
  face.position.z = 0.259;
  head.add(face);
  const eyeGeo = new THREE.CapsuleGeometry(0.03, 0.05, 6, 12);
  const eyeL = T.mesh(eyeGeo, eyeMat);
  const eyeR = T.mesh(eyeGeo, eyeMat);
  eyeL.position.set(-0.1, 0.045, 0);
  eyeR.position.set(0.1, 0.045, 0);
  face.add(eyeL, eyeR);
  const smile = T.mesh(new THREE.TorusGeometry(0.065, 0.0125, 10, 28, Math.PI), smileMat);
  smile.rotation.z = Math.PI; // the lower half of a ring is a smile
  smile.position.set(0, -0.02, 0);
  face.add(smile);
  const cheekMat = glowMat(0xff7fc8, 0.5);
  const cheekGeo = new THREE.CircleGeometry(0.03, 20);
  const cheekL = T.mesh(cheekGeo, cheekMat);
  const cheekR = T.mesh(cheekGeo, cheekMat);
  cheekL.position.set(-0.165, -0.03, -0.002);
  cheekR.position.set(0.165, -0.03, -0.002);
  face.add(cheekL, cheekR);
  // ear pods
  const podGeo = new THREE.CylinderGeometry(0.07, 0.07, 0.07, 28);
  const podL = furry(podGeo, VIOLET);
  const podR = furry(podGeo, VIOLET);
  podL.rotation.z = podR.rotation.z = Math.PI / 2;
  podL.position.set(-0.3, 0, 0);
  podR.position.set(0.3, 0, 0);
  head.add(podL, podR);
  // antenna
  const stem = T.mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.13, 10), accent(0xb9a8ff, 0.2));
  stem.position.y = 0.27;
  head.add(stem);
  const bulb = T.mesh(new THREE.SphereGeometry(0.04, 20, 16), glowMat(0xff8ad8));
  bulb.position.y = 0.355;
  head.add(bulb);

  // --- arms (pivot at the shoulder)
  const armGeo = new THREE.CapsuleGeometry(0.04, 0.17, 6, 12);
  const handGeo = new THREE.SphereGeometry(0.052, 16, 12);
  const mkArm = (side: 1 | -1) => {
    const pivot = new THREE.Group();
    pivot.position.set(side * 0.255, -0.08, 0);
    const a = furry(armGeo, WHITE);
    a.position.y = -0.12;
    const h = furry(handGeo, VIOLET);
    h.position.y = -0.245;
    pivot.add(a, h);
    root.add(pivot);
    return pivot;
  };
  const armL = mkArm(-1);
  const armR = mkArm(1);

  // --- blue jet flame under the body
  const jet = makeJet(T, 0.5, 0.085, BLUE);
  jet.group.position.y = -0.41;
  root.add(jet.group);
  const nozzle = T.mesh(new THREE.CylinderGeometry(0.095, 0.07, 0.04, 28), violet);
  nozzle.position.y = -0.4;
  root.add(nozzle);

  let blink = 0, nextBlink = 2.2, spin = 0;
  const update = (i: MascotInput) => {
    const { t, look, vx, near, hop } = i;
    furTime.value = t;
    // float
    root.position.y = Math.sin(t * 1.6) * 0.025 + (hop > 0 ? Math.sin(hop * Math.PI) * 0.08 : 0);
    root.rotation.z += (clamp(-vx * 0.16, -0.35, 0.35) - root.rotation.z) * 0.1; // lean into the move
    // look at the pointer: eyes slide, head turns
    face.position.x += (look.x * 0.045 - face.position.x) * 0.2;
    face.position.y += (look.y * 0.03 - face.position.y) * 0.2;
    head.rotation.y += (look.x * 0.42 - head.rotation.y) * 0.12;
    head.rotation.x += (-look.y * 0.22 - head.rotation.x) * 0.12;
    // blink
    nextBlink -= i.dt;
    if (nextBlink <= 0) { blink = 0.14; nextBlink = 2.4 + Math.random() * 2.6; }
    blink = Math.max(0, blink - i.dt);
    const eyeY = blink > 0 ? 0.12 : 1 + hop * 0.15;
    eyeL.scale.y = eyeR.scale.y += (eyeY - eyeR.scale.y) * 0.5;
    // happier when the pointer is close or after a click
    const joy = clamp(near * 0.7 + hop);
    smile.scale.setScalar(1 + joy * 0.3);
    cheekMat.opacity = 0.35 + joy * 0.5;
    // arms: gentle swing, a wave when the pointer is near
    const wave = clamp(near * 1.2 + hop);
    // a hanging arm swings outwards with a negative angle on the left and a positive one on the right; the wave lifts the right arm up
    armL.rotation.z = -0.25 - Math.sin(t * 1.3) * 0.07;
    armR.rotation.z = 0.25 + wave * (2.1 + Math.sin(t * 9) * 0.3) + (1 - wave) * Math.sin(t * 1.3 + 1) * 0.07;
    // antenna bulb pulses
    bulb.scale.setScalar(1 + Math.sin(t * 3) * 0.15);
    // flame
    jet.update(t, 1 + Math.sin(t * 38) * 0.06 + Math.sin(t * 23) * 0.05 + clamp(Math.abs(i.vy) * 0.6, 0, 0.6));
    // the click spin: one full turn with a hop
    spin = hop > 0 ? easeInOut(hop) * Math.PI * 2 : 0;
    root.rotation.y = spin;
  };
  return { group, update, dispose: T.dispose };
}

/** A polished rocket that points the way it travels, with a porthole and a flickering flame. */
export function buildRocket(): Mascot {
  const T = tracker();
  const white = shell();
  const coral = accent(0xff6f9f, 0.4);
  const violet = accent(0x7a5cff, 0.45);
  const group = new THREE.Group();
  const root = new THREE.Group();
  group.add(root);

  const lathe = (pts: [number, number][], m: THREE.Material) => T.mesh(new THREE.LatheGeometry(pts.map(([r, y]) => new THREE.Vector2(r, y)), 48), m);
  // fuselage, then the nose cone in a second colour
  root.add(lathe([[0.001, -0.34], [0.1, -0.34], [0.15, -0.28], [0.185, -0.14], [0.2, 0.05], [0.185, 0.2], [0.15, 0.3]], white));
  root.add(lathe([[0.15, 0.299], [0.11, 0.38], [0.06, 0.46], [0.001, 0.56]], coral));
  // a coloured band between the two
  const band = T.mesh(new THREE.TorusGeometry(0.155, 0.012, 10, 40), violet);
  band.rotation.x = Math.PI / 2;
  band.position.y = 0.3;
  root.add(band);
  // porthole, facing +Z (towards the camera)
  const ring = T.mesh(new THREE.TorusGeometry(0.075, 0.017, 12, 36), violet);
  ring.position.set(0, 0.11, 0.185);
  root.add(ring);
  const win = T.mesh(
    new THREE.CircleGeometry(0.068, 28),
    new THREE.MeshPhysicalMaterial({ color: 0x6fe3ff, emissive: 0x2a8cff, emissiveIntensity: 0.7, roughness: 0.05, metalness: 0.1, clearcoat: 1 }),
  );
  win.position.set(0, 0.11, 0.19);
  root.add(win);
  // fins
  const finShape = new THREE.Shape();
  finShape.moveTo(0, 0); finShape.lineTo(0.17, -0.14); finShape.lineTo(0.17, -0.3); finShape.lineTo(0, -0.18); finShape.closePath();
  const finGeo = new THREE.ExtrudeGeometry(finShape, { depth: 0.025, bevelEnabled: true, bevelSize: 0.008, bevelThickness: 0.008, bevelSegments: 2 });
  finGeo.translate(0, 0, -0.0125);
  for (let k = 0; k < 3; k++) {
    const holder = new THREE.Group();
    holder.rotation.y = (k * Math.PI * 2) / 3;
    const fin = T.mesh(finGeo, coral);
    fin.position.set(0.15, -0.05, 0);
    holder.add(fin);
    root.add(holder);
  }
  // engine bell
  const bell = lathe([[0.08, -0.34], [0.1, -0.4], [0.115, -0.44]], accent(0x3a2a9a, 0.2));
  root.add(bell);
  // flame
  const jet = makeJet(T, 0.6, 0.12, WARM);
  jet.group.position.y = -0.45;
  root.add(jet.group);

  let heading = -0.35;
  const update = (i: MascotInput) => {
    const { t, vx, vy } = i;
    const speed = Math.hypot(vx, vy);
    const w = clamp(speed / 0.45);
    const rest = -0.32 + Math.sin(t * 0.8) * 0.05;
    const flight = Math.atan2(vy, vx) - Math.PI / 2;
    let diff = flight - heading;
    diff = Math.atan2(Math.sin(diff), Math.cos(diff));
    const want = heading + diff;
    heading += ((rest * (1 - w) + want * w) - heading) * 0.07;
    root.rotation.set(0, Math.sin(t * 0.9) * 0.35 + (i.hop > 0 ? easeInOut(i.hop) * Math.PI * 2 : 0), heading, "ZYX");
    root.position.y = Math.sin(t * 1.5) * 0.02;
    jet.update(t, 1 + Math.sin(t * 41) * 0.07 + Math.sin(t * 27) * 0.05 + w * 0.7 + clamp(i.near, 0, 1) * 0.2);
  };
  return { group, update, dispose: T.dispose };
}
