import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/installed_widget.dart';
import '../models/marketplace_listing.dart';
import '../models/notebook.dart';
import '../models/widget_type.dart';
import 'app_database.dart';
import 'seed_catalog.dart';

const _uuid = Uuid();

/// Local marketplace. V2 replaces this with an API-backed implementation
/// exposing the same methods.
class MarketplaceRepository {
  MarketplaceRepository(this._db);

  final AppDatabase _db;

  Future<List<MarketplaceListing>> all() async {
    final rows = await _db.db.query('marketplace_listings', orderBy: 'downloads DESC, created_at DESC');
    return rows.map(MarketplaceListing.fromRow).whereType<MarketplaceListing>().toList();
  }

  Future<void> incrementDownloads(String id) => _db.db.rawUpdate(
        'UPDATE marketplace_listings SET downloads = downloads + 1 WHERE id = ?',
        [id],
      );

  /// Publishes a user's widget as a new listing.
  Future<MarketplaceListing> publish(InstalledWidget widget, {required String description, required List<String> tags}) async {
    final listing = MarketplaceListing(
      id: _uuid.v4(),
      type: widget.type,
      name: widget.name,
      description: description,
      author: 'You',
      source: ListingSource.user,
      config: widget.type.sanitizeConfig(widget.config, defaultConfigs[widget.type]!),
      tags: tags,
      downloads: 0,
      createdAt: DateTime.now(),
    );
    await _db.db.insert('marketplace_listings', listing.toRow());
    return listing;
  }

  /// Users may only remove their own listings.
  Future<void> unpublish(String id) => _db.db.delete(
        'marketplace_listings',
        where: 'id = ? AND source = ?',
        whereArgs: [id, ListingSource.user.name],
      );
}

class WidgetRepository {
  WidgetRepository(this._db);

  final AppDatabase _db;

  Future<List<InstalledWidget>> all() async {
    final rows = await _db.db.query('installed_widgets', orderBy: 'updated_at DESC');
    return rows.map(InstalledWidget.fromRow).whereType<InstalledWidget>().toList();
  }

  Future<InstalledWidget> installFromListing(MarketplaceListing listing) async {
    final now = DateTime.now();
    final widget = InstalledWidget(
      id: _uuid.v4(),
      type: listing.type,
      name: listing.name,
      // Listings are untrusted input once a backend exists; only keep known keys.
      config: listing.type.sanitizeConfig(listing.config, defaultConfigs[listing.type]!),
      placement: WidgetPlacement.none,
      enabled: true,
      sourceListingId: listing.id,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('installed_widgets', widget.toRow());
    return widget;
  }

  Future<InstalledWidget> createBlank(WidgetType type) async {
    final now = DateTime.now();
    final widget = InstalledWidget(
      id: _uuid.v4(),
      type: type,
      name: 'My ${type.label}',
      config: Map.of(defaultConfigs[type]!),
      placement: WidgetPlacement.none,
      enabled: true,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('installed_widgets', widget.toRow());
    return widget;
  }

  Future<InstalledWidget> update(InstalledWidget widget) async {
    final updated = widget.copyWith(updatedAt: DateTime.now());
    await _db.db.update('installed_widgets', updated.toRow(), where: 'id = ?', whereArgs: [widget.id]);
    return updated;
  }

  Future<void> delete(String id) => _db.db.delete('installed_widgets', where: 'id = ?', whereArgs: [id]);
}

class DuplicateNotebookException implements Exception {
  const DuplicateNotebookException(this.name);
  final String name;
}

class NotebookRepository {
  NotebookRepository(this._db);

  final AppDatabase _db;

  Future<List<Notebook>> all() async {
    final rows = await _db.db.rawQuery('''
      SELECT n.*, COUNT(x.id) AS note_count
      FROM notebooks n LEFT JOIN notes x ON x.notebook_id = n.id
      GROUP BY n.id ORDER BY n.name COLLATE NOCASE''');
    return rows.map(Notebook.fromRow).toList();
  }

  Future<Notebook> create(String name, {required int color, String iconKey = 'book'}) async {
    final nb = Notebook(id: _uuid.v4(), name: name.trim(), color: color, iconKey: iconKey, createdAt: DateTime.now());
    try {
      await _db.db.insert('notebooks', nb.toRow(), conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateNotebookException(nb.name);
      rethrow;
    }
    return nb;
  }

  Future<void> delete(String id) => _db.db.delete('notebooks', where: 'id = ?', whereArgs: [id]);

  Future<List<Note>> notes(String notebookId) async {
    final rows = await _db.db.query('notes', where: 'notebook_id = ?', whereArgs: [notebookId], orderBy: 'created_at DESC');
    return rows.map(Note.fromRow).toList();
  }

  Future<Note> addNote({
    required String notebookId,
    required String title,
    required String content,
    required String rawText,
    String? summary,
    String? sourceApp,
  }) async {
    final note = Note(
      id: _uuid.v4(),
      notebookId: notebookId,
      title: title,
      content: content,
      rawText: rawText,
      summary: summary,
      sourceApp: sourceApp,
      createdAt: DateTime.now(),
    );
    await _db.db.insert('notes', note.toRow());
    return note;
  }

  Future<void> deleteNote(String id) => _db.db.delete('notes', where: 'id = ?', whereArgs: [id]);
}

/// Per-widget runtime state (JSON), separate from the shareable config.
class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;

  Future<Map<String, Object?>> get(String widgetId) async {
    final rows = await _db.db.query('widget_progress', where: 'widget_id = ?', whereArgs: [widgetId]);
    if (rows.isEmpty) return {};
    try {
      return Map<String, Object?>.from(jsonDecode(rows.first['data'] as String) as Map);
    } on FormatException {
      return {};
    }
  }

  Future<void> set(String widgetId, Map<String, Object?> data) => _db.db.insert(
        'widget_progress',
        {'widget_id': widgetId, 'data': jsonEncode(data), 'updated_at': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}
