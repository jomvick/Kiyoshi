import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/features/notes/note_detail_screen.dart';
import 'package:kiyoshi/src/features/notes/tag_detail_screen.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:intl/intl.dart';

import 'package:kiyoshi/src/core/localization/app_translation.dart';

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildToolbar(context),
          const SizedBox(height: 12),
          _buildTagsRow(context),
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
                  return _buildEmptyState(context);
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
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(translationProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.frameMargin, AppTheme.frameMargin, AppTheme.frameMargin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.quickCapture,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary.withValues(alpha: 0.7),
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.notes,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(width: AppTheme.spaceLarge),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    t.fleetingThoughts,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
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

  Widget _buildToolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(translationProvider);
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
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: t.searchNotes,
                        hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
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
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
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
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 18, color: scheme.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      t.newNote,
                      style: TextStyle(
                        color: scheme.onPrimary,
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

  Widget _buildTagsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer(
      builder: (context, ref, _) {
        final tagsAsync = ref.watch(allTagsProvider);
        return tagsAsync.when(
          data: (tags) {
            if (tags.isEmpty) return const SizedBox.shrink();
            final sorted = tags.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final entry = sorted[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TagDetailScreen(tag: entry.key),
                        ),
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#${entry.key}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.value}',
                                style: TextStyle(fontSize: 11, color: scheme.primary.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
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
    final scheme = Theme.of(context).colorScheme;
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
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.fileText,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconButton(
                        context,
                        LucideIcons.folderInput,
                        () => _attachToProject(note),
                      ),
                      const SizedBox(width: 4),
                      _buildIconButton(
                        context,
                        LucideIcons.trash2,
                        () => _onDeleteNote(note),
                        danger: true,
                      ),
                    ],
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
                      color: scheme.onSurface.withValues(alpha: 0.95),
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
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
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
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
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

  Widget _buildIconButton(BuildContext context, IconData icon, VoidCallback onTap,
      {bool danger = false}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: danger
                ? scheme.error.withValues(alpha: 0.1)
                : scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: danger
                ? scheme.error.withValues(alpha: 0.8)
                : scheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(translationProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileText,
              size: 56, color: scheme.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 20),
          Text(
            t.blankCanvas,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            t.blankCanvasSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
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

  Future<void> _attachToProject(ZenBlock note) async {
    final selected = await showDialog<Project>(
      context: context,
      builder: (ctx) {
        final dialogScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: dialogScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Attach to project'),
          content: SizedBox(
            width: 320,
            child: Consumer(
              builder: (context, ref, _) {
                final projectsAsync = ref.watch(allProjectsProvider);
                return projectsAsync.when(
                  data: (projects) {
                    if (projects.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No projects yet — create one first.',
                          style: TextStyle(color: dialogScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 280,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: projects.length,
                        itemBuilder: (context, i) {
                          final p = projects[i];
                          return ListTile(
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: p.statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(p.title),
                            onTap: () => Navigator.pop(ctx, p),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Could not load projects.',
                      style: TextStyle(color: dialogScheme.error),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected == null || !mounted) return;
    try {
      await ref.read(blockServiceProvider).moveBlockToProject(note.id, selected.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved to "${selected.title}"')),
        );
      }
    } catch (e) {
      debugPrint('Failed to attach note to project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not attach note to project.')),
        );
      }
    }
  }

  void _onDeleteNote(ZenBlock note) async {
    final scheme = Theme.of(context).colorScheme;
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
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
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
