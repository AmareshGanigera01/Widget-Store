import 'dart:async';

import 'package:device_bridge/device_bridge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../capture/capture_sheet.dart';
import '../../data/repositories.dart';
import '../../models/installed_widget.dart';
import '../../models/widget_type.dart';
import '../../services/cricket.dart';
import '../../services/micro_goals.dart';
import '../../services/reminder_service.dart';
import '../../state/app_state.dart';
import '../components/widget_preview.dart';
import 'widget_editor_screen.dart';

/// The working view of an installed widget: checklist, scoreboard, etc.
class WidgetLiveScreen extends StatelessWidget {
  const WidgetLiveScreen({super.key, required this.widgetId});

  final String widgetId;

  @override
  Widget build(BuildContext context) {
    final w = context.select<MyWidgetsState, InstalledWidget?>((s) => s.byId(widgetId));
    if (w == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Widget not found.')));
    return Scaffold(
      appBar: AppBar(
        title: Text(w.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WidgetEditorScreen(widgetId: w.id))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!w.enabled)
            const Card(child: ListTile(leading: Icon(Icons.pause_circle), title: Text('This widget is paused. Turn on "Active" in Edit.'))),
          switch (w.type) {
            WidgetType.reminder => _ReminderView(key: ValueKey(w.updatedAt), widget: w),
            WidgetType.cricketTimer => _CricketView(key: ValueKey(w.updatedAt), widget: w),
            WidgetType.microGoals => _GoalsView(key: ValueKey(w.updatedAt), widget: w),
            WidgetType.textNotebook => _CaptureView(widget: w),
          },
        ],
      ),
    );
  }
}

// ---------------- Reminder ----------------

class _ReminderView extends StatefulWidget {
  const _ReminderView({super.key, required this.widget});

  final InstalledWidget widget;

  @override
  State<_ReminderView> createState() => _ReminderViewState();
}

class _ReminderViewState extends State<_ReminderView> with WidgetsBindingObserver {
  DateTime? _next;
  bool _exact = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final r = context.read<ReminderService>();
    await r.init();
    final next = await r.nextFire(widget.widget);
    final exact = await r.canScheduleExact();
    if (mounted) {
      setState(() {
        _next = next;
        _exact = exact;
      });
    }
  }

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final day = d.day == now.day && d.month == now.month ? 'Today' : 'Tomorrow';
    return '$day at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.read<ReminderService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WidgetPreview(type: widget.widget.type, config: widget.widget.config),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(_next == null ? 'Not scheduled' : 'Next: ${_fmt(_next!)}'),
          subtitle: Text(widget.widget.config['repeatDaily'] == false ? 'One time' : 'Every day'),
        ),
        if (!_exact)
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Reminders may arrive a few minutes late'),
              subtitle: const Text('Allow "Alarms & reminders" for on-time delivery.'),
              trailing: TextButton(
                onPressed: () async {
                  final myWidgets = context.read<MyWidgetsState>();
                  await reminders.requestExactAlarms();
                  // Reschedule with exact timing if it was just granted.
                  await myWidgets.load();
                  await _refresh();
                },
                child: const Text('Allow'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Send a test notification'),
          onPressed: () => reminders.preview(widget.widget),
        ),
      ],
    );
  }
}

// ---------------- Cricket timer ----------------

class _CricketView extends StatefulWidget {
  const _CricketView({super.key, required this.widget});

  final InstalledWidget widget;

  @override
  State<_CricketView> createState() => _CricketViewState();
}

class _CricketViewState extends State<_CricketView> with WidgetsBindingObserver {
  CricketScore? _score;
  bool? _access;
  Map<String, String> _labels = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    DeviceBridge.launchableApps().then((apps) {
      if (mounted) setState(() => _labels = {for (final a in apps) a.packageName: a.label});
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the Usage access settings page.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final access = await DeviceBridge.hasUsageAccess();
    final score = access ? await CricketScore.fetch(widget.widget) : null;
    if (!mounted) return;
    final hadAccess = _access;
    setState(() {
      _access = access;
      _score = score;
    });
    // Restart the native monitor once access is granted.
    if (hadAccess == false && access && mounted) await context.read<MyWidgetsState>().load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final apps = CricketScore.trackedApps(widget.widget);
    final s = _score;
    final c = widget.widget.config;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_access == false)
          Card(
            color: scheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Usage access needed'),
              subtitle: const Text('The timer needs to see how long tracked apps are open. Data stays on your phone.'),
              trailing: FilledButton(onPressed: DeviceBridge.openUsageAccessSettings, child: const Text('Grant')),
            ),
          ),
        Card.filled(
          color: s?.allOut == true ? scheme.errorContainer : scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(s?.allOut == true ? 'ALL OUT' : 'Runs to defend', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(s == null ? '—' : '${s.runsLeft}', style: text.displayLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('of ${c['dailyRuns']} today', style: text.bodyMedium),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: s?.fraction ?? 1, minHeight: 12, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < (c['wickets'] as int? ?? 3); i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.sports_cricket,
                          color: s != null && i >= s.wicketsLeft ? scheme.outline : scheme.primary,
                          size: 28,
                        ),
                      ),
                  ],
                ),
                Text(s == null ? '' : '${s.wicketsLeft} wicket${s.wicketsLeft == 1 ? '' : 's'} left', style: text.labelLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(s == null ? 'Usage today: —' : 'Used today: ${s.minutesUsed} min'),
          subtitle: Text('Tracking: ${apps.isEmpty ? 'no apps (edit to choose)' : apps.map((p) => _labels[p] ?? p).join(', ')}'),
        ),
        ListTile(
          leading: const Icon(Icons.school_outlined),
          title: Text('Study hours ${c['studyStart']}–${c['studyEnd']}'),
          subtitle: const Text('Opening a tracked app in study hours costs a wicket.'),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Resets every day at midnight'),
          subtitle: Text('A live score stays in your notifications. Add the "Cricket Focus score" widget to your home screen, '
              'or set Show on → Overlay.'),
        ),
      ],
    );
  }
}

// ---------------- Micro-goals ----------------

class _GoalsView extends StatefulWidget {
  const _GoalsView({super.key, required this.widget});

  final InstalledWidget widget;

  @override
  State<_GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<_GoalsView> {
  MicroGoalProgress? _p;

  @override
  void initState() {
    super.initState();
    MicroGoalProgress.load(context.read<ProgressRepository>(), widget.widget).then((p) {
      if (mounted) setState(() => _p = p);
    });
  }

  Future<void> _toggle(String step) async {
    final p = _p!;
    final wasComplete = p.complete;
    await p.toggle(step);
    if (!mounted) return;
    setState(() {});
    if (!wasComplete && p.complete) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Goal complete! Take a well-earned break.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) return const Center(child: CircularProgressIndicator());
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.widget.config['goal'] as String? ?? '', style: text.headlineSmall),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: p.steps.isEmpty ? 0 : p.doneCount / p.steps.length,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 6),
        Text('${p.doneCount} of ${p.steps.length} steps · ${p.cheer}', style: text.bodyMedium),
        const SizedBox(height: 8),
        for (final step in p.steps)
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              step,
              style: p.done.contains(step) ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
            ),
            value: p.done.contains(step),
            onChanged: (_) => _toggle(step),
          ),
        if (widget.widget.config['resetDaily'] == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Ticks reset every day.', style: text.bodySmall),
          ),
      ],
    );
  }
}

// ---------------- Text capture ----------------

class _CaptureView extends StatefulWidget {
  const _CaptureView({required this.widget});

  final InstalledWidget widget;

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tryIt() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final notebooks = context.read<NotebooksState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: CaptureSheet(text: text, sourceApp: 'Widget Market', onDone: (saved) => Navigator.pop(ctx, saved)),
      ),
    );
    await notebooks.load();
    if (saved == true) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WidgetPreview(type: widget.widget.type, config: widget.widget.config),
        const SizedBox(height: 16),
        Text('How to capture', style: text.titleMedium),
        const SizedBox(height: 4),
        const Text('1. In any app, long-press to select text.\n'
            '2. Tap ⋮ in the selection menu, then "Send to Notebook".\n'
            '3. It is sorted into the right notebook with headings and a summary.\n\n'
            'You can also use Share → "Send to Notebook".'),
        const SizedBox(height: 16),
        Text('Try it here', style: text.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Paste some text…'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _tryIt, icon: const Icon(Icons.send), label: const Text('Send to Notebook')),
      ],
    );
  }
}
