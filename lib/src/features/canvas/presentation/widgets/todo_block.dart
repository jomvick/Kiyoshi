import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class TodoBlockWidget extends StatefulWidget {
  final String content;
  final bool isChecked;
  final Function(bool?) onChanged;
  final Function(String)? onContentChanged;
  final VoidCallback? onDelete;

  const TodoBlockWidget({
    super.key,
    required this.content,
    required this.isChecked,
    required this.onChanged,
    this.onContentChanged,
    this.onDelete,
  });

  @override
  State<TodoBlockWidget> createState() => _TodoBlockWidgetState();
}

class _TodoBlockWidgetState extends State<TodoBlockWidget> {
  late TextEditingController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(TodoBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content && _controller.text != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppTheme.animFastest,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _isHovered
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: widget.isChecked,
                onChanged: widget.onChanged,
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(
                  color: AppTheme.onBackground.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onContentChanged,
                maxLines: null,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: widget.isChecked
                          ? AppTheme.onBackground.withValues(alpha: 0.4)
                          : AppTheme.onBackground.withValues(alpha: 0.85),
                      decoration: widget.isChecked ? TextDecoration.lineThrough : null,
                      height: 1.5,
                    ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            if (_isHovered && widget.onDelete != null)
              GestureDetector(
                onTap: widget.onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppTheme.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
