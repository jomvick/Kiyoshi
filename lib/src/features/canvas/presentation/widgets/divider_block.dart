import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class DividerBlockWidget extends StatelessWidget {
  final VoidCallback? onDelete;

  const DividerBlockWidget({super.key, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return _BlockShell(
      onDelete: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
        child: Divider(
          color: AppTheme.onBackground.withValues(alpha: 0.1),
          thickness: 1,
        ),
      ),
    );
  }
}

class _BlockShell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDelete;

  const _BlockShell({required this.child, this.onDelete});

  @override
  State<_BlockShell> createState() => _BlockShellState();
}

class _BlockShellState extends State<_BlockShell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _isHovered
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: widget.child),
            if (_isHovered && widget.onDelete != null)
              GestureDetector(
                onTap: widget.onDelete,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppTheme.error.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
