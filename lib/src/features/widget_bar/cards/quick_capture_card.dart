import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// First swipeable card: capture a note or a task from the widget bar.
/// The parsed text flows through [ZenParser] exactly like the main app, so
/// `/task Buy coffee !1` or `- [ ] Water plants` behave identically.
class QuickCaptureCard extends ConsumerStatefulWidget {
  const QuickCaptureCard({super.key});

  @override
  ConsumerState<QuickCaptureCard> createState() => _QuickCaptureCardState();
}

class _QuickCaptureCardState extends ConsumerState<QuickCaptureCard> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty || _busy) return;

    final parsed = ZenParser.parseRawInput(raw);
    if (parsed.content.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(blockServiceProvider).addBlock('global', parsed);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parsed.type == 'todo' ? 'Task captured' : 'Note captured'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Quick capture failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blocks = ref.watch(projectBlocksProvider('global')).value ?? const <ZenBlock>[];
    final recent = blocks
        .where((b) => b.type == 'text' || b.type == 'todo')
        .toList()
      ..sort((a, b) => b.position.compareTo(a.position));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capture a note or task',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autofocus: false,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _capture(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
            decoration: InputDecoration(
              hintText: '/task Buy coffee !1 …',
              hintStyle: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              filled: true,
              fillColor: scheme.surfaceContainerLowest.withValues(alpha: 0.55),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.primary.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _busy ? null : _capture,
              child: MouseRegion(
                cursor: _busy
                    ? MouseCursor.defer
                    : SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _busy
                          ? SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Icon(LucideIcons.zap,
                              size: 16, color: scheme.onPrimary),
                      const SizedBox(width: 8),
                      Text(
                        _busy ? 'Capturing…' : 'Capture',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'RECENT CAPTURES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recent.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.inbox,
                          size: 40,
                          color: scheme.primary.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nothing captured yet',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: recent.length > 8 ? 8 : recent.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final b = recent[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              b.type == 'todo'
                                  ? LucideIcons.circle
                                  : LucideIcons.fileText,
                              size: 13,
                              color: b.type == 'todo'
                                  ? scheme.primary
                                  : scheme.tertiary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}