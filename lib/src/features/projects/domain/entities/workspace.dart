import 'package:flutter/material.dart';

class Workspace {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Color themeColor;
  final double progress;
  final List<String> boardIds;

  const Workspace({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'folder',
    this.themeColor = Colors.blue,
    this.progress = 0.0,
    this.boardIds = const [],
  });

  Workspace copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    Color? themeColor,
    double? progress,
    List<String>? boardIds,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      themeColor: themeColor ?? this.themeColor,
      progress: progress ?? this.progress,
      boardIds: boardIds ?? this.boardIds,
    );
  }
}
