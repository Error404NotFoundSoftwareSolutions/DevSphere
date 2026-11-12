// Capability: CAP-DESIGN-SYSTEM. Tests: TC-MD-01..
// Implemented here: a small, safe Markdown view for AI-written explanations: headings, paragraphs, bullet and
// numbered lists, fenced code, inline code and bold. Links, images and HTML are never active; they show as text.

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.source, {super.key});
  final String source;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final blocks = <Widget>[];
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final para = <String>[];

    void flush() {
      if (para.isEmpty) return;
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: BL.space3),
        child: Text.rich(_inline(para.join(' '), text.bodyMedium!)),
      ));
      para.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final t = line.trim();
      if (t.startsWith('```')) {
        flush();
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        blocks.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: BL.space3),
          padding: const EdgeInsets.all(BL.space3),
          decoration: BoxDecoration(
              color: BL.editorBackground,
              borderRadius: BorderRadius.circular(BL.radiusMd)),
          child: SelectableText(code.join('\n'),
              style:
                  BL.codeStyle.copyWith(color: BL.editorText, fontSize: 12.5)),
        ));
        continue;
      }
      if (t.isEmpty) {
        flush();
        continue;
      }
      final heading = RegExp(r'^(#{1,4})\s+(.*)$').firstMatch(t);
      if (heading != null) {
        flush();
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: BL.space2, bottom: BL.space2),
          child: Text(heading.group(2)!,
              style: heading.group(1)!.length <= 2
                  ? text.titleLarge
                  : text.titleMedium),
        ));
        continue;
      }
      final bullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(t);
      final numbered = RegExp(r'^(\d{1,2})[.)]\s+(.*)$').firstMatch(t);
      if (bullet != null || numbered != null) {
        flush();
        final marker = bullet != null ? '•' : '${numbered!.group(1)}.';
        final body = bullet != null ? bullet.group(1)! : numbered!.group(2)!;
        blocks.add(Padding(
          padding: const EdgeInsets.only(left: BL.space2, bottom: BL.space1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 22, child: Text(marker, style: text.bodyMedium)),
            Expanded(child: Text.rich(_inline(body, text.bodyMedium!))),
          ]),
        ));
        continue;
      }
      para.add(t.startsWith('> ') ? t.substring(2) : t);
    }
    flush();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  /// `code` and **bold**; everything else is plain text.
  static TextSpan _inline(String s, TextStyle base) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'`([^`]+)`|\*\*([^*]+)\*\*');
    var last = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > last) spans.add(TextSpan(text: s.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(
            text: m.group(1),
            style: BL.codeStyle.copyWith(
                fontSize: (base.fontSize ?? 14) - 1,
                backgroundColor: BL.surfaceMuted)));
      } else {
        spans.add(TextSpan(
            text: m.group(2),
            style: const TextStyle(fontWeight: FontWeight.w600)));
      }
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}
