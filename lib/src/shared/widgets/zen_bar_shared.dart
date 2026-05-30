import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/constants/zen_typography.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/shared/widgets/smart_bar_controller.dart';

class ZenBarSlashMenu extends StatelessWidget {
  final List<Map<String, dynamic>> commands;
  final void Function(Map<String, dynamic> command) onCommandSelected;

  const ZenBarSlashMenu({
    super.key,
    required this.commands,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8),
            child: Row(
              children: [
                Icon(LucideIcons.zap, size: 12, color: AppTheme.primary.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  'BLOCK TYPES',
                  style: ZenTypography.structuralLabel.copyWith(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commands.map((cmd) => _buildItem(cmd)).toList(),
          ),
        ],
      ),
    ).animate().fade(duration: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildItem(Map<String, dynamic> cmd) {
    final color = cmd['color'] as Color? ?? AppTheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCommandSelected(cmd),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cmd['icon'] as IconData, size: 18, color: color),
              const SizedBox(height: 6),
              Text(
                cmd['label'] as String,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZenBarVisualFeedback extends StatelessWidget {
  final ParsedBlock? result;

  const ZenBarVisualFeedback({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result!.type != 'text')
              _buildBadge(result!.type.toUpperCase(), AppTheme.primary),
            if (result!.metadata.containsKey('priority') &&
                result!.metadata['priority'] < 3) ...[
              const SizedBox(width: 4),
              _buildBadge('P${result!.metadata['priority']}', const Color(0xFFFF4D8D)),
            ],
            if (result!.metadata.containsKey('assignee')) ...[
              const SizedBox(width: 4),
              _buildBadge('@${result!.metadata['assignee']}', const Color(0xFF2DD4BF)),
            ],
            if (result!.metadata.containsKey('project')) ...[
              const SizedBox(width: 4),
              _buildBadge('PROJ', AppTheme.primary),
            ],
          ],
        ),
      ),
    ).animate().fade();
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ZenBarSubmitButton extends StatelessWidget {
  final VoidCallback onTap;

  const ZenBarSubmitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(LucideIcons.arrowUp, size: 20, color: Colors.white),
      ),
    );
  }
}

class ZenBarCommandPill extends StatelessWidget {
  final Map<String, dynamic>? command;
  final Color color;
  final VoidCallback onDismiss;

  const ZenBarCommandPill({
    super.key,
    required this.command,
    required this.color,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (command == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              command!['label'].toString().toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 5),
            Icon(LucideIcons.x, size: 10, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    ).animate().fade(duration: 150.ms).scale(begin: const Offset(0.85, 0.85));
  }
}

class ZenBarSuggestiveChips extends StatelessWidget {
  final void Function(String label) onChipTap;

  const ZenBarSuggestiveChips({super.key, required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChip('New Task', LucideIcons.plus, 'Task'),
        const SizedBox(width: 16),
        _buildChip('Quick Note', LucideIcons.penTool, 'Note'),
        const SizedBox(width: 16),
        _buildChip('New Project', LucideIcons.folder, 'Project'),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon, String commandLabel) {
    return GestureDetector(
      onTap: () => onChipTap(commandLabel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.onBackground.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.onBackground.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

mixin ZenBarSharedState<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  final SmartBarController controller = SmartBarController();
  late final FocusNode focusNode;
  bool isFocused = false;

  final List<String> placeholders = [
    'What is your next focus?',
    'A new milestone awaits...',
    'Capture a spark of genius',
    'One breath, one task',
  ];
  late String currentPlaceholder;

  ParsedBlock? lastResult;
  bool showGhostMenu = false;
  bool showSlashMenu = false;

  final List<Map<String, dynamic>> slashCommands = [
    {'icon': LucideIcons.checkSquare, 'label': 'Task',    'color': const Color(0xFF7C8CFF)},
    {'icon': LucideIcons.fileText,    'label': 'Note',    'color': const Color(0xFF5EEAD4)},
    {'icon': LucideIcons.folder,      'label': 'Project', 'color': const Color(0xFF86EFAC)},
  ];

  Map<String, dynamic>? activeCommand;

  late AnimationController borderRotationController;

  FocusNode? get externalFocusNode;

  void initZenBarState() {
    currentPlaceholder = placeholders[DateTime.now().second % placeholders.length];
    focusNode = externalFocusNode ?? FocusNode();

    borderRotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    controller.addListener(_onTextChanged);
    focusNode.addListener(_onFocusChanged);
  }

  void disposeZenBar() {
    controller.dispose();
    if (externalFocusNode == null) focusNode.dispose();
    borderRotationController.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    final text = controller.text;
    setState(() {
      lastResult = ZenParser.parseRawInput(text);
      showGhostMenu = ZenParser.isProjectIntent(text);
      showSlashMenu = ZenParser.isSlashIntent(text);
    });
  }

  void _onFocusChanged();

  void onSlashCommandSelected(Map<String, dynamic> cmd) {
    setState(() {
      activeCommand = cmd;
      showSlashMenu = false;
    });
    controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void dismissCommand() {
    setState(() => activeCommand = null);
    controller.clear();
    focusNode.requestFocus();
  }

  void onChipTap(String commandLabel) {
    controller.text = '/${commandLabel.toLowerCase()} ';
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    focusNode.requestFocus();
  }

  void resetBar() {
    setState(() {
      currentPlaceholder = placeholders[DateTime.now().second % placeholders.length];
      showSlashMenu = false;
      activeCommand = null;
    });
    controller.clear();
    focusNode.unfocus();
  }
}
