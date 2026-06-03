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
  final TextEditingController _noteInputController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _noteInputController.dispose();
    super.dispose();
  }

  Future<void> _createNote(String content) async {
    if (content.trim().isEmpty) return;
    final parsed = ParsedBlock(
      type: 'text',
      content: content.trim(),
      metadata: {},
    );
    try {
      await ref.read(blockServiceProvider).addBlock('global', parsed);
      _noteInputController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note created'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to create note: $e');
    }
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
          _buildSearchBar(),
          _buildNoteInput(),
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
                    .where((b) => _searchQuery.isEmpty ||
                        b.content.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList()
                  ..sort((a, b) => b.position.compareTo(a.position));

                if (notes.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildNotesList(notes);
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
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
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildNoteInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.frameMargin, AppTheme.spaceMedium, AppTheme.frameMargin, 0),
      child: ZenGlassCard(
        radius: 18,
        opacity: 0.5,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Row(
          children: [
            Icon(LucideIcons.feather,
                size: 18,
                color: AppTheme.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _noteInputController,
                onSubmitted: _createNote,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Write a quick note…',
                  hintStyle: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _createNote(_noteInputController.text),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.arrowUp,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildNotesList(List<ZenBlock> notes) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.frameMargin),
      child: ListView.separated(
        itemCount: notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _buildNoteCard(notes[i], i),
      ),
    );
  }

  Widget _buildNoteCard(ZenBlock note, int index) {
    final date = DateFormat('MMM d, HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(note.position.toInt() * 1000),
    );

    return GestureDetector(
      onTap: () => _openNoteDetail(note),
      child: ZenGlassCard(
        radius: 20,
        opacity: 0.45,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onBackground.withValues(alpha: 0.85),
                    height: 1.7,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                ),
                _buildIconButton(
                    LucideIcons.trash2, () => _onDeleteNote(note),
                    danger: true),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
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
          Icon(LucideIcons.feather,
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
            'Type /note in the quick entry bar\nto capture your first thought.',
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
