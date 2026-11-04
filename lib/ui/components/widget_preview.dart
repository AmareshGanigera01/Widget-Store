import 'package:flutter/material.dart';

import '../../models/widget_type.dart';
import '../icons.dart';

/// Visual preview of a widget built from its type and config. Used in the
/// marketplace, the editor (live preview), and My Widgets.
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({super.key, required this.type, required this.config, this.compact = false});

  final WidgetType type;
  final Map<String, Object?> config;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = Color((config['color'] as int?) ?? 0xFF6750A4);
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: Theme.of(context).brightness);
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: Builder(
        builder: (context) => Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: switch (type) {
            WidgetType.reminder => _Reminder(config, compact),
            WidgetType.cricketTimer => _Cricket(config, compact),
            WidgetType.textNotebook => _Capture(config, compact),
            WidgetType.microGoals => _Goals(config, compact),
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.icon, this.title, this.trailing);

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary,
          child: Icon(icon, color: scheme.onPrimary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer)),
      ],
    );
  }
}

class _Reminder extends StatelessWidget {
  const _Reminder(this.c, this.compact);

  final Map<String, Object?> c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(iconFor(c['category'] as String? ?? 'custom'), c['title'] as String? ?? '', c['time'] as String?),
        const SizedBox(height: 8),
        Text(
          c['message'] as String? ?? '',
          maxLines: compact ? 1 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
      ],
    );
  }
}

class _Cricket extends StatelessWidget {
  const _Cricket(this.c, this.compact);

  final Map<String, Object?> c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final runs = c['dailyRuns'] as int? ?? 300;
    final wickets = c['wickets'] as int? ?? 3;
    final apps = (c['trackedApps'] as List?)?.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(Icons.sports_cricket, 'Runs to defend', '$runs runs · $wickets wkts'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: 1, minHeight: 10, color: scheme.primary, backgroundColor: scheme.surface),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            'Tracking $apps app${apps == 1 ? '' : 's'} · Study hours ${c['studyStart']}–${c['studyEnd']}',
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ],
      ],
    );
  }
}

class _Capture extends StatelessWidget {
  const _Capture(this.c, this.compact);

  final Map<String, Object?> c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auto = c['autoRoute'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(Icons.edit_note, 'Send to Notebook', null),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Chip(avatar: const Icon(Icons.menu_book, size: 16), label: Text(c['defaultNotebook'] as String? ?? 'General')),
            if (auto && !compact) const Chip(avatar: Icon(Icons.auto_awesome, size: 16), label: Text('AI routing')),
            if (c['summarize'] == true && !compact) const Chip(label: Text('Summary')),
          ],
        ),
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Select text in any app → "Send to Notebook"', style: TextStyle(color: scheme.onPrimaryContainer)),
          ),
      ],
    );
  }
}

class _Goals extends StatelessWidget {
  const _Goals(this.c, this.compact);

  final Map<String, Object?> c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final steps = (c['steps'] as List?)?.whereType<String>().toList() ?? const [];
    final shown = compact ? steps.take(2) : steps.take(5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(Icons.checklist, c['goal'] as String? ?? '', '0/${steps.length}'),
        const SizedBox(height: 6),
        for (final s in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.check_box_outline_blank, size: 18, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onPrimaryContainer)),
                ),
              ],
            ),
          ),
        if (steps.length > shown.length)
          Text('+${steps.length - shown.length} more', style: TextStyle(color: scheme.onPrimaryContainer)),
      ],
    );
  }
}
