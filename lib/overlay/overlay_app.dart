import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../data/app_database.dart';
import '../data/repositories.dart';
import '../models/installed_widget.dart';
import '../models/notebook.dart';
import '../models/widget_type.dart';
import '../services/cricket.dart';
import '../services/micro_goals.dart';
import '../ui/icons.dart';
import '../ui/theme.dart';

/// Sizes in dp, as expected by flutter_overlay_window.
const bubbleSize = 64;
const panelWidth = 320;
const panelHeight = 460;

/// UI that runs inside the WindowManager overlay, on top of other apps.
class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      home: const _OverlayRoot(),
    );
  }
}

class _OverlayRoot extends StatefulWidget {
  const _OverlayRoot();

  @override
  State<_OverlayRoot> createState() => _OverlayRootState();
}

class _OverlayRootState extends State<_OverlayRoot> {
  bool _expanded = false;
  List<InstalledWidget> _widgets = [];
  List<Notebook> _notebooks = [];
  final Map<String, CricketScore> _scores = {};
  ProgressRepository? _progress;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) => _refreshScores());
    
    // Wait for the overlay to be ready before resizing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Give the overlay a moment to initialize
        await Future.delayed(const Duration(milliseconds: 300));
        await FlutterOverlayWindow.resizeOverlay(bubbleSize, bubbleSize, true);
      } catch (e) {
        // If resize fails, overlay will use the default size from showOverlay
        print('Overlay resize failed (normal on first run): $e');
      }
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance();
    _progress = ProgressRepository(db);
    final all = await WidgetRepository(db).all();
    final notebooks = await NotebookRepository(db).all();
    if (!mounted) return;
    setState(() {
      _widgets = all.where((w) => w.enabled && w.placement == WidgetPlacement.overlay).toList();
      _notebooks = notebooks;
    });
    await _refreshScores();
  }

  Future<void> _refreshScores() async {
    for (final w in _widgets.where((w) => w.type == WidgetType.cricketTimer)) {
      try {
        final s = await CricketScore.fetch(w);
        if (mounted) setState(() => _scores[w.id] = s);
      } catch (_) {
        // Usage access missing; card shows a hint.
      }
    }
  }

  Future<void> _setExpanded(bool expanded) async {
    if (expanded) await _load();
    await FlutterOverlayWindow.resizeOverlay(
      expanded ? panelWidth : bubbleSize,
      expanded ? panelHeight : bubbleSize,
      !expanded, // Drag the bubble; keep the panel still so lists can scroll.
    );
    if (mounted) setState(() => _expanded = expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _expanded ? _panel(context) : _bubble(context),
    );
  }

  Widget _bubble(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstScore = _scores.values.firstOrNull;
    return GestureDetector(
      onTap: () => _setExpanded(true),
      child: Container(
        decoration: BoxDecoration(
          color: firstScore?.allOut == true ? scheme.error : scheme.primary,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
        ),
        alignment: Alignment.center,
        child: firstScore == null
            ? Icon(Icons.widgets, color: scheme.onPrimary)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_cricket, size: 18, color: scheme.onPrimary),
                  Text(
                    firstScore.allOut ? 'OUT' : '${firstScore.runsLeft}',
                    style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black38)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: scheme.primaryContainer,
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                Icon(Icons.widgets, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('My widgets', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
                ),
                IconButton(tooltip: 'Minimize', icon: const Icon(Icons.close_fullscreen), onPressed: () => _setExpanded(false)),
                IconButton(tooltip: 'Close overlay', icon: const Icon(Icons.close), onPressed: FlutterOverlayWindow.closeOverlay),
              ],
            ),
          ),
          Expanded(
            child: _widgets.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No overlay widgets yet.\nIn Widget Market, edit a widget and set "Show on" to Overlay.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [for (final w in _widgets) _card(context, w)],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, InstalledWidget w) {
    final accent = Color(w.config['color'] as int? ?? 0xFF6750A4);
    final body = switch (w.type) {
      WidgetType.cricketTimer => _cricket(w),
      WidgetType.microGoals => _OverlayGoals(widget: w, progress: _progress!),
      WidgetType.reminder => Text('${w.config['title']} at ${w.config['time']}${w.config['repeatDaily'] == true ? ' daily' : ''}'),
      WidgetType.textNotebook => Text(
          'Select text in any app, then tap "Send to Notebook".\n'
          '${_notebooks.map((n) => '${n.name} (${n.noteCount})').join(' · ')}',
        ),
    };
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconFor(w.type == WidgetType.reminder ? (w.config['category'] as String? ?? 'custom') : w.type.iconKey), color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(w.name, style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }

  Widget _cricket(InstalledWidget w) {
    final s = _scores[w.id];
    if (s == null) return const Text('Grant Usage access in Widget Market to start scoring.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.allOut ? 'ALL OUT 🏏' : '${s.runsLeft} runs left · ${s.wicketsLeft}/${s.wickets} wickets',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: s.fraction, minHeight: 8, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }
}

class _OverlayGoals extends StatefulWidget {
  const _OverlayGoals({required this.widget, required this.progress});

  final InstalledWidget widget;
  final ProgressRepository progress;

  @override
  State<_OverlayGoals> createState() => _OverlayGoalsState();
}

class _OverlayGoalsState extends State<_OverlayGoals> {
  MicroGoalProgress? _p;

  @override
  void initState() {
    super.initState();
    MicroGoalProgress.load(widget.progress, widget.widget).then((p) => mounted ? setState(() => _p = p) : null);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) return const LinearProgressIndicator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.widget.config['goal']}  (${p.doneCount}/${p.steps.length})'),
        for (final s in p.steps)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(s),
            value: p.done.contains(s),
            onChanged: (_) async {
              await p.toggle(s);
              if (mounted) setState(() {});
            },
          ),
        Text(p.cheer, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
