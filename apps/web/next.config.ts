import type { NextConfig } from "next";

const config: NextConfig = {
  // A static export (plain files in out/): the page needs no server, so it is hosted for free on Firebase Hosting
  // (https://devpilot.web.app). Run `npm run deploy` to publish.
  output: "export",
  reactStrictMode: true,
  images: { unoptimized: true },
};

export default config;
