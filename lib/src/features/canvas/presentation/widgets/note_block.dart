import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class NoteBlockWidget extends StatefulWidget {
  final String content;
  final bool isHeading;
  final Function(String)? onChanged;
  final VoidCallback? onDelete;
  final bool autofocus;

  /// Called when Enter (without Shift) is pressed — Notion-style "create a
  /// new block below and move on", instead of just inserting a newline.
  /// Shift+Enter still inserts a literal newline within this block.
  final VoidCallback? onEnterPressed;

  const NoteBlockWidget({
    super.key,
    required this.content,
    this.isHeading = false,
    this.onChanged,
    this.onDelete,
    this.autofocus = false,
    this.onEnterPressed,
  });

  @override
  State<NoteBlockWidget> createState() => _NoteBlockWidgetState();
}

class _NoteBlockWidgetState extends State<NoteBlockWidget> {
  late TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.onEnterPressed == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter || HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    widget.onEnterPressed!();
    return KeyEventResult.handled;
  }

  @override
  void didUpdateWidget(NoteBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content && _controller.text != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              ? scheme.surfaceContainerLowest.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _isHovered
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
                maxLines: null,
                style: widget.isHeading
                    ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        )
                    : Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.85),
                          height: 1.65,
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
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: scheme.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
