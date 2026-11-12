// The scene's media. The defaults are the files in public/media: the night desk clip (cleaned and looped) and its still,
// used for both the hero and the night scene, so visitors download the video once. Set a
// NEXT_PUBLIC_* variable to use another file, or set it to an empty value and the site draws a built-in stand-in instead
// (a generated dusk or night plate), so the page always works. See README.md for the exact specs.
export const assets = {
  /** Still image of the hero scene (a "day" plate), wide, about 2400 px. Also shown under reduced motion. */
  dayPlate: process.env.NEXT_PUBLIC_DAY_PLATE ?? "/media/day.jpg",
  /** Looping hero video, muted, no audio, first frame = last frame. The host must send Access-Control-Allow-Origin: *. */
  video: process.env.NEXT_PUBLIC_HERO_VIDEO ?? "/media/hero.mp4",
  /** The same scene at night, behind the call to action and footer. */
  nightPlate: process.env.NEXT_PUBLIC_NIGHT_PLATE ?? "/media/day.jpg",
  /** Optional looping video for the night scene (call to action and footer). Muted, no audio. Falls back to the night plate. */
  nightVideo: process.env.NEXT_PUBLIC_NIGHT_VIDEO ?? "/media/hero.mp4",
  /** A GLB 3D model that swims through the page. Must allow CORS. Its longest axis is its length, nose to tail. */
  model: process.env.NEXT_PUBLIC_MODEL_GLB ?? "",
  /** The built-in character used while there is no model file: "robot" (default), "rocket" or "plane". Try it with ?mascot=rocket. */
  mascot: process.env.NEXT_PUBLIC_MASCOT ?? "robot",
};

/** The current desktop release. The source repository is private, so the app is published from a public releases
 * repository that holds only the downloadable files, checksums and install notes. Bump `release.tag` for a new release. */
const PUBLIC = "https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases";
export const release = {
  tag: process.env.NEXT_PUBLIC_RELEASE_TAG ?? "v0.1.0-preview.1",
  file: "devpilot-linux-x64.tar.gz",
  label: "Linux x64 preview",
};

/** Where the downloads and docs live. */
export const links = {
  /** Direct download of the Linux package (starts the download straight away). */
  download: `${PUBLIC}/releases/download/${release.tag}/${release.file}`,
  /** The release page: notes, checksums and install steps. */
  releases: `${PUBLIC}/releases/tag/${release.tag}`,
  github: PUBLIC,
  docs: `${PUBLIC}#readme`,
  issues: `${PUBLIC}/issues`,
  api: process.env.NEXT_PUBLIC_API_URL ?? "https://devpilot-api-664564860639.asia-south1.run.app",
};
