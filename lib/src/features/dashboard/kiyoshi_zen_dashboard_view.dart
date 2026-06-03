import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/shared/layout/zen_studio_page_shell.dart';
import 'package:kiyoshi/src/shared/widgets/glass_prism_panel.dart';
import 'package:kiyoshi/src/features/zen/the_monolith_widget.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class KiyoshiZenDashboardView extends ConsumerStatefulWidget {
  const KiyoshiZenDashboardView({super.key});

  @override
  ConsumerState<KiyoshiZenDashboardView> createState() => _KiyoshiZenDashboardViewState();
}

class _KiyoshiZenDashboardViewState extends ConsumerState<KiyoshiZenDashboardView> {
  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(latestActivitiesProvider);
    final statsAsync = ref.watch(globalStatsProvider);
    final isZenMode = ref.watch(preferencesProvider.select((p) => p.zenModeEnabled));

    if (isZenMode) {
      return TheMonolith(
        taskTitle: "Deep Focus Session",
        onComplete: () {
          ref.read(preferencesProvider.notifier).setZenModeEnabled(false);
        },
      );
    }

    return ZenStudioPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spaceLarge),
          _buildEditorialHeader(context),
          const SizedBox(height: AppTheme.spaceXLarge),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
              child: Column(
                children: [
                  const _FocusOfTheDayWidget(),
                  const SizedBox(height: AppTheme.spaceXLarge),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 1000;
                      return Column(
                        children: [
                          if (isNarrow) ...[
                            _buildActivitySection(activitiesAsync),
                            const SizedBox(height: AppTheme.spaceLarge),
                            _buildStatsSection(statsAsync),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _buildActivitySection(activitiesAsync)),
                                const SizedBox(width: AppTheme.spaceLarge),
                                Expanded(flex: 4, child: _buildStatsSection(statsAsync)),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(AsyncValue<List<ZenBlock>> activitiesAsync) {
    return activitiesAsync.when(
      data: (blocks) => _ActivityTimelineCard(blocks: blocks),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Could not load activities.')),
    );
  }

  Widget _buildStatsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => _ProjectBreakdownCard(stats: stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Could not load stats.')),
    );
  }

  Widget _buildEditorialHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.frameMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STUDIO OVERVIEW',
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
                'Zen Workspace',
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
                    'Your personal sanctuary of productivity and focus.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                  ),
                ),
              ),
              _ZenModeButton(onPressed: () => ref.read(preferencesProvider.notifier).setZenModeEnabled(true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTimelineCard extends StatelessWidget {
  final List<ZenBlock> blocks;

  const _ActivityTimelineCard({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return GlassPrismPanel(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT ACTIVITY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          if (blocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No recent activity found.'),
            )
          else
            ...blocks.asMap().entries.map((e) => _TimelineRow(
                  block: e.value,
                  showLine: e.key != blocks.length - 1,
                )),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ZenBlock block;
  final bool showLine;

  const _TimelineRow({required this.block, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (showLine)
                Container(width: 2, height: 40, color: AppTheme.primary.withValues(alpha: 0.1)),
            ],
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.type.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  block.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Just now',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
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

class _ProjectBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _ProjectBreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GlassPrismPanel(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STUDIO METRICS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          _MetricRow(label: 'Total Blocks', value: stats['totalBlocks'].toString()),
          const SizedBox(height: AppTheme.spaceMedium),
          _MetricRow(label: 'Tasks Created', value: stats['totalTasks'].toString()),
          const SizedBox(height: AppTheme.spaceMedium),
          _MetricRow(label: 'Completed', value: stats['completedTasks'].toString()),
          const SizedBox(height: AppTheme.spaceXLarge),
          LinearProgressIndicator(
            value: (stats['efficiency'] as double),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            'Sanctuary Efficiency',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _FocusOfTheDayWidget extends StatelessWidget {
  const _FocusOfTheDayWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text(
            'CURRENT FOCUS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mastering your Digital Sanctuary',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

class _ZenModeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ZenModeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.flame, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'ENTER ZEN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
