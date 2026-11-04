import '../data/repositories.dart';
import '../models/installed_widget.dart';

String todayKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}

/// Checked-off steps for a micro-goals widget. Steps are tracked by text so
/// reordering or inserting steps in the editor keeps existing ticks.
class MicroGoalProgress {
  MicroGoalProgress._(this._repo, this.widget, this.done);

  final ProgressRepository _repo;
  final InstalledWidget widget;
  final Set<String> done;

  List<String> get steps => (widget.config['steps'] as List?)?.whereType<String>().toList() ?? const [];
  int get doneCount => steps.where(done.contains).length;
  bool get complete => steps.isNotEmpty && doneCount == steps.length;

  static Future<MicroGoalProgress> load(ProgressRepository repo, InstalledWidget widget) async {
    final data = await repo.get(widget.id);
    var done = (data['done'] as List?)?.whereType<String>().toSet() ?? <String>{};
    if (widget.config['resetDaily'] == true && data['day'] != todayKey()) done = {};
    return MicroGoalProgress._(repo, widget, done);
  }

  Future<void> toggle(String step) async {
    if (!done.remove(step)) done.add(step);
    final data = await _repo.get(widget.id);
    await _repo.set(widget.id, {...data, 'done': done.toList(), 'day': todayKey()});
  }

  /// A short encouragement that matches how far along the user is.
  String get cheer {
    if (steps.isEmpty) return 'Add a few small steps to get started.';
    if (complete) return 'All done! 🎉 Big goal, small steps, and you did it.';
    final ratio = doneCount / steps.length;
    if (doneCount == 0) return 'Start with the first step. Just that one.';
    if (ratio < 0.5) return 'Nice start! Keep the momentum going 💪';
    if (ratio < 1) return 'More than halfway there. Almost done!';
    return '';
  }
}
