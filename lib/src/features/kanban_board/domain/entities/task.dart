import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

enum TaskPriority {
  low,
  medium,
  high,
}

enum TaskStatus {
  todo,
  inProgress,
  done,
}

class Task {
  final String id;
  final String boardId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final List<String> tags;
  final String? timeIndicator;
  final int? progress;

  const Task({
    required this.id,
    required this.boardId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.dueDate,
    this.tags = const [],
    this.timeIndicator,
    this.progress,
  });

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFF5757); // Vibrant Red
      case TaskPriority.medium:
        return AppTheme.primary; // Indigo
      case TaskPriority.low:
        return const Color(0xFF34C98F); // Emerald
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Task copyWith({
    String? id,
    String? boardId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    List<String>? tags,
    String? timeIndicator,
    int? progress,
  }) {
    return Task(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      timeIndicator: timeIndicator ?? this.timeIndicator,
      progress: progress ?? this.progress,
    );
  }
}
