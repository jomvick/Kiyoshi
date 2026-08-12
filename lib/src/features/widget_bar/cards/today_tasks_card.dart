import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Second swipeable card: today's tasks.
///
/// Shows tasks that are due today (or overdue), and lets you toggle a task as
/// done directly from the widget — the canonical "glance & act" desktop-widget
/// interaction.
class TodayTasksCard extends ConsumerStatefulWidget {
  const TodayTasksCard({super.key});

  @override
  ConsumerState<TodayTasksCard> createState() => _TodayTasksCardState();
}

class _TodayTasksCardState extends ConsumerState<TodayTasksCard> {
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _parseDue(ZenBlock b) {
    final raw = b.metadata['dueDate'];
    if (raw is String && raw.isNotEmpty) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return DateTime.now();
  }

  bool _isDueToday(ZenBlock b, DateTime today) {
    final raw = b.metadata['dueDate'];
    if (raw is String && raw.isNotEmpty) {
      try {
        return _normalize(DateTime.parse(raw)) == _normalize(today);
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<void> _toggle(ZenBlock block) async {
    final status = block.metadata['status'] ?? 'todo';
    final newStatus = status == 'done' ? 'todo' : 'done';
    final meta = Map<String, dynamic>.from(block.metadata)..['status'] = newStatus;
    if (newStatus == 'done') {
      meta['completedAt'] = DateTime.now().toIso8601String();
    } else {
      meta.remove('completedAt');
    }
    await ref.read(blockServiceProvider).updateBlock(block.copyWith(metadata: meta));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final blocks = ref.watch(projectBlocksProvider('global')).value ?? const <ZenBlock>[];

    final tasks = blocks.where((b) => b.type == 'todo').toList();
    final dueShortly = tasks
        .where((b) {
      if ((b.metadata['status'] ?? 'todo') == 'done') return false;
      if (_isDueToday(b, today)) return true;
      final due = _parseDue(b);
      return due.isBefore(today.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => _parseDue(a).compareTo(_parseDue(b)));

    final doneToday = tasks.where((b) {
      if (b.metadata['status'] != 'done') return false;
      final raw = b.metadata['completedAt'];
      if (raw is! String) return false;
      final completedAt = DateTime.tryParse(raw);
      return completedAt != null && _normalize(completedAt) == _normalize(today);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today · ${DateFormat('EEEE d MMMM').format(today)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (dueShortly.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${dueShortly.length}',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? _emptyState(scheme, 'No tasks yet', LucideIcons.checkSquare)
                : dueShortly.isEmpty
                    ? _emptyState(scheme, 'All caught up 🎉', LucideIcons.checkCircle2)
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: dueShortly.length > 12 ? 12 : dueShortly.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (ctx, i) {
                          final b = dueShortly[i];
                          return _TaskTile(
                            block: b,
                            due: _parseDue(b),
                            today: today,
                            onTap: () => _toggle(b),
                          );
                        },
                      ),
          ),
          if (doneToday.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${doneToday.length} done today',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary.withValues(alpha: 0.7),
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: scheme.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final ZenBlock block;
  final DateTime due;
  final DateTime today;
  final VoidCallback onTap;

  const _TaskTile({
    required this.block,
    required this.due,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = (block.metadata['status'] ?? 'todo') == 'done';
    final isOverdue =
        due.isBefore(DateTime(today.year, today.month, today.day)) &&
            !isDone;
    final priority = block.metadata['priority'] as int? ?? 2;

    Color priorityColor = Colors.blueGrey;
    if (priority == 1) priorityColor = Colors.redAccent;
    if (priority == 3) priorityColor = const Color(0xFF5E5F5F);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue
                  ? scheme.error.withValues(alpha: 0.35)
                  : scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: isDone
                        ? scheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      width: 1.8,
                    ),
                  ),
                  child: isDone
                      ? Icon(LucideIcons.check, size: 11, color: scheme.onPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDone
                                ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                                : scheme.onSurface.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                    ),
                    if (block.metadata['dueDate'] != null)
                      Text(
                        isOverdue
                            ? 'Overdue'
                            : DateFormat('HH:mm').format(due),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isOverdue
                                  ? scheme.error.withValues(alpha: 0.85)
                                  : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}