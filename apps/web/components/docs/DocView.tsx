import Link from "next/link";
import DocsToc from "./DocsToc";
import { neighbours, render, type Doc } from "@/lib/docs";

export default function DocView({ doc }: { doc: Doc }) {
  const { html, headings } = render(doc.body);
  const { prev, next } = neighbours(doc);
  return (
    <div className="docs-page">
      <article className="docs-article">
        <p className="docs-crumb">{doc.section}</p>
        <h1>{doc.title}</h1>
        <p className="docs-lead">{doc.description}</p>
        <div className="docs-prose" dangerouslySetInnerHTML={{ __html: html }} />
        <nav className="docs-pager" aria-label="Previous and next page">
          {prev ? <Link href={prev.href} className="prev"><small>Previous</small><span>{prev.title}</span></Link> : <i />}
          {next ? <Link href={next.href} className="next"><small>Next</small><span>{next.title}</span></Link> : <i />}
        </nav>
        <p className="docs-foot">DevPilot 0.1.0 preview · Found a mistake or something unclear? <a href="https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/issues" target="_blank" rel="noopener noreferrer">Tell us</a>.</p>
      </article>
      <DocsToc headings={headings} />
    </div>
  );
}
