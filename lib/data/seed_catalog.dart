import '../models/marketplace_listing.dart';
import '../models/widget_type.dart';

/// Default configs per type. Also used to fill gaps when sanitizing configs.
const Map<WidgetType, Map<String, Object?>> defaultConfigs = {
  WidgetType.reminder: {
    'title': 'Reminder',
    'message': 'A gentle nudge from your future self.',
    'category': 'custom',
    'time': '09:00',
    'repeatDaily': true,
    'color': 0xFF6750A4,
  },
  WidgetType.cricketTimer: {
    'dailyRuns': 300,
    'trackedApps': <String>['com.instagram.android'],
    'studyStart': '18:00',
    'studyEnd': '21:00',
    'wickets': 3,
    'allOutAlarm': true,
    'color': 0xFF2E7D32,
  },
  WidgetType.textNotebook: {
    'defaultNotebook': 'General',
    'autoRoute': true,
    'summarize': true,
    'color': 0xFF0061A4,
  },
  WidgetType.microGoals: {
    'goal': 'Finish today\'s main task',
    'steps': <String>['Open the material', 'Work for 25 minutes', 'Take a 5-minute break'],
    'resetDaily': false,
    'color': 0xFFB3261E,
  },
};

/// Developer-created listings shipped with the app. Seeded into the local
/// marketplace on first launch.
List<MarketplaceListing> seedListings() {
  final now = DateTime.now();
  MarketplaceListing listing(
    String id,
    WidgetType type,
    String name,
    String description,
    Map<String, Object?> overrides,
    List<String> tags,
    int downloads,
  ) {
    return MarketplaceListing(
      id: id,
      type: type,
      name: name,
      description: description,
      author: 'Widget Market Team',
      source: ListingSource.developer,
      config: {...defaultConfigs[type]!, ...overrides},
      tags: tags,
      downloads: downloads,
      createdAt: now,
    );
  }

  return [
    listing(
      'seed-cricket-focus',
      WidgetType.cricketTimer,
      'Cricket Focus Timer',
      'Defend 300 runs a day. Every minute on Instagram costs a run, and '
          'opening it during study hours costs a wicket.',
      {},
      ['focus', 'gamified', 'screen time'],
      1240,
    ),
    listing(
      'seed-med-reminder',
      WidgetType.reminder,
      'Medicine Reminder',
      'Daily medicine reminder with a pill-bottle icon and a kind message.',
      {
        'title': 'Time for your meds',
        'message': 'Take care of yourself today. Your medicine is due 💊',
        'category': 'medicine',
        'time': '08:30',
        'color': 0xFF00897B,
      },
      ['health', 'daily'],
      860,
    ),
    listing(
      'seed-study-reminder',
      WidgetType.reminder,
      'Study Session Reminder',
      'A book-themed nudge to start your evening study session.',
      {
        'title': 'Study time',
        'message': 'Your books miss you. 30 focused minutes, you\'ve got this 📚',
        'category': 'study',
        'time': '18:00',
        'color': 0xFF5E35B1,
      },
      ['study', 'daily'],
      640,
    ),
    listing(
      'seed-science-capture',
      WidgetType.textNotebook,
      'Science Notebook Capture',
      'Select text in any app, tap "Send to Notebook", and it lands in your '
          'Science notebook with headings and a summary.',
      {'defaultNotebook': 'Science'},
      ['notes', 'study', 'AI'],
      930,
    ),
    listing(
      'seed-micro-goals',
      WidgetType.microGoals,
      'Daily Micro-Goals',
      'Break a big task into small steps and tick them off through the day.',
      {'resetDaily': true},
      ['productivity', 'focus'],
      510,
    ),
  ];
}
