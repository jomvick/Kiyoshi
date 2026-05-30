import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/task.dart';
import 'package:kiyoshi/src/shared/widgets/prismatic_painter.dart';
import 'package:intl/intl.dart';

/// Zen Kanban Card - Apple-Inspired Modern Design
///
/// Design Principles:
/// - Clarity: Strong visual hierarchy with generous whitespace
/// - Depth: Refined glassmorphism with layered shadows
/// - Motion: Purposeful micro-interactions (350ms spring curves)
/// - Typography: Editorial-style text with tight letter-spacing
/// - Details: Pill-shaped priority badges, avatar circles, clean icons
class KanbanCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Color? accentColor;

  const KanbanCard({
    super.key,
    required this.task,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.accentColor,
  });

  @override
  State<KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<KanbanCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isFocused = false;
  Offset _mousePosition = Offset.zero;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster, snappier
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get isDone => widget.task.status == TaskStatus.done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = _isOverdue();

    return Focus(
          focusNode: _focusNode,
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
                if (widget.onTap != null) widget.onTap!();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.delete || event.logicalKey == LogicalKeyboardKey.backspace) {
                if (widget.onDelete != null) widget.onDelete!();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            onHover: (event) => setState(() => _mousePosition = event.localPosition),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              onLongPress: _showContextMenu,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final isDone = widget.task.status == TaskStatus.done;
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedOpacity(
                      duration: AppTheme.animSlow,
                      opacity: isDone ? 0.45 : 1.0,
                      child: _buildFrostedCard(context, theme, isOverdue),
                    ),
                  );
                },
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppTheme.animMedium, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppTheme.animSlow,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildFrostedCard(
    BuildContext context,
    ThemeData theme,
    bool isOverdue,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: _isFocused
              ? AppTheme.primary.withValues(alpha: 0.8)
              : (widget.task.priority == TaskPriority.high
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : AppTheme.outline.withValues(alpha: 0.25)),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: _isHovering ? 0.15 : 0.08),
            blurRadius: _isHovering ? 20 : 10,
            offset: Offset(0, _isHovering ? 8 : 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Prismatic Border (for high priority or active state) - RepaintBoundary for isolation
          if (widget.task.priority == TaskPriority.high || _isHovering)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: PrismaticPainter(
                    mousePosition: _mousePosition,
                    radius: AppTheme.radiusLarge,
                    opacity: _isHovering ? 0.4 : 0.2,
                  ),
                ),
              ),
            ),
          
          // The Glass Surface
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 1),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: AppTheme.blurStrength, sigmaY: AppTheme.blurStrength),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceLarge),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDone ? 0.5 : 0.8),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDone ? 0.5 : 0.7),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ZenCheckbox(
                            isDone: isDone,
                            onChanged: (val) {
                              if (widget.onTap != null) widget.onTap!();
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onBackground,
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                                decorationColor:
                                    AppTheme.primary.withValues(alpha: 0.3),
                                letterSpacing: -0.4,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceSmall),
                        Text(
                          widget.task.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      if (widget.task.progress != null) ...[
                        const SizedBox(height: AppTheme.spaceLarge),
                        _buildProgressSection(theme),
                      ],
                      
                      const SizedBox(height: AppTheme.spaceLarge),
                      _buildFooter(theme, isOverdue),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onHover(bool isHovering) {
    setState(() => _isHovering = isHovering);
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }


  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Priority pill badge
        _buildPriorityBadge(theme),

        const Spacer(),

        // Action buttons (visible on hover)
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildPriorityBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.task.priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: widget.task.priorityColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Priority dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.task.priorityColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.task.priorityColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.task.priorityLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: widget.task.priorityColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return AnimatedOpacity(
      opacity: _isHovering ? 1.0 : 0.0,
      duration: AppTheme.animFast,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Theme(
            data: theme.copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit' && widget.onEdit != null) widget.onEdit!();
                if (value == 'delete' && widget.onDelete != null) widget.onDelete!();
              },
              icon: Icon(
                LucideIcons.moreHorizontal,
                size: 16,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              offset: const Offset(0, 30),
              itemBuilder: (context) => [
                if (widget.onEdit != null)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.pencil, size: 14, color: AppTheme.onBackground.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        Text('Edit Task', style: TextStyle(fontSize: 13, color: AppTheme.onBackground.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                if (widget.onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isOverdue) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Due date with calendar icon
        if (widget.task.dueDate != null) ...[
          _buildDueDateChip(theme, isOverdue),
        ],

        // Tags (show first 2-3)
        if (widget.task.tags.isNotEmpty) ...[
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(child: _buildTags(theme)),
        ],

        if (widget.task.progress == null &&
            widget.task.timeIndicator != null &&
            widget.task.timeIndicator!.isNotEmpty) ...[
          if (widget.task.tags.isNotEmpty) const SizedBox(width: AppTheme.spaceSmall),
          _buildTimeIndicatorChip(theme),
        ],

        if (widget.task.tags.isEmpty) const Spacer(),

        // Status indicator dot
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    final progress = widget.task.progress!.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PROGRESS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.5),
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$progress%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: Container(
            height: 4,
            width: double.infinity,
            color: AppTheme.primary.withValues(alpha: 0.1),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeIndicatorChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF34C98F).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        widget.task.timeIndicator!,
        style: theme.textTheme.labelSmall?.copyWith(
          color: const Color(0xFF14895E),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDueDateChip(ThemeData theme, bool isOverdue) {
    final dateColor = isOverdue
        ? AppTheme.error.withValues(alpha: 0.8)
        : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.mintTeal.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar, size: 13, color: dateColor),
          const SizedBox(width: 6),
          Text(
            _formatDate(widget.task.dueDate!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: dateColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(ThemeData theme) {
    final tagsToShow = widget.task.tags.take(2).toList();
    final hasMore = widget.task.tags.length > 2;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...tagsToShow.map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Text(
              '#${tag.length > 8 ? '${tag.substring(0, 8)}…' : tag}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Text(
              '+${widget.task.tags.length - 2}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    Color indicatorColor;
    switch (widget.task.status) {
      case TaskStatus.todo:
        indicatorColor = AppTheme.onSurfaceVariant.withValues(alpha: 0.3);
      case TaskStatus.inProgress:
        indicatorColor = AppTheme.primary.withValues(alpha: 0.8);
      case TaskStatus.done:
        indicatorColor = const Color(0xFF34C759).withValues(alpha: 0.8);
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: indicatorColor.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  void _showContextMenu() {
    // Long press handler - can show context menu
    // Reserved for future implementation
  }

  bool _isOverdue() {
    if (widget.task.dueDate == null) return false;
    if (widget.task.status == TaskStatus.done) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      widget.task.dueDate!.year,
      widget.task.dueDate!.month,
      widget.task.dueDate!.day,
    );
    return due.isBefore(today);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }
}

/// A tactile, satisfying checkbox that pops when clicked
class _ZenCheckbox extends StatefulWidget {
  final bool isDone;
  final ValueChanged<bool> onChanged;

  const _ZenCheckbox({required this.isDone, required this.onChanged});

  @override
  State<_ZenCheckbox> createState() => _ZenCheckboxState();
}

class _ZenCheckboxState extends State<_ZenCheckbox> {
  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.isDone;
  }

  @override
  void didUpdateWidget(covariant _ZenCheckbox oldWidget) {
    if (widget.isDone != oldWidget.isDone) {
      _checked = widget.isDone;
    }
    super.didUpdateWidget(oldWidget);
  }

  void _handleTap() {
    setState(() => _checked = !_checked);
    widget.onChanged(_checked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _checked
              ? const Color(0xFF34C759)
              : AppTheme.surfaceContainerLowest,
          border: Border.all(
            color: _checked ? const Color(0xFF34C759) : AppTheme.outline,
            width: _checked ? 0 : 1.5,
          ),
          boxShadow: _checked
              ? [
                  BoxShadow(
                    color: const Color(0xFF34C759).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: _checked
            ? const Icon(
                LucideIcons.check,
                size: 12,
                color: Colors.white,
              )
                .animate()
                .scale(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                )
            : null,
      ),
    );
  }
}
