import 'package:flutter/material.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';
import 'package:kiyoshi/src/shared/widgets/botanical_logo.dart';
import 'package:kiyoshi/src/shared/widgets/prismatic_border_painter.dart';
import 'package:lucide_icons/lucide_icons.dart';


class Sidebar extends StatelessWidget {
  final Workspace? selectedWorkspace;
  final List<Workspace> workspaces;
  final ValueChanged<Workspace> onWorkspaceSelected;
  final VoidCallback onCreateWorkspace;
  final VoidCallback? onNewProjectTap;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;

  const Sidebar({
    super.key,
    this.selectedWorkspace,
    required this.workspaces,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
    this.onNewProjectTap,
    this.selectedDestination = AppDestination.projects,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Cache local references to avoid widget. lookups
    final dest = selectedDestination;
    final onDestSelect = onDestinationSelected;
    final onProjectTap = onNewProjectTap;

    return Container(
      width: 272,
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: AppTheme.glassPanel(radius: 32),
      child: Stack(
        children: [
          // Prismatic Border - cached static
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
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BotanicalLogo(
                      color: AppTheme.primary,
                      size: 40,
                      showPrismaticHalo: true,
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Kiyoshi',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onBackground,
                            ),
                          ),
                          Text(
                            'ZEN STUDIO',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                              letterSpacing: 2.0,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                ...AppDestination.values.map((destination) {
                  final isSelected = dest == destination;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => onDestSelect(destination),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMedium,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                destination.icon,
                                size: 18,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: AppTheme.spaceMedium),
                              Text(
                                destination.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isSelected
                                          ? AppTheme.onBackground
                                          : AppTheme.primary.withValues(alpha: 0.6),
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onProjectTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMedium,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppTheme.spaceSmall,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 18,
                              color: Colors.white,
                            ),
                            Text(
                              'New Project',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLarge),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onDestSelect(AppDestination.settings),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMedium,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.settings,
                            size: 18,
                            color: AppTheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: AppTheme.spaceMedium),
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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