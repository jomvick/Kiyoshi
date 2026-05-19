import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/shared/layout/zen_studio_page_shell.dart';
import 'package:kiyoshi/src/shared/widgets/zen_editorial_header.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(globalStatsProvider);

    return ZenStudioPageShell(
      title: 'ANALYTICS',
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZenEditorialHeader(
              label: 'Real-time Insights',
              title: 'Production Metrics',
              subtitle: 'A deep dive into your creative output and atomic block progression.',
            ),
            statsAsync.when(
              data: (stats) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2XLarge),
                child: Column(
                  children: [
                    _buildKeyMetrics(stats),
                    const SizedBox(height: AppTheme.spaceXLarge),
                    _EfficiencyCard(efficiency: stats['efficiency'] as double),
                    const SizedBox(height: AppTheme.spaceXLarge),
                    _SummaryCard(stats: stats),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Center(child: Text('Could not load analytics.')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: AppTheme.spaceLarge,
      mainAxisSpacing: AppTheme.spaceLarge,
      childAspectRatio: 1.5,
      children: [
        _MetricCard(
          icon: LucideIcons.layoutGrid,
          label: 'TOTAL BLOCKS',
          value: stats['totalBlocks'].toString(),
          color: AppTheme.primary,
        ),
        _MetricCard(
          icon: LucideIcons.checkCircle,
          label: 'TASKS DONE',
          value: stats['completedTasks'].toString(),
          color: const Color(0xFF10B981),
        ),
        _MetricCard(
          icon: LucideIcons.trendingUp,
          label: 'FLOW RATE',
          value: '${((stats['efficiency'] as double) * 100).toInt()}%',
          color: const Color(0xFF6366F1),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ZenGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant)),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _EfficiencyCard extends StatelessWidget {
  final double efficiency;

  const _EfficiencyCard({required this.efficiency});

  @override
  Widget build(BuildContext context) {
    return ZenGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2XLarge),
        child: Column(
          children: [
            Text('OVERALL EFFICIENCY', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: efficiency,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
                Text('${(efficiency * 100).toInt()}%', style: Theme.of(context).textTheme.displaySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _SummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ZenGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DATA SUMMARY', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 20),
            _SummaryRow(label: 'Active Workspace Nodes', value: stats['totalBlocks'].toString()),
            _SummaryRow(label: 'Strategic Task Units', value: stats['totalTasks'].toString()),
            _SummaryRow(label: 'Completed Milestones', value: stats['completedTasks'].toString()),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
