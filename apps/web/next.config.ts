import type { NextConfig } from "next";

const config: NextConfig = {
  // A self-contained server build, small enough for a container (Cloud Run) or any Node host.
  output: "standalone",
  reactStrictMode: true,
};

export default config;
