import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/notes/note_detail_screen.dart';
import 'package:kiyoshi/src/features/projects/presentation/project_detail_view.dart';

/// Everything tagged `#tag` anywhere in the app — global notes and every
/// project — grouped in one browsable list. Obsidian-style tag view.
class TagDetailScreen extends ConsumerWidget {
  final String tag;

  const TagDetailScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final blocksAsync = ref.watch(blocksForTagProvider(tag));

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.frameMargin,
              AppTheme.frameMargin,
              AppTheme.frameMargin,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.hash, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  tag,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05),
          const SizedBox(height: AppTheme.spaceLarge),
          Expanded(
            child: blocksAsync.when(
              data: (blocks) {
                if (blocks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.hash, size: 48, color: scheme.primary.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        Text(
                          'Nothing tagged #$tag yet',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.frameMargin,
                    vertical: 4,
                  ),
                  itemCount: blocks.length,
                  itemBuilder: (context, i) => _TagResultTile(block: blocks[i], index: i),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Could not load results.')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagResultTile extends ConsumerWidget {
  final ZenBlock block;
  final int index;

  const _TagResultTile({required this.block, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isGlobal = block.projectId == 'global';
    final snippet = block.content.trim();

    return GestureDetector(
      onTap: () => _navigate(context, ref),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isGlobal ? LucideIcons.fileText : LucideIcons.folder,
                size: 15,
                color: scheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  snippet.isEmpty ? '(empty block)' : snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 14, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 20 * index))
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }

  Future<void> _navigate(BuildContext context, WidgetRef ref) async {
    if (block.projectId == 'global') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => NoteDetailScreen(note: block)),
      );
      return;
    }
    final project = await ref.read(projectByIdProvider(block.projectId).future);
    if (project == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ProjectDetailView(project: project)),
    );
  }
}
