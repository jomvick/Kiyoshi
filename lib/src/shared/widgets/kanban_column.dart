import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/board.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/task.dart';
import 'package:kiyoshi/src/shared/widgets/kanban_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Zen Kanban Column - "Invisible Space"
/// Redesigned with glassmorphic headers, poetic empty states, and dynamic glow drops.
class KanbanColumn extends StatefulWidget {
  final Board board;
  final List<Task> tasks;
  final VoidCallback? onAddTask;
  final VoidCallback? onBoardDeleted;
  final Function(Task) onTaskMoved;
  final Function(Task)? onTaskTap;
  final Function(Task)? onTaskDeleted;
  final Function(Task)? onTaskEdited;
  final Function(Task task, int oldIndex, int newIndex) onTaskReordered;
  final Color? accentColor;

  const KanbanColumn({
    super.key,
    required this.board,
    required this.tasks,
    this.onAddTask,
    this.onBoardDeleted,
    this.onTaskTap,
    this.onTaskDeleted,
    this.onTaskEdited,
    required this.onTaskMoved,
    required this.onTaskReordered,
    this.accentColor,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isHovering = false;
  bool _isDropTarget = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.tasks.isEmpty && !_isDropTarget;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isDropTarget = true);
        return true;
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDropTarget = false);
        widget.onTaskMoved(details.data);
      },
      onLeave: (_) => setState(() => _isDropTarget = false),
      builder: (context, candidateData, rejectedData) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AnimatedContainer(
            duration: AppTheme.animMedium,
            curve: Curves.easeOutCubic,
            width: isEmpty ? 280 : 320,
            margin: const EdgeInsets.only(
              right: AppTheme.spaceLarge,
            ),
            decoration: BoxDecoration(
              color: _isDropTarget
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.surfaceContainerLow.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(
                color: _isDropTarget
                    ? AppTheme.primary.withValues(alpha: 0.6)
                    : AppTheme.outline.withValues(alpha: 0.2),
                width: _isDropTarget ? 2.0 : 1.5,
              ),
              boxShadow: [
                if (_isDropTarget)
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isEmpty),
                Expanded(
                  child: isEmpty 
                    ? _buildEmptyState() 
                    : _buildTaskList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isEmpty) {
    return Padding(
      padding: EdgeInsets.only(bottom: isEmpty ? 0 : AppTheme.spaceLarge),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLarge,
              vertical: AppTheme.spaceMedium,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.board.title.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: AppTheme.onBackground.withValues(alpha: 0.8),
                  ),
                ),
                if (!isEmpty) ...[
                  const SizedBox(width: AppTheme.spaceMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${widget.tasks.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.onBoardDeleted != null) ...[
                  GestureDetector(
                    onTap: () {
                      // show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Column', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('Are you sure you want to delete this column? All tasks will be moved to "To Do".'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.onBoardDeleted!();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                  ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: widget.onAddTask,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;
    
    switch (widget.board.id) {
      case 'done':
        icon = LucideIcons.leaf;
        message = 'Awaiting accomplishments';
        break;
      case 'inProgress':
        icon = LucideIcons.loader;
        message = 'Find your focus';
        break;
      case 'todo':
      default:
        icon = LucideIcons.wind;
        message = 'Clear mind, empty space';
        break;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: AppTheme.primary.withValues(alpha: 0.3),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .moveY(begin: -4, end: 4, duration: 2.seconds, curve: Curves.easeInOutSine),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: widget.onAddTask,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add Task'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary.withValues(alpha: 0.8),
              backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTaskList() {
    return Scrollbar(
      controller: _scrollController,
      thickness: 6.0,
      radius: const Radius.circular(8.0),
      thumbVisibility: true,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: true,
          physics: const BouncingScrollPhysics(),
        ),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 60),
          itemCount: widget.tasks.length + 1,
          itemBuilder: (context, index) {
          if (index == widget.tasks.length) {
            return _buildAddTaskButton();
          }

          final task = widget.tasks[index];
          return Padding(
            key: ValueKey(task.id),
            padding: const EdgeInsets.only(bottom: AppTheme.spaceLarge),
            child: Draggable<Task>(
              data: task,
              feedback: Material(
                color: Colors.transparent,
                elevation: 0,
                child: SizedBox(
                  width: 288,
                  child: KanbanCard(
                    task: task,
                    accentColor: widget.accentColor,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: KanbanCard(task: task, accentColor: widget.accentColor),
              ),
              child: KanbanCard(
                task: task,
                onTap: () {
                  if (widget.onTaskTap != null) widget.onTaskTap!(task);
                },
                onDelete: () {
                  if (widget.onTaskDeleted != null) widget.onTaskDeleted!(task);
                },
                onEdit: () {
                  if (widget.onTaskEdited != null) widget.onTaskEdited!(task);
                },
                accentColor: widget.accentColor,
              ),
            ),
          );
        },
      ),
    ),
  );
  }

  Widget _buildAddTaskButton() {
    return GestureDetector(
      key: const ValueKey('add-task-button'),
      onTap: widget.onAddTask,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(
            top: AppTheme.spaceMedium,
            bottom: AppTheme.spaceMedium,
          ),
          height: 48,
          decoration: BoxDecoration(
            color: _isHovering
                ? AppTheme.surfaceContainerLow.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _isHovering
                  ? AppTheme.outline.withValues(alpha: 0.15)
                  : AppTheme.outline.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: AppTheme.onSurfaceVariant.withValues(
                    alpha: _isHovering ? 0.7 : 0.4,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Text(
                  'Add a task',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: _isHovering ? 0.7 : 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
