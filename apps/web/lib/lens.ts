// The hero hover lens: the pond (video, image or a generated plate) is drawn through a WebGL ripple shader.
import { pointer } from "./pointer";

export type LensSource = { kind: "video"; el: HTMLVideoElement } | { kind: "still"; el: TexImageSource & { width: number; height: number } };

const VERT = `attribute vec2 p; varying vec2 vUv; void main(){ vUv = p*0.5+0.5; gl_Position = vec4(p,0.0,1.0); }`;
const FRAG = `precision mediump float;
varying vec2 vUv;
uniform sampler2D tex; uniform vec2 mouse; uniform float time; uniform float presence;
uniform vec2 scale; uniform vec2 tilt; uniform float ambient;
void main(){
  float dist = distance(vUv, mouse);
  float ripple = sin(dist*20.0 - time*5.0)*0.006;
  float strength = smoothstep(0.2, 0.0, dist)*presence;
  vec2 offset = normalize(vUv - mouse + 1e-5)*ripple*strength;
  vec2 drift = vec2(sin(vUv.y*14.0 + time*0.6), cos(vUv.x*11.0 + time*0.5))*0.0016*ambient;
  vec2 c = (vUv - 0.5)*scale + 0.5 + tilt;
  vec2 o = offset + drift;
  float r = texture2D(tex, c + o + vec2(0.005,0.0)*strength).r;
  float g = texture2D(tex, c + o).g;
  float b = texture2D(tex, c + o - vec2(0.005,0.0)*strength).b;
  gl_FragColor = vec4(r,g,b,1.0);
}`;

/** Starts the lens. Returns a stop function, or null when WebGL is unavailable (the caller shows the plain video). */
export function startLens(canvas: HTMLCanvasElement, source: LensSource, onReady: () => void): (() => void) | null {
  const gl = canvas.getContext("webgl", { alpha: false, antialias: false }) as WebGLRenderingContext | null;
  if (!gl) return null;
  const sh = (type: number, src: string) => {
    const s = gl.createShader(type)!;
    gl.shaderSource(s, src);
    gl.compileShader(s);
    return gl.getShaderParameter(s, gl.COMPILE_STATUS) ? s : null;
  };
  const vs = sh(gl.VERTEX_SHADER, VERT);
  const fs = sh(gl.FRAGMENT_SHADER, FRAG);
  if (!vs || !fs) return null;
  const prog = gl.createProgram()!;
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);
  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) return null;
  gl.useProgram(prog);

  const buf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buf);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]), gl.STATIC_DRAW);
  const loc = gl.getAttribLocation(prog, "p");
  gl.enableVertexAttribArray(loc);
  gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);

  const tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex);
  gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

  const U = (n: string) => gl.getUniformLocation(prog, n);
  const uMouse = U("mouse"), uTime = U("time"), uPresence = U("presence"), uScale = U("scale"), uTilt = U("tilt"), uAmbient = U("ambient");

  const resize = () => {
    const dpr = Math.min(window.devicePixelRatio || 1, 1.5);
    canvas.width = Math.round(window.innerWidth * dpr);
    canvas.height = Math.round(window.innerHeight * dpr);
    gl.viewport(0, 0, canvas.width, canvas.height);
  };
  resize();
  window.addEventListener("resize", resize);

  let ready = source.kind === "still";
  let announced = false;
  if (source.kind === "video") {
    source.el.addEventListener("playing", () => (ready = true), { once: true });
  } else {
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, gl.RGB, gl.UNSIGNED_BYTE, source.el);
  }

  let raf = 0;
  let last = performance.now();
  const start = last;
  let presence = 0;
  let tx = 0, ty = 0;
  const loop = (now: number) => {
    raf = requestAnimationFrame(loop);
    const dt = Math.min((now - last) / 1000, 0.05);
    last = now;
    presence += ((pointer.inside ? 1 : 0) - presence) * (1 - Math.exp(-6 * dt));
    const k = 1 - Math.exp(-dt / 0.1);
    tx += (pointer.tx - tx) * k;
    ty += (pointer.ty - ty) * k;
    const ok = source.kind === "still" || (ready && !source.el.paused && source.el.readyState >= 2);
    if (!ok) return;
    if (source.kind === "video") gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, gl.RGB, gl.UNSIGNED_BYTE, source.el);
    const A = canvas.width / canvas.height;
    const V = source.kind === "video" ? (source.el.videoWidth || 1276) / (source.el.videoHeight || 720) : source.el.width / source.el.height;
    const sc = A > V ? [1, V / A] : [A / V, 1];
    const z = 0.975;
    const s = [sc[0] * z, sc[1] * z];
    gl.uniform2f(uMouse, pointer.u, 1 - pointer.v);
    gl.uniform1f(uTime, (now - start) / 1000);
    gl.uniform1f(uPresence, presence);
    gl.uniform2f(uScale, s[0], s[1]);
    gl.uniform2f(uTilt, tx * 0.009 * s[0], -ty * 0.009 * s[1]);
    gl.uniform1f(uAmbient, source.kind === "still" ? 1 : 0);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
    if (!announced) {
      announced = true;
      onReady();
    }
  };
  raf = requestAnimationFrame(loop);
  return () => {
    cancelAnimationFrame(raf);
    window.removeEventListener("resize", resize);
  };
}

/** A generated dusk plate for when no image or video is supplied: sky, horizon glow, water, soft light blooms. */
export function makeDuskPlate(night = false): HTMLCanvasElement {
  const c = document.createElement("canvas");
  c.width = 1600;
  c.height = 900;
  const g = c.getContext("2d")!;
  const sky = g.createLinearGradient(0, 0, 0, 900);
  if (night) {
    sky.addColorStop(0, "#07051f"); sky.addColorStop(0.5, "#120a3a"); sky.addColorStop(1, "#1a0f4d");
  } else {
    sky.addColorStop(0, "#2a1b66"); sky.addColorStop(0.42, "#6b3f9f"); sky.addColorStop(0.55, "#e58fb1"); sky.addColorStop(0.58, "#f3b3a0");
    sky.addColorStop(0.6, "#3a2a7a"); sky.addColorStop(1, "#150c40");
  }
  g.fillStyle = sky;
  g.fillRect(0, 0, 1600, 900);
  // water ripples
  g.globalAlpha = night ? 0.12 : 0.22;
  for (let i = 0; i < 90; i++) {
    const y = 540 + (i / 90) * 360;
    g.strokeStyle = night ? "#8c7bff" : "#ffd3e6";
    g.lineWidth = 1 + (i / 90) * 2;
    g.beginPath();
    for (let x = 0; x <= 1600; x += 20) g.lineTo(x, y + Math.sin(x * 0.012 + i) * (1 + i * 0.05));
    g.stroke();
  }
  g.globalAlpha = 1;
  // soft blooms (lanterns on the water) and, at night, stars
  const rnd = (() => { let s = 7; return () => ((s = (s * 9301 + 49297) % 233280) / 233280); })();
  for (let i = 0; i < 18; i++) {
    const x = 120 + rnd() * 1360, y = 600 + rnd() * 260, r = 30 + rnd() * 70;
    const rg = g.createRadialGradient(x, y, 0, x, y, r);
    rg.addColorStop(0, night ? "rgba(160,140,255,.35)" : "rgba(255,190,220,.5)");
    rg.addColorStop(1, "rgba(255,190,220,0)");
    g.fillStyle = rg;
    g.fillRect(x - r, y - r, r * 2, r * 2);
  }
  if (night) {
    g.fillStyle = "rgba(255,255,255,.8)";
    for (let i = 0; i < 160; i++) g.fillRect(rnd() * 1600, rnd() * 480, 1.4, 1.4);
  }
  return c;
}
