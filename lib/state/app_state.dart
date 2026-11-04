import 'package:flutter/foundation.dart';

import '../data/repositories.dart';
import '../models/installed_widget.dart';
import '../models/marketplace_listing.dart';
import '../models/notebook.dart';
import '../models/widget_type.dart';
import '../services/runtime_sync.dart';

class MarketplaceState extends ChangeNotifier {
  MarketplaceState(this._repo);

  final MarketplaceRepository _repo;

  List<MarketplaceListing> _listings = [];
  bool loading = true;
  String query = '';
  WidgetType? typeFilter;

  List<MarketplaceListing> get visible {
    final q = query.trim().toLowerCase();
    return _listings.where((l) {
      if (typeFilter != null && l.type != typeFilter) return false;
      if (q.isEmpty) return true;
      return l.name.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q) ||
          l.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> load() async {
    _listings = await _repo.all();
    loading = false;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setTypeFilter(WidgetType? type) {
    typeFilter = type;
    notifyListeners();
  }

  Future<void> recordDownload(MarketplaceListing listing) async {
    await _repo.incrementDownloads(listing.id);
    await load();
  }

  Future<void> publish(InstalledWidget widget, {required String description, required List<String> tags}) async {
    await _repo.publish(widget, description: description, tags: tags);
    await load();
  }

  Future<void> unpublish(String listingId) async {
    await _repo.unpublish(listingId);
    await load();
  }
}

class MyWidgetsState extends ChangeNotifier {
  MyWidgetsState(this._repo, this._runtime);

  final WidgetRepository _repo;
  final RuntimeSync _runtime;

  List<InstalledWidget> widgets = [];
  bool loading = true;

  bool isInstalled(String listingId) => widgets.any((w) => w.sourceListingId == listingId);

  InstalledWidget? byId(String id) => widgets.where((w) => w.id == id).firstOrNull;

  /// Reloads from the database (which the overlay may also write) and pushes
  /// the result to notifications / the focus monitor.
  Future<void> load() async {
    widgets = await _repo.all();
    loading = false;
    notifyListeners();
    await _runtime.sync(widgets);
  }

  Future<InstalledWidget> install(MarketplaceListing listing) async {
    final w = await _repo.installFromListing(listing);
    await load();
    return w;
  }

  Future<InstalledWidget> createBlank(WidgetType type) async {
    final w = await _repo.createBlank(type);
    await load();
    return w;
  }

  Future<void> save(InstalledWidget widget) async {
    await _repo.update(widget);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await load();
  }
}

class NotebooksState extends ChangeNotifier {
  NotebooksState(this._repo);

  final NotebookRepository _repo;

  List<Notebook> notebooks = [];
  bool loading = true;

  Future<void> load() async {
    notebooks = await _repo.all();
    loading = false;
    notifyListeners();
  }

  /// Throws [DuplicateNotebookException] if the name is taken.
  Future<void> create(String name, int color) async {
    await _repo.create(name, color: color);
    await load();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await load();
  }

  Future<List<Note>> notesFor(String notebookId) => _repo.notes(notebookId);
}
