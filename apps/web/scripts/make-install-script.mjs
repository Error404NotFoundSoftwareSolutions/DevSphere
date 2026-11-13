// Writes public/install.ps1 from scripts/install.template.ps1 and release-info.json.
// release-info.json must be updated with every release (the tag and the SHA-256 of the Windows installer). The script
// refuses to build when the tag differs from the one in lib/assets.ts, so the site and the one-line install cannot drift apart.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const info = JSON.parse(fs.readFileSync(path.join(root, "release-info.json"), "utf8"));
const assets = fs.readFileSync(path.join(root, "lib", "assets.ts"), "utf8");
const siteTag = /NEXT_PUBLIC_RELEASE_TAG \?\? "([^"]+)"/.exec(assets)?.[1];
if (siteTag !== info.tag) {
  console.error(`install.ps1: release-info.json says ${info.tag} but lib/assets.ts says ${siteTag}. Update them together.`);
  process.exit(1);
}
if (!/^[0-9a-f]{64}$/.test(info.windowsSetup.sha256)) {
  console.error("install.ps1: windowsSetup.sha256 is not a SHA-256.");
  process.exit(1);
}
const url = `https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases/download/${info.tag}/${info.windowsSetup.file}`;
const out = fs
  .readFileSync(path.join(root, "scripts", "install.template.ps1"), "utf8")
  .replaceAll("__TAG__", info.tag)
  .replaceAll("__URL__", url)
  .replaceAll("__SHA256__", info.windowsSetup.sha256);
fs.mkdirSync(path.join(root, "public"), { recursive: true });
fs.writeFileSync(path.join(root, "public", "install.ps1"), out.replace(/\r?\n/g, "\n"), "utf8");
console.log(`install.ps1 written for ${info.tag}`);
