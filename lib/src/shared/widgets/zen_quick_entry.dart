import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/shared/widgets/zen_glass_card.dart';
import 'package:kiyoshi/src/core/constants/zen_typography.dart';
import 'package:kiyoshi/src/shared/widgets/smart_bar_controller.dart';
import 'package:kiyoshi/src/core/design_system/kiyoshi_zen_tokens.dart';
import 'package:kiyoshi/src/shared/widgets/prismatic_border_painter.dart';

class ZenQuickEntry extends StatefulWidget {
  final Function(String title, DateTime? date, String? project, int priority) onTaskCreated;
  final Function(String type, String content, Map<String, dynamic> metadata)? onBlockCreated;
  final FocusNode? focusNode;
  final bool isDashboard;
  final List<String> projectList;
  final Future<String?> Function(String)? onCreateProject;

  const ZenQuickEntry({
    super.key, 
    required this.onTaskCreated, 
    this.onBlockCreated,
    this.focusNode,
    this.isDashboard = true,
    this.projectList = const [],
    this.onCreateProject,
  });

  @override
  State<ZenQuickEntry> createState() => _ZenQuickEntryState();
}

class _ZenQuickEntryState extends State<ZenQuickEntry> with TickerProviderStateMixin {
  final SmartBarController _controller = SmartBarController();
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isManuallyExpanded = false;
  
  final List<String> _placeholders = [
    'What is your next focus?',
    'A new milestone awaits...',
    'Capture a spark of genius',
    'Assign a priority to your peace',
    'One breath, one task',
  ];
  late String _currentPlaceholder;
  
  ParsedBlock? _lastResult;
  bool _showGhostMenu = false;
  bool _showSlashMenu = false;
  late List<String> _projectSuggestions;
  
  final List<Map<String, dynamic>> _slashCommands = [
    {'icon': LucideIcons.type, 'label': 'Text', 'color': AppTheme.primary},
    {'icon': LucideIcons.heading, 'label': 'Heading', 'color': const Color(0xFF5EEAD4)},
    {'icon': LucideIcons.checkSquare, 'label': 'Todo', 'color': const Color(0xFF7C8CFF)},
    {'icon': LucideIcons.link, 'label': 'Link', 'color': AppTheme.primary},
    {'icon': LucideIcons.image, 'label': 'Image', 'color': const Color(0xFFFF6B9A)},
  ];

  /// Mode commande actif
  Map<String, dynamic>? _activeCommand;

  late AnimationController _borderRotationController;

  @override
  void initState() {
    super.initState();
    _currentPlaceholder = _placeholders[DateTime.now().second % _placeholders.length];
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Initialize project list from props or defaults
    _projectSuggestions = widget.projectList.isNotEmpty 
        ? widget.projectList 
        : ['Design', 'Marketing', 'Core', 'Vision', 'Calm'];

    _borderRotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _borderRotationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    setState(() {
      _lastResult = ZenParser.parseRawInput(text);
      _showGhostMenu = ZenParser.isProjectIntent(text);
      // Only show slash menu while user is still choosing (no space after command yet)
      _showSlashMenu = ZenParser.isSlashIntent(text);
    });
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _borderRotationController.repeat();
      } else {
        _borderRotationController.stop();
        if (!widget.isDashboard) {
          _isManuallyExpanded = false;
        }
      }
    });
  }

  void _submitTask() async {
    final contentText = _controller.text.trim();
    // En mode commande, on ajoute le préfixe pour le parser
    final label = _activeCommand?['label']?.toString().toLowerCase() ?? '';
    
  String rawText;
  if (label.isNotEmpty && contentText.isNotEmpty) {
    if (label == 'heading') {
      rawText = '# $contentText';
    } else if (label == 'todo') {
      rawText = '- [ ] $contentText';
    } else if (label == 'image') {
      rawText = '/img $contentText';
    } else if (label == 'link') {
      rawText = contentText.startsWith('http') ? contentText : 'https://$contentText';
    } else {
      rawText = contentText;
    }
  } else {
    rawText = contentText;
  }

    if (rawText.isEmpty) return;
    
    final parsed = ZenParser.parseRawInput(rawText);
    final projectName = parsed.metadata['project'] as String?;
    
    // Handle project: create if doesn't exist
    if (projectName != null && widget.onCreateProject != null) {
      final exists = _projectSuggestions.any(
        (p) => p.toLowerCase() == projectName.toLowerCase(),
      );
      
      if (!exists) {
        final createdId = await widget.onCreateProject!(projectName);
        if (createdId != null) {
          setState(() {
            _projectSuggestions = [..._projectSuggestions, projectName];
          });
        }
      }
    }
    
    if (widget.onBlockCreated != null) {
      widget.onBlockCreated!(
        parsed.type,
        parsed.content,
        parsed.metadata,
      );
    } else {
      widget.onTaskCreated(
        parsed.content,
        null,
        parsed.metadata['project'],
        parsed.metadata['priority'] ?? 3,
      );
    }
    
    setState(() {
      _currentPlaceholder = _placeholders[DateTime.now().second % _placeholders.length];
      if (!widget.isDashboard) _isManuallyExpanded = false;
      _showSlashMenu = false;
      _activeCommand = null;
    });
    _controller.clear();
    _focusNode.unfocus();
  }

  bool get shouldBeExpanded => widget.isDashboard || _isFocused || _isManuallyExpanded;
  bool get isVisualActive => _isFocused || _isManuallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showGhostMenu && shouldBeExpanded)
          _buildGhostMenu(),

        if (_showSlashMenu && shouldBeExpanded)
          _buildSlashMenu(),
        
        GestureDetector(
          onTap: () {
            if (!shouldBeExpanded) {
              setState(() => _isManuallyExpanded = true);
              _focusNode.requestFocus();
            }
          },
          child: _buildPrismaticBar(),
        ),

        if (shouldBeExpanded && !_isFocused && _controller.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildSuggestiveChips(),
          ),
      ],
    );
  }

  Widget _buildPrismaticBar() {
    // Center and cap width — never stretch across the full page.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
          width: shouldBeExpanded ? double.infinity : 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(shouldBeExpanded ? 20 : 30),
            boxShadow: [
              if (isVisualActive || (widget.isDashboard && !_isFocused))
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(shouldBeExpanded ? 20 : 30),
            child: Stack(
              children: [
                ZenGlassCard(
                  radius: shouldBeExpanded ? 20 : 30,
                  opacity: isVisualActive ? 0.98 : (widget.isDashboard ? 0.4 : 0.05),
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
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  child: shouldBeExpanded
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
    return Center(
      key: const ValueKey('collapsed'),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.plus,
          size: 18,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final cmd = _activeCommand;
    final cmdColor = cmd != null ? (cmd['color'] as Color? ?? AppTheme.primary) : AppTheme.primary;
    final hintText = cmd != null ? 'Write your ${cmd['label'].toString().toLowerCase()}...' : _currentPlaceholder;

    return Container(
      key: const ValueKey('expanded'),
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge de commande
          if (cmd != null) ...[
            GestureDetector(
              onTap: () {
                setState(() => _activeCommand = null);
                _controller.clear();
                _focusNode.requestFocus();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cmdColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cmdColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cmd['label'].toString().toUpperCase(),
                      style: TextStyle(
                        color: cmdColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(LucideIcons.x, size: 10, color: cmdColor.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ).animate().fade(duration: 150.ms).scale(begin: const Offset(0.85, 0.85)),
            const SizedBox(width: 8),
          ],

          // Champ de texte
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
          // Badges de feedback visuel
          if (cmd == null && _isFocused && _lastResult != null)
            _buildVisualFeedback(),
          // Bouton de validation
          if (_isFocused || cmd != null) ...[
            const SizedBox(width: 8),
            _buildSubmitButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildGhostMenu() {
    final query = _controller.text.split('#').last;
    final queryLower = query.toLowerCase();
    final filtered = _projectSuggestions.where((p) => p.toLowerCase().contains(queryLower)).toList();
    
    // Show "create" option if typed project doesn't exist and has input
    final hasExactMatch = _projectSuggestions.any((p) => p.toLowerCase() == queryLower);
    final showCreateOption = query.isNotEmpty && !hasExactMatch && widget.onCreateProject != null;

    if (filtered.isEmpty && !showCreateOption) return const SizedBox.shrink();

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
          children: [
            ...filtered.map((p) => _buildGhostItem(p)),
            if (showCreateOption)
              _buildGhostItem(query, isNew: true),
          ],
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
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
    final color = cmd['color'] as Color? ?? AppTheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Activer le mode commande : badge visible, champ vidé et focus
          setState(() {
            _activeCommand = cmd;
            _showSlashMenu = false;
          });
          _controller.clear();
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
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cmd['icon'] as IconData, size: 18, color: color),
              const SizedBox(height: 6),
              Text(
                cmd['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostItem(String label, {bool isNew = false}) {
    return InkWell(
      onTap: () async {
        final parts = _controller.text.split('#');
        parts.removeLast();
        
        if (isNew && widget.onCreateProject != null) {
          // Create the new project
          final projectName = _controller.text.split('#').last.trim();
          await widget.onCreateProject!(projectName);
          // Add to suggestions
          setState(() {
            _projectSuggestions = [..._projectSuggestions, projectName];
          });
        }
        
        final newText = isNew 
            ? '${parts.join('#')}#${_controller.text.split('#').last.trim()} '
            : '${parts.join('#')}#$label ';
        final cursorPos = newText.length;
        
        setState(() => _showGhostMenu = false);
        
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: cursorPos);
        _focusNode.requestFocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              isNew ? LucideIcons.plus : LucideIcons.hash,
              size: 14,
              color: isNew ? Colors.green : AppTheme.primary,
            ),
            const SizedBox(width: 14),
            Text(
              isNew ? 'Create "$label"' : label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isNew ? Colors.green : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualFeedback() {
    if (_lastResult == null) return const SizedBox.shrink();
    // Constrain badges to max 130px so they never crowd the submit button.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_lastResult!.type != 'text')
              _buildBadge(_lastResult!.type.toUpperCase(), AppTheme.primary),
            if (_lastResult!.metadata.containsKey('priority') &&
                _lastResult!.metadata['priority'] < 3) ...[
              const SizedBox(width: 4),
              _buildBadge('P${_lastResult!.metadata['priority']}', const Color(0xFFFF4D8D)),
            ],
            if (_lastResult!.metadata.containsKey('assignee')) ...[
              const SizedBox(width: 4),
              _buildBadge('@${_lastResult!.metadata['assignee']}', const Color(0xFF2DD4BF)),
            ],
            if (_lastResult!.metadata.containsKey('project')) ...[
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
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.onBackground.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: AppTheme.onBackground.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
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