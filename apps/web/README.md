# DevPilot website

The hosted landing page for DevPilot (Next.js 16, React 19, three.js). It is a website, separate from the Flutter desktop app in `apps/desktop`.

## Run

```bash
npm install
npm run dev        # http://localhost:3100
npm run build && npm start
```

## What is on the page

1. A fixed scene: looping pond video drawn through a WebGL hover-ripple lens, fading to a violet gradient and then a night plate as you scroll.
2. A 3D character that flies to a new spot in each section. Until you supply a model it is a smiling robot built in code: its eyes follow the mouse, it drifts toward the cursor, waves when the cursor is close, and does a happy spin-hop when you click. `?mascot=rocket` shows a rocket that points the way it flies instead (set it for everyone with `NEXT_PUBLIC_MASCOT=rocket`); `?mascot=plane` is the old crystal paper plane. A supplied GLB replaces all three and swims behind the glass cards.
3. Glass UI, a dashboard preview (labelled sample data), a typing terminal, stepped role cards, and a footer with the live service status chip.

Everything degrades gracefully: no video falls back to a still, no still falls back to a generated dusk/night plate, no WebGL falls back to plain CSS layers, and `prefers-reduced-motion` turns the motion off.

## Supplying your own media

The defaults are the files already in `public/media/` (the night desk clip, cleaned of its watermark and looped, plus its still). To use other files, put them in `public/media/` (or any CORS-enabled URL) and set these in `.env.local`:

```bash
NEXT_PUBLIC_HERO_VIDEO=/media/hero.mp4
NEXT_PUBLIC_DAY_PLATE=/media/day.jpg
NEXT_PUBLIC_NIGHT_PLATE=/media/night.jpg
NEXT_PUBLIC_NIGHT_VIDEO=/media/night.mp4   # optional, plays behind the footer
NEXT_PUBLIC_MODEL_GLB=/media/koi.glb
NEXT_PUBLIC_API_URL=https://your-api.example.com   # optional, defaults to the hosted API
```

| Asset | Spec |
| --- | --- |
| Hero video | MP4 (H.264), muted, no audio track, seamless loop (first frame equals last frame), about 1920x1080, under 8 MB. If it is on another host it must send `Access-Control-Allow-Origin: *`, otherwise WebGL cannot read it. |
| Day plate | 16:9 still, about 2400 px wide. Shown behind the video and used if the video cannot play. |
| Night plate | 16:9 still, about 2400 px wide, darker and cooler than the day plate. |
| Model | Binary glTF (`.glb`), single mesh preferred, under 5 MB. The longest axis is scaled to length 1, the nose should point along +X (it is auto-oriented along the longest axis). |

## Downloads

The source repository is private, so the app is published from the public repository
[devpilot-releases](https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases). Every "Download" button
links straight to the release file; the "Get DevPilot" button opens the release page. For a new release, change
`release.tag` in `lib/assets.ts` (or set `NEXT_PUBLIC_RELEASE_TAG`) and rebuild. Steps for publishing a release are in
`docs/RELEASING.md`.

## Hosting

`next.config.ts` uses `output: "standalone"`, so it ships as a small Node server.

```bash
docker build -t devpilot-web .
docker run -p 8080:8080 devpilot-web
```

Cloud Run works as-is with that image. Pass the `NEXT_PUBLIC_*` values as build args, since Next inlines them at build time.
