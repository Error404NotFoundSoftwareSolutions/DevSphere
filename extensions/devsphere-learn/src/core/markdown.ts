// Capability: CAP-COURSE-PLAYER. Rules: SEC-21, SEC-27. Tests: TC-LRN-30-xx.
// Implemented here: a tiny markdown renderer for lab text. Everything is escaped first; the only
// tags produced are fixed ones. Raw HTML, comments and links never become active.
import { escapeText } from './escape';

function inline(escaped: string): string {
  const codes: string[] = [];
  let s = escaped.replace(/`([^`]+)`/g, (_m, c: string) => {
    codes.push(`<code>${c}</code>`);
    return `\u0000${codes.length - 1}\u0000`;
  });
  s = s.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1');
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  // eslint-disable-next-line no-control-regex
  return s.replace(/\u0000(\d+)\u0000/g, (_m, i: string) => codes[Number(i)] ?? '');
}

export function renderMarkdownSafe(markdown: string): string {
  const src = markdown.replace(/<!--[\s\S]*?-->/g, '').replace(/\r\n?/g, '\n');
  const out: string[] = [];
  const para: string[] = [];
  const quote: string[] = [];
  let list: { tag: 'ul' | 'ol'; items: string[] } | undefined;
  const flushPara = (): void => {
    if (para.length) out.push(`<p>${inline(escapeText(para.join(' ')))}</p>`);
    para.length = 0;
  };
  const flushQuote = (): void => {
    if (quote.length) out.push(`<blockquote><p>${inline(escapeText(quote.join(' ')))}</p></blockquote>`);
    quote.length = 0;
  };
  const flushList = (): void => {
    if (list) out.push(`<${list.tag}>${list.items.map((i) => `<li>${inline(escapeText(i))}</li>`).join('')}</${list.tag}>`);
    list = undefined;
  };
  const flush = (): void => { flushPara(); flushQuote(); flushList(); };
  let code: string[] | undefined;
  for (const line of src.split('\n')) {
    if (line.startsWith('```')) {
      if (code === undefined) {
        flush();
        code = [];
      } else {
        out.push(`<pre><code>${escapeText(code.join('\n') + '\n')}</code></pre>`);
        code = undefined;
      }
      continue;
    }
    if (code !== undefined) {
      code.push(line);
      continue;
    }
    const h = /^(#{1,3})\s+(.+)$/.exec(line);
    const ul = /^\s{0,3}[-*]\s+(.+)$/.exec(line);
    const ol = /^\s{0,3}\d{1,2}[.)]\s+(.+)$/.exec(line);
    const bq = /^>\s?(.*)$/.exec(line);
    if (h) {
      flush();
      const level = (h[1] ?? '#').length;
      out.push(`<h${level}>${inline(escapeText(h[2] ?? ''))}</h${level}>`);
    } else if (ul || ol) {
      flushPara(); flushQuote();
      const tag = ul ? 'ul' : 'ol';
      if (list && list.tag !== tag) flushList();
      list ??= { tag, items: [] };
      list.items.push(((ul ?? ol)?.[1] ?? '').trim());
    } else if (bq) {
      flushPara(); flushList();
      if ((bq[1] ?? '').trim() === '') flushQuote(); else quote.push((bq[1] ?? '').trim());
    } else if (line.trim() === '') {
      flush();
    } else if (list && /^\s{2,}\S/.test(line)) {
      const last = list.items.length - 1;
      list.items[last] = `${list.items[last] ?? ''} ${line.trim()}`;
    } else {
      flushQuote(); flushList();
      para.push(line.trim());
    }
  }
  if (code !== undefined) out.push(`<pre><code>${escapeText(code.join('\n') + '\n')}</code></pre>`);
  flush();
  return out.join('\n');
}
