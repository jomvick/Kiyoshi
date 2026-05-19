import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/board.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/task.dart';
import 'package:kiyoshi/src/shared/widgets/kanban_column.dart';
import 'package:kiyoshi/src/shared/layout/zen_studio_page_shell.dart';
import 'package:kiyoshi/src/shared/widgets/zen_editorial_header.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final ScrollController _kanbanScrollController = ScrollController();
  List<Board> _boards = const [
    Board(id: 'todo', title: 'To Do', workspaceId: 'global', order: 0),
    Board(id: 'inProgress', title: 'In Progress', workspaceId: 'global', order: 1),
    Board(id: 'done', title: 'Done', workspaceId: 'global', order: 2),
  ];

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _kanbanScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final boardsJson = prefs.getStringList('global_boards');
    if (boardsJson != null && boardsJson.isNotEmpty) {
      try {
        final List<Board> loaded = boardsJson.map((str) {
          final map = jsonDecode(str);
          return Board(
            id: map['id'],
            title: map['title'],
            workspaceId: map['workspaceId'],
            order: map['order'],
          );
        }).toList();
        setState(() {
          _boards = loaded;
        });
      } catch (e) {
        debugPrint('Error loading boards: $e');
      }
    }
  }

  Future<void> _saveBoards() async {
    final prefs = await SharedPreferences.getInstance();
    final boardsJson = _boards.map((b) => jsonEncode({
      'id': b.id,
      'title': b.title,
      'workspaceId': b.workspaceId,
      'order': b.order,
    })).toList();
    await prefs.setStringList('global_boards', boardsJson);
  }

  Task _mapToTask(ZenBlock block) {
    final statusStr = block.metadata['status'] ?? 'todo';
    TaskStatus status = TaskStatus.todo;
    if (statusStr == 'inProgress') status = TaskStatus.inProgress;
    if (statusStr == 'done') status = TaskStatus.done;

    return Task(
      id: block.id,
      boardId: statusStr,
      title: block.content,
      description: block.metadata['description'],
      status: status,
      priority: _mapPriority(block.metadata['priority'] as int?),
      tags: List<String>.from(block.metadata['tags'] ?? []),
    );
  }

  TaskPriority _mapPriority(int? p) {
    if (p == 1) return TaskPriority.high;
    if (p == 2) return TaskPriority.medium;
    return TaskPriority.low;
  }

  void _onTaskMoved(ZenBlock block, String newStatus) async {
    final updatedMetadata = Map<String, dynamic>.from(block.metadata);
    updatedMetadata['status'] = newStatus;
    
    final updatedBlock = block.copyWith(metadata: updatedMetadata);
    await ref.read(blockServiceProvider).updateBlock(updatedBlock);
  }

  Future<void> _onTaskToggle(ZenBlock block) async {
    try {
      final status = block.metadata['status'] ?? 'todo';
      final newStatus = status == 'done' ? 'todo' : 'done';
      await _onTaskMoved(block, newStatus);
    } catch (e) {
      debugPrint('Failed to toggle task: $e');
    }
  }

  void _onAddTask(String status) async {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
        onSubmitted: (value) async {
          if (value.trim().isNotEmpty) {
            final parsed = ParsedBlock(
              type: 'todo',
              content: value.trim(),
              metadata: {'status': status},
            );
            await ref.read(blockServiceProvider).addBlock('global', parsed);
            if (context.mounted) Navigator.pop(dialogContext);
          }
        },
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            child: const Text('Cancel')
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final parsed = ParsedBlock(
                  type: 'todo',
                  content: nameController.text.trim(),
                  metadata: {'status': status},
                );
                await ref.read(blockServiceProvider).addBlock('global', parsed);
                if (context.mounted) Navigator.pop(dialogContext);
              }
            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutQuart),
    );
  }

  void _onAddBoard() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                      child: Icon(LucideIcons.layout, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'New Column',
                      style: TextStyle(
                        color: AppTheme.onBackground.withValues(alpha: 0.8),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. In Review',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                        foregroundColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      child: const Text('Cancel')
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          final newBoard = Board(
                            id: nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
                            title: nameController.text.trim(),
                            workspaceId: 'global',
                            order: _boards.length,
                          );
                          setState(() {
                            _boards = [..._boards, newBoard];
                          });
                  await _saveBoards();
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutQuart),
    );
  }

  Widget _buildMetricsPill(List<ZenBlock> blocks) {
    int total = blocks.length;
    int done = blocks.where((b) => (b.metadata['status'] ?? 'todo') == 'done').length;
    int inProgress = blocks.where((b) => b.metadata['status'] == 'inProgress').length;
    
    double progress = total == 0 ? 0 : (done / total);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$inProgress In Progress • $done Completed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.05);
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(projectBlocksProvider('global'));
    final kanbanWidth = ref.watch(preferencesProvider.select((p) => p.kanbanColumnWidth));

    return ZenStudioPageShell(
      title: 'TASKS',
      child: blocksAsync.when(
        data: (blocks) {
          final todoBlocks = blocks.where((b) => b.type == 'todo').toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZenEditorialHeader(
                label: 'Strategic Space',
                title: 'Global Tasks',
                subtitle: 'Orchestrate your progress across all sanctuaries.',
                progressIndicator: _buildMetricsPill(todoBlocks),
              ),
              Expanded(
                child: _buildKanbanBoard(todoBlocks, columnWidth: kanbanWidth),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Could not load tasks.')),
      ),
    );
  }

  void _onDeleteBoard(String boardId, List<ZenBlock> boardBlocks) async {
    // 1. Move tasks to 'todo'
    for (final block in boardBlocks) {
      final updatedMetadata = Map<String, dynamic>.from(block.metadata);
      updatedMetadata['status'] = 'todo';
      final updatedBlock = block.copyWith(metadata: updatedMetadata);
      await ref.read(blockServiceProvider).updateBlock(updatedBlock);
    }

    // 2. Remove board
    setState(() {
      _boards.removeWhere((b) => b.id == boardId);
    });
    await _saveBoards();
  }

  void _onEditTask(ZenBlock block) async {
    final nameController = TextEditingController(text: block.content);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                      child: Icon(LucideIcons.pencil, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Edit Task',
                      style: TextStyle(
                        color: AppTheme.onBackground.withValues(alpha: 0.8),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  cursorColor: AppTheme.primary,
                  decoration: InputDecoration(
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
        onSubmitted: (value) async {
          if (value.trim().isNotEmpty) {
            final updatedBlock = block.copyWith(content: value.trim());
            await ref.read(blockServiceProvider).updateBlock(updatedBlock);
            if (context.mounted) Navigator.pop(dialogContext);
          }
        },
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            child: const Text('Cancel')
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final updatedBlock = block.copyWith(content: nameController.text.trim());
                await ref.read(blockServiceProvider).updateBlock(updatedBlock);
                if (context.mounted) Navigator.pop(dialogContext);
              }
            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutQuart),
    );
  }

  Widget _buildKanbanBoard(List<ZenBlock> blocks, {double columnWidth = 320}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Scrollbar(
            controller: _kanbanScrollController,
          thickness: 6.0,
          radius: const Radius.circular(8.0),
          thumbVisibility: true,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
            controller: _kanbanScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
            children: _boards.asMap().entries.map((entry) {
              final index = entry.key;
              final board = entry.value;
              final boardBlocks = blocks.where((b) => (b.metadata['status'] ?? 'todo') == board.id).toList();
              final boardTasks = boardBlocks.map(_mapToTask).toList();
              final isDefault = const ['todo', 'inProgress', 'done'].contains(board.id);

              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spaceLarge),
                child: SizedBox(
                  width: columnWidth,
                  child: KanbanColumn(
                    board: board,
                    tasks: boardTasks,
                    onAddTask: () => _onAddTask(board.id),
                    onBoardDeleted: isDefault ? null : () => _onDeleteBoard(board.id, boardBlocks),
                    onTaskTap: (task) {
                      final block = boardBlocks.firstWhere((b) => b.id == task.id);
                      _onTaskToggle(block);
                    },
                    onTaskMoved: (task) {
                      final block = boardBlocks.firstWhere(
                        (b) => b.id == task.id, 
                        orElse: () => blocks.firstWhere((b) => b.id == task.id)
                      );
                      _onTaskMoved(block, board.id);
                    },
                    onTaskReordered: (task, oldIdx, newIdx) {
                      // Handled by fractional indexing usually
                    },
                    onTaskDeleted: (task) async {
                      final block = boardBlocks.firstWhere((b) => b.id == task.id);
                      await ref.read(blockServiceProvider).deleteBlock(block);
                    },
                    onTaskEdited: (task) {
                      final block = boardBlocks.firstWhere((b) => b.id == task.id);
                      _onEditTask(block);
                    },
                    accentColor: AppTheme.primary,
                  ),
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1);
            }).cast<Widget>().toList()
              ..add(
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spaceLarge),
                  child: InkWell(
                    onTap: _onAddBoard,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.plus, color: AppTheme.primary, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
          ),
        ),
      ),
      ),
    ),
    ),
    );
  }
}
