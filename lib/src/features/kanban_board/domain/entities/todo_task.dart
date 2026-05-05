import 'package:flutter/material.dart';

enum TodoTaskStatus {
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  done('done', 'Done');

  final String value;
  final String label;

  const TodoTaskStatus(this.value, this.label);

  static TodoTaskStatus fromString(String value) {
    return TodoTaskStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => TodoTaskStatus.todo,
    );
  }
}

enum TodoTaskPriority {
  low(1, 'Low', Color(0xFF34C759)),
  medium(2, 'Medium', Color(0xFF2A9D84)),
  high(3, 'High', Color(0xFFEF4444));

  final int value;
  final String label;
  final Color color;

  const TodoTaskPriority(this.value, this.label, this.color);

  static TodoTaskPriority fromInt(int value) {
    return TodoTaskPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TodoTaskPriority.medium,
    );
  }
}

class TodoTask {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TodoTaskStatus status;
  final TodoTaskPriority priority;
  final DateTime? dueDate;
  final double position;

  const TodoTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = TodoTaskStatus.todo,
    this.priority = TodoTaskPriority.medium,
    this.dueDate,
    this.position = 0.0,
  });

  factory TodoTask.create({
    required String id,
    required String projectId,
    required String title,
    String description = '',
    TodoTaskStatus status = TodoTaskStatus.todo,
    TodoTaskPriority priority = TodoTaskPriority.medium,
    DateTime? dueDate,
  }) {
    return TodoTask(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
    );
  }

  TodoTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TodoTaskStatus? status,
    TodoTaskPriority? priority,
    DateTime? dueDate,
    double? position,
  }) {
    return TodoTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
    );
  }

  bool get isCompleted => status == TodoTaskStatus.done;

  bool get isOverdue {
    if (dueDate == null) return false;
    if (isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }
}