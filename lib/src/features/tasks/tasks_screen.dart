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
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskViewMode { list, board }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final ScrollController _kanbanScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  TaskViewMode _viewMode = TaskViewMode.list;
  String _statusFilter = 'all'; // 'all', 'todo', 'inProgress', 'done'
  String _searchQuery = '';

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
    _searchController.dispose();
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

  Future<void> _onTaskMoved(ZenBlock block, String newStatus) async {
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

  void _showTaskModal({ZenBlock? blockToEdit, String? defaultStatus}) {
    final scheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController(text: blockToEdit?.content ?? '');
    final descController = TextEditingController(text: blockToEdit?.metadata['description'] ?? '');
    String selectedStatus = blockToEdit?.metadata['status'] ?? defaultStatus ?? 'todo';
    int selectedPriority = blockToEdit?.metadata['priority'] ?? 2; // 1: High, 2: Medium, 3: Low

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ZenGlassCard(
            radius: 28,
            opacity: 0.9,
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              blockToEdit != null ? LucideIcons.pencil : LucideIcons.plusCircle,
                              color: scheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            blockToEdit != null ? 'Edit Task' : 'New Task',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => Navigator.pop(dialogContext),
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title Input
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Task title…',
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: scheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Description Input
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Description or notes (optional)…',
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: scheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Status selector chips
                  Text(
                    'STATUS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChipOption(
                        label: 'To Do',
                        icon: LucideIcons.circle,
                        isSelected: selectedStatus == 'todo',
                        onTap: () => setModalState(() => selectedStatus = 'todo'),
                      ),
                      const SizedBox(width: 8),
                      _buildChipOption(
                        label: 'In Progress',
                        icon: LucideIcons.clock,
                        isSelected: selectedStatus == 'inProgress',
                        onTap: () => setModalState(() => selectedStatus = 'inProgress'),
                      ),
                      const SizedBox(width: 8),
                      _buildChipOption(
                        label: 'Done',
                        icon: LucideIcons.checkCircle2,
                        isSelected: selectedStatus == 'done',
                        onTap: () => setModalState(() => selectedStatus = 'done'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Priority selector chips
                  Text(
                    'PRIORITY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityChip(
                        label: 'Low',
                        color: Colors.blueGrey,
                        isSelected: selectedPriority == 3,
                        onTap: () => setModalState(() => selectedPriority = 3),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityChip(
                        label: 'Medium',
                        color: Colors.amber,
                        isSelected: selectedPriority == 2,
                        onTap: () => setModalState(() => selectedPriority = 2),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityChip(
                        label: 'High',
                        color: Colors.redAccent,
                        isSelected: selectedPriority == 1,
                        onTap: () => setModalState(() => selectedPriority = 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final title = nameController.text.trim();
                          if (title.isEmpty) return;
                          final desc = descController.text.trim();

                          if (blockToEdit != null) {
                            final meta = Map<String, dynamic>.from(blockToEdit.metadata);
                            meta['status'] = selectedStatus;
                            meta['priority'] = selectedPriority;
                            if (desc.isNotEmpty) {
                              meta['description'] = desc;
                            } else {
                              meta.remove('description');
                            }
                            final updated = blockToEdit.copyWith(
                              content: title,
                              metadata: meta,
                            );
                            await ref.read(blockServiceProvider).updateBlock(updated);
                          } else {
                            final parsed = ParsedBlock(
                              type: 'todo',
                              content: title,
                              metadata: {
                                'status': selectedStatus,
                                'priority': selectedPriority,
                                if (desc.isNotEmpty) 'description': desc,
                              },
                            );
                            await ref.read(blockServiceProvider).addBlock('global', parsed);
                          }
                          if (context.mounted) Navigator.pop(dialogContext);
                        },
                        icon: Icon(LucideIcons.check, size: 16, color: scheme.onPrimary),
                        label: Text(
                          blockToEdit != null ? 'Save Changes' : 'Create Task',
                          style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.15)
              : scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddBoard() {
    final scheme = Theme.of(context).colorScheme;
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
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.layout, color: scheme.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'New Column',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.9),
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
                    fillColor: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
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
                        foregroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
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
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
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

  Widget _buildMetricsBanner(List<ZenBlock> blocks) {
    final scheme = Theme.of(context).colorScheme;
    final int total = blocks.length;
    final int done = blocks.where((b) => (b.metadata['status'] ?? 'todo') == 'done').length;
    final int inProgress = blocks.where((b) => b.metadata['status'] == 'inProgress').length;
    final int todo = blocks.where((b) => (b.metadata['status'] ?? 'todo') == 'todo').length;
    
    final double progress = total == 0 ? 0 : (done / total);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3.5,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34C759)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}% completed',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$todo To Do • $inProgress In Progress • $done Done',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05);
  }

  Widget _buildToolbar(List<ZenBlock> allBlocks) {
    final scheme = Theme.of(context).colorScheme;
    final int total = allBlocks.length;
    final int todoCount = allBlocks.where((b) => (b.metadata['status'] ?? 'todo') == 'todo').length;
    final int inProgressCount = allBlocks.where((b) => b.metadata['status'] == 'inProgress').length;
    final int doneCount = allBlocks.where((b) => b.metadata['status'] == 'done').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // View mode switch toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    _buildViewModeButton(
                      mode: TaskViewMode.list,
                      icon: LucideIcons.list,
                      label: 'List',
                    ),
                    const SizedBox(width: 4),
                    _buildViewModeButton(
                      mode: TaskViewMode.board,
                      icon: LucideIcons.kanban,
                      label: 'Board',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Search field
              Expanded(
                child: ZenGlassCard(
                  radius: 16,
                  opacity: 0.5,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    children: [
                      Icon(LucideIcons.search,
                          size: 16,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'Search tasks…',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(LucideIcons.x,
                              size: 14,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // New Task Button
              GestureDetector(
                onTap: () => _showTaskModal(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, size: 16, color: scheme.onPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'New Task',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Tabs Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab('all', 'All Tasks', total),
                const SizedBox(width: 8),
                _buildFilterTab('todo', 'To Do', todoCount),
                const SizedBox(width: 8),
                _buildFilterTab('inProgress', 'In Progress', inProgressCount),
                const SizedBox(width: 8),
                _buildFilterTab('done', 'Completed', doneCount),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildViewModeButton({
    required TaskViewMode mode,
    required IconData icon,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bool isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String statusKey, String label, int count) {
    final scheme = Theme.of(context).colorScheme;
    final bool isSelected = _statusFilter == statusKey;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = statusKey),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

          // Filter tasks based on search & status filter
          final filteredBlocks = todoBlocks.where((b) {
            final status = b.metadata['status'] ?? 'todo';
            final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
            final matchesSearch = _searchQuery.isEmpty ||
                b.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (b.metadata['description'] != null &&
                    (b.metadata['description'] as String).toLowerCase().contains(_searchQuery.toLowerCase()));
            return matchesStatus && matchesSearch;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZenEditorialHeader(
                label: 'Strategic Space',
                title: 'Global Tasks',
                subtitle: 'Orchestrate your progress across all sanctuaries.',
                progressIndicator: _buildMetricsBanner(todoBlocks),
              ),
              _buildToolbar(todoBlocks),
              const SizedBox(height: 16),
              Expanded(
                child: _viewMode == TaskViewMode.list
                    ? _buildTaskListView(filteredBlocks)
                    : _buildKanbanBoard(todoBlocks, columnWidth: kanbanWidth),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Could not load tasks.')),
      ),
    );
  }

  Widget _buildTaskListView(List<ZenBlock> blocks) {
    final scheme = Theme.of(context).colorScheme;
    if (blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.checkSquare,
                size: 52, color: scheme.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Click + New Task to capture your next objective.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: blocks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _buildTaskRow(blocks[i], i),
      ),
    );
  }

  Widget _buildTaskRow(ZenBlock block, int index) {
    final scheme = Theme.of(context).colorScheme;
    final status = block.metadata['status'] ?? 'todo';
    final isDone = status == 'done';
    final priorityVal = block.metadata['priority'] as int? ?? 2;
    final description = block.metadata['description'] as String?;

    Color priorityColor;
    String priorityText;
    if (priorityVal == 1) {
      priorityColor = Colors.redAccent;
      priorityText = 'High';
    } else if (priorityVal == 2) {
      priorityColor = Colors.amber;
      priorityText = 'Medium';
    } else {
      priorityColor = Colors.blueGrey;
      priorityText = 'Low';
    }

    return ZenGlassCard(
      radius: 18,
      opacity: isDone ? 0.3 : 0.5,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Checkbox toggle button
          GestureDetector(
            onTap: () => _onTaskToggle(block),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone
                      ? scheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? Icon(LucideIcons.check, size: 14, color: scheme.onPrimary)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDone
                            ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                            : scheme.onSurface.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Priority badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  priorityText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Edit action
          _buildIconButton(
            LucideIcons.pencil,
            () => _showTaskModal(blockToEdit: block),
          ),
          const SizedBox(width: 6),
          // Delete action
          _buildIconButton(
            LucideIcons.trash2,
            () async {
              await ref.read(blockServiceProvider).deleteBlock(block);
            },
            danger: true,
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 25 * index)).fadeIn(duration: 250.ms);
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {bool danger = false}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: danger
                ? scheme.error.withValues(alpha: 0.1)
                : scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: danger
                ? scheme.error.withValues(alpha: 0.8)
                : scheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Future<void> _onDeleteBoard(String boardId, List<ZenBlock> boardBlocks) async {
    // Move tasks to 'todo'
    for (final block in boardBlocks) {
      final updatedMetadata = Map<String, dynamic>.from(block.metadata);
      updatedMetadata['status'] = 'todo';
      final updatedBlock = block.copyWith(metadata: updatedMetadata);
      await ref.read(blockServiceProvider).updateBlock(updatedBlock);
    }

    // Remove board
    setState(() {
      _boards.removeWhere((b) => b.id == boardId);
    });
    await _saveBoards();
  }

  Widget _buildKanbanBoard(List<ZenBlock> blocks, {double columnWidth = 320}) {
    final scheme = Theme.of(context).colorScheme;
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
                    final boardBlocks = blocks.where((b) {
                      final status = b.metadata['status'] ?? 'todo';
                      final matchesSearch = _searchQuery.isEmpty ||
                          b.content.toLowerCase().contains(_searchQuery.toLowerCase());
                      return status == board.id && matchesSearch;
                    }).toList();

                    final boardTasks = boardBlocks.map(_mapToTask).toList();
                    final isDefault = const ['todo', 'inProgress', 'done'].contains(board.id);

                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spaceLarge),
                      child: SizedBox(
                        width: columnWidth,
                        child: KanbanColumn(
                          board: board,
                          tasks: boardTasks,
                          onAddTask: () => _showTaskModal(defaultStatus: board.id),
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
                          onTaskReordered: (task, oldIdx, newIdx) {},
                          onTaskDeleted: (task) async {
                            final block = boardBlocks.firstWhere((b) => b.id == task.id);
                            await ref.read(blockServiceProvider).deleteBlock(block);
                          },
                          onTaskEdited: (task) {
                            final block = boardBlocks.firstWhere((b) => b.id == task.id);
                            _showTaskModal(blockToEdit: block);
                          },
                          accentColor: scheme.primary,
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
                              color: scheme.surfaceContainerLowest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.15),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(LucideIcons.plus, color: scheme.primary, size: 24),
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
