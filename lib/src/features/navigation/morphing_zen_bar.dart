import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:kiyoshi/src/shared/widgets/botanical_logo.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';
import 'package:kiyoshi/src/shared/widgets/prismatic_border_painter.dart';
import 'package:kiyoshi/src/shared/widgets/zen_bar_shared.dart';

class MorphingZenBar extends StatefulWidget {
  final Function(String title, DateTime? date, String? project, int priority) onTaskCreated;
  final Function(String type, String content, Map<String, dynamic> metadata)? onBlockCreated;
  final Function(String title, String? description)? onProjectCreated;
  final VoidCallback? onNavigateToCalendar;
  final FocusNode? focusNode;
  final bool isDashboard;
  final bool showPrismaticBorders;

  const MorphingZenBar({
    super.key,
    required this.onTaskCreated,
    this.onBlockCreated,
    this.onProjectCreated,
    this.onNavigateToCalendar,
    this.focusNode,
    this.isDashboard = true,
    this.showPrismaticBorders = true,
  });

  @override
  State<MorphingZenBar> createState() => _MorphingZenBarState();
}

class _MorphingZenBarState extends State<MorphingZenBar> with TickerProviderStateMixin, ZenBarSharedState<MorphingZenBar> {
  final bool _isManuallyExpanded = false;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    initZenBarState();
  }

  @override
  void dispose() {
    disposeZenBar();
    super.dispose();
  }

  @override
  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {
      isFocused = focusNode.hasFocus;
      if (isFocused) {
        borderRotationController.repeat();
      } else {
        borderRotationController.stop();
      }
    });
  }

  void _submitTask() async {
    try {
      final contentText = controller.text.trim();
      final label = activeCommand?['label']?.toString().toLowerCase() ?? '';
      final rawText = (label.isNotEmpty && contentText.isNotEmpty)
          ? '/$label $contentText'
          : contentText;

      if (rawText.isEmpty || rawText == '/') return;

      final parsed = ZenParser.parseRawInput(rawText);

      if (parsed.type == 'project') {
        if (widget.onProjectCreated != null) {
          await widget.onProjectCreated!(parsed.content, parsed.metadata['description']);
        }
      } else if (parsed.type == 'event') {
        widget.onNavigateToCalendar?.call();
      } else if (parsed.type != 'todo' && widget.onBlockCreated != null) {
        await widget.onBlockCreated!(parsed.type, parsed.content, parsed.metadata);
      } else {
        await widget.onTaskCreated(
          parsed.content,
          null,
          parsed.metadata['project'],
          parsed.metadata['priority'] ?? 3,
        );
      }
    } catch (e) {
      debugPrint('Failed to submit task: $e');
    }

    if (!mounted) return;
    resetBar();
  }

  bool get _shouldBeExpanded => widget.isDashboard || isFocused || _isManuallyExpanded;
  bool get _isVisualActive => isFocused || _isManuallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGhostMenu && _shouldBeExpanded)
          _buildGhostMenu(),
        if (showSlashMenu && _shouldBeExpanded)
          ZenBarSlashMenu(commands: slashCommands, onCommandSelected: onSlashCommandSelected),
        _buildPrismaticBar(),
        if (_shouldBeExpanded && !isFocused && controller.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ZenBarSuggestiveChips(onChipTap: onChipTap),
          ),
      ],
    );
  }

  Widget _buildPrismaticBar() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: _shouldBeExpanded ? double.infinity : 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                ZenGlassCard(
                  radius: 20,
                  opacity: _isVisualActive ? 0.95 : 0.4,
                  blurSigma: 15,
                  padding: EdgeInsets.zero,
                  child: const SizedBox.expand(),
                ),
                if (isFocused && widget.showPrismaticBorders)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: borderRotationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PrismaticBorderPainter(
                            animation: borderRotationController.value,
                            colors: KiyoshiZenTokens.spectralColors,
                            radius: 20,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _shouldBeExpanded
                      ? _buildExpandedContent()
                      : _buildCollapsedIcon(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedIcon() {
    return Container(
      key: const ValueKey('collapsed'),
      alignment: Alignment.center,
      child: const BotanicalLogo(
        size: 32,
        color: AppTheme.primary,
        showPrismaticHalo: false,
      ),
    );
  }

  Widget _buildExpandedContent() {
    final cmd = activeCommand;
    final cmdColor = cmd != null
        ? (cmd['color'] as Color? ?? AppTheme.primary)
        : AppTheme.primary;
    final hintText = cmd != null
        ? 'Write your ${cmd['label'].toString().toLowerCase()}...'
        : currentPlaceholder;

    return Container(
      key: const ValueKey('expanded'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BotanicalLogo(
            size: 28,
            color: isFocused
                ? AppTheme.primary
                : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
            showPrismaticHalo: isFocused,
          ),
          const SizedBox(width: 10),
          if (cmd != null) ...[
            ZenBarCommandPill(command: cmd, color: cmdColor, onDismiss: dismissCommand),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: (_) => _submitTask(),
              cursorColor: AppTheme.primary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onBackground,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (cmd == null && lastResult != null && controller.text.isNotEmpty)
            ZenBarVisualFeedback(result: lastResult),
          if (controller.text.isNotEmpty || cmd != null) ...[
            const SizedBox(width: 8),
            ZenBarSubmitButton(onTap: _submitTask),
          ],
        ],
      ),
    );
  }

  List<String> get _projectSuggestions => ['Design', 'Marketing', 'Core', 'Vision', 'Calm'];

  Widget _buildGhostMenu() {
    final query = ZenParser.getProjectQuery(controller.text);
    final filtered = _projectSuggestions.where((p) => p.toLowerCase().contains(query)).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 240,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: filtered.map((p) => _buildGhostItem(p)).toList(),
        ),
      ),
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildGhostItem(String label) {
    return InkWell(
      onTap: () {
        final parts = controller.text.split('#');
        parts.removeLast();
        controller.text = '${parts.join('#')}#$label ';
        controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            const Icon(LucideIcons.hash, size: 14, color: AppTheme.primary),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

}
