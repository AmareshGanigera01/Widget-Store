import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/repositories.dart';
import '../models/installed_widget.dart';
import '../models/widget_type.dart';

/// Schedules reminder widgets as local notifications.
class ReminderService {
  ReminderService(this._progress);

  final ProgressRepository _progress;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'reminders';
  static const _idBase = 100000;
  static const _idRange = 900000;

  static const _emoji = {'study': '📚', 'medicine': '💊', 'work': '💼', 'custom': '🔔'};

  static const _sweetFallback = {
    'study': 'Your future self will thank you. Open the book for just 10 minutes 📖',
    'medicine': 'Time for your medicine. Taking care of you matters 💛',
    'work': 'Small focused steps beat long busy hours. You\'ve got this!',
    'custom': 'A gentle nudge, just for you ✨',
  };

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Timezone lookup failed, using UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_custom')),
    );
    _ready = true;
  }

  /// Asks for the notification permission (Android 13+). Returns whether granted.
  Future<bool> requestNotificationPermission() async => await _android?.requestNotificationsPermission() ?? true;

  Future<bool> canScheduleExact() async => await _android?.canScheduleExactNotifications() ?? true;

  /// Opens the system "Alarms & reminders" page.
  Future<void> requestExactAlarms() async => _android?.requestExactAlarmsPermission();

  /// Stable notification id for a widget (FNV-1a; String.hashCode isn't stable across runs).
  static int notificationId(String widgetId) {
    var h = 0x811c9dc5;
    for (final c in widgetId.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return _idBase + h % _idRange;
  }

  static tz.TZDateTime nextAt(String hhmm, [tz.TZDateTime? from]) {
    final now = from ?? tz.TZDateTime.now(tz.local);
    final parts = hhmm.split(':');
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  NotificationDetails _details(Map<String, Object?> c) {
    final category = c['category'] as String? ?? 'custom';
    final message = _message(c);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Reminders',
        channelDescription: 'Your reminder widgets',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_$category',
        color: Color(c['color'] as int? ?? 0xFF6750A4),
        styleInformation: BigTextStyleInformation(message),
        category: AndroidNotificationCategory.reminder,
      ),
    );
  }

  static String _message(Map<String, Object?> c) {
    final m = (c['message'] as String?)?.trim() ?? '';
    return m.isNotEmpty ? m : _sweetFallback[c['category']] ?? _sweetFallback['custom']!;
  }

  static String _title(Map<String, Object?> c) => '${_emoji[c['category']] ?? '🔔'} ${c['title'] ?? 'Reminder'}';

  /// Makes scheduled notifications match the current reminder widgets.
  Future<void> sync(List<InstalledWidget> widgets) async {
    await init();
    final reminders = widgets.where((w) => w.enabled && w.type == WidgetType.reminder).toList();
    final wanted = {for (final w in reminders) notificationId(w.id)};

    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.id >= _idBase && p.id < _idBase + _idRange && !wanted.contains(p.id)) {
        await _plugin.cancel(id: p.id);
      }
    }

    final mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final w in reminders) {
      final c = w.config;
      final time = c['time'] as String? ?? '09:00';
      final repeat = c['repeatDaily'] != false;
      final id = notificationId(w.id);
      var at = nextAt(time);

      if (!repeat) {
        // One-shot: fire once per configured time. Editing the time re-arms it.
        final p = await _progress.get(w.id);
        final firedFor = p['oneShotTime'];
        final firedAt = p['oneShotAt'] as int?;
        if (firedFor == time && firedAt != null) {
          final scheduled = DateTime.fromMillisecondsSinceEpoch(firedAt);
          if (scheduled.isBefore(DateTime.now())) {
            await _plugin.cancel(id: id);
            continue;
          }
          at = tz.TZDateTime.from(scheduled, tz.local);
        } else {
          await _progress.set(w.id, {...p, 'oneShotTime': time, 'oneShotAt': at.millisecondsSinceEpoch});
        }
      }

      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: at,
        notificationDetails: _details(c),
        androidScheduleMode: mode,
        title: _title(c),
        body: _message(c),
        payload: w.id,
        matchDateTimeComponents: repeat ? DateTimeComponents.time : null,
      );
    }
  }

  /// Shows the reminder right now so the user can preview it.
  Future<void> preview(InstalledWidget w) async {
    await init();
    await _plugin.show(id: notificationId(w.id) - 1, title: _title(w.config), body: _message(w.config), notificationDetails: _details(w.config));
  }

  Future<DateTime?> nextFire(InstalledWidget w) async {
    final pending = await _plugin.pendingNotificationRequests();
    if (!pending.any((p) => p.id == notificationId(w.id))) return null;
    final c = w.config;
    if (c['repeatDaily'] == false) {
      final at = (await _progress.get(w.id))['oneShotAt'] as int?;
      return at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
    }
    return nextAt(c['time'] as String? ?? '09:00');
  }
}
