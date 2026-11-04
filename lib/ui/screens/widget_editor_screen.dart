import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/installed_widget.dart';
import '../../state/app_state.dart';
import '../components/config_form.dart';
import '../components/widget_preview.dart';
import 'my_widgets_screen.dart' show placementLabel;

/// Edits an installed widget's name, placement and config, with a live preview.
class WidgetEditorScreen extends StatefulWidget {
  const WidgetEditorScreen({super.key, required this.widgetId});

  final String widgetId;

  @override
  State<WidgetEditorScreen> createState() => _WidgetEditorScreenState();
}

class _WidgetEditorScreenState extends State<WidgetEditorScreen> {
  InstalledWidget? _original;
  late Map<String, Object?> _config;
  late String _name;
  late WidgetPlacement _placement;
  late bool _enabled;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final w = context.read<MyWidgetsState>().widgets.where((w) => w.id == widget.widgetId).firstOrNull;
    _original = w;
    _config = Map.of(w?.config ?? const {});
    _name = w?.name ?? '';
    _placement = w?.placement ?? WidgetPlacement.none;
    _enabled = w?.enabled ?? true;
    _nameController = TextEditingController(text: _name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _dirty {
    final o = _original!;
    return _name != o.name ||
        _placement != o.placement ||
        _enabled != o.enabled ||
        _config.toString() != o.config.toString();
  }

  InstalledWidget get _current => _original!.copyWith(
        name: _name.trim().isEmpty ? _original!.name : _name.trim(),
        config: _config,
        placement: _placement,
        enabled: _enabled,
      );

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await context.read<MyWidgetsState>().save(_current);
    messenger.showSnackBar(const SnackBar(content: Text('Widget saved')));
    navigator.pop();
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final state = context.read<MyWidgetsState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${_original!.name}"?'),
        content: const Text('This removes the widget from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await state.remove(_original!.id);
      navigator.pop();
    }
  }

  Future<void> _publish() async {
    final result = await showDialog<(String, List<String>)>(
      context: context,
      builder: (_) => const _PublishDialog(),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final myWidgets = context.read<MyWidgetsState>();
    final market = context.read<MarketplaceState>();
    final current = _current;
    // Publish what the user sees, and keep the saved copy in sync.
    await myWidgets.save(current);
    if (mounted) setState(() => _original = current);
    await market.publish(current, description: result.$1, tags: result.$2);
    messenger.showSnackBar(const SnackBar(content: Text('Published to the marketplace')));
  }

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_original == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Widget not found.')));
    }
    final type = _original!.type;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit ${type.label}'),
          actions: [
            IconButton(tooltip: 'Publish to marketplace', icon: const Icon(Icons.publish), onPressed: _publish),
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            WidgetPreview(type: type, config: _config),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Widget name', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _name = v),
            ),
            const SizedBox(height: 8),
            Text('Show on', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            SegmentedButton<WidgetPlacement>(
              segments: [
                for (final p in WidgetPlacement.values) ButtonSegment(value: p, label: Text(placementLabel(p))),
              ],
              selected: {_placement},
              onSelectionChanged: (s) => setState(() => _placement = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const Divider(height: 24),
            ConfigForm(
              fields: type.fields,
              values: _config,
              onChanged: (key, value) => setState(() => _config = {..._config, key: value}),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _dirty ? _save : null,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PublishDialog extends StatefulWidget {
  const _PublishDialog();

  @override
  State<_PublishDialog> createState() => _PublishDialogState();
}

class _PublishDialogState extends State<_PublishDialog> {
  final _description = TextEditingController();
  final _tags = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _description.text.trim().length >= 10;
    return AlertDialog(
      title: const Text('Publish to marketplace'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Description', helperText: 'At least 10 characters'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(labelText: 'Tags', helperText: 'Comma separated, e.g. study, focus'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: valid
              ? () {
                  final tags = _tags.text
                      .split(',')
                      .map((t) => t.trim().toLowerCase())
                      .where((t) => t.isNotEmpty)
                      .toSet()
                      .take(5)
                      .toList();
                  Navigator.pop(context, (_description.text.trim(), tags));
                }
              : null,
          child: const Text('Publish'),
        ),
      ],
    );
  }
}
