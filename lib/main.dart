import 'package:flutter/material.dart';
import 'models/task.dart';
import 'data/task_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final store = TaskStore();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    store.loadThemeMode().then((mode) {
      setState(() {
        _themeMode = switch (mode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      });
    });
  }

  void _toggleTheme() async {
    final next = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setState(() => _themeMode = next);
    await store.saveThemeMode(switch (next) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Priority To-Do',
      themeMode: _themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: TaskPage(onToggleTheme: _toggleTheme),
    );
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;
  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final store = TaskStore();
  final titleCtrl = TextEditingController();
  Priority _newPriority = Priority.medium;
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await store.loadTasks();
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _persist() async => store.saveTasks(_tasks);

  void _addTask() {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _tasks.add(Task(id: id, title: title, priority: _newPriority));
      _tasks.sort(TaskStore.taskComparator);
      titleCtrl.clear();
      _newPriority = Priority.medium;
    });
    _persist();
  }

  void _deleteTask(Task t) {
    setState(() => _tasks.removeWhere((e) => e.id == t.id));
    _persist();
  }

  void _toggleComplete(Task t, bool? value) {
    final idx = _tasks.indexWhere((e) => e.id == t.id);
    if (idx == -1) return;
    setState(() => _tasks[idx].completed = value ?? false);
    _persist();
  }

  Future<void> _editPriority(Task t) async {
    Priority selected = t.priority;
    final result = await showDialog<Priority>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Priority'),
        content: DropdownButton<Priority>(
          isExpanded: true,
          value: selected,
          items: Priority.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
              .toList(),
          onChanged: (p) => setState(() => selected = p ?? selected),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      final idx = _tasks.indexWhere((e) => e.id == t.id);
      if (idx != -1) {
        setState(() {
          _tasks[idx].priority = result;
          _tasks.sort(TaskStore.taskComparator);
        });
        _persist();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority To-Do'),
        actions: [
          IconButton(
            tooltip: 'Toggle Light/Dark/System',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Add a task',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<Priority>(
                          value: _newPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: Priority.values
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p.label)))
                              .toList(),
                          onChanged: (p) =>
                              setState(() => _newPriority = p ?? Priority.medium),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: _addTask, child: const Icon(Icons.add)),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: _tasks.isEmpty
                      ? const Center(child: Text('No tasks yet. Add one above.'))
                      : ListView.builder(
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final t = _tasks[index];
                            return Dismissible(
                              key: ValueKey(t.id),
                              background: Container(color: Colors.redAccent),
                              onDismissed: (_) => _deleteTask(t),
                              child: ListTile(
                                leading: Checkbox(
                                    value: t.completed,
                                    onChanged: (v) => _toggleComplete(t, v)),
                                title: Text(
                                  t.title,
                                  style: TextStyle(
                                      decoration: t.completed
                                          ? TextDecoration.lineThrough
                                          : null),
                                ),
                                subtitle: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _PriorityChip(priority: t.priority),
                                    const SizedBox(width: 8),
                                    Text('Created ${t.createdAt.toLocal()}'
                                        .split('.')
                                        .first),
                                  ],
                                ),
                                trailing: IconButton(
                                  tooltip: 'Change priority',
                                  icon: const Icon(Icons.flag_outlined),
                                  onPressed: () => _editPriority(t),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      Priority.high => Colors.red,
      Priority.medium => Colors.orange,
      Priority.low => Colors.green,
    };
    return Chip(
      label: Text(priority.label),
      avatar: Icon(Icons.flag, size: 16, color: color),
      side: BorderSide(color: color),
    );
  }
}
