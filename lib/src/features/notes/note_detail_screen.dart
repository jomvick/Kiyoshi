import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:intl/intl.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final ZenBlock note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final initialTitle = widget.note.metadata['title'] as String? ?? 
        (widget.note.content.isNotEmpty ? widget.note.content.split('\n').first : '');
    
    _titleController = TextEditingController(text: initialTitle);
    _bodyController = TextEditingController(text: widget.note.content);

    _titleController.addListener(_onChanged);
    _bodyController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy • HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(widget.note.position.toInt() * 1000),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.onBackground),
          onPressed: () => _maybePop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.fileText, size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Document Editor',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.onBackground.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          if (_isDirty)
            IconButton(
              icon: const Icon(LucideIcons.check, color: AppTheme.primary),
              onPressed: _save,
            ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppTheme.onSurfaceVariant),
            onPressed: () => _delete(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.frameMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 13,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Expanded(
              child: ZenGlassCard(
                radius: 24,
                opacity: 0.5,
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    // Document Title Field
                    TextField(
                      controller: _titleController,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.onBackground,
                            fontWeight: FontWeight.w700,
                          ),
                      cursorColor: AppTheme.primary,
                      decoration: InputDecoration(
                        hintText: 'Note Title…',
                        hintStyle: TextStyle(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    // Document Body Field
                    Expanded(
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: AppTheme.primary,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.onBackground.withValues(alpha: 0.85),
                              height: 1.8,
                            ),
                        decoration: InputDecoration(
                          hintText: 'Start typing note content here…',
                          hintStyle: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text;

    final updatedMetadata = Map<String, dynamic>.from(widget.note.metadata);
    if (title.isNotEmpty) {
      updatedMetadata['title'] = title;
    }

    final updated = widget.note.copyWith(
      content: body,
      metadata: updatedMetadata,
    );

    await ref.read(blockServiceProvider).updateBlock(updated);
    setState(() => _isDirty = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note saved'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(blockServiceProvider).deleteBlock(widget.note);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _maybePop() {
    if (_isDirty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Unsaved changes'),
          content: const Text('Do you want to discard your changes?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep editing')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
