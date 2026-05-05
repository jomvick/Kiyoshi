import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/canvas/presentation/block_canvas.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProjectDetailView extends ConsumerStatefulWidget {
  final Project project;
  final VoidCallback? onBack;

  const ProjectDetailView({
    super.key,
    required this.project,
    this.onBack,
  });

  @override
  ConsumerState<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends ConsumerState<ProjectDetailView> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _descriptionController = TextEditingController(text: widget.project.description);
  }

  @override
  void didUpdateWidget(ProjectDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      _titleController.text = widget.project.title;
      _descriptionController.text = widget.project.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(projectBlocksProvider(widget.project.id));
    final projectAsync = ref.watch(projectByIdProvider(widget.project.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: projectAsync.when(
        data: (project) {
          final currentProject = project ?? widget.project;
          return Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main Content
              Column(
                children: [
                  // Header
                  _buildAppBar(currentProject)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: -0.1),
                  
                  // Content
                  Expanded(
                    child: blocksAsync.when(
                      data: (blocks) => ZenCanvas(
                        projectId: currentProject.id,
                        blocks: blocks,
                        header: _buildZenHeader(currentProject)
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideY(begin: -0.05),
                        onReorder: (oldIndex, newIndex) => _handleReorder(blocks, oldIndex, newIndex),
                        onTodoChanged: _handleTodoChanged,
                        onContentChanged: _handleContentChanged,
                        onDelete: _handleBlockDeleted,
                        onCreateBlock: _handleBlockCreated,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              size: 48,
                              color: AppTheme.error.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading blocks',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: AppTheme.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text('Error: $err'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Project project) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spaceLarge,
        left: AppTheme.spaceLarge,
        right: AppTheme.spaceLarge,
        bottom: AppTheme.spaceSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AnimatedIconButton(
            icon: LucideIcons.arrowLeft,
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
          _AnimatedIconButton(
            icon: LucideIcons.moreHorizontal,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(Project project) {
    return PopupMenuButton<ProjectStatus>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: project.statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: project.statusColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: project.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              project.status.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: project.statusColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: project.statusColor,
            ),
          ],
        ),
      ),
      onSelected: (status) => _updateProjectStatus(project, status),
      itemBuilder: (context) => ProjectStatus.values
          .map((status) => PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status.label),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Color _statusColor(ProjectStatus status) {
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

  // _buildContent replaced by ZenCanvas

  Widget _buildZenHeader(Project project) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space2XLarge,
        vertical: AppTheme.spaceLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space2XLarge),
            decoration: AppTheme.glassPanel(radius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: AppTheme.onBackground.withValues(alpha: 0.9),
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (val) {
                    ref.read(projectRepositoryProvider).updateProject(
                      project.copyWith(title: val.trim()),
                    );
                  },
                ),
              ),
              _buildStatusDropdown(project),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Row(
            children: [
              if (project.deadline != null)
                _buildMetadataChip(
                  icon: LucideIcons.calendar,
                  label: DateFormat('MMM d, yyyy').format(project.deadline!),
                  isOverdue: project.isOverdue,
                ),
              if (project.deadline != null && project.status != ProjectStatus.completed)
                const SizedBox(width: AppTheme.spaceMedium),
              _buildMetadataChip(
                icon: LucideIcons.clock,
                label: 'Updated ${_formatRelativeDate(project.updatedAt)}',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          TextField(
            controller: _descriptionController,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.5,
                ),
            decoration: InputDecoration(
              hintText: 'Add a project description...',
              hintStyle: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (val) {
              ref.read(projectRepositoryProvider).updateProject(
                project.copyWith(description: val.trim()),
              );
            },
          ),
        ],
      ),
    ),
    ),
    ),
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    bool isOverdue = false,
  }) {
    final color = isOverdue ? AppTheme.error : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Custom blocks replaced by ZenCanvas

  Future<void> _updateProjectStatus(Project project, ProjectStatus status) async {
    try {
      final updated = project.copyWith(status: status);
      await ref.read(projectRepositoryProvider).updateProject(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update status: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleBlockCreated(
    String type,
    String content,
    Map<String, dynamic> metadata,
  ) async {
    if (content.trim().isEmpty) return;
    try {
      await ref.read(blockServiceProvider).addBlock(
        widget.project.id,
        ParsedBlock(type: type, content: content, metadata: metadata),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save block: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleBlockDeleted(ZenBlock block) async {
    try {
      await ref.read(blockServiceProvider).deleteBlock(block);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete block: $e')),
        );
      }
    }
  }

  void _handleTodoChanged(ZenBlock block, bool isChecked) {
    final metadata = Map<String, dynamic>.from(block.metadata);
    metadata['checked'] = isChecked;
    ref.read(blockServiceProvider).updateBlock(
      block.copyWith(metadata: metadata),
    );
  }

  void _handleReorder(List<ZenBlock> blocks, int oldIndex, int newIndex) {
    ref
        .read(blockServiceProvider)
        .reorderBlocks(widget.project.id, oldIndex, newIndex);
  }

  void _handleContentChanged(ZenBlock block, String newContent) {
    ref.read(blockServiceProvider).updateBlock(
          block.copyWith(content: newContent),
        );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}