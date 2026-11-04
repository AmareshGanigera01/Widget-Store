import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/notebook.dart';
import 'seed_catalog.dart';

/// Owns the single SQLite database. Bump [_version] and add a step to
/// [_migrate] for every schema change; never edit an existing step.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const _version = 2;

  static AppDatabase? _instance;

  /// One connection per isolate. The main UI, overlay and capture sheet each
  /// run in their own isolate and open their own connection to the same file.
  static Future<AppDatabase> instance() async => _instance ??= await open();

  static Future<AppDatabase> open() async {
    final path = p.join(await getDatabasesPath(), 'widget_market.db');
    final db = await openDatabase(
      path,
      version: _version,
      singleInstance: true,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // Several isolates write to this file; wait briefly instead of failing on a lock.
        await db.rawQuery('PRAGMA busy_timeout = 3000');
      },
      onCreate: (db, version) async {
        await _migrate(db, 0, version);
        await _seed(db);
      },
      onUpgrade: _migrate,
    );
    return AppDatabase._(db);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    if (from < 1) {
      final batch = db.batch()
        ..execute('''
          CREATE TABLE marketplace_listings (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            author TEXT NOT NULL,
            source TEXT NOT NULL,
            config TEXT NOT NULL,
            tags TEXT NOT NULL,
            downloads INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )''')
        ..execute('''
          CREATE TABLE installed_widgets (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            config TEXT NOT NULL,
            placement TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            source_listing_id TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''')
        ..execute('''
          CREATE TABLE notebooks (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE COLLATE NOCASE,
            color INTEGER NOT NULL,
            icon_key TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''')
        ..execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            notebook_id TEXT NOT NULL REFERENCES notebooks(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            raw_text TEXT NOT NULL,
            summary TEXT,
            source_app TEXT,
            created_at INTEGER NOT NULL
          )''')
        ..execute('CREATE INDEX idx_notes_notebook ON notes(notebook_id, created_at)');
      await batch.commit(noResult: true);
    }
    if (from < 2) {
      // Runtime state that isn't part of a widget's shareable config
      // (checked steps, reminder bookkeeping).
      await db.execute('''
        CREATE TABLE widget_progress (
          widget_id TEXT PRIMARY KEY REFERENCES installed_widgets(id) ON DELETE CASCADE,
          data TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )''');
    }
  }

  static Future<void> _seed(Database db) async {
    final batch = db.batch();
    for (final listing in seedListings()) {
      batch.insert('marketplace_listings', listing.toRow());
    }
    final now = DateTime.now();
    for (final nb in [
      Notebook(id: 'nb-general', name: 'General', color: 0xFF0061A4, iconKey: 'book', createdAt: now),
      Notebook(id: 'nb-science', name: 'Science', color: 0xFF2E7D32, iconKey: 'science', createdAt: now),
    ]) {
      batch.insert('notebooks', nb.toRow());
    }
    await batch.commit(noResult: true);
  }
}
