import 'package:device_bridge/device_bridge.dart';

import '../models/installed_widget.dart';
import '../models/widget_type.dart';

/// Today's innings for one cricket timer. Mirrors the native Score so the
/// app, overlay, notification and home widget all agree.
class CricketScore {
  const CricketScore({
    required this.dailyRuns,
    required this.wickets,
    required this.minutesUsed,
    required this.studyOpens,
  });

  final int dailyRuns;
  final int wickets;
  final int minutesUsed;
  final int studyOpens;

  int get runsLeft => (dailyRuns - minutesUsed).clamp(0, dailyRuns);
  int get wicketsLeft => (wickets - studyOpens).clamp(0, wickets);
  bool get allOut => runsLeft == 0 || wicketsLeft == 0;
  double get fraction => dailyRuns == 0 ? 0 : runsLeft / dailyRuns;

  static List<String> trackedApps(InstalledWidget w) =>
      (w.config['trackedApps'] as List?)?.whereType<String>().toList() ?? const [];

  static Future<CricketScore> fetch(InstalledWidget w) async {
    final c = w.config;
    final stats = await DeviceBridge.focusStats(
      packages: trackedApps(w),
      studyStart: c['studyStart'] as String? ?? '18:00',
      studyEnd: c['studyEnd'] as String? ?? '21:00',
    );
    return CricketScore(
      dailyRuns: c['dailyRuns'] as int? ?? 300,
      wickets: c['wickets'] as int? ?? 3,
      minutesUsed: stats.minutes,
      studyOpens: stats.studyOpens,
    );
  }

  static FocusTimerSpec spec(InstalledWidget w) {
    final c = w.config;
    return FocusTimerSpec(
      id: w.id,
      name: w.name,
      dailyRuns: c['dailyRuns'] as int? ?? 300,
      wickets: c['wickets'] as int? ?? 3,
      packages: trackedApps(w),
      studyStart: c['studyStart'] as String? ?? '18:00',
      studyEnd: c['studyEnd'] as String? ?? '21:00',
      allOutAlarm: c['allOutAlarm'] as bool? ?? true,
      home: w.placement == WidgetPlacement.homeScreen,
    );
  }

  static bool isActive(InstalledWidget w) => w.enabled && w.type == WidgetType.cricketTimer;
}
