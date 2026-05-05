import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum AppDestination {
  dashboard(
    label: 'Dashboard',
    icon: LucideIcons.layoutGrid,
  ),
  projects(
    label: 'Projects',
    icon: LucideIcons.columns,
  ),
  tasks(
    label: 'Tasks',
    icon: LucideIcons.checkSquare,
  ),
  notes(
    label: 'Notes',
    icon: LucideIcons.fileText,
  ),
  calendar(
    label: 'Calendar',
    icon: LucideIcons.calendar,
  ),
  analytics(
    label: 'Analytics',
    icon: LucideIcons.barChart3,
  );

  const AppDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
