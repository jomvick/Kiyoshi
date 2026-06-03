import 'package:flutter/material.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';
import 'package:kiyoshi/src/shared/widgets/botanical_logo.dart';
import 'package:kiyoshi/src/shared/widgets/prismatic_border_painter.dart';


class Sidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Cache local references to avoid widget. lookups
    final dest = selectedDestination;
    final onDestSelect = onDestinationSelected;

    return Container(
      width: isExpanded ? 272 : 76,
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: AppTheme.glassPanel(radius: 32),
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
                    const BotanicalLogo(
                      color: AppTheme.primary,
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
                                          color: AppTheme.onBackground,
                                        ),
                                      ),
                                      Text(
                                        'ZEN STUDIO',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppTheme.primary.withValues(alpha: 0.5),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: isExpanded ? '' : destination.label,
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
                    ? AppTheme.primary.withValues(alpha: isExpanded ? 0.1 : 0.15)
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
                        ? AppTheme.primary
                        : (isExpanded ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.onSurfaceVariant),
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
                                  destination.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? AppTheme.onBackground
                                        : AppTheme.primary.withValues(alpha: 0.6),
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