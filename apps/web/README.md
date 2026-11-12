# DevPilot website

The landing page for DevPilot (Next.js 16, React 19, three.js), live at **https://devpilot.web.app**. It is a website, separate from the Flutter desktop app in `apps/desktop`.

## Run

```bash
npm install
npm run dev        # http://localhost:3100
npm run build && npm start   # serves the static export in out/ on http://localhost:3100
npm run deploy               # builds and publishes to https://devpilot.web.app
```

## What is on the page

1. A fixed scene: the looping night desk video drawn through a WebGL hover-ripple lens, fading to a violet gradient and then a night plate as you scroll.
2. A 3D character that flies to a new spot in each section. Until you supply a model it is a smiling robot built in code: its eyes follow the mouse, it drifts toward the cursor, waves when the cursor is close, and does a happy spin-hop when you click. `?mascot=rocket` shows a rocket that points the way it flies instead (set it for everyone with `NEXT_PUBLIC_MASCOT=rocket`); `?mascot=plane` is the old crystal paper plane. A supplied GLB replaces all three and swims behind the glass cards.
3. Glass UI, a dashboard preview (labelled sample data), a typing terminal, stepped role cards, and a footer with the live service status chip.

Everything degrades gracefully: no video falls back to a still, no still falls back to a generated dusk/night plate, no WebGL falls back to plain CSS layers, and `prefers-reduced-motion` turns the motion off.

## Supplying your own media

The defaults are the files already in `public/media/` (the night desk clip, cleaned of its watermark and looped, plus its still, used for both the hero and the night scene). The day version of the clip is kept in `public/media/alt/` and is not uploaded. To use other files, put them in `public/media/` (or any CORS-enabled URL) and set these in `.env.local`:

```bash
NEXT_PUBLIC_HERO_VIDEO=/media/hero.mp4
NEXT_PUBLIC_DAY_PLATE=/media/day.jpg
NEXT_PUBLIC_NIGHT_PLATE=/media/day.jpg     # default: the same still as the hero
NEXT_PUBLIC_NIGHT_VIDEO=/media/hero.mp4    # default: the same clip as the hero, so it downloads once
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

## Hosting (free)

The page needs no server, so `next.config.ts` uses `output: "export"` and the site is plain files in `out/`, hosted on
**Firebase Hosting** in the `devpilot-app` project, site `devpilot` (`firebase.json` and `.firebaserc` in this folder;
they only touch hosting, never the Firestore rules or auth settings in the repository root).

```bash
npm run deploy
```

The Firebase CLI must be signed in with the Google account that owns the `devpilot-app` project. If it says
`403 The caller does not have permission`, switch account with `firebase login:use <owner account>` or add
`--account <owner account>` to the deploy command.

**Cost:** Firebase Hosting includes 10 GB of storage and 10 GB of transfer a month at no cost; the site uses about
3.5 MB of storage, and a first visit downloads about 2.5 MB (the 1.6 MB video, three.js and fonts), so roughly 4,000 new
visitors a month are free. Videos are cached for a week and the scripts for a year, so return visits cost almost
nothing. Above the free amount transfer is billed per GB.
