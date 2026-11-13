import type { Metadata } from "next";
import DocsChrome from "@/components/docs/DocsChrome";
import { getNav } from "@/lib/docs";
import "./docs.css";

export const metadata: Metadata = {
  title: { default: "Documentation · DevPilot", template: "%s · DevPilot docs" },
  description: "How to install DevPilot, build a learning path, practise in your own VS Code, and how the AI, scoring and privacy work.",
};

export default function DocsLayout({ children }: { children: React.ReactNode }) {
  return <DocsChrome nav={getNav()}>{children}</DocsChrome>;
}
