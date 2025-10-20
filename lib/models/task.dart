import 'dart:convert';

enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'Low',
        Priority.medium => 'Medium',
        Priority.high => 'High',
      };

  int get sortWeight => switch (this) {
        Priority.high => 3,
        Priority.medium => 2,
        Priority.low => 1,
      };

  static Priority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'medium':
        return Priority.medium;
      default:
        return Priority.low;
    }
  }
}

class Task {
  final String id;
  String title;
  bool completed;
  Priority priority;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.completed = false,
    this.priority = Priority.medium,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'completed': completed,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        completed: map['completed'] as bool? ?? false,
        priority: Priority.values.firstWhere(
          (p) => p.name == (map['priority'] as String? ?? 'medium'),
          orElse: () => Priority.medium,
        ),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  String toJson() => jsonEncode(toMap());
  factory Task.fromJson(String source) => Task.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
