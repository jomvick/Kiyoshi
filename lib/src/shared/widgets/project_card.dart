import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: _isHovering
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: _isHovering
                  ? AppTheme.primary.withValues(alpha: 0.25)
                  : AppTheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovering ? 0.06 : 0.03),
                blurRadius: _isHovering ? 16 : 8,
                offset: Offset(0, _isHovering ? 6 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildTitle(),
              if (widget.project.description.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSmall),
                _buildDescription(),
              ],
              const SizedBox(height: AppTheme.spaceMedium),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildStatusBadge(),
        const Spacer(),
        if (_isHovering) _buildActions(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.project.statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: widget.project.statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
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
          const SizedBox(width: 6),
          Text(
            widget.project.status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.project.statusColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onEdit != null)
          _buildIconButton(icon: LucideIcons.pencil, onTap: widget.onEdit!),
        const SizedBox(width: AppTheme.spaceXSmall),
        if (widget.onDelete != null)
          _buildIconButton(icon: LucideIcons.trash2, onTap: widget.onDelete!),
      ],
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 14,
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.project.title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.onBackground,
        letterSpacing: -0.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.project.description,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (widget.project.deadline != null) ...[
          _buildDeadlineChip(),
          const SizedBox(width: AppTheme.spaceSmall),
        ],
        const Spacer(),
        _buildDateInfo(),
      ],
    );
  }

  Widget _buildDeadlineChip() {
    final isOverdue = widget.project.isOverdue;
    final dateColor = isOverdue ? AppTheme.error : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dateColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: dateColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.calendar,
            size: 12,
            color: dateColor,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d, yyyy').format(widget.project.deadline!),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dateColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo() {
    return Text(
      'Updated ${_formatRelativeDate(widget.project.updatedAt)}',
      style: TextStyle(
        fontSize: 11,
        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
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