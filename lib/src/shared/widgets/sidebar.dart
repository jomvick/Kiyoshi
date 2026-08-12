import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/localization/app_translation.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';
import 'package:kiyoshi/src/shared/widgets/botanical_logo.dart';
import 'package:kiyoshi/src/shared/widgets/prismatic_border_painter.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/ai_agent_providers.dart';
import 'package:kiyoshi/src/features/widget_bar/widget_window_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Sidebar extends ConsumerWidget {
  final Workspace? selectedWorkspace;
  final List<Workspace> workspaces;
  final ValueChanged<Workspace> onWorkspaceSelected;
  final VoidCallback onCreateWorkspace;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final bool showPrismaticBorders;
  final bool isExpanded;

  const Sidebar({
    super.key,
    this.selectedWorkspace,
    required this.workspaces,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
    this.selectedDestination = AppDestination.projects,
    required this.onDestinationSelected,
    this.showPrismaticBorders = true,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cache local references to avoid widget. lookups
    final dest = selectedDestination;
    final onDestSelect = onDestinationSelected;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: isExpanded ? 272 : 76,
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: AppTheme.glassPanel(radius: 32, context: context),
      child: Stack(
        children: [
          if (showPrismaticBorders)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: PrismaticBorderPainter(
                    animation: 0,
                    colors: KiyoshiZenTokens.spectralColors,
                    radius: 32,
                    strokeWidth: 1.2,
                  ),
                ),
              ),
            ),
          AnimatedPadding(
            duration: AppTheme.animMedium,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? AppTheme.spaceLarge : 16,
              vertical: AppTheme.spaceLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    BotanicalLogo(
                      color: scheme.primary,
                      size: 40,
                      showPrismaticHalo: true,
                    ),
                    ClipRect(
                      child: AnimatedSize(
                        duration: AppTheme.animMedium,
                        curve: Curves.easeOutCubic,
                        child: isExpanded
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: AppTheme.spaceMedium),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Kiyoshi',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'ZEN STUDIO',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: scheme.primary.withValues(alpha: 0.5),
                                          letterSpacing: 2.0,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...AppDestination.values.map((destination) {
                          final isSelected = dest == destination;
                          return _SidebarNavItem(
                            destination: destination,
                            isSelected: isSelected,
                            isExpanded: isExpanded,
                            onTap: onDestSelect,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // ─── AI Agent Button ───────────────────────────────────────
                _AiSidebarButton(isExpanded: isExpanded),
                // ─── Widget Bar Button ─────────────────────────────────────
                _WidgetBarSidebarButton(isExpanded: isExpanded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _SidebarNavItem extends ConsumerWidget {
  final AppDestination destination;
  final bool isSelected;
  final bool isExpanded;
  final ValueChanged<AppDestination> onTap;

  const _SidebarNavItem({
    required this.destination,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = ref.watch(translationProvider);
    final localizedLabel = t.getDestinationLabel(destination);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: isExpanded ? '' : localizedLabel,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onTap(destination),
            child: AnimatedContainer(
              duration: AppTheme.animMedium,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? AppTheme.spaceMedium : 0,
                vertical: 12,
              ),
              alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withValues(alpha: isExpanded ? 0.1 : 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    destination.icon,
                    size: isExpanded ? 18 : 20,
                    color: isSelected
                        ? scheme.primary
                        : (isExpanded ? scheme.primary.withValues(alpha: 0.5) : scheme.onSurfaceVariant),
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: AppTheme.animMedium,
                      curve: Curves.easeOutCubic,
                      child: isExpanded
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: AppTheme.spaceMedium),
                                Text(
                                  localizedLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? scheme.onSurface
                                        : scheme.primary.withValues(alpha: 0.6),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glowing AI button shown at the bottom of the sidebar.
class _AiSidebarButton extends ConsumerWidget {
  final bool isExpanded;

  const _AiSidebarButton({required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const aiColor = Color(0xFF2A9D84);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Tooltip(
        message: isExpanded ? '' : 'Kiyoshi AI',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => ref.read(aiDrawerOpenProvider.notifier).state = true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? AppTheme.spaceMedium : 0,
                vertical: 12,
              ),
              alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    aiColor.withValues(alpha: 0.12),
                    const Color(0xFF5C8DAE).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: aiColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: isExpanded ? 18 : 20,
                    color: aiColor,
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: AppTheme.spaceMedium),
                    Flexible(
                      child: Text(
                        'Kiyoshi AI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: aiColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: aiColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'IA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: aiColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating widget bar toggle shown under the AI button.
class _WidgetBarSidebarButton extends ConsumerWidget {
  final bool isExpanded;

  const _WidgetBarSidebarButton({required this.isExpanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(widgetWindowServiceProvider);
    const widgetColor = Color(0xFF5C8DAE);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Tooltip(
        message: isExpanded ? '' : 'Kiyoshi Widget',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => service.toggle(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? AppTheme.spaceMedium : 0,
                vertical: 12,
              ),
              alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widgetColor.withValues(alpha: 0.12),
                    const Color(0xFF2A9D84).withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: widgetColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.layoutGrid,
                    size: isExpanded ? 18 : 20,
                    color: widgetColor,
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: AppTheme.spaceMedium),
                    Flexible(
                      child: Text(
                        'Kiyoshi Widget',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widgetColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: widgetColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'WIDGET',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: widgetColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}