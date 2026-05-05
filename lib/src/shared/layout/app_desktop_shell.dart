import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/zen_mode_provider.dart';
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
  final VoidCallback? onNewProjectTap;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final Widget child;

  const AppDesktopShell({
    super.key,
    required this.selectedWorkspace,
    required this.workspaces,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
    this.onNewProjectTap,
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
            Row(
              children: [
                // Left Sidebar - Hidden in Zen Mode
                AnimatedContainer(
                  duration: AppTheme.animMedium,
                  curve: Curves.easeOutCubic,
                  width: isZenMode ? 0 : 280,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: 280,
                      child: Sidebar(
                        selectedWorkspace: widget.selectedWorkspace,
                        workspaces: widget.workspaces,
                        onWorkspaceSelected: widget.onWorkspaceSelected,
                        onCreateWorkspace: widget.onCreateWorkspace,
                        onNewProjectTap: widget.onNewProjectTap,
                        selectedDestination: widget.selectedDestination,
                        onDestinationSelected: widget.onDestinationSelected,
                      ),
                    ),
                  ),
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGradients extends StatelessWidget {
  const _BackgroundGradients();

  @override
  Widget build(BuildContext context) {
    return Stack(
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
    );
  }
}
