import type { Metadata } from "next";
import { notFound } from "next/navigation";
import DocView from "@/components/docs/DocView";
import { findDoc } from "@/lib/docs";

export const metadata: Metadata = { title: { absolute: "Documentation · DevPilot" } };

export default function DocsHome() {
  const doc = findDoc("");
  if (!doc) notFound();
  return <DocView doc={doc} />;
}
