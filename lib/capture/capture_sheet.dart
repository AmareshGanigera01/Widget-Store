import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/repositories.dart';
import '../data/seed_catalog.dart';
import '../models/notebook.dart';
import '../models/widget_type.dart';
import '../services/ai_settings.dart';
import '../services/note_processor.dart';

/// Processes captured text and saves it into a notebook.
///
/// When the AI (or keyword router) is confident the note is saved right away
/// and the sheet closes itself; otherwise the user confirms the notebook.
class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key, required this.text, required this.onDone, this.sourceApp});

  final String text;
  final String? sourceApp;

  /// Called with true when a note was saved.
  final ValueChanged<bool> onDone;

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

enum _Phase { processing, confirm, saved, error }

class _CaptureSheetState extends State<CaptureSheet> {
  _Phase _phase = _Phase.processing;
  late NotebookRepository _notebooks;
  List<Notebook> _books = [];
  ProcessedNote? _result;
  String? _selectedBook;
  Note? _saved;
  String? _error;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final db = await AppDatabase.instance();
      _notebooks = NotebookRepository(db);
      _books = await _notebooks.all();
      if (_books.isEmpty) {
        await _notebooks.create('General', color: 0xFF0061A4);
        _books = await _notebooks.all();
      }

      // Settings come from the user's first active Text Capture widget.
      final widgets = await WidgetRepository(db).all();
      final capture = widgets.where((w) => w.enabled && w.type == WidgetType.textNotebook).firstOrNull;
      final cfg = capture?.config ?? defaultConfigs[WidgetType.textNotebook]!;

      final processor = NoteProcessor(await AiSettingsStore.load());
      final result = await processor.process(
        widget.text,
        notebooks: [for (final b in _books) b.name],
        defaultNotebook: cfg['defaultNotebook'] as String? ?? 'General',
        autoRoute: cfg['autoRoute'] != false,
        summarize: cfg['summarize'] != false,
      );
      if (!mounted) return;
      _result = result;
      _selectedBook = result.notebook;
      if (result.confident) {
        await _save();
      } else {
        setState(() => _phase = _Phase.confirm);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _save() async {
    final r = _result!;
    final book = _books.firstWhere((b) => b.name == _selectedBook, orElse: () => _books.first);
    final terms = r.entities.isEmpty ? '' : '\n\n**Key terms:** ${r.entities.join(', ')}';
    _saved = await _notebooks.addNote(
      notebookId: book.id,
      title: r.title,
      content: '${r.markdown}$terms',
      rawText: widget.text,
      summary: r.summary,
      sourceApp: widget.sourceApp,
    );
    if (!mounted) return;
    setState(() => _phase = _Phase.saved);
    _autoClose = Timer(const Duration(seconds: 3), () => widget.onDone(true));
  }

  Future<void> _changeNotebook() async {
    _autoClose?.cancel();
    if (_saved != null) {
      await _notebooks.deleteNote(_saved!.id);
      _saved = null;
    }
    setState(() => _phase = _Phase.confirm);
  }

  Future<void> _undo() async {
    _autoClose?.cancel();
    if (_saved != null) await _notebooks.deleteNote(_saved!.id);
    widget.onDone(false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: switch (_phase) {
          _Phase.processing => Row(
              children: [
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 16),
                Expanded(child: Text('Organizing your note…', style: text.titleMedium)),
              ],
            ),
          _Phase.error => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not save the note', style: text.titleMedium),
                const SizedBox(height: 8),
                Text(_error ?? ''),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => widget.onDone(false), child: const Text('Close')),
                ),
              ],
            ),
          _Phase.saved => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Saved to $_selectedBook', style: text.titleMedium)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_result!.title, style: text.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (_result!.summary != null)
                  Text(_result!.summary!, style: text.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                if (_result!.aiError != null) _AiFallbackNote(_result!.aiError!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _undo, child: const Text('Undo')),
                    TextButton(onPressed: _changeNotebook, child: const Text('Change notebook')),
                    FilledButton(onPressed: () => widget.onDone(true), child: const Text('Done')),
                  ],
                ),
              ],
            ),
          _Phase.confirm => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Which notebook?', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  _result!.usedAi ? 'Not sure where this belongs. Suggested: ${_result!.notebook}' : 'Pick a notebook for this note.',
                  style: text.bodyMedium,
                ),
                if (_result!.aiError != null) _AiFallbackNote(_result!.aiError!),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(child: Text(widget.text, style: text.bodySmall)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in _books)
                      ChoiceChip(
                        avatar: CircleAvatar(backgroundColor: Color(b.color), radius: 8),
                        label: Text(b.name),
                        selected: b.name == _selectedBook,
                        onSelected: (_) => setState(() => _selectedBook = b.name),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => widget.onDone(false), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _selectedBook == null ? null : _save,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _AiFallbackNote extends StatelessWidget {
  const _AiFallbackNote(this.error);

  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'AI unavailable, used offline sorting. ($error)',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
