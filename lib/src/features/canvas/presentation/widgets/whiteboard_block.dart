import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

/// A single shape on a whiteboard block. Kept intentionally simple (v1
/// scope): rectangle, ellipse, arrow, free text, and sticky note.
class WhiteboardShape {
  final String id;
  final String kind; // 'rect' | 'ellipse' | 'arrow' | 'text' | 'sticky'
  double x;
  double y;
  double width;
  double height;
  int color;
  String text;

  WhiteboardShape({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.text = '',
  });

  factory WhiteboardShape.fromJson(Map<String, dynamic> json) {
    return WhiteboardShape(
      id: json['id'] as String,
      kind: json['kind'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      color: json['color'] as int,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'color': color,
        'text': text,
      };

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

enum _WhiteboardTool { select, rect, ellipse, arrow, text, sticky }

/// Freeform "Excalidraw-like" canvas block. Shapes are stored as JSON in
/// the parent [ZenBlock]'s metadata (`shapes`), so no new DB table is
/// needed for this v1. See docs/ROADMAP.md for the full plan.
class WhiteboardBlockWidget extends StatefulWidget {
  final Map<String, dynamic> metadata;
  final ValueChanged<Map<String, dynamic>> onMetadataChanged;
  final VoidCallback? onDelete;

  const WhiteboardBlockWidget({
    super.key,
    required this.metadata,
    required this.onMetadataChanged,
    this.onDelete,
  });

  @override
  State<WhiteboardBlockWidget> createState() => _WhiteboardBlockWidgetState();
}

class _WhiteboardBlockWidgetState extends State<WhiteboardBlockWidget> {
  static const List<Color> _palette = [
    Color(0xFF8FBDB8), // sage/teal — matches Kiyoshi's accent
    Color(0xFFE9C46A), // warm yellow, classic sticky-note color
    Color(0xFFF4A261), // coral
    Color(0xFF9B8AFB), // violet
    Color(0xFF6FA8DC), // sky blue
  ];

  late List<WhiteboardShape> _shapes;
  double _boardHeight = 420;
  _WhiteboardTool _tool = _WhiteboardTool.select;
  int _colorIndex = 0;
  String? _selectedId;
  WhiteboardShape? _draft;
  Offset? _dragAnchor;
  bool _isHoveringChrome = false;

  @override
  void initState() {
    super.initState();
    _loadFromMetadata();
  }

  void _loadFromMetadata() {
    final rawShapes = widget.metadata['shapes'] as List<dynamic>? ?? const [];
    _shapes = rawShapes
        .map((e) => WhiteboardShape.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _boardHeight = (widget.metadata['boardHeight'] as num?)?.toDouble() ?? 420;
  }

  void _persist() {
    widget.onMetadataChanged({
      ...widget.metadata,
      'shapes': _shapes.map((s) => s.toJson()).toList(),
      'boardHeight': _boardHeight,
    });
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_shapes.length}';

  Color get _activeColor => _palette[_colorIndex % _palette.length];

  WhiteboardShape? _shapeAt(Offset pos) {
    for (final shape in _shapes.reversed) {
      if (shape.rect.inflate(4).contains(pos)) return shape;
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;

    if (_tool == _WhiteboardTool.select) {
      final hit = _shapeAt(pos);
      setState(() {
        _selectedId = hit?.id;
        _dragAnchor = pos;
      });
      return;
    }

    setState(() {
      _draft = WhiteboardShape(
        id: _newId(),
        kind: _tool.name,
        x: pos.dx,
        y: pos.dy,
        width: 0,
        height: 0,
        color: _activeColor.toARGB32(),
      );
      _dragAnchor = pos;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_tool == _WhiteboardTool.select) {
      if (_selectedId == null || _dragAnchor == null) return;
      final delta = details.localPosition - _dragAnchor!;
      final idx = _shapes.indexWhere((s) => s.id == _selectedId);
      if (idx == -1) return;
      setState(() {
        _shapes[idx].x += delta.dx;
        _shapes[idx].y += delta.dy;
        _dragAnchor = details.localPosition;
      });
      return;
    }

    if (_draft == null || _dragAnchor == null) return;
    final pos = details.localPosition;
    final dx = pos.dx - _dragAnchor!.dx;
    final dy = pos.dy - _dragAnchor!.dy;
    setState(() {
      _draft!.x = dx < 0 ? pos.dx : _dragAnchor!.dx;
      _draft!.y = dy < 0 ? pos.dy : _dragAnchor!.dy;
      _draft!.width = dx.abs();
      _draft!.height = dy.abs();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragAnchor = null;

    if (_tool == _WhiteboardTool.select) {
      if (_selectedId != null) _persist();
      return;
    }

    final draft = _draft;
    if (draft == null) return;

    // Guard against a stray click producing an invisible sliver of a shape;
    // sticky notes and text get a sensible default size on a simple tap.
    if (draft.width < 6 || draft.height < 6) {
      if (draft.kind == 'sticky') {
        draft.width = 160;
        draft.height = 120;
      } else if (draft.kind == 'text') {
        draft.width = 160;
        draft.height = 32;
      } else {
        setState(() => _draft = null);
        return;
      }
    }

    setState(() {
      _shapes.add(draft);
      _selectedId = draft.id;
      _draft = null;
      _tool = _WhiteboardTool.select; // back to select after drawing (Excalidraw-style)
    });
    _persist();

    if (draft.kind == 'text' || draft.kind == 'sticky') {
      _editText(draft);
    }
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      _shapes.removeWhere((s) => s.id == _selectedId);
      _selectedId = null;
    });
    _persist();
  }

  Future<void> _editText(WhiteboardShape shape) async {
    final controller = TextEditingController(text: shape.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final idx = _shapes.indexWhere((s) => s.id == shape.id);
      if (idx != -1) _shapes[idx].text = result;
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringChrome = true),
      onExit: (_) => setState(() => _isHoveringChrome = false),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.5 : 0.4),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbar(scheme),
            SizedBox(
              height: _boardHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onDoubleTapDown: (details) {
                        final hit = _shapeAt(details.localPosition);
                        if (hit != null && (hit.kind == 'text' || hit.kind == 'sticky')) {
                          _editText(hit);
                        }
                      },
                      child: CustomPaint(
                        painter: _WhiteboardPainter(
                          shapes: _shapes,
                          draft: _draft,
                          selectedId: _selectedId,
                          isDark: isDark,
                          gridColor: scheme.outlineVariant.withValues(alpha: isDark ? 0.10 : 0.16),
                          textColor: scheme.onSurface,
                          selectionColor: scheme.primary,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: GestureDetector(
                        onPanUpdate: (d) => setState(
                          () => _boardHeight = (_boardHeight + d.delta.dy).clamp(240, 900),
                        ),
                        onPanEnd: (_) => _persist(),
                        child: Icon(
                          LucideIcons.gripHorizontal,
                          size: 16,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          _ToolButton(
            icon: LucideIcons.mousePointer2,
            isActive: _tool == _WhiteboardTool.select,
            onTap: () => setState(() => _tool = _WhiteboardTool.select),
            tooltip: 'Select',
          ),
          _ToolButton(
            icon: LucideIcons.square,
            isActive: _tool == _WhiteboardTool.rect,
            onTap: () => setState(() => _tool = _WhiteboardTool.rect),
            tooltip: 'Rectangle',
          ),
          _ToolButton(
            icon: LucideIcons.circle,
            isActive: _tool == _WhiteboardTool.ellipse,
            onTap: () => setState(() => _tool = _WhiteboardTool.ellipse),
            tooltip: 'Ellipse',
          ),
          _ToolButton(
            icon: LucideIcons.moveUpRight,
            isActive: _tool == _WhiteboardTool.arrow,
            onTap: () => setState(() => _tool = _WhiteboardTool.arrow),
            tooltip: 'Arrow',
          ),
          _ToolButton(
            icon: LucideIcons.type,
            isActive: _tool == _WhiteboardTool.text,
            onTap: () => setState(() => _tool = _WhiteboardTool.text),
            tooltip: 'Text',
          ),
          _ToolButton(
            icon: LucideIcons.stickyNote,
            isActive: _tool == _WhiteboardTool.sticky,
            onTap: () => setState(() => _tool = _WhiteboardTool.sticky),
            tooltip: 'Sticky note',
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: 20, color: scheme.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _colorIndex = (_colorIndex + 1) % _palette.length),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _activeColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const Spacer(),
          if (_selectedId != null)
            _ToolButton(
              icon: LucideIcons.trash2,
              isActive: false,
              onTap: _deleteSelected,
              tooltip: 'Delete shape',
              color: Colors.redAccent,
            ),
          if (widget.onDelete != null && _isHoveringChrome)
            _ToolButton(
              icon: LucideIcons.x,
              isActive: false,
              onTap: widget.onDelete,
              tooltip: 'Remove whiteboard block',
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? color;

  const _ToolButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color ?? (isActive ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  final List<WhiteboardShape> shapes;
  final WhiteboardShape? draft;
  final String? selectedId;
  final bool isDark;
  final Color gridColor;
  final Color textColor;
  final Color selectionColor;

  const _WhiteboardPainter({
    required this.shapes,
    required this.draft,
    required this.selectedId,
    required this.isDark,
    required this.gridColor,
    required this.textColor,
    required this.selectionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    for (final shape in shapes) {
      _paintShape(canvas, shape, isSelected: shape.id == selectedId);
    }
    if (draft != null) {
      _paintShape(canvas, draft!, isSelected: false, isDraft: true);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    const step = 24.0;
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintShape(Canvas canvas, WhiteboardShape shape, {required bool isSelected, bool isDraft = false}) {
    final color = Color(shape.color);
    final rect = shape.rect;

    switch (shape.kind) {
      case 'rect':
        final fill = Paint()..color = color.withValues(alpha: isDraft ? 0.15 : 0.18);
        final border = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, fill);
        canvas.drawRRect(rrect, border);
        break;

      case 'ellipse':
        final fill = Paint()..color = color.withValues(alpha: isDraft ? 0.15 : 0.18);
        final border = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, border);
        break;

      case 'arrow':
        final paint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        final start = Offset(rect.left, rect.top);
        final end = Offset(rect.right, rect.bottom);
        canvas.drawLine(start, end, paint);
        _paintArrowHead(canvas, start, end, paint);
        break;

      case 'text':
        _paintText(canvas, shape, rect, background: false);
        break;

      case 'sticky':
        final fill = Paint()..color = color.withValues(alpha: isDark ? 0.35 : 0.85);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rrect, fill);
        _paintText(canvas, shape, rect.deflate(10), background: true);
        break;
    }

    if (isSelected) {
      final selPaint = Paint()
        ..color = selectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(rect.inflate(4), selPaint);
    }
  }

  void _paintArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowSize = 10.0;
    final angle = (end - start).direction;
    final p1 = end - Offset.fromDirection(angle - 0.5, arrowSize);
    final p2 = end - Offset.fromDirection(angle + 0.5, arrowSize);
    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  void _paintText(Canvas canvas, WhiteboardShape shape, Rect rect, {required bool background}) {
    if (shape.text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: shape.text,
        style: TextStyle(
          color: background ? const Color(0xFF1F1E1D) : textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 6,
      ellipsis: '…',
    )..layout(maxWidth: rect.width);
    painter.paint(canvas, rect.topLeft);
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    // The `shapes` list is mutated in place (add/removeWhere/x+=delta), so
    // it's always the same object reference across rebuilds — comparing it
    // would make shouldRepaint wrongly return false while dragging or
    // deleting a shape, leaving the canvas visually stale. Always repaint;
    // this is cheap enough for the shape counts a block-embedded board
    // realistically holds.
    return true;
  }
}
