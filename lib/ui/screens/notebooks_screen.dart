import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/notebook.dart';
import '../../state/app_state.dart';
import '../icons.dart';
import 'ai_settings_screen.dart';
import 'note_screen.dart';

class NotebooksScreen extends StatelessWidget {
  const NotebooksScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final state = context.read<NotebooksState>();
    await showDialog<void>(context: context, builder: (_) => _NewNotebookDialog(state: state));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotebooksState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'New notebook',
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Notebooks'),
            actions: [
              IconButton(
                tooltip: 'AI settings',
                icon: const Icon(Icons.auto_awesome_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
              ),
            ],
          ),
          if (state.loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverList.builder(
              itemCount: state.notebooks.length,
              itemBuilder: (context, i) {
                final nb = state.notebooks[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(nb.color),
                    child: Icon(iconFor(nb.iconKey), color: Colors.white),
                  ),
                  title: Text(nb.name),
                  subtitle: Text('${nb.noteCount} note${nb.noteCount == 1 ? '' : 's'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NotebookDetailScreen(notebook: nb)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _NewNotebookDialog extends StatefulWidget {
  const _NewNotebookDialog({required this.state});

  final NotebooksState state;

  @override
  State<_NewNotebookDialog> createState() => _NewNotebookDialogState();
}

class _NewNotebookDialogState extends State<_NewNotebookDialog> {
  final _name = TextEditingController();
  int _color = paletteColors.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    try {
      await widget.state.create(name, _color);
      if (mounted) Navigator.pop(context);
    } on DuplicateNotebookException {
      setState(() => _error = 'A notebook called "$name" already exists');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New notebook'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(labelText: 'Name', hintText: 'e.g. History', errorText: _error),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in paletteColors)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(c),
                    child: c == _color ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

class NotebookDetailScreen extends StatelessWidget {
  const NotebookDetailScreen({super.key, required this.notebook});

  final Notebook notebook;

  Future<void> _delete(BuildContext context) async {
    final state = context.read<NotebooksState>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${notebook.name}"?'),
        content: Text('This also deletes its ${notebook.noteCount} note(s).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await state.remove(notebook.id);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<NotebooksState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(notebook.name),
        actions: [
          IconButton(tooltip: 'Delete notebook', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context)),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: state.notesFor(notebook.id),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final notes = snap.data!;
          if (notes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No notes yet.\nSelect text in any app and tap "Send to Notebook".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(notes[i].title),
              subtitle: Text(notes[i].summary ?? notes[i].rawText, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteScreen(note: notes[i]))),
            ),
          );
        },
      ),
    );
  }
}
