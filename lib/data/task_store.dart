import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskStore {
  static const _keyTasks = 'tasks_v1';
  static const _keyTheme = 'theme_mode_v1'; // 'light'|'dark'|'system'

  /// Public comparator for sorting tasks.
  static final Comparator<Task> taskComparator = (a, b) {
    // High priority first
    final byPriority = b.priority.sortWeight.compareTo(a.priority.sortWeight);
    if (byPriority != 0) return byPriority;

    // Incomplete (false) before complete (true)
    final byCompleted =
        (a.completed ? 1 : 0).compareTo(b.completed ? 1 : 0);
    if (byCompleted != 0) return byCompleted;

    // Newest first
    return b.createdAt.compareTo(a.createdAt);
  };

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyTasks) ?? <String>[];
    final tasks = raw.map((s) => Task.fromJson(s)).toList();
    tasks.sort(taskComparator);
    return tasks;
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    tasks.sort(taskComparator);
    await prefs.setStringList(_keyTasks, tasks.map((t) => t.toJson()).toList());
  }

  Future<String> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode);
  }
}
