import 'package:device_bridge/device_bridge.dart';
import 'package:flutter/material.dart';

import '../../models/config_field.dart';
import '../icons.dart';

/// Builds an editor for any widget type from its [ConfigField] list.
class ConfigForm extends StatelessWidget {
  const ConfigForm({super.key, required this.fields, required this.values, required this.onChanged});

  final List<ConfigField> fields;
  final Map<String, Object?> values;
  final void Function(String key, Object? value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _FieldEditor(
              // Key by field so text controllers survive rebuilds.
              key: ValueKey(f.key),
              field: f,
              value: values[f.key],
              onChanged: (v) => onChanged(f.key, v),
            ),
          ),
      ],
    );
  }
}

class _FieldEditor extends StatelessWidget {
  const _FieldEditor({super.key, required this.field, required this.value, required this.onChanged});

  final ConfigField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    switch (field.kind) {
      case ConfigFieldKind.text:
      case ConfigFieldKind.multiline:
        return _TextFieldEditor(field: field, initial: value as String? ?? '', onChanged: onChanged);
      case ConfigFieldKind.number:
        return _NumberEditor(field: field, initial: value as int? ?? field.min ?? 0, onChanged: onChanged);
      case ConfigFieldKind.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.label),
          subtitle: field.help == null ? null : Text(field.help!),
          value: value == true,
          onChanged: onChanged,
        );
      case ConfigFieldKind.color:
        return _ColorEditor(field: field, value: value as int?, onChanged: onChanged);
      case ConfigFieldKind.time:
        return _TimeEditor(field: field, value: value as String? ?? '09:00', onChanged: onChanged);
      case ConfigFieldKind.choice:
        return _ChoiceEditor(field: field, value: value as String?, onChanged: onChanged);
      case ConfigFieldKind.stringList:
        return _ListEditor(
          field: field,
          items: (value as List?)?.whereType<String>().toList() ?? const [],
          onChanged: onChanged,
        );
      case ConfigFieldKind.appList:
        return _AppListEditor(
          field: field,
          packages: (value as List?)?.whereType<String>().toList() ?? const [],
          onChanged: onChanged,
        );
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.field);

  final ConfigField field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: Theme.of(context).textTheme.titleSmall),
          if (field.help != null) Text(field.help!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TextFieldEditor extends StatefulWidget {
  const _TextFieldEditor({required this.field, required this.initial, required this.onChanged});

  final ConfigField field;
  final String initial;
  final ValueChanged<Object?> onChanged;

  @override
  State<_TextFieldEditor> createState() => _TextFieldEditorState();
}

class _TextFieldEditorState extends State<_TextFieldEditor> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.field.kind == ConfigFieldKind.multiline;
    return TextField(
      controller: _controller,
      minLines: multi ? 2 : 1,
      maxLines: multi ? 4 : 1,
      maxLength: multi ? 280 : 60,
      decoration: InputDecoration(
        labelText: widget.field.label,
        helperText: widget.field.help,
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _NumberEditor extends StatefulWidget {
  const _NumberEditor({required this.field, required this.initial, required this.onChanged});

  final ConfigField field;
  final int initial;
  final ValueChanged<Object?> onChanged;

  @override
  State<_NumberEditor> createState() => _NumberEditorState();
}

class _NumberEditorState extends State<_NumberEditor> {
  late final _controller = TextEditingController(text: '${widget.initial}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final n = int.tryParse(text);
    final f = widget.field;
    String? error;
    if (n == null) {
      error = 'Enter a whole number';
    } else if ((f.min != null && n < f.min!) || (f.max != null && n > f.max!)) {
      error = 'Must be between ${f.min} and ${f.max}';
    }
    setState(() => _error = error);
    if (error == null) widget.onChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.field.label,
        helperText: widget.field.help,
        errorText: _error,
        border: const OutlineInputBorder(),
      ),
      onChanged: _onChanged,
    );
  }
}

class _ColorEditor extends StatelessWidget {
  const _ColorEditor({required this.field, required this.value, required this.onChanged});

  final ConfigField field;
  final int? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(field),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in paletteColors)
              Semantics(
                button: true,
                selected: c == value,
                label: 'Color ${c.toRadixString(16)}',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(c),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(c),
                    child: c == value ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimeEditor extends StatelessWidget {
  const _TimeEditor({required this.field, required this.value, required this.onChanged});

  final ConfigField field;
  final String value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: Text(field.label),
      subtitle: field.help == null ? null : Text(field.help!),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      onTap: () async {
        final parts = value.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: int.tryParse(parts.first) ?? 9, minute: int.tryParse(parts.last) ?? 0),
        );
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
    );
  }
}

class _ChoiceEditor extends StatelessWidget {
  const _ChoiceEditor({required this.field, required this.value, required this.onChanged});

  final ConfigField field;
  final String? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(field),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in field.choices)
              ChoiceChip(
                avatar: Icon(iconFor(choice), size: 18),
                label: Text(choice[0].toUpperCase() + choice.substring(1)),
                selected: choice == value,
                onSelected: (_) => onChanged(choice),
              ),
          ],
        ),
      ],
    );
  }
}

class _ListEditor extends StatefulWidget {
  const _ListEditor({required this.field, required this.items, required this.onChanged});

  final ConfigField field;
  final List<String> items;
  final ValueChanged<Object?> onChanged;

  @override
  State<_ListEditor> createState() => _ListEditorState();
}

class _ListEditorState extends State<_ListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.items.contains(text)) return;
    widget.onChanged([...widget.items, text]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(widget.field),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) {
            final items = [...widget.items];
            items.insert(newIndex, items.removeAt(oldIndex));
            widget.onChanged(items);
          },
          children: [
            for (var i = 0; i < widget.items.length; i++)
              ListTile(
                key: ValueKey('${widget.items[i]}-$i'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                title: Text(widget.items[i]),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => widget.onChanged([...widget.items]..removeAt(i)),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Add item', border: OutlineInputBorder(), isDense: true),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(tooltip: 'Add', onPressed: _add, icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}

/// Picks installed apps by name; stores package names.
class _AppListEditor extends StatefulWidget {
  const _AppListEditor({required this.field, required this.packages, required this.onChanged});

  final ConfigField field;
  final List<String> packages;
  final ValueChanged<Object?> onChanged;

  @override
  State<_AppListEditor> createState() => _AppListEditorState();
}

class _AppListEditorState extends State<_AppListEditor> {
  Map<String, String> _labels = {};

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    try {
      final apps = await DeviceBridge.launchableApps();
      if (mounted) setState(() => _labels = {for (final a in apps) a.packageName: a.label});
    } catch (_) {
      // Not on Android (or bridge unavailable): fall back to package names.
    }
  }

  Future<void> _pick() async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AppPickerSheet(selected: widget.packages.toSet()),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(widget.field),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in widget.packages)
              InputChip(
                label: Text(_labels[p] ?? p),
                onDeleted: () => widget.onChanged([...widget.packages]..remove(p)),
              ),
            ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Choose apps'), onPressed: _pick),
          ],
        ),
      ],
    );
  }
}

class _AppPickerSheet extends StatefulWidget {
  const _AppPickerSheet({required this.selected});

  final Set<String> selected;

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  late final Set<String> _selected = {...widget.selected};
  List<InstalledApp>? _apps;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    DeviceBridge.launchableApps().then(
      (apps) => mounted ? setState(() => _apps = apps) : null,
      onError: (Object e) => mounted ? setState(() => _error = 'Could not list apps: $e') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final apps = (_apps ?? const <InstalledApp>[])
        .where((a) => q.isEmpty || a.label.toLowerCase().contains(q) || a.packageName.contains(q))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBar(hintText: 'Search apps', leading: const Icon(Icons.search), onChanged: (v) => setState(() => _query = v)),
          ),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!))
                : _apps == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: apps.length,
                        itemBuilder: (_, i) {
                          final a = apps[i];
                          return CheckboxListTile(
                            title: Text(a.label),
                            subtitle: Text(a.packageName),
                            value: _selected.contains(a.packageName),
                            onChanged: (v) => setState(() => v == true ? _selected.add(a.packageName) : _selected.remove(a.packageName)),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected.toList()),
                  child: Text('Track ${_selected.length} app${_selected.length == 1 ? '' : 's'}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
