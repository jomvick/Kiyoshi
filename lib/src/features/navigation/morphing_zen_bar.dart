import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:kiyoshi/src/core/constants/zen_typography.dart';
import 'package:kiyoshi/src/shared/widgets/smart_bar_controller.dart';
import 'package:kiyoshi/src/shared/widgets/botanical_logo.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';
import 'package:kiyoshi/src/shared/widgets/prismatic_border_painter.dart';

class MorphingZenBar extends StatefulWidget {
  final Function(String title, DateTime? date, String? project, int priority) onTaskCreated;
  final Function(String type, String content, Map<String, dynamic> metadata)? onBlockCreated;
  final Function(String title, String? description)? onProjectCreated;
  final FocusNode? focusNode;
  final bool isDashboard;

  const MorphingZenBar({
    super.key, 
    required this.onTaskCreated, 
    this.onBlockCreated,
    this.onProjectCreated,
    this.focusNode,
    this.isDashboard = true,
  });

  @override
  State<MorphingZenBar> createState() => _MorphingZenBarState();
}

class _MorphingZenBarState extends State<MorphingZenBar> with TickerProviderStateMixin {
  final SmartBarController _controller = SmartBarController();
  late final FocusNode _focusNode;
  bool _isFocused = false;
  final bool _isManuallyExpanded = false;
  
  final List<String> _placeholders = [
    'What is your next focus?',
    'A new milestone awaits...',
    'Capture a spark of genius',
    'One breath, one task',
  ];
  late String _currentPlaceholder;
  
  ParsedBlock? _lastResult;
  bool _showGhostMenu = false;
  bool _showSlashMenu = false;
  final List<String> _projectSuggestions = ['Design', 'Marketing', 'Core', 'Vision', 'Calm'];
  
  final List<Map<String, dynamic>> _slashCommands = [
    {'icon': LucideIcons.checkSquare, 'label': 'Task',    'prefix': '/task '},
    {'icon': LucideIcons.fileText,    'label': 'Note',    'prefix': '/note '},
    {'icon': LucideIcons.calendar,    'label': 'Event',   'prefix': '/event '},
    {'icon': LucideIcons.folder,      'label': 'Project', 'prefix': '/project '},
    {'icon': LucideIcons.code,        'label': 'Code',    'prefix': '```\n\n```'},
    {'icon': LucideIcons.link,        'label': 'Link',    'prefix': 'https://'},
  ];

  late AnimationController _borderRotationController;

  @override
  void initState() {
    super.initState();
    _currentPlaceholder = _placeholders[DateTime.now().second % _placeholders.length];
    _focusNode = widget.focusNode ?? FocusNode();

    _borderRotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _borderRotationController.repeat();
      } else {
        _borderRotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _borderRotationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    final text = _controller.text;
    setState(() {
      _lastResult = ZenParser.parseRawInput(text);
      _showGhostMenu = ZenParser.isProjectIntent(text);
      _showSlashMenu = ZenParser.isSlashIntent(text);
    });
  }

  void _submitTask() async {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty || rawText == '/') return;
    
    final parsed = ZenParser.parseRawInput(rawText);
    
    if (parsed.type == 'project') {
      // Route to project creation
      if (widget.onProjectCreated != null) {
        await widget.onProjectCreated!(parsed.content, parsed.metadata['description']);
      }
    } else if (parsed.type != 'todo' && widget.onBlockCreated != null) {
      await widget.onBlockCreated!(
        parsed.type,
        parsed.content,
        parsed.metadata,
      );
    } else {
      await widget.onTaskCreated(
        parsed.content,
        null, // Date handled differently now, but we pass null for now or extract from metadata
        parsed.metadata['project'],
        parsed.metadata['priority'] ?? 3,
      );
    }
    
    if (!mounted) return;
    setState(() {
      _currentPlaceholder = _placeholders[DateTime.now().second % _placeholders.length];
      _showSlashMenu = false;
    });
    _controller.clear();
    if (mounted) _focusNode.unfocus();
  }

  bool get _shouldBeExpanded => widget.isDashboard || _isFocused || _isManuallyExpanded;
  bool get _isVisualActive => _isFocused || _isManuallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showGhostMenu && _shouldBeExpanded)
          _buildGhostMenu(),
        if (_showSlashMenu && _shouldBeExpanded)
          _buildSlashMenu(),
        
        _buildPrismaticBar(),
        
        if (_shouldBeExpanded && !_isFocused && _controller.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildSuggestiveChips(),
          ),
      ],
    );
  }

  Widget _buildPrismaticBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth < 640 ? constraints.maxWidth - 60 : 600;
        final double currentWidth = _shouldBeExpanded ? maxWidth : 60;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: currentWidth,
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
                
                if (_isFocused)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _borderRotationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PrismaticBorderPainter(
                            animation: _borderRotationController.value,
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
        );
      },
    );
  }

  Widget _buildCollapsedIcon() {
    return Container(
      key: const ValueKey('collapsed'),
      alignment: Alignment.center,
      child: BotanicalLogo(
        size: 32,
        color: AppTheme.primary,
        showPrismaticHalo: false,
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      key: const ValueKey('expanded'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BotanicalLogo(
            size: 28,
            color: _isFocused ? AppTheme.primary : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
            showPrismaticHalo: _isFocused,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: (_) => _submitTask(),
              cursorColor: AppTheme.primary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onBackground,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: _currentPlaceholder,
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
          if (_lastResult != null && _controller.text.isNotEmpty) 
            Flexible(child: _buildVisualFeedback()),
          if (_controller.text.isNotEmpty) ...[
            const SizedBox(width: 12),
            _buildSubmitButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildGhostMenu() {
    final query = ZenParser.getProjectQuery(_controller.text);
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

  Widget _buildSlashMenu() {
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
            children: _slashCommands.map((cmd) => _buildSlashItem(cmd)).toList(),
          ),
        ],
      ),
    ).animate().fade(duration: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildSlashItem(Map<String, dynamic> cmd) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Replace the whole field with the chosen prefix (e.g. "/task ")
          // then re-focus AFTER the frame so Flutter places the cursor correctly.
          _controller.value = TextEditingValue(
            text: cmd['prefix'] as String,
            selection: TextSelection.collapsed(
              offset: (cmd['prefix'] as String).length,
            ),
          );
          setState(() => _showSlashMenu = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusNode.requestFocus();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cmd['icon'] as IconData, size: 18, color: AppTheme.primary),
              const SizedBox(height: 6),
              Text(
                cmd['label'] as String,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostItem(String label) {
    return InkWell(
      onTap: () {
        final parts = _controller.text.split('#');
        parts.removeLast();
        _controller.text = '${parts.join('#')}#$label ';
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(LucideIcons.hash, size: 14, color: AppTheme.primary),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualFeedback() {
    if (_lastResult == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_lastResult!.type != 'text')
          _buildBadge(_lastResult!.type.toUpperCase(), AppTheme.primary),
        const SizedBox(width: 4),
        if (_lastResult!.metadata.containsKey('priority') && _lastResult!.metadata['priority'] < 3)
          _buildBadge('P${_lastResult!.metadata['priority']}', const Color(0xFFFF4D8D)),
        if (_lastResult!.metadata.containsKey('assignee'))
          _buildBadge('@${_lastResult!.metadata['assignee']}', const Color(0xFF2DD4BF)),
        if (_lastResult!.metadata.containsKey('project'))
          _buildBadge('PROJ', AppTheme.primary),
      ],
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

  Widget _buildSuggestiveChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChip('New Task', LucideIcons.plus),
        const SizedBox(width: 16),
        _buildChip('Quick Note', LucideIcons.penTool),
        const SizedBox(width: 16),
        _buildChip('Schedule', LucideIcons.calendar),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        _controller.text = '$label ';
        _focusNode.requestFocus();
      },
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

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submitTask,
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