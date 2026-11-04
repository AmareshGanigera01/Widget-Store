import 'package:device_bridge/device_bridge.dart';
import 'package:flutter/foundation.dart';

import '../models/installed_widget.dart';
import 'cricket.dart';
import 'reminder_service.dart';

/// Pushes widget configs to the OS: scheduled reminders and the native
/// focus monitor. Runs after every change to My Widgets.
class RuntimeSync {
  RuntimeSync(this.reminders);

  final ReminderService reminders;
  Future<void> _last = Future.value();

  /// Serialized so overlapping saves can't interleave schedule/cancel calls.
  Future<void> sync(List<InstalledWidget> widgets) {
    final snapshot = List.of(widgets);
    return _last = _last.then((_) => _run(snapshot));
  }

  Future<void> _run(List<InstalledWidget> widgets) async {
    try {
      await reminders.sync(widgets);
    } catch (e, st) {
      debugPrint('Reminder sync failed: $e\n$st');
    }
    try {
      await DeviceBridge.syncFocusTimers(widgets.where(CricketScore.isActive).map(CricketScore.spec).toList());
    } catch (e, st) {
      debugPrint('Focus monitor sync failed: $e\n$st');
    }
  }
}
