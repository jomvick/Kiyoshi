import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/constants/zen_typography.dart';

/// A standardized header for the Zen Studio pages.
/// Follows the editorial design rules: bold headings, subtle labels, and breathability.
class ZenEditorialHeader extends StatelessWidget {
  final String label;
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final Widget? progressIndicator;
  final List<Widget>? actions;

  const ZenEditorialHeader({
    super.key,
    required this.label,
    required this.title,
    this.subtitle,
    this.accentColor,
    this.progressIndicator,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primary;

    return Container(
      padding: const EdgeInsets.only(
        top: 56,
        left: AppTheme.space2XLarge,
        right: AppTheme.space2XLarge,
        bottom: AppTheme.spaceLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Label (e.g., PROJECT, STRATEGIC SPACE)
                    Text(
                      label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color.withValues(alpha: 0.7),
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      title,
                      style: ZenTypography.editorialHeader.copyWith(
                        color: AppTheme.onBackground,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
            ),
          ],
          if (progressIndicator != null) ...[
            const SizedBox(height: 16),
            progressIndicator!,
          ],
        ],
      ),
    );
  }
}
