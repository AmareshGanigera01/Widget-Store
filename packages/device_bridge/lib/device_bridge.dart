import 'package:flutter/services.dart';

/// Today's usage of a cricket timer's tracked apps.
class FocusStats {
  const FocusStats({required this.minutes, required this.studyOpens});

  /// Foreground minutes in tracked apps since local midnight.
  final int minutes;

  /// Times a tracked app was opened during study hours today.
  final int studyOpens;
}

class InstalledApp {
  const InstalledApp(this.packageName, this.label);
  final String packageName;
  final String label;
}

/// Text received from the "Send to Notebook" selection menu or share sheet.
class CapturedText {
  const CapturedText(this.text, this.sourceApp);
  final String text;
  final String? sourceApp;
}

/// Config the native focus monitor needs for one cricket timer.
class FocusTimerSpec {
  const FocusTimerSpec({
    required this.id,
    required this.name,
    required this.dailyRuns,
    required this.wickets,
    required this.packages,
    required this.studyStart,
    required this.studyEnd,
    required this.allOutAlarm,
    this.home = false,
  });

  /// Shown on the home screen widget.
  final bool home;

  final String id;
  final String name;
  final int dailyRuns;
  final int wickets;
  final List<String> packages;

  /// "HH:mm"
  final String studyStart;
  final String studyEnd;
  final bool allOutAlarm;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'dailyRuns': dailyRuns,
        'wickets': wickets,
        'packages': packages,
        'studyStart': studyStart,
        'studyEnd': studyEnd,
        'allOutAlarm': allOutAlarm,
        'home': home,
      };
}

/// Works from any Flutter engine in the app (main UI, overlay, capture sheet).
class DeviceBridge {
  static const _channel = MethodChannel('com.pranav.device_bridge');

  static Future<bool> hasUsageAccess() async => await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;

  static Future<void> openUsageAccessSettings() => _channel.invokeMethod('openUsageAccessSettings');

  static Future<List<InstalledApp>> launchableApps() async {
    final raw = await _channel.invokeListMethod<Map>('launchableApps') ?? const [];
    return [for (final m in raw) InstalledApp(m['package'] as String, m['label'] as String)];
  }

  static Future<FocusStats> focusStats({
    required List<String> packages,
    required String studyStart,
    required String studyEnd,
  }) async {
    final m = await _channel.invokeMapMethod<String, Object?>('focusStats', {
      'packages': packages,
      'studyStart': studyStart,
      'studyEnd': studyEnd,
    });
    return FocusStats(minutes: (m?['minutes'] as int?) ?? 0, studyOpens: (m?['studyOpens'] as int?) ?? 0);
  }

  /// Replaces the monitored timers. An empty list stops the monitor service.
  static Future<void> syncFocusTimers(List<FocusTimerSpec> timers) =>
      _channel.invokeMethod('syncFocusTimers', [for (final t in timers) t.toMap()]);

  /// Returns the text this activity was launched with, if any.
  static Future<CapturedText?> pendingCapture() async {
    final m = await _channel.invokeMapMethod<String, Object?>('pendingCapture');
    final text = m?['text'] as String?;
    if (text == null || text.trim().isEmpty) return null;
    return CapturedText(text, m?['source'] as String?);
  }

  /// Human-readable label for a package name, or null if not installed.
  static Future<String?> appLabel(String packageName) =>
      _channel.invokeMethod<String>('appLabel', {'package': packageName});
}
