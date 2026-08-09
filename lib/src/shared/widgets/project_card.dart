import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int index;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          child: ZenGlassCard(
            radius: 22,
            opacity: _isHovering ? 0.65 : 0.5,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title header section ──
                _buildTitleHeader(context, scheme),
                // ── Body section: description ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Expanded(
                          child: Text(
                            widget.project.description.isNotEmpty
                                ? widget.project.description
                                : 'No description',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: widget.project.description.isNotEmpty
                                      ? scheme.onSurface.withValues(alpha: 0.75)
                                      : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  height: 1.5,
                                  fontSize: 12,
                                  fontStyle: widget.project.description.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Footer: deadline + date
                        _buildFooter(context, scheme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 30 * widget.index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildTitleHeader(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        border: Border(
          bottom: BorderSide(
            color: scheme.primary.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Project icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: widget.project.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.folder,
              size: 16,
              color: widget.project.statusColor,
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Text(
              widget.project.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
            ),
          ),
          // Hover actions
          if (_isHovering) ...[
            _buildSmallAction(
              icon: LucideIcons.pencil,
              onTap: widget.onEdit,
              scheme: scheme,
            ),
            const SizedBox(width: 4),
            _buildSmallAction(
              icon: LucideIcons.trash2,
              onTap: widget.onDelete,
              danger: true,
              scheme: scheme,
            ),
          ] else ...[
            // Status dot indicator
            _buildStatusDot(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.project.statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.project.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.project.status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: widget.project.statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAction({
    required IconData icon,
    required ColorScheme scheme,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: danger
                ? scheme.error.withValues(alpha: 0.1)
                : scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 13,
            color: danger
                ? scheme.error.withValues(alpha: 0.8)
                : scheme.primary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme scheme) {
    return Row(
      children: [
        if (widget.project.deadline != null) ...[
          _buildDeadlineChip(scheme),
          const Spacer(),
        ] else
          const Spacer(),
        Text(
          _formatRelativeDate(widget.project.updatedAt),
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineChip(ColorScheme scheme) {
    final isOverdue = widget.project.isOverdue;
    final dateColor = isOverdue ? scheme.error : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: dateColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar, size: 11, color: dateColor),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d').format(widget.project.deadline!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: dateColor,
            ),
          ),
        ],
      ),
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
