import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Fourth swipeable card: a compact 3-column kanban summary.
///
/// Use the widget bar to read work-in-progress at a glance and to advance a
/// task from To Do → In Progress → Done by tapping it.
class MiniKanbanCard extends ConsumerStatefulWidget {
  const MiniKanbanCard({super.key});

  @override
  ConsumerState<MiniKanbanCard> createState() => _MiniKanbanCardState();
}

class _MiniKanbanCardState extends ConsumerState<MiniKanbanCard> {
  static const _columns = ['todo', 'inProgress', 'done'];
  static const _titles = {'todo': 'To Do', 'inProgress': 'WIP', 'done': 'Done'};

  static const _icons = {
    'todo': LucideIcons.circle,
    'inProgress': LucideIcons.clock,
    'done': LucideIcons.checkCircle2,
  };

  Future<void> _advance(ZenBlock block) async {
    final current = block.metadata['status'] ?? 'todo';
    const order = ['todo', 'inProgress', 'done'];
    final idx = order.indexOf(current);
    if (idx >= order.length - 1) return;
    final next = order[idx + 1];
    final meta = Map<String, dynamic>.from(block.metadata)..['status'] = next;
    if (next == 'done') {
      meta['completedAt'] = DateTime.now().toIso8601String();
    }
    await ref.read(blockServiceProvider).updateBlock(block.copyWith(metadata: meta));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blocks = ref.watch(projectBlocksProvider('global')).value ?? const <ZenBlock>[];

    final tasks = blocks.where((b) => b.type == 'todo').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MINI KANBAN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _columns.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildColumn(scheme, _columns[i], tasks),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(ColorScheme scheme, String status, List<ZenBlock> tasks) {
    final columnTasks = tasks
        .where((b) => (b.metadata['status'] ?? 'todo') == status)
        .toList()
      ..sort((a, b) => b.position.compareTo(a.position));

    final isDone = status == 'done';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _icons[status],
                size: 13,
                color: isDone
                    ? const Color(0xFF34C759)
                    : status == 'inProgress'
                        ? Colors.amber
                        : scheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _titles[status]!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${columnTasks.length}',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: columnTasks.isEmpty
                ? Center(
                    child: Text(
                      '—',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: columnTasks.length > 8 ? 8 : columnTasks.length,
                    itemBuilder: (ctx, i) {
                      final b = columnTasks[i];
                      return GestureDetector(
                        onTap: () => _advance(b),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? scheme.primary.withValues(alpha: 0.08)
                                  : scheme.surfaceContainerLowest
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              b.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: b.metadata['status'] == 'done'
                                        ? scheme.onSurfaceVariant
                                            .withValues(alpha: 0.5)
                                        : scheme.onSurface.withValues(alpha: 0.9),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                    decoration:
                                        b.metadata['status'] == 'done'
                                            ? TextDecoration.lineThrough
                                            : null,
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}