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
const BLUE: Palette = { outer: 0x2b7bff, outerHot: 0x9fe6ff, mid: 0x3fe0ff, midHot: 0xe6fbff, core: 0xd6f8ff, glow: 0x39b8ff, spark: 0x9ff0ff };
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

/** A friendly plush robot (the pitch-deck mascot): squircle head with a glossy black screen and happy glowing eyes, indigo
 * ear muffs and mitten hands, an amber antenna ball, a glowing cyan chest button and a cyan jet. White fur with soft blue shading. */
export function buildRobot(): Mascot {
  const T = tracker();
  const INDIGO = 0x4b3fd6;
  const CYAN = 0x4fe3ff;
  const glass = new THREE.MeshPhysicalMaterial({ color: 0x05081a, roughness: 0.05, metalness: 0.3, clearcoat: 1, clearcoatRoughness: 0.02, envMapIntensity: 1.4 });
  const indigoMat = accent(INDIGO, 0.25);
  const eyeMat = glowMat(CYAN);
  const WHITE: FurSpec = { tip: 0xf6f8ff, root: 0x6f86d6, len: 0.044 };
  const BODYFUR: FurSpec = { tip: 0xe6ecff, root: 0x5d73c8, len: 0.044 };
  const MITT: FurSpec = { tip: 0x6f60f2, root: 0x2c1fa8, len: 0.034 };
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

  // --- body (small and round, tucked under the big head)
  const bodyGeo = new THREE.SphereGeometry(1, 56, 42);
  bodyGeo.scale(0.205, 0.265, 0.17);
  // a little narrower towards the bottom: an egg, not a ball
  const bp = bodyGeo.getAttribute('position') as THREE.BufferAttribute;
  for (let i = 0; i < bp.count; i++) {
    const y = bp.getY(i) / 0.265; // -1 bottom .. 1 top
    const k = 1 - 0.14 * Math.max(0, -y);
    bp.setX(i, bp.getX(i) * k);
    bp.setZ(i, bp.getZ(i) * k);
  }
  bodyGeo.computeVertexNormals();
  const body = furry(bodyGeo, BODYFUR);
  body.position.y = -0.37;
  root.add(body);
  // a short indigo neck makes the head and body two clear shapes
  const neck = T.mesh(new THREE.CylinderGeometry(0.07, 0.085, 0.14, 24), accent(0x3a2fb8, 0.15));
  neck.position.y = -0.14;
  root.add(neck);
  // glowing cyan chest button with a ring and a soft halo
  const haloTex = radial(CYAN);
  T.trackTex(haloTex);
  const haloMat = new THREE.SpriteMaterial({ map: haloTex, blending: THREE.AdditiveBlending, depthWrite: false, transparent: true, opacity: 0.55, toneMapped: false });
  T.track(haloMat);
  const halo = new THREE.Sprite(haloMat);
  halo.position.set(0, -0.3, 0.235);
  halo.scale.setScalar(0.2);
  root.add(halo);
  const button = T.mesh(new THREE.CircleGeometry(0.043, 32), glowMat(CYAN));
  button.position.set(0, -0.3, 0.218);
  const ring = T.mesh(new THREE.TorusGeometry(0.054, 0.007, 10, 36), glowMat(0xa8f4ff, 0.9));
  ring.position.set(0, -0.3, 0.218);
  root.add(button, ring);

  // --- head (a big squircle)
  const head = new THREE.Group();
  head.position.y = 0.15;
  root.add(head);
  head.add(furry(new RoundedBoxGeometry(0.66, 0.52, 0.46, 10, 0.23), WHITE));
  const screen = T.mesh(new RoundedBoxGeometry(0.45, 0.31, 0.05, 8, 0.15), glass);
  screen.position.z = 0.27;
  head.add(screen);
  const face = new THREE.Group(); // slides a little towards the pointer
  face.position.z = 0.305;
  head.add(face);
  // happy eyes: glowing arches ( ^ ^ ), each with a soft outer glow
  const archGeo = new THREE.TorusGeometry(0.052, 0.0135, 10, 28, Math.PI);
  const archGlowGeo = new THREE.TorusGeometry(0.052, 0.024, 10, 28, Math.PI);
  const glowEye = new THREE.MeshBasicMaterial({ color: CYAN, transparent: true, opacity: 0.16, blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false });
  const mkEye = (x: number) => {
    const g = new THREE.Group();
    g.position.set(x, 0.045, 0);
    g.add(T.mesh(archGeo, eyeMat), T.mesh(archGlowGeo, glowEye));
    face.add(g);
    return g;
  };
  const eyeL = mkEye(-0.118);
  const eyeR = mkEye(0.118);
  const smile = T.mesh(new THREE.TorusGeometry(0.038, 0.0105, 10, 24, Math.PI), eyeMat);
  smile.rotation.z = Math.PI; // the lower half of a ring is a smile
  smile.position.set(0, -0.035, 0);
  face.add(smile);
  const cheekMat = glowMat(0xff7fb4, 0.75);
  const cheekGeo = new THREE.CircleGeometry(0.026, 24);
  const cheekL = T.mesh(cheekGeo, cheekMat);
  const cheekR = T.mesh(cheekGeo, cheekMat);
  cheekL.position.set(-0.17, -0.02, 0);
  cheekR.position.set(0.17, -0.02, 0);
  cheekL.scale.set(1.35, 0.8, 1);
  cheekR.scale.set(1.35, 0.8, 1);
  face.add(cheekL, cheekR);
  // indigo ear muffs
  const podGeo = new THREE.CylinderGeometry(0.088, 0.088, 0.07, 32);
  const podL = furry(podGeo, MITT);
  const podR = furry(podGeo, MITT);
  podL.rotation.z = podR.rotation.z = Math.PI / 2;
  podL.position.set(-0.37, -0.005, 0);
  podR.position.set(0.37, -0.005, 0);
  head.add(podL, podR);
  // antenna: a thin indigo stem and an amber ball
  const stem = T.mesh(new THREE.CylinderGeometry(0.011, 0.011, 0.1, 10), indigoMat);
  stem.position.y = 0.3;
  head.add(stem);
  const bulb = T.mesh(new THREE.SphereGeometry(0.042, 24, 18), glowMat(0xffb52e));
  bulb.position.y = 0.375;
  head.add(bulb);

  // --- arms: short and thick, with indigo mitten hands (pivot at the shoulder)
  const armGeo = new THREE.CapsuleGeometry(0.064, 0.1, 10, 18);
  const handGeo = new THREE.SphereGeometry(0.078, 22, 18);
  handGeo.scale(1, 0.9, 0.95);
  const knuckle = new THREE.SphereGeometry(0.024, 12, 10);
  const knuckleMat = accent(0x6f60f2, 0.2);
  const mkArm = (side: 1 | -1) => {
    const pivot = new THREE.Group();
    pivot.position.set(side * 0.15, -0.27, 0.01);
    const a = furry(armGeo, WHITE);
    a.position.y = -0.11;
    const h = furry(handGeo, MITT);
    h.position.y = -0.235;
    for (const [kx, ky] of [[-0.034, -0.052], [0, -0.062], [0.034, -0.052]] as const) {
      const k = T.mesh(knuckle, knuckleMat);
      k.position.set(kx, ky, 0.07);
      h.add(k);
    }
    pivot.add(a, h);
    root.add(pivot);
    return pivot;
  };
  const armL = mkArm(-1);
  const armR = mkArm(1);

  // --- cyan jet under the body, from an indigo nozzle
  const jet = makeJet(T, 0.5, 0.085, BLUE);
  jet.group.position.y = -0.64;
  root.add(jet.group);
  const nozzle = T.mesh(new THREE.CylinderGeometry(0.1, 0.075, 0.045, 28), indigoMat);
  nozzle.position.y = -0.625;
  root.add(nozzle);

  let blink = 0, nextBlink = 2.2, spin = 0, lift = 0;
  const update = (i: MascotInput) => {
    const { t, look, vx, near, hop } = i;
    furTime.value = t;
    // float
    root.position.y = Math.sin(t * 1.6) * 0.025 + (hop > 0 ? Math.sin(hop * Math.PI) * 0.08 : 0);
    root.rotation.z += (clamp(-vx * 0.16, -0.35, 0.35) - root.rotation.z) * 0.1; // lean into the move
    // look at the pointer: eyes slide, head turns
    face.position.x += (look.x * 0.04 - face.position.x) * 0.2;
    face.position.y += (look.y * 0.025 - face.position.y) * 0.2;
    head.rotation.y += (look.x * 0.4 - head.rotation.y) * 0.12;
    head.rotation.x += (-look.y * 0.2 - head.rotation.x) * 0.12;
    // blink: the arches flatten
    nextBlink -= i.dt;
    if (nextBlink <= 0) { blink = 0.14; nextBlink = 2.4 + Math.random() * 2.6; }
    blink = Math.max(0, blink - i.dt);
    const joy = clamp(near * 0.7 + hop);
    const eyeY = blink > 0 ? 0.1 : 1 + joy * 0.1;
    eyeL.scale.y = eyeR.scale.y += (eyeY - eyeR.scale.y) * 0.5;
    eyeL.scale.x = eyeR.scale.x = 1 + joy * 0.05;
    smile.scale.setScalar(1 + joy * 0.35);
    cheekMat.opacity = 0.6 + joy * 0.35;
    // arms: a slow bob; the left arm (on the viewer's left) waves up when the pointer is near, as in the slides
    const wave = clamp(near * 1.2 + hop);
    lift += (wave - lift) * 0.12;
    armR.rotation.z = 0.72 + Math.sin(t * 1.3 + 1) * 0.07;
    armL.rotation.z = -(0.72 + lift * (1.55 + Math.sin(t * 9) * 0.28)) - (1 - lift) * Math.sin(t * 1.3) * 0.07;
    // antenna ball pulses
    bulb.scale.setScalar(1 + Math.sin(t * 3) * 0.12);
    haloMat.opacity = 0.45 + Math.sin(t * 2.4) * 0.12;
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
