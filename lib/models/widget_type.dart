import 'config_field.dart';

/// The built-in widget templates. Every marketplace listing and installed
/// widget is one of these types plus a config map.
enum WidgetType {
  reminder(
    id: 'reminder',
    label: 'Reminder',
    iconKey: 'alarm',
    fields: [
      ConfigField(key: 'title', label: 'Title', kind: ConfigFieldKind.text),
      ConfigField(
        key: 'message',
        label: 'Reminder message',
        kind: ConfigFieldKind.multiline,
        help: 'Shown in the notification.',
      ),
      ConfigField(
        key: 'category',
        label: 'Category',
        kind: ConfigFieldKind.choice,
        choices: ['study', 'medicine', 'work', 'custom'],
        help: 'Picks the notification icon.',
      ),
      ConfigField(key: 'time', label: 'Time', kind: ConfigFieldKind.time),
      ConfigField(key: 'repeatDaily', label: 'Repeat daily', kind: ConfigFieldKind.toggle),
      ConfigField(key: 'color', label: 'Accent color', kind: ConfigFieldKind.color),
    ],
  ),
  cricketTimer(
    id: 'cricket_timer',
    label: 'Cricket Timer',
    iconKey: 'sports_cricket',
    fields: [
      ConfigField(
        key: 'dailyRuns',
        label: 'Daily runs (minutes)',
        kind: ConfigFieldKind.number,
        min: 10,
        max: 1440,
        help: '1 minute in a tracked app costs 1 run.',
      ),
      ConfigField(
        key: 'trackedApps',
        label: 'Tracked apps',
        kind: ConfigFieldKind.appList,
        help: 'Each minute in these apps costs a run.',
      ),
      ConfigField(key: 'studyStart', label: 'Study hours start', kind: ConfigFieldKind.time),
      ConfigField(key: 'studyEnd', label: 'Study hours end', kind: ConfigFieldKind.time),
      ConfigField(
        key: 'wickets',
        label: 'Wickets',
        kind: ConfigFieldKind.number,
        min: 1,
        max: 10,
        help: 'Lost when a tracked app is opened during study hours.',
      ),
      ConfigField(key: 'allOutAlarm', label: 'Ring alarm when all out', kind: ConfigFieldKind.toggle),
      ConfigField(key: 'color', label: 'Accent color', kind: ConfigFieldKind.color),
    ],
  ),
  textNotebook(
    id: 'text_notebook',
    label: 'Text Capture',
    iconKey: 'edit_note',
    fields: [
      ConfigField(
        key: 'defaultNotebook',
        label: 'Default notebook',
        kind: ConfigFieldKind.text,
        help: 'Used when auto-routing is off or unsure.',
      ),
      ConfigField(key: 'autoRoute', label: 'AI auto-route to notebook', kind: ConfigFieldKind.toggle),
      ConfigField(key: 'summarize', label: 'Add one-sentence summary', kind: ConfigFieldKind.toggle),
      ConfigField(key: 'color', label: 'Accent color', kind: ConfigFieldKind.color),
    ],
  ),
  microGoals(
    id: 'micro_goals',
    label: 'Micro-Goals',
    iconKey: 'checklist',
    fields: [
      ConfigField(key: 'goal', label: 'Main goal', kind: ConfigFieldKind.text),
      ConfigField(key: 'steps', label: 'Steps', kind: ConfigFieldKind.stringList),
      ConfigField(key: 'resetDaily', label: 'Reset every day', kind: ConfigFieldKind.toggle),
      ConfigField(key: 'color', label: 'Accent color', kind: ConfigFieldKind.color),
    ],
  );

  const WidgetType({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.fields,
  });

  final String id;
  final String label;
  final String iconKey;
  final List<ConfigField> fields;

  static WidgetType? fromId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Returns a config containing only known keys with valid values, filling
  /// gaps from [defaults].
  Map<String, Object?> sanitizeConfig(Map<String, Object?> raw, Map<String, Object?> defaults) {
    return {
      for (final f in fields) f.key: f.sanitize(raw[f.key], defaults[f.key]),
    };
  }
}
