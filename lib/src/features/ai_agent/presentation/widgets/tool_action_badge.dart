/// Tool action badge — shown after an AI tool call executes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/chat_message.dart';

class ToolActionBadge extends StatelessWidget {
  final ToolCallRecord record;

  const ToolActionBadge({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (bg, fg, borderColor) = switch (record.status) {
      ToolCallStatus.success => (
          const Color(0xFF2A9D84).withValues(alpha: 0.1),
          const Color(0xFF2A9D84),
          const Color(0xFF2A9D84).withValues(alpha: 0.3),
        ),
      ToolCallStatus.error => (
          Colors.red.withValues(alpha: 0.1),
          Colors.red,
          Colors.red.withValues(alpha: 0.3),
        ),
      ToolCallStatus.executing => (
          scheme.primary.withValues(alpha: 0.08),
          scheme.primary,
          scheme.primary.withValues(alpha: 0.2),
        ),
      ToolCallStatus.pending => (
          scheme.surfaceContainerHigh,
          scheme.onSurfaceVariant,
          scheme.outline.withValues(alpha: 0.3),
        ),
    };

    return Tooltip(
      message: record.result ?? '',
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.status == ToolCallStatus.executing)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: fg,
                ),
              )
            else
              Text(
                _statusIcon,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(width: 5),
            Text(
              record.displaySummary,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 300.ms)
        .scaleXY(begin: 0.85, end: 1.0, curve: Curves.elasticOut);
  }

  String get _statusIcon => switch (record.status) {
        ToolCallStatus.success => '✓',
        ToolCallStatus.error => '✗',
        ToolCallStatus.executing => '',
        ToolCallStatus.pending => '⏳',
      };
}
