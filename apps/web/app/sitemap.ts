import type { MetadataRoute } from "next";
import { getDocs } from "@/lib/docs";

export const dynamic = "force-static";
const SITE = "https://devpilot.web.app";

export default function sitemap(): MetadataRoute.Sitemap {
  return [{ url: SITE, changeFrequency: "weekly", priority: 1 }, ...getDocs().map((d) => ({ url: `${SITE}${d.href}`, changeFrequency: "weekly" as const, priority: d.slug ? 0.6 : 0.8 }))];
}
