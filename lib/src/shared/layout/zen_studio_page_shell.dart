import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/shared/widgets/ambient_zen_background.dart';

/// Wraps feature screens with the same mist + sage/mint atmosphere as the dashboard.
class ZenStudioPageShell extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;
  final Widget? floatingAction;
  final bool showSidebar;

  const ZenStudioPageShell({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    required this.child,
    this.floatingAction,
    this.showSidebar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientZenBackground(
        child: Stack(
          children: [
            Column(
              children: [
                if (title != null || subtitle != null || actions != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space2XLarge,
                      AppTheme.space2XLarge,
                      AppTheme.space2XLarge,
                      0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Text(
                                  title!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  subtitle!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
            if (floatingAction != null)
              Positioned(
                bottom: AppTheme.space2XLarge,
                left: 0,
                right: 0,
                child: Center(child: floatingAction!),
              ),
          ],
        ),
      ),
    );
  }
}
