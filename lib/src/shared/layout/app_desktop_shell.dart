import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/shared/widgets/sidebar.dart';
import 'package:kiyoshi/src/features/navigation/morphing_zen_bar.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/ai_agent_drawer.dart';

class AppDesktopShell extends ConsumerStatefulWidget {
  final Workspace? selectedWorkspace;
  final List<Workspace> workspaces;
  final ValueChanged<Workspace> onWorkspaceSelected;
  final VoidCallback onCreateWorkspace;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final Widget child;

  const AppDesktopShell({
    super.key,
    required this.selectedWorkspace,
    required this.workspaces,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
    required this.selectedDestination,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  ConsumerState<AppDesktopShell> createState() => _AppDesktopShellState();
}

class _AppDesktopShellState extends ConsumerState<AppDesktopShell> {
  final FocusNode _quickEntryFocusNode = FocusNode();
  static const double compactWidth = 76.0;

  @override
  void dispose() {
    _quickEntryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final isZenMode = prefs.zenModeEnabled;

    return Scaffold(
      body: _buildKeyboardListener(isZenMode, prefs),
    );
  }

  Widget _buildKeyboardListener(bool isZenMode, AppPreferences prefs) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            !_quickEntryFocusNode.hasFocus &&
            event.character != null &&
            event.character!.isNotEmpty) {
          _quickEntryFocusNode.requestFocus();
        }
      },
      child: Stack(
        children: [
          const Positioned.fill(child: _BackgroundGradients()),
          _buildLayoutRow(isZenMode, prefs),
          if (!isZenMode && widget.selectedDestination == AppDestination.dashboard)
            _buildZenBar(prefs),
          // ─── AI Agent Drawer Overlay ─────────────────────────────
          const AiAgentDrawer(),
        ],
      ),
    );
  }

  Widget _buildLayoutRow(bool isZenMode, AppPreferences prefs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isNarrow = screenWidth < 600;

        final sidebarWidth = isZenMode
            ? 0.0
            : (isNarrow
                ? 0.0
                : (prefs.sidebarExpanded ? prefs.sidebarWidth : compactWidth));

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebarSection(isNarrow, sidebarWidth, prefs),
            _buildContentSection(isZenMode),
          ],
        );
      },
    );
  }

  Widget _buildSidebarSection(bool isNarrow, double sidebarWidth, AppPreferences prefs) {
    return AnimatedContainer(
      duration: AppTheme.animMedium,
      curve: Curves.easeOutCubic,
      width: sidebarWidth,
      child: sidebarWidth > 0
          ? Sidebar(
              isExpanded: prefs.sidebarExpanded,
              selectedWorkspace: widget.selectedWorkspace,
              workspaces: widget.workspaces,
              onWorkspaceSelected: widget.onWorkspaceSelected,
              onCreateWorkspace: widget.onCreateWorkspace,
              selectedDestination: widget.selectedDestination,
              onDestinationSelected: widget.onDestinationSelected,
              showPrismaticBorders: prefs.prismaticBorders,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContentSection(bool isZenMode) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          top: isZenMode ? 0 : AppTheme.spaceMedium,
          right: isZenMode ? 0 : AppTheme.spaceMedium,
          bottom: isZenMode ? 0 : AppTheme.spaceMedium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isZenMode ? 0 : AppTheme.radiusXLarge),
          child: widget.child,
        ),
      ),
    );
  }

  Widget _buildZenBar(AppPreferences prefs) {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Center(
        child: MorphingZenBar(
          isDashboard: true,
          focusNode: _quickEntryFocusNode,
          showPrismaticBorders: prefs.prismaticBorders,
          onTaskCreated: (title, date, project, priority) async {
            try {
              final parsed = ParsedBlock(
                type: 'todo',
                content: title,
                metadata: {
                  'status': 'todo',
                  'priority': priority,
                  'project': project,
                  if (date != null) 'dueDate': date.toIso8601String(),
                },
              );
              final String targetProject = project ?? 'global';
              await ref.read(blockServiceProvider).addBlock(targetProject, parsed);
              if (context.mounted) {
                _showSnackBar('Task "$title" created');
              }
            } catch (e) {
              debugPrint('Failed to create task: $e');
              if (context.mounted) {
                _showSnackBar('Could not create task.', isError: true);
              }
            }
          },
          onBlockCreated: (type, content, metadata) async {
            try {
              final parsed = ParsedBlock(
                type: type,
                content: content,
                metadata: metadata,
              );
              final String targetProject = metadata['project'] ?? 'global';
              await ref.read(blockServiceProvider).addBlock(targetProject, parsed);
              if (context.mounted) {
                _showSnackBar('${type.toUpperCase()} created in $targetProject');
              }
            } catch (e) {
              debugPrint('Failed to create block: $e');
              if (context.mounted) {
                _showSnackBar('Could not create block.', isError: true);
              }
            }
          },
          onProjectCreated: (title, description) async {
            try {
              if (title.trim().isEmpty) return;
              final workspaceId = widget.selectedWorkspace?.id ?? 'default';
              final project = Project.create(
                id: const Uuid().v4(),
                workspaceId: workspaceId,
                title: title.trim(),
                description: description ?? '',
              );
              await ref.read(projectRepositoryProvider).addProject(project);
              if (context.mounted) {
                _showSnackBar('\u2728 Project "$title" created');
              }
            } catch (e) {
              debugPrint('Failed to create project: $e');
              if (context.mounted) {
                _showSnackBar('Could not create project.', isError: true);
              }
            }
          },
          onNavigateToCalendar: () => widget.onDestinationSelected(AppDestination.calendar),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : scheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Compact sidebar methods removed in favor of unified Sidebar widget

}

class _BackgroundGradients extends StatelessWidget {
  const _BackgroundGradients();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Slightly boosted alpha in dark mode so the blobs still read as an
    // ambient glow against the warm charcoal canvas instead of vanishing.
    final boost = isDark ? 1.4 : 1.0;
    return RepaintBoundary(
      child: Stack(
        children: [
          // Top Left Sage Blob
          Positioned(
            top: -200,
            left: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.sage.withValues(alpha: 0.15 * boost),
                    AppTheme.sage.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Right Mint Blob
          Positioned(
            bottom: -300,
            right: -100,
            child: Container(
              width: 800,
              height: 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mintTeal.withValues(alpha: 0.2 * boost),
                    AppTheme.mintTeal.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
