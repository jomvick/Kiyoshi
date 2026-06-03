import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/shared/layout/zen_studio_page_shell.dart';
import 'package:kiyoshi/src/shared/widgets/zen_editorial_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return ZenStudioPageShell(
      title: 'SETTINGS',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space2XLarge,
          AppTheme.spaceLarge,
          AppTheme.space2XLarge,
          AppTheme.space2XLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZenEditorialHeader(
              label: 'Configuration',
              title: 'Settings',
              subtitle: 'Customize your Zen Studio experience.',
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildAppearanceSection(context, ref, prefs),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildBehaviorSection(context, ref, prefs),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildNavigationSection(context, ref, prefs),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildDataManagementSection(context, ref),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildShortcutsSection(context),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildCanvasSection(context, ref, prefs),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref, AppPreferences prefs) {
    return _SettingsSection(
      title: 'APPEARANCE',
      icon: LucideIcons.palette,
      children: [
        _SettingsSwitchTile(
          icon: LucideIcons.layoutTemplate,
          title: 'Sidebar Extended',
          subtitle: 'Show full sidebar with labels',
          value: prefs.sidebarExpanded,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setSidebarExpanded(v),
        ),
        _SettingsSwitchTile(
          icon: LucideIcons.moon,
          title: 'Dark Mode',
          subtitle: 'Switch to dark theme (coming soon)',
          value: prefs.darkMode,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setDarkMode(v),
        ),
        _SettingsSwitchTile(
          icon: LucideIcons.sparkles,
          title: 'Prismatic Borders',
          subtitle: 'Rainbow border animation on focus',
          value: prefs.prismaticBorders,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setPrismaticBorders(v),
        ),
      ],
    );
  }

  Widget _buildBehaviorSection(BuildContext context, WidgetRef ref, AppPreferences prefs) {
    final isZenMode = ref.watch(preferencesProvider.select((p) => p.zenModeEnabled));

    return _SettingsSection(
      title: 'BEHAVIOR',
      icon: LucideIcons.cpu,
      children: [
        _SettingsSwitchTile(
          icon: LucideIcons.focus,
          title: 'Zen Mode Default',
          subtitle: 'Start app in focus mode',
          value: prefs.zenModeEnabled,
          onChanged: (v) {
            ref.read(preferencesProvider.notifier).setZenModeEnabled(v);
          },
        ),
        _SettingsSwitchTile(
          icon: LucideIcons.eye,
          title: 'Zen Mode Active',
          subtitle: isZenMode ? 'Minimal UI is on' : 'Full UI is visible',
          value: isZenMode,
          onChanged: (v) {
            ref.read(preferencesProvider.notifier).setZenModeEnabled(v);
          },
        ),
        _SettingsSwitchTile(
          icon: LucideIcons.bell,
          title: 'Notifications',
          subtitle: 'Show snackbar feedback on actions',
          value: prefs.notifications,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setNotifications(v),
        ),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context, WidgetRef ref, AppPreferences prefs) {
    return _SettingsSection(
      title: 'NAVIGATION',
      icon: LucideIcons.compass,
      children: [
        _SettingsDropdownTile(
          icon: LucideIcons.home,
          title: 'Default Page',
          subtitle: 'Opens when app starts',
          value: prefs.defaultDestination,
          items: AppDestination.values.map((d) => (value: d.name, label: d.label)).toList(),
          onChanged: (v) => ref.read(preferencesProvider.notifier).setDefaultDestination(v),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'DATA MANAGEMENT',
      icon: LucideIcons.database,
      children: [
        _SettingsActionTile(
          icon: LucideIcons.download,
          title: 'Export as JSON',
          subtitle: 'Save all data to a JSON file',
          actionLabel: 'JSON',
          onTap: () async {
            try {
              final directory = await getApplicationDocumentsDirectory();
              final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
              final file = File('${directory.path}/kiyoshi_export_$timestamp.json');
              final data = {
                'version': '1.0.0',
                'exportedAt': timestamp,
                'preferences': ref.read(preferencesProvider).toJson(),
              };
              await file.writeAsString(jsonEncode(data));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data exported to ${file.path}')),
                );
              }
            } catch (e) {
              debugPrint('Export failed: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export failed. Please try again.')),
                );
              }
            }
          },
        ),
        _SettingsActionTile(
          icon: LucideIcons.fileText,
          title: 'Export as Markdown',
          subtitle: 'Export projects to Markdown files',
          actionLabel: 'MD',
          onTap: () async {
            try {
              final directory = await getApplicationDocumentsDirectory();
              final exportDir = Directory('${directory.path}/kiyoshi_exports_${DateTime.now().millisecondsSinceEpoch}');
              await exportDir.create(recursive: true);
              
              final prefsData = ref.read(preferencesProvider);
              final mdContent = '''# Kiyoshi Export
Generated: ${DateTime.now().toIso8601String()}

## Settings
- Sidebar Expanded: ${prefsData.sidebarExpanded}
- Dark Mode: ${prefsData.darkMode}
- Prismatic Borders: ${prefsData.prismaticBorders}
- Auto-save: ${prefsData.autoSave}
- Show Grid: ${prefsData.showGrid}
- Snap to Grid: ${prefsData.snapToGrid}
- Kanban Column Width: ${prefsData.kanbanColumnWidth.toInt()}px

---
*Exported from Kiyoshi Zen Studio*
''';
              
              final file = File('${exportDir.path}/kiyoshi_export.md');
              await file.writeAsString(mdContent);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exported to ${exportDir.path}')),
                );
              }
            } catch (e) {
              debugPrint('Export failed: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export failed. Please try again.')),
                );
              }
            }
          },
        ),
        _SettingsActionTile(
          icon: LucideIcons.upload,
          title: 'Import Data',
          subtitle: 'Load projects and settings from a file',
          actionLabel: 'Import',
          onTap: () async {
            try {
              final result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
                final file = File(result.files.first.path!);
                final content = await file.readAsString();
                final decoded = jsonDecode(content);
                if (decoded is! Map) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid import file format.')),
                    );
                  }
                  return;
                }
                final data = decoded as Map<String, dynamic>;
                final prefsNotifier = ref.read(preferencesProvider.notifier);
                if (data['preferences'] is Map) {
                  final imported = const AppPreferences().importFromJson(data['preferences'] as Map<String, dynamic>);
                  await prefsNotifier.setSidebarExpanded(imported.sidebarExpanded);
                  await prefsNotifier.setZenModeEnabled(imported.zenModeEnabled);
                  await prefsNotifier.setDefaultDestination(imported.defaultDestination);
                  await prefsNotifier.setSidebarWidth(imported.sidebarWidth);
                  await prefsNotifier.setDarkMode(imported.darkMode);
                  await prefsNotifier.setPrismaticBorders(imported.prismaticBorders);
                  await prefsNotifier.setNotifications(imported.notifications);
                  await prefsNotifier.setAutoSave(imported.autoSave);
                  await prefsNotifier.setShowGrid(imported.showGrid);
                  await prefsNotifier.setSnapToGrid(imported.snapToGrid);
                  await prefsNotifier.setKanbanColumnWidth(imported.kanbanColumnWidth);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data imported successfully')),
                  );
                }
              }
            } catch (e) {
              debugPrint('Import failed: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import failed. The file may be corrupted.')),
                );
              }
            }
          },
        ),
        _SettingsActionTile(
          icon: LucideIcons.trash2,
          title: 'Clear Cache',
          subtitle: 'Remove temporary files and caches',
          actionLabel: 'Clear',
          onTap: () async {
            try {
              final directory = await getApplicationDocumentsDirectory();
              final cacheDir = Directory('${directory.path}/kiyoshi_cache');
              if (await cacheDir.exists()) {
                await cacheDir.delete(recursive: true);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            } catch (e) {
              debugPrint('Clear cache failed: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not clear cache. Please try again.')),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildShortcutsSection(BuildContext context) {
    return const _SettingsSection(
      title: 'KEYBOARD SHORTCUTS',
      icon: LucideIcons.keyboard,
      children: [
        _SettingsInfoTile(
          icon: LucideIcons.command,
          title: 'Command Palette',
          subtitle: 'Ctrl+K or Cmd+K',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.search,
          title: 'Quick Search',
          subtitle: 'Ctrl+P or Cmd+P',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.plus,
          title: 'New Project',
          subtitle: 'Ctrl+N or Cmd+N',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.save,
          title: 'Save',
          subtitle: 'Ctrl+S or Cmd+S',
        ),
      ],
    );
  }

  Widget _buildCanvasSection(BuildContext context, WidgetRef ref, AppPreferences prefs) {
    return _SettingsSection(
      title: 'CANVAS & KANBAN',
      icon: LucideIcons.layoutDashboard,
      children: [
        _SettingsSwitchTile(
          icon: LucideIcons.save,
          title: 'Auto-save',
          subtitle: 'Save changes automatically',
          value: prefs.autoSave,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setAutoSave(v),
        ),
        _SettingsSwitchTile(
          icon: LucideIcons.layoutGrid,
          title: 'Show Grid',
          subtitle: 'Display canvas grid lines',
          value: prefs.showGrid,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setShowGrid(v),
        ),
        _SettingsSwitchTile(
          icon: LucideIcons.alignHorizontalDistributeCenter,
          title: 'Snap to Grid',
          subtitle: 'Align blocks to grid',
          value: prefs.snapToGrid,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setSnapToGrid(v),
        ),
        _SettingsSliderTile(
          icon: LucideIcons.moreHorizontal,
          title: 'Default Column Width',
          subtitle: '${prefs.kanbanColumnWidth.toInt()}px',
          value: prefs.kanbanColumnWidth,
          min: 250,
          max: 500,
          onChanged: (v) => ref.read(preferencesProvider.notifier).setKanbanColumnWidth(v),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return const _SettingsSection(
      title: 'ABOUT',
      icon: LucideIcons.info,
      children: [
        _SettingsInfoTile(
          icon: LucideIcons.leaf,
          title: 'Kiyoshi',
          subtitle: 'A minimalist glassmorphic Kanban workspace manager',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.hash,
          title: 'Version',
          subtitle: '1.0.0',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.code,
          title: 'Built with Flutter',
          subtitle: 'Desktop (Linux, macOS, Windows)',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.palette,
          title: 'Design System',
          subtitle: 'Zen Studio — Glassmorphic',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.database,
          title: 'Database',
          subtitle: 'Drift (SQLite)',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.layers,
          title: 'State Management',
          subtitle: 'Riverpod',
        ),
        _SettingsInfoTile(
          icon: LucideIcons.shield,
          title: 'License',
          subtitle: 'MIT — Open Source',
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        ...children,
      ],
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SettingsSliderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsDropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final List<({String value, String label})> items;
  final ValueChanged<String> onChanged;

  const _SettingsDropdownTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox.shrink(),
              icon: const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.primary),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
              items: items.map((item) => DropdownMenuItem<String>(
                value: item.value,
                child: Text(item.label),
              )).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}