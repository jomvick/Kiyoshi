import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/board.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/task.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/todo_task.dart';

import 'package:kiyoshi/src/shared/widgets/kanban_column.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:uuid/uuid.dart';

class DatabaseViewWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> metadata;
  final String projectId;
  final VoidCallback? onDelete;

  const DatabaseViewWidget({
    super.key,
    required this.metadata,
    required this.projectId,
    this.onDelete,
  });

  @override
  ConsumerState<DatabaseViewWidget> createState() => _DatabaseViewWidgetState();
}

class _DatabaseViewWidgetState extends ConsumerState<DatabaseViewWidget> {
  static const List<Board> _boards = [
    Board(id: 'todo', title: 'To Do', workspaceId: 'canvas', order: 0),
    Board(id: 'in_progress', title: 'In Progress', workspaceId: 'canvas', order: 1),
    Board(id: 'done', title: 'Done', workspaceId: 'canvas', order: 2),
  ];

  Task _mapToTask(TodoTask t) => Task(
        id: t.id,
        boardId: t.status.value,
        title: t.title,
        description: t.description,
        status: _mapStatus(t.status),
        priority: TaskPriority.medium,
        tags: const [],
      );

  TaskStatus _mapStatus(TodoTaskStatus s) {
    switch (s) {
      case TodoTaskStatus.inProgress:
        return TaskStatus.inProgress;
      case TodoTaskStatus.done:
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  void _onAddTask(String boardId) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ZenGlassCard(
          radius: 32,
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.penTool, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Capture Intent',
                      style: TextStyle(
                        color: AppTheme.onBackground.withValues(alpha: 0.8),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  cursorColor: AppTheme.primary,
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) _createTask(boardId, value.trim(), ctx);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          _createTask(boardId, nameController.text.trim(), ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutQuart),
    );
  }

  void _createTask(String boardId, String title, BuildContext ctx) {
    final repo = ref.read(projectRepositoryProvider);
    repo.addTask(TodoTask(
      id: const Uuid().v4(),
      projectId: widget.projectId,
      title: title,
      description: '',
      status: TodoTaskStatus.values.firstWhere(
        (s) => s.value == boardId,
        orElse: () => TodoTaskStatus.todo,
      ),
      priority: TodoTaskPriority.medium,
    ));
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksForProjectProvider(widget.projectId));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.outline.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.layoutGrid, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Board View',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: widget.onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Kanban columns
          Padding(
            padding: const EdgeInsets.all(12),
            child: tasksAsync.when(
              data: (tasks) => SizedBox(
                height: 360,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _boards.asMap().entries.map((entry) {
                      final index = entry.key;
                      final board = entry.value;
                      final boardTasks = tasks
                          .where((t) => t.status.value == board.id)
                          .map(_mapToTask)
                          .toList();

                      return SizedBox(
                        width: 280,
                        child: KanbanColumn(
                          board: board,
                          tasks: boardTasks,
                          onAddTask: () => _onAddTask(board.id),
                          onTaskMoved: (_) {},
                          onTaskReordered: (task, a, b) {},
                          accentColor: AppTheme.primary,
                        ),
                      ).animate().fadeIn(delay: (80 * index).ms).slideY(begin: 0.08);
                    }).toList(),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => const Center(child: Text('Could not load data.')),
            ),
          ),
        ],
      ),
    );
  }
}