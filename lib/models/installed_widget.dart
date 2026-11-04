import 'dart:convert';

import 'widget_type.dart';

/// Where a widget is shown. Home screen holds static dashboards; the overlay
/// holds the interactive pieces.
enum WidgetPlacement { none, homeScreen, overlay }

/// A widget the user downloaded (or created) and can edit.
class InstalledWidget {
  const InstalledWidget({
    required this.id,
    required this.type,
    required this.name,
    required this.config,
    required this.placement,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.sourceListingId,
  });

  final String id;
  final WidgetType type;
  final String name;
  final Map<String, Object?> config;
  final WidgetPlacement placement;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The marketplace listing this was downloaded from, if any.
  final String? sourceListingId;

  InstalledWidget copyWith({
    String? name,
    Map<String, Object?>? config,
    WidgetPlacement? placement,
    bool? enabled,
    DateTime? updatedAt,
  }) {
    return InstalledWidget(
      id: id,
      type: type,
      name: name ?? this.name,
      config: config ?? this.config,
      placement: placement ?? this.placement,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceListingId: sourceListingId,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'type': type.id,
        'name': name,
        'config': jsonEncode(config),
        'placement': placement.name,
        'enabled': enabled ? 1 : 0,
        'source_listing_id': sourceListingId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static InstalledWidget? fromRow(Map<String, Object?> row) {
    final type = WidgetType.fromId(row['type'] as String);
    if (type == null) return null;
    return InstalledWidget(
      id: row['id'] as String,
      type: type,
      name: row['name'] as String,
      config: Map<String, Object?>.from(jsonDecode(row['config'] as String) as Map),
      placement: WidgetPlacement.values.byName(row['placement'] as String),
      enabled: row['enabled'] == 1,
      sourceListingId: row['source_listing_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
