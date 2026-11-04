import 'dart:convert';

import 'widget_type.dart';

enum ListingSource { developer, community, user }

/// A widget template shared in the marketplace. In V1 the marketplace lives
/// on the device; in V2 the same shape maps to a backend row with a JSONB
/// `config` column.
class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.author,
    required this.source,
    required this.config,
    required this.tags,
    required this.downloads,
    required this.createdAt,
  });

  final String id; // Can be string (local) or numeric string (API)
  final WidgetType type;
  final String name;
  final String description;
  final String author;
  final ListingSource source;
  final Map<String, Object?> config;
  final List<String> tags;
  final int downloads;
  final DateTime createdAt;

  /// Gets the ID as an integer if possible (for API operations)
  int? get idAsInt => int.tryParse(id);

  Map<String, Object?> toRow() => {
        'id': id,
        'type': type.id,
        'name': name,
        'description': description,
        'author': author,
        'source': source.name,
        'config': jsonEncode(config),
        'tags': jsonEncode(tags),
        'downloads': downloads,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Returns null if the row references an unknown widget type.
  static MarketplaceListing? fromRow(Map<String, Object?> row) {
    final type = WidgetType.fromId(row['type'] as String);
    if (type == null) return null;
    
    // Handle both string and numeric IDs
    final id = row['id'];
    final idString = id is int ? id.toString() : id as String;
    
    return MarketplaceListing(
      id: idString,
      type: type,
      name: row['name'] as String,
      description: row['description'] as String,
      author: row['author'] as String,
      source: ListingSource.values.byName(row['source'] as String),
      config: Map<String, Object?>.from(jsonDecode(row['config'] as String) as Map),
      tags: List<String>.from(jsonDecode(row['tags'] as String) as List),
      downloads: row['downloads'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  /// Creates a MarketplaceListing from API data
  static MarketplaceListing? fromApiData(Map<String, dynamic> data) {
    final type = _widgetTypeFromCategory(data['category'] as String? ?? 'productivity');
    
    // Convert API integer ID to string
    final id = data['id'].toString();
    
    // Parse tags from API format
    final tags = (data['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [];
    
    return MarketplaceListing(
      id: id,
      type: type,
      name: data['name'] as String,
      description: data['description'] as String,
      author: data['author'] as String,
      source: ListingSource.community, // API listings are community-sourced
      config: Map<String, Object?>.from(data['config_schema'] as Map),
      tags: tags,
      downloads: data['download_count'] as int? ?? 0,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  static WidgetType _widgetTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'productivity':
        return WidgetType.microGoals;
      case 'entertainment':
        return WidgetType.cricketTimer;
      case 'health':
        return WidgetType.reminder;
      case 'notes':
        return WidgetType.textNotebook;
      default:
        return WidgetType.microGoals;
    }
  }
}
