import 'package:flutter/material.dart';

enum ProjectStatus {
  notStarted('not_started', 'Not Started'),
  inProgress('in_progress', 'In Progress'),
  onHold('on_hold', 'On Hold'),
  completed('completed', 'Completed'),
  archived('archived', 'Archived');

  final String value;
  final String label;

  const ProjectStatus(this.value, this.label);

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ProjectStatus.notStarted,
    );
  }
}

class Project {
  final String id;
  final String workspaceId;
  final String title;
  final String description;
  final ProjectStatus status;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description = '',
    this.status = ProjectStatus.notStarted,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.create({
    required String id,
    required String workspaceId,
    required String title,
    String description = '',
    ProjectStatus status = ProjectStatus.notStarted,
    DateTime? deadline,
  }) {
    final now = DateTime.now();
    return Project(
      id: id,
      workspaceId: workspaceId,
      title: title,
      description: description,
      status: status,
      deadline: deadline,
      createdAt: now,
      updatedAt: now,
    );
  }

  Project copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? description,
    ProjectStatus? status,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Color get statusColor {
    switch (status) {
      case ProjectStatus.notStarted:
        return const Color(0xFF64748B);
      case ProjectStatus.inProgress:
        return const Color(0xFF2A9D84);
      case ProjectStatus.onHold:
        return const Color(0xFFF59E0B);
      case ProjectStatus.completed:
        return const Color(0xFF10B981);
      case ProjectStatus.archived:
        return const Color(0xFF94A3B8);
    }
  }

  bool get isOverdue {
    if (deadline == null) return false;
    if (status == ProjectStatus.completed || status == ProjectStatus.archived) return false;
    return deadline!.isBefore(DateTime.now());
  }

  bool get isCompleted =>
      status == ProjectStatus.completed || status == ProjectStatus.archived;
}