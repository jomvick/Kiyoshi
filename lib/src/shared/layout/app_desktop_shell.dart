import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/zen_mode_provider.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/shared/widgets/sidebar.dart';
import 'package:kiyoshi/src/features/navigation/morphing_zen_bar.dart';

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

  @override
  void dispose() {
    _quickEntryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZenMode = ref.watch(zenModeProvider);
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: KeyboardListener(
        focusNode: FocusNode(), // Dummy focus node for catching global events
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
            // Background Misty Gradients
            const Positioned.fill(
              child: _BackgroundGradients(),
            ),
            
// Layout: Sidebar + Main Content
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isNarrow = screenWidth < 600;
                final isMedium = screenWidth < 900;

final sidebarWidth = isZenMode 
    ? 0.0 
    : (isNarrow ? 0.0 : (isMedium ? 60.0 : (prefs.sidebarExpanded ? prefs.sidebarWidth : 0.0)));

                return Row(
                  children: [
                    // Left Sidebar - Responsive
                    AnimatedContainer(
                      duration: AppTheme.animMedium,
                      curve: Curves.easeOutCubic,
                      width: sidebarWidth,
                      child: sidebarWidth > 0
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: SizedBox(
                                width: isMedium ? 60 : prefs.sidebarWidth,
                                child: isMedium
                                    ? _buildCompactSidebar()
                                    : Sidebar(
                                        selectedWorkspace: widget.selectedWorkspace,
                                        workspaces: widget.workspaces,
                                        onWorkspaceSelected: widget.onWorkspaceSelected,
                                        onCreateWorkspace: widget.onCreateWorkspace,
                                        selectedDestination: widget.selectedDestination,
                                        onDestinationSelected: widget.onDestinationSelected,
                                        showPrismaticBorders: prefs.prismaticBorders,
                                      ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Right Main Content
                    Expanded(
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
                    ),
                  ],
                );
              },
            ),
    
            // Zen Quick Entry - Only on Dashboard
            if (!isZenMode && widget.selectedDestination == AppDestination.dashboard)
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Center(
                  child: MorphingZenBar(
                    isDashboard: true,
                    focusNode: _quickEntryFocusNode,
                    showPrismaticBorders: prefs.prismaticBorders,
                    onTaskCreated: (title, date, project, priority) async {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task "$title" created'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    },
                    onBlockCreated: (type, content, metadata) async {
                      final parsed = ParsedBlock(
                        type: type,
                        content: content,
                        metadata: metadata,
                      );
                      final String targetProject = metadata['project'] ?? 'global';
                      await ref.read(blockServiceProvider).addBlock(targetProject, parsed);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${type.toUpperCase()} created in $targetProject'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    },
                    onProjectCreated: (title, description) async {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('\u2728 Project "$title" created'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    },
                    onNavigateToCalendar: () => widget.onDestinationSelected(AppDestination.calendar),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSidebar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          ...AppDestination.values.map((dest) => _buildCompactNavItem(dest)),
        ],
      ),
    );
  }

  Widget _buildCompactNavItem(AppDestination dest) {
    final isSelected = widget.selectedDestination == dest;
    return Tooltip(
      message: dest.label,
      child: InkWell(
        onTap: () => widget.onDestinationSelected(dest),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            dest.icon,
            size: 20,
            color: isSelected 
                ? AppTheme.primary 
                : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

}

class _BackgroundGradients extends StatelessWidget {
  const _BackgroundGradients();

  @override
  Widget build(BuildContext context) {
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
                    AppTheme.sage.withValues(alpha: 0.15),
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
                    AppTheme.mintTeal.withValues(alpha: 0.2),
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
