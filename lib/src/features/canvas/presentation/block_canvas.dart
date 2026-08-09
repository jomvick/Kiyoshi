import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/note_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/todo_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/link_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/image_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/code_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/heading_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/divider_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/file_block.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/database_view_widget.dart';
import 'package:kiyoshi/src/features/canvas/presentation/widgets/whiteboard_block.dart';
import 'package:kiyoshi/src/shared/widgets/command_palette.dart';

class ZenCanvas extends StatefulWidget {
  final List<ZenBlock> blocks;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(ZenBlock block, bool isChecked) onTodoChanged;
  final Function(ZenBlock block, String newContent) onContentChanged;
  final Function(ZenBlock block)? onDelete;
  final Function(String type, String content, Map<String, dynamic> metadata)? onCreateBlock;
  /// Inserts a block right after [afterBlockId] and returns its new id, so
  /// the canvas can move keyboard focus to it — backs the gutter's "+" and
  /// Enter-to-create-next-block inside text/todo blocks.
  final Future<String> Function(String afterBlockId, String type, String content, Map<String, dynamic> metadata)?
      onCreateBlockAfter;
  final Widget? header;
  final Widget? footer;
  final String projectId;

  const ZenCanvas({
    super.key,
    required this.blocks,
    required this.onReorder,
    required this.onTodoChanged,
    required this.onContentChanged,
    this.onDelete,
    this.onCreateBlock,
    this.onCreateBlockAfter,
    this.header,
    this.footer,
    required this.projectId,
  });

  @override
  State<ZenCanvas> createState() => _ZenCanvasState();
}

class _ZenCanvasState extends State<ZenCanvas> {
  final ValueNotifier<String?> _hoveredBlockId = ValueNotifier<String?>(null);
  final TextEditingController _quickEntryController = TextEditingController();
  late final FocusNode _quickEntryFocusNode;
  final ScrollController _scrollController = ScrollController();

  /// Id of a block that was just inserted via the gutter '+' or Enter, and
  /// should receive keyboard focus on its next build.
  String? _pendingFocusBlockId;

  // Inline '/' menu (Notion-style: filters live, arrow-key navigable).
  // Visibility is derived directly from the text field's content rather
  // than tracked via a separate Overlay controller — simpler and matches
  // the proven pattern already used by ZenBarSlashMenu on the Dashboard.
  String _slashQuery = '';
  int _slashSelectedIndex = 0;

  bool get _isSlashMenuOpen => ZenParser.isSlashIntent(_quickEntryController.text);

  @override
  void initState() {
    super.initState();
    _quickEntryFocusNode = FocusNode(onKeyEvent: _handleSlashMenuKeyEvent);
    _quickEntryController.addListener(_onQuickEntryChanged);
  }

  @override
  void didUpdateWidget(ZenCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Skip the auto-scroll-to-bottom when a mid-list insertion is pending a
    // focus hand-off — jumping to the bottom would yank focus away from the
    // block the user just created with '+' or Enter.
    if (widget.blocks.length > oldWidget.blocks.length && _pendingFocusBlockId == null) {
      _scrollToBottom();
    }
  }

  /// Inserts a block right after [afterBlockId] via [widget.onCreateBlockAfter]
  /// and hands keyboard focus to it once it appears in the list.
  Future<void> _insertBlockAfter(String afterBlockId, String type, String content, Map<String, dynamic> metadata) async {
    if (widget.onCreateBlockAfter == null) return;
    final newId = await widget.onCreateBlockAfter!(afterBlockId, type, content, metadata);
    if (!mounted) return;
    setState(() => _pendingFocusBlockId = newId);
    // autofocus only matters on a widget's first build; clear the flag on
    // the next frame so it doesn't linger in state indefinitely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _pendingFocusBlockId = null);
    });
  }

  /// Clones [block] into a new block of the same type/content/metadata,
  /// placed right after the original — backs the gutter's unified "⋮" menu.
  void _duplicateBlock(ZenBlock block) {
    _insertBlockAfter(
      block.id,
      block.type,
      block.content,
      Map<String, dynamic>.from(block.metadata),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onQuickEntryChanged() {
    final text = _quickEntryController.text;
    if (ZenParser.isSlashIntent(text)) {
      setState(() {
        _slashQuery = text.substring(1).toLowerCase();
        _slashSelectedIndex = 0;
      });
    } else if (_slashQuery.isNotEmpty || _slashSelectedIndex != 0) {
      setState(() {
        _slashQuery = '';
        _slashSelectedIndex = 0;
      });
    }
  }

  void _closeSlashMenu() {
    setState(() {
      _slashQuery = '';
      _slashSelectedIndex = 0;
    });
  }

  /// Opens the menu on demand (e.g. from the '+' button) by simulating a
  /// typed '/', so it goes through the exact same live-filtering path.
  void _openSlashMenuManually() {
    _quickEntryController.text = '/';
    _quickEntryController.selection = const TextSelection.collapsed(offset: 1);
    _quickEntryFocusNode.requestFocus();
  }

  KeyEventResult _handleSlashMenuKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isSlashMenuOpen) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final filtered = _filteredSlashCommands;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _slashSelectedIndex = filtered.isEmpty ? 0 : (_slashSelectedIndex + 1) % filtered.length;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _slashSelectedIndex = filtered.isEmpty
            ? 0
            : (_slashSelectedIndex - 1 + filtered.length) % filtered.length;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (filtered.isNotEmpty) {
        _executeSlashCommand(filtered[_slashSelectedIndex.clamp(0, filtered.length - 1)]);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeSlashMenu();
      _quickEntryController.clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _executeSlashCommand(Command command) {
    _closeSlashMenu();
    _quickEntryController.clear();
    command.onExecute();
    _quickEntryFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _quickEntryController.removeListener(_onQuickEntryChanged);
    _hoveredBlockId.dispose();
    _quickEntryController.dispose();
    _quickEntryFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// The '/' command list. Data-only (icon/title/subtitle/keywords/onExecute)
  /// so it can back both the inline dropdown and, if needed later, a bigger
  /// search surface — same [Command] model as the global Cmd+K palette.
  List<Command> get _blockCommands => [
        Command(
          id: 'text',
          title: 'Text',
          subtitle: 'Start writing with plain text',
          icon: LucideIcons.type,
          keywords: ['text', 'paragraph', 'writing'],
          onExecute: () => widget.onCreateBlock?.call('text', '', {}),
        ),
        Command(
          id: 'heading',
          title: 'Heading',
          subtitle: 'Large section heading',
          icon: LucideIcons.heading,
          keywords: ['h1', 'title', 'heading'],
          onExecute: () => widget.onCreateBlock?.call('heading', 'New Heading', {}),
        ),
        Command(
          id: 'todo',
          title: 'To-do List',
          subtitle: 'Track tasks with a checklist',
          icon: LucideIcons.checkSquare,
          keywords: ['todo', 'task', 'checklist'],
          onExecute: () => widget.onCreateBlock?.call('todo', 'New Task', {'checked': false}),
        ),
        Command(
          id: 'kanban',
          title: 'Kanban Board',
          subtitle: 'Organize tasks in a board',
          icon: LucideIcons.layoutGrid,
          keywords: ['kanban', 'board', 'database'],
          onExecute: () => widget.onCreateBlock?.call('database_view', 'kanban', {'view': 'kanban', 'source': 'tasks'}),
        ),
        Command(
          id: 'whiteboard',
          title: 'Whiteboard',
          subtitle: 'Freeform canvas for shapes, arrows & sticky notes',
          icon: LucideIcons.penTool,
          keywords: ['whiteboard', 'canvas', 'draw', 'excalidraw', 'shapes', 'sticky'],
          onExecute: () => widget.onCreateBlock?.call('whiteboard', 'Whiteboard', {'shapes': <Map<String, dynamic>>[]}),
        ),
        Command(
          id: 'image',
          title: 'Image',
          subtitle: 'Upload an image',
          icon: LucideIcons.image,
          keywords: ['image', 'photo', 'picture', 'upload'],
          onExecute: () async {
            try {
              final result = await FilePicker.pickFiles(
                type: FileType.image,
              );
              if (result != null && result.files.single.path != null) {
                widget.onCreateBlock?.call('image', result.files.single.path!, {});
              }
            } catch (e) {
              debugPrint('Error picking file: $e');
            }
          },
        ),
        Command(
          id: 'link',
          title: 'Link',
          subtitle: 'Embed a web bookmark',
          icon: LucideIcons.link,
          keywords: ['link', 'url', 'bookmark', 'web'],
          onExecute: () => widget.onCreateBlock?.call('link', 'https://', {}),
        ),
        Command(
          id: 'code',
          title: 'Code Snippet',
          subtitle: 'Capture a code snippet',
          icon: LucideIcons.code,
          keywords: ['code', 'snippet', 'development'],
          onExecute: () => widget.onCreateBlock?.call('code', '', {'language': 'dart'}),
        ),
        Command(
          id: 'file',
          title: 'File',
          subtitle: 'Attach a file from your computer',
          icon: LucideIcons.paperclip,
          keywords: ['file', 'attachment', 'upload', 'document'],
          onExecute: () => widget.onCreateBlock?.call('file', '', {}),
        ),
        Command(
          id: 'divider',
          title: 'Divider',
          subtitle: 'Visually divide blocks',
          icon: LucideIcons.minus,
          keywords: ['divider', 'line', 'separator'],
          onExecute: () => widget.onCreateBlock?.call('divider', '---', {}),
        ),
      ];

  List<Command> get _filteredSlashCommands {
    if (_slashQuery.isEmpty) return _blockCommands;
    return _blockCommands
        .where((c) =>
            c.title.toLowerCase().contains(_slashQuery) ||
            c.keywords.any((k) => k.toLowerCase().contains(_slashQuery)))
        .toList();
  }

  void _handleQuickEntry() {
    // Safety net: if the inline slash menu is open, Enter should always
    // select the highlighted command rather than submit raw '/text' —
    // regardless of whether the key was already intercepted upstream by
    // _handleSlashMenuKeyEvent.
    if (_isSlashMenuOpen) {
      final filtered = _filteredSlashCommands;
      if (filtered.isNotEmpty) {
        _executeSlashCommand(filtered[_slashSelectedIndex.clamp(0, filtered.length - 1)]);
      } else {
        _closeSlashMenu();
        _quickEntryController.clear();
      }
      return;
    }

    final text = _quickEntryController.text.trim();
    if (text.isEmpty || widget.onCreateBlock == null) return;

    final parsed = ZenParser.parseRawInput(text);
    widget.onCreateBlock!(parsed.type, parsed.content, parsed.metadata);
    _quickEntryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (widget.header != null) SliverToBoxAdapter(child: widget.header),
        if (widget.blocks.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space2XLarge,
              vertical: AppTheme.space2XLarge,
            ),
          sliver: SliverReorderableList(
            itemCount: widget.blocks.length,
            onReorder: widget.onReorder,
            itemBuilder: (context, index) {
              final block = widget.blocks[index];
              return Padding(
                key: ValueKey(block.id),
                padding: const EdgeInsets.only(bottom: AppTheme.spaceLarge),
                child: ValueListenableBuilder<String?>(
                  valueListenable: _hoveredBlockId,
                  builder: (context, hoveredId, child) {
                    final isHovered = hoveredId == block.id;
                    final isOtherHovered = hoveredId != null && !isHovered;

                    return MouseRegion(
                      onEnter: (_) => _hoveredBlockId.value = block.id,
                      onExit: (_) => _hoveredBlockId.value = null,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: isOtherHovered ? 0.35 : 1.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBlockGutter(block, index, isHovered),
                            Expanded(child: _buildBlock(block)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSlashMenuOpen)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.space2XLarge + AppTheme.spaceMedium,
                    right: AppTheme.space2XLarge,
                    bottom: 6,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 320, child: _buildSlashMenuCard()),
                  ),
                ),
              _buildQuickEntry(),
            ],
          ),
        ),
        if (widget.footer != null) SliverToBoxAdapter(child: widget.footer),
      ],
    );
  }

  Widget _buildSlashMenuCard() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredSlashCommands;

    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.98)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: filtered.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.searchX, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'No matching blocks',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(6),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final cmd = filtered[index];
                  return _SlashMenuItem(
                    command: cmd,
                    isHighlighted: index == _slashSelectedIndex,
                    onHover: () => setState(() => _slashSelectedIndex = index),
                    onTap: () => _executeSlashCommand(cmd),
                  );
                },
              ),
            ),
    ).animate().fadeIn(duration: 120.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }

  /// Notion-style drag handle: invisible until the block is hovered, so
  /// reordering is discoverable (previously the whole block needed an
  /// unlabeled long-press with zero visual affordance).
  /// Notion-style gutter: '+' to insert a new block right below this one,
  /// and a drag handle to reorder — both invisible until hovered.
  Widget _buildBlockGutter(ZenBlock block, int index, bool isHovered) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 76,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: AnimatedOpacity(
          duration: AppTheme.animFast,
          opacity: isHovered ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isHovered,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Add block below',
                  waitDuration: const Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: () => _insertBlockAfter(block.id, 'text', '', {}),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Tooltip(
                      message: 'Drag to reorder',
                      waitDuration: const Duration(milliseconds: 500),
                      child: Icon(
                        LucideIcons.gripVertical,
                        size: 16,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Unified per-block menu — Duplicate/Delete work the same way
                // for every block type, instead of each widget implementing
                // its own inconsistent hover-delete affordance.
                PopupMenuButton<String>(
                  tooltip: 'More',
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    LucideIcons.moreHorizontal,
                    size: 16,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  color: scheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'duplicate') _duplicateBlock(block);
                    if (value == 'delete') widget.onDelete?.call(block);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(LucideIcons.copy, size: 14, color: scheme.onSurface.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Text('Duplicate', style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.85))),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(ZenBlock block) {
    final autofocus = block.id == _pendingFocusBlockId;
    switch (block.type) {
      case 'heading':
        return HeadingBlockWidget(
          content: block.content,
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
          onChanged: (val) => widget.onContentChanged(block, val),
        );

      case 'todo':
        return TodoBlockWidget(
          content: block.content,
          isChecked: block.metadata['checked'] == true,
          onChanged: (val) => widget.onTodoChanged(block, val ?? false),
          onContentChanged: (val) => widget.onContentChanged(block, val),
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
          autofocus: autofocus,
          onEnterPressed: () => _insertBlockAfter(block.id, 'todo', '', {'checked': false}),
        );

      case 'link':
        return LinkBlockWidget(
          url: block.content,
          title: block.metadata['title'] as String?,
          faviconUrl: block.metadata['favicon'] as String?,
          onChanged: (val) => widget.onContentChanged(block, val),
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );

      case 'image':
        return ImageBlockWidget(
          imageUrl: block.content,
          size: block.metadata['size'] as String? ?? 'large',
          onChanged: (val) => widget.onContentChanged(block, val),
          onSizeChanged: (val) {
            final updated = Map<String, dynamic>.from(block.metadata)..['size'] = val;
            widget.onContentChanged(block.copyWith(metadata: updated), block.content);
          },
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );

      case 'file':
        return FileBlockWidget(
          fileName: block.content,
          fileSize: block.metadata['size'] as String?,
          onChanged: (val) => widget.onContentChanged(block, val),
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );

      case 'divider':
        return DividerBlockWidget(
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );

      case 'code':
        return CodeBlockWidget(
          content: block.content,
          language: block.metadata['language'] as String?,
          onChanged: (val) => widget.onContentChanged(block, val),
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );

      case 'database_view':
        return DatabaseViewWidget(
          projectId: widget.projectId,
          metadata: block.metadata,
          onDelete: widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );

      case 'whiteboard':
        return WhiteboardBlockWidget(
          metadata: block.metadata,
          onMetadataChanged: (updated) =>
              widget.onContentChanged(block.copyWith(metadata: updated), block.content),
          onDelete: widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );

      case 'text':
      default:
        return NoteBlockWidget(
          content: block.content,
          onChanged: (val) => widget.onContentChanged(block, val),
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
          autofocus: autofocus,
          onEnterPressed: () => _insertBlockAfter(block.id, 'text', '', {}),
        );
    }
  }

  Widget _buildQuickEntry() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: 4,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space2XLarge,
        vertical: AppTheme.spaceSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle plus button that acts like a block handle
          Opacity(
            opacity: 0.5,
            child: Tooltip(
              message: "Add a block (or type '/')",
              child: IconButton(
                icon: const Icon(LucideIcons.plus, size: 20),
                onPressed: _openSlashMenuManually,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                style: IconButton.styleFrom(
                  hoverColor: scheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _quickEntryController,
                  focusNode: _quickEntryFocusNode,
                  autofocus: true,
                  onSubmitted: (_) {
                    _handleQuickEntry();
                    // Keep focus so the user can keep typing blocks rapidly
                    _quickEntryFocusNode.requestFocus();
                  },
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                        height: 1.65,
                      ),
                  decoration: InputDecoration(
                    hintText: "Type '/' for commands",
                    hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
                // Obsidian-style syntax hint — quiet reminder that markdown
                // shortcuts work directly, no menu required for the basics.
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '#  heading     -[ ]  todo     ```  code     /  more blocks',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.2,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single row in the inline '/' menu. Highlight state is driven by the
/// parent (keyboard nav + mouse hover both write to the same index), so
/// this stays a lightweight StatelessWidget rather than tracking its own
/// hover state.
class _SlashMenuItem extends StatelessWidget {
  final Command command;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _SlashMenuItem({
    required this.command,
    required this.isHighlighted,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFastest,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                command.icon,
                size: 16,
                color: isHighlighted ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      command.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      command.subtitle,
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isHighlighted)
                Icon(LucideIcons.cornerDownLeft, size: 12, color: scheme.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

