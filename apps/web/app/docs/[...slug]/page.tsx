import type { Metadata } from "next";
import { notFound } from "next/navigation";
import DocView from "@/components/docs/DocView";
import { findDoc, getDocs } from "@/lib/docs";

export const dynamicParams = false;
export const generateStaticParams = () => getDocs().filter((d) => d.slug).map((d) => ({ slug: d.slug.split("/") }));

export async function generateMetadata({ params }: { params: Promise<{ slug: string[] }> }): Promise<Metadata> {
  const doc = findDoc((await params).slug.join("/"));
  return doc ? { title: doc.title, description: doc.description } : {};
}

export default async function DocPage({ params }: { params: Promise<{ slug: string[] }> }) {
  const doc = findDoc((await params).slug.join("/"));
  if (!doc) notFound();
  return <DocView doc={doc} />;
}
