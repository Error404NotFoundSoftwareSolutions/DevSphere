// The documentation: Markdown files in content/docs, read at build time (the site is a static export).
// Each file starts with a front matter block: title, description, section, order. The slug is the file path without
// ".md"; "index.md" is the docs home. Notes are written as ":::note Title" ... ":::" (also tip, warning, important).
import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import { Marked, type Renderer, type Tokens } from "marked";

const DIR = path.join(process.cwd(), "content", "docs");
export const SECTIONS = ["Get started", "Using DevPilot", "How it works", "Reference", "Project"] as const;

export type Doc = { slug: string; href: string; title: string; description: string; section: string; order: number; body: string };
export type Heading = { id: string; text: string; depth: number };

function walk(dir: string): string[] {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(dir, e.name)) : e.name.endsWith(".md") ? [path.join(dir, e.name)] : []));
}

let cache: Doc[] | null = null;
export function getDocs(): Doc[] {
  if (cache) return cache;
  const docs = walk(DIR).map((file) => {
    const raw = fs.readFileSync(file, "utf8");
    const { data, content } = matter(raw);
    const rel = path.relative(DIR, file).replace(/\\/g, "/").replace(/\.md$/, "");
    const slug = rel === "index" ? "" : rel;
    for (const k of ["title", "description", "section"] as const) {
      if (typeof data[k] !== "string" || !data[k]) throw new Error(`docs/${rel}.md: front matter "${k}" is missing`);
    }
    if (!SECTIONS.includes(data.section)) throw new Error(`docs/${rel}.md: unknown section "${data.section}"`);
    return { slug, href: slug ? `/docs/${slug}` : "/docs", title: data.title as string, description: data.description as string, section: data.section as string, order: Number(data.order ?? 100), body: content };
  });
  docs.sort((a, b) => SECTIONS.indexOf(a.section as never) - SECTIONS.indexOf(b.section as never) || a.order - b.order || a.title.localeCompare(b.title));
  cache = docs;
  return docs;
}

export const findDoc = (slug: string): Doc | undefined => getDocs().find((d) => d.slug === slug);

export function getNav(): { title: string; items: { title: string; href: string }[] }[] {
  return SECTIONS.map((s) => ({ title: s, items: getDocs().filter((d) => d.section === s).map((d) => ({ title: d.title, href: d.href })) })).filter((s) => s.items.length);
}

export function neighbours(doc: Doc): { prev?: Doc; next?: Doc } {
  const all = getDocs();
  const i = all.findIndex((d) => d.slug === doc.slug);
  return { prev: all[i - 1], next: all[i + 1] };
}

export const slugify = (s: string): string =>
  s.toLowerCase().replace(/<[^>]+>/g, "").replace(/&[a-z]+;/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "section";

const CALLOUT_TITLES: Record<string, string> = { note: "Note", tip: "Tip", warning: "Warning", important: "Important" };
function callouts(md: string): string {
  return md.replace(/^:::(note|tip|warning|important)[ \t]*(.*)\n([\s\S]*?)\n:::[ \t]*$/gm, (_m, kind: string, title: string, inner: string) =>
    `<div class="callout c-${kind}">\n\n<p class="callout-title">${title.trim() || CALLOUT_TITLES[kind]}</p>\n\n${inner}\n\n</div>`);
}

const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

export function render(body: string): { html: string; headings: Heading[] } {
  const headings: Heading[] = [];
  const used = new Map<string, number>();
  const marked = new Marked({
    gfm: true,
    renderer: {
      heading(this: Renderer, t: Tokens.Heading) {
        const inner = this.parser.parseInline(t.tokens);
        let id = slugify(t.text);
        const n = used.get(id) ?? 0;
        used.set(id, n + 1);
        if (n) id = `${id}-${n}`;
        if (t.depth === 2 || t.depth === 3) headings.push({ id, text: t.text.replace(/`/g, ""), depth: t.depth });
        return `<h${t.depth} id="${id}">${inner}<a class="anchor" href="#${id}" aria-label="Link to this section">#</a></h${t.depth}>\n`;
      },
      code(t: Tokens.Code) {
        const lang = (t.lang ?? "").split(/\s/)[0];
        return `<div class="dcode"><div class="code-bar"><span>${esc(lang || "text")}</span><button type="button" class="code-copy" aria-label="Copy code">Copy</button></div><pre><code>${esc(t.text)}</code></pre></div>\n`;
      },
      link(this: Renderer, t: Tokens.Link) {
        const external = /^https?:\/\//i.test(t.href);
        const inner = this.parser.parseInline(t.tokens);
        return `<a href="${esc(t.href)}"${t.title ? ` title="${esc(t.title)}"` : ""}${external ? ' target="_blank" rel="noopener noreferrer"' : ""}>${inner}</a>`;
      },
    },
  });
  let html = marked.parse(callouts(body)) as string;
  html = html.replace(/<table>/g, '<div class="table-wrap"><table>').replace(/<\/table>/g, "</table></div>");
  return { html, headings };
}

/** Plain text of a page, for the search index. */
export function plainText(body: string): string {
  return body
    .replace(/^:::.*$/gm, " ")
    .replace(/```[a-z]*\n?/g, " ")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, " ")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/<[^>]+>/g, " ")
    .replace(/[#>*_`|]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}
