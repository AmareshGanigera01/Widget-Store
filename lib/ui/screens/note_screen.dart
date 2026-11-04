import 'package:flutter/material.dart';

import '../../models/notebook.dart';

/// Shows a note's structured markdown. A tiny renderer covers what the
/// processor emits (headings, bullets, bold) without another dependency.
class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = note.createdAt;
    return Scaffold(
      appBar: AppBar(title: Text(note.title, overflow: TextOverflow.ellipsis)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(note.title, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'
              '${note.sourceApp == null ? '' : ' · from ${note.sourceApp}'}',
              style: text.bodySmall,
            ),
            if (note.summary != null) ...[
              const SizedBox(height: 12),
              Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(note.summary!)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ..._render(context, note.content),
            const Divider(height: 32),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Original text'),
              children: [Text(note.rawText)],
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _render(BuildContext context, String md) {
    final text = Theme.of(context).textTheme;
    final out = <Widget>[];
    for (final raw in md.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        out.add(const SizedBox(height: 8));
      } else if (line.startsWith('#')) {
        final level = RegExp(r'^#+').firstMatch(line)!.group(0)!.length;
        final style = level <= 1 ? text.titleLarge : (level == 2 ? text.titleMedium : text.titleSmall);
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(line.replaceFirst(RegExp(r'^#+\s*'), ''), style: style),
        ));
      } else if (RegExp(r'^\s*[-*]\s').hasMatch(line)) {
        out.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const Text('•  '), Expanded(child: _inline(line.replaceFirst(RegExp(r'^\s*[-*]\s+'), ''), text.bodyMedium))],
          ),
        ));
      } else {
        out.add(_inline(line, text.bodyMedium));
      }
    }
    return out;
  }

  /// Handles **bold** spans.
  static Widget _inline(String s, TextStyle? style) {
    final spans = <TextSpan>[];
    final parts = s.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i], style: i.isOdd ? const TextStyle(fontWeight: FontWeight.bold) : null));
    }
    return Text.rich(TextSpan(children: spans, style: style));
  }
}
