import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/features/notes/note_detail_screen.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:intl/intl.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Classic note flow: create a blank note in DB, then open the editor immediately
  Future<void> _createAndOpenNote() async {
    final parsed = ParsedBlock(
      type: 'text',
      content: '',
      metadata: {'title': 'Untitled Note'},
    );
    try {
      final newId = await ref.read(blockServiceProvider).addBlock('global', parsed);

      // Wait for provider to refresh, then find the newly created block and navigate
      if (!mounted) return;

      // Listen once for the updated blocks list to retrieve the new ZenBlock
      final blocks = await ref.read(projectBlocksProvider('global').future);
      final newNote = blocks.firstWhere(
        (b) => b.id == newId,
        orElse: () => ZenBlock(
          id: newId,
          projectId: 'global',
          type: 'text',
          content: '',
          metadata: {'title': 'Untitled Note'},
          position: DateTime.now().millisecondsSinceEpoch / 1000,
        ),
      );

      if (!mounted) return;
      _openNoteDetail(newNote);
    } catch (e) {
      debugPrint('Failed to create note: $e');
    }
  }

  /// Extract display title from a note: metadata title > first line of content > fallback
  String _getNoteTitle(ZenBlock note) {
    final metaTitle = note.metadata['title'] as String?;
    if (metaTitle != null && metaTitle.trim().isNotEmpty && metaTitle != 'Untitled Note') {
      return metaTitle;
    }
    // Fallback: first line of content
    final content = note.content.trim();
    if (content.isEmpty) return 'Untitled Note';
    final firstLine = content.split('\n').first.trim();
    if (firstLine.isEmpty) return 'Untitled Note';
    return firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine;
  }

  /// Extract a body preview (excluding the first line used as title)
  String _getNotePreview(ZenBlock note) {
    final content = note.content.trim();
    if (content.isEmpty) return 'No additional text';
    final lines = content.split('\n');
    if (lines.length <= 1) return 'No additional text';
    final preview = lines.skip(1).join('\n').trim();
    if (preview.isEmpty) return 'No additional text';
    return preview;
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(projectBlocksProvider('global'));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildToolbar(),
          const SizedBox(height: 8),
          Expanded(
            child: blocksAsync.when(
              data: (blocks) {
                // Only show 'text' type blocks (notes without project tag)
                final notes = blocks
                    .where((b) =>
                        b.type == 'text' &&
                        (b.metadata['project'] == null ||
                            b.metadata['project'] == '') &&
                        (b.metadata['intent'] == null ||
                            b.metadata['intent'] == 'text'))
                    .where((b) {
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      final title = _getNoteTitle(b).toLowerCase();
                      final content = b.content.toLowerCase();
                      return title.contains(q) || content.contains(q);
                    })
                    .toList()
                  ..sort((a, b) => b.position.compareTo(a.position));

                if (notes.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildNotesGrid(notes);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Could not load notes.')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.frameMargin, AppTheme.frameMargin, AppTheme.frameMargin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK CAPTURE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Notes',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
              ),
              const SizedBox(width: AppTheme.spaceLarge),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'All your fleeting thoughts, unattached to any project.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05);
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
      child: Row(
        children: [
          Expanded(
            child: ZenGlassCard(
              radius: 18,
              opacity: 0.5,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  Icon(LucideIcons.search,
                      size: 18,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search notes…',
                        hintStyle: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(LucideIcons.x,
                          size: 16,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: _createAndOpenNote,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.plus, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'New Note',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildNotesGrid(List<ZenBlock> notes) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.frameMargin),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 220,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: notes.length,
        itemBuilder: (ctx, i) => _buildFileNoteCard(notes[i], i),
      ),
    );
  }

  Widget _buildFileNoteCard(ZenBlock note, int index) {
    final date = DateFormat('MMM d, HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(note.position.toInt() * 1000),
    );
    final title = _getNoteTitle(note);
    final preview = _getNotePreview(note);

    return GestureDetector(
      onTap: () => _openNoteDetail(note),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ZenGlassCard(
          radius: 20,
          opacity: 0.45,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                  ),
                  _buildIconButton(
                    LucideIcons.trash2,
                    () => _onDeleteNote(note),
                    danger: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Note title
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onBackground.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 6),
              // Note preview
              Expanded(
                child: Text(
                  preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        height: 1.4,
                        fontSize: 11,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 12,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 30 * index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap,
      {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: danger
                ? Colors.red.withValues(alpha: 0.08)
                : AppTheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: danger
                ? Colors.red.withValues(alpha: 0.7)
                : AppTheme.primary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileText,
              size: 56, color: AppTheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text(
            'A blank canvas awaits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onBackground.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + New Note button\nto capture your first thought.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.45),
                  height: 1.6,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  void _openNoteDetail(ZenBlock note) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NoteDetailScreen(note: note),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _onDeleteNote(ZenBlock note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete note?'),
        content:
            const Text('This note will be permanently deleted.'),
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
      await ref.read(blockServiceProvider).deleteBlock(note);
    }
  }
}
