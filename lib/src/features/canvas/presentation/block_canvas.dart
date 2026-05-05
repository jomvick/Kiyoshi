import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import 'package:kiyoshi/src/shared/widgets/command_palette.dart';

class ZenCanvas extends StatefulWidget {
  final List<ZenBlock> blocks;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(ZenBlock block, bool isChecked) onTodoChanged;
  final Function(ZenBlock block, String newContent) onContentChanged;
  final Function(ZenBlock block)? onDelete;
  final Function(String type, String content, Map<String, dynamic> metadata)? onCreateBlock;
  final Widget? header;
  final String projectId;

  const ZenCanvas({
    super.key,
    required this.blocks,
    required this.onReorder,
    required this.onTodoChanged,
    required this.onContentChanged,
    this.onDelete,
    this.onCreateBlock,
    this.header,
    required this.projectId,
  });

  @override
  State<ZenCanvas> createState() => _ZenCanvasState();
}

class _ZenCanvasState extends State<ZenCanvas> {
  final ValueNotifier<String?> _hoveredBlockId = ValueNotifier<String?>(null);
  final TextEditingController _quickEntryController = TextEditingController();
  final FocusNode _quickEntryFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _quickEntryController.addListener(_onQuickEntryChanged);
  }

  @override
  void didUpdateWidget(ZenCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blocks.length > oldWidget.blocks.length) {
      _scrollToBottom();
    }
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
    if (_quickEntryController.text == '/') {
      _showBlockCommandPalette();
    }
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

  void _showBlockCommandPalette() {
    // Clear the trigger character so it doesn't loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickEntryController.clear();
      _quickEntryFocusNode.unfocus();
    });

    CommandPalette.show(
      context,
      commands: [
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
      ],
    );
  }

  void _handleQuickEntry() {
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
              return ReorderableDelayedDragStartListener(
                key: ValueKey(block.id),
                index: index,
                child: ValueListenableBuilder<String?>(
                  valueListenable: _hoveredBlockId,
                  builder: (context, hoveredId, child) {
                    final isOtherHovered =
                        hoveredId != null && hoveredId != block.id;

                    return MouseRegion(
                      onEnter: (_) => _hoveredBlockId.value = block.id,
                      onExit: (_) => _hoveredBlockId.value = null,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: isOtherHovered ? 0.35 : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppTheme.spaceLarge),
                          child: _buildBlock(block),
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
          child: _buildQuickEntry(),
        ),
      ],
    );
  }

  Widget _buildBlock(ZenBlock block) {
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

      case 'text':
      default:
        return NoteBlockWidget(
          content: block.content,
          onChanged: (val) => widget.onContentChanged(block, val),
          onDelete:
              widget.onDelete != null ? () => widget.onDelete!(block) : null,
        );
    }
  }

  Widget _buildQuickEntry() {
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
            child: IconButton(
              icon: const Icon(LucideIcons.plus, size: 20),
              onPressed: _showBlockCommandPalette,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              style: IconButton.styleFrom(
                hoverColor: AppTheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _quickEntryController,
              focusNode: _quickEntryFocusNode,
              onSubmitted: (_) {
                _handleQuickEntry();
                // Keep focus so the user can keep typing blocks rapidly
                _quickEntryFocusNode.requestFocus();
              },
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.onBackground.withValues(alpha: 0.85),
                    height: 1.65,
                  ),
              decoration: InputDecoration(
                hintText: "Type '/' for commands",
                hintStyle: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

