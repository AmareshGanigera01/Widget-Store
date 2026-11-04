class Notebook {
  const Notebook({
    required this.id,
    required this.name,
    required this.color,
    required this.iconKey,
    required this.createdAt,
    this.noteCount = 0,
  });

  final String id;
  final String name;
  final int color;
  final String iconKey;
  final DateTime createdAt;

  /// Populated by queries that join notes; not stored.
  final int noteCount;

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'color': color,
        'icon_key': iconKey,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Notebook.fromRow(Map<String, Object?> row) => Notebook(
        id: row['id'] as String,
        name: row['name'] as String,
        color: row['color'] as int,
        iconKey: row['icon_key'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        noteCount: (row['note_count'] as int?) ?? 0,
      );
}

/// A captured piece of text, stored as markdown after pre-processing.
class Note {
  const Note({
    required this.id,
    required this.notebookId,
    required this.title,
    required this.content,
    required this.rawText,
    required this.createdAt,
    this.summary,
    this.sourceApp,
  });

  final String id;
  final String notebookId;
  final String title;

  /// Structured markdown (headings, entities) produced by pre-processing.
  final String content;

  /// The original captured text, kept so it can be re-processed later.
  final String rawText;
  final String? summary;
  final String? sourceApp;
  final DateTime createdAt;

  Map<String, Object?> toRow() => {
        'id': id,
        'notebook_id': notebookId,
        'title': title,
        'content': content,
        'raw_text': rawText,
        'summary': summary,
        'source_app': sourceApp,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Note.fromRow(Map<String, Object?> row) => Note(
        id: row['id'] as String,
        notebookId: row['notebook_id'] as String,
        title: row['title'] as String,
        content: row['content'] as String,
        rawText: row['raw_text'] as String,
        summary: row['summary'] as String?,
        sourceApp: row['source_app'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );
}
