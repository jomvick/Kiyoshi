import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class HeadingBlockWidget extends StatefulWidget {
  final String content;
  final Function(String)? onChanged;
  final VoidCallback? onDelete;

  const HeadingBlockWidget({
    super.key,
    required this.content,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<HeadingBlockWidget> createState() => _HeadingBlockWidgetState();
}

class _HeadingBlockWidgetState extends State<HeadingBlockWidget> {
  late TextEditingController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(HeadingBlockWidget oldWidget) {
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
        duration: const Duration(milliseconds: 150),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                maxLines: null,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onBackground,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
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
                  padding: const EdgeInsets.only(left: 8, top: 12),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
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
