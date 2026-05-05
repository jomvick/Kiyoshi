import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

/// Reworked Profile Widget (Single User, Clean Aesthetic)
class AppAvatar extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const AppAvatar({
    super.key,
    this.label = 'User',
    this.imageUrl,
    this.size = 40,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile Menu',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.mintTeal.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              // Open personal profile / settings
            },
            child: const Center(
              child: Icon(
                LucideIcons.user,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
