import { getDocs, plainText } from "@/lib/docs";

export const dynamic = "force-static";

export function GET() {
  const index = getDocs().map((d) => ({ title: d.title, href: d.href, section: d.section, text: `${d.description} ${plainText(d.body)}`.slice(0, 7000) }));
  return Response.json(index);
}
