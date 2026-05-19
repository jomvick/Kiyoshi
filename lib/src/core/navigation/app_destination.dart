import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum AppDestination {
  dashboard('Dashboard', LucideIcons.layoutGrid),
  projects('Projects', LucideIcons.columns),
  tasks('Tasks', LucideIcons.checkSquare),
  notes('Notes', LucideIcons.fileText),
  calendar('Calendar', LucideIcons.calendar),
  analytics('Analytics', LucideIcons.barChart3),
  settings('Settings', LucideIcons.settings);

  const AppDestination(this.label, this.icon);

  final String label;
  final IconData icon;

  int get ordinal => index;
}
