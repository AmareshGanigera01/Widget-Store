/// Describes one user-editable parameter of a widget template.
///
/// Marketplace widgets are never code: they are a built-in [WidgetType] plus a
/// JSON config. These field definitions drive the generic editor UI and are
/// used to validate configs coming from the marketplace.
enum ConfigFieldKind { text, multiline, number, toggle, color, time, choice, stringList, appList }

class ConfigField {
  const ConfigField({
    required this.key,
    required this.label,
    required this.kind,
    this.help,
    this.choices = const [],
    this.min,
    this.max,
  });

  final String key;
  final String label;
  final ConfigFieldKind kind;
  final String? help;

  /// Allowed values for [ConfigFieldKind.choice].
  final List<String> choices;

  /// Bounds for [ConfigFieldKind.number].
  final int? min;
  final int? max;

  /// Coerces an untrusted value (e.g. from an imported listing) into a valid
  /// value for this field, or returns [fallback] if it can't.
  Object? sanitize(Object? value, Object? fallback) {
    switch (kind) {
      case ConfigFieldKind.text:
      case ConfigFieldKind.multiline:
        return value is String ? value : fallback;
      case ConfigFieldKind.number:
        if (value is! num) return fallback;
        var n = value.toInt();
        if (min != null && n < min!) n = min!;
        if (max != null && n > max!) n = max!;
        return n;
      case ConfigFieldKind.toggle:
        return value is bool ? value : fallback;
      case ConfigFieldKind.color:
        return value is int ? value : fallback;
      case ConfigFieldKind.time:
        return value is String && _timePattern.hasMatch(value) ? value : fallback;
      case ConfigFieldKind.choice:
        return value is String && choices.contains(value) ? value : fallback;
      case ConfigFieldKind.stringList:
        return value is List ? value.whereType<String>().toList() : fallback;
      case ConfigFieldKind.appList:
        return value is List ? value.whereType<String>().where(_packagePattern.hasMatch).toList() : fallback;
    }
  }

  static final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final _packagePattern = RegExp(r'^[A-Za-z][\w]*(\.[A-Za-z][\w]*)+$');
}
