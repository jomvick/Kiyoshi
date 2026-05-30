import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class Command {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;
  final VoidCallback onExecute;
  final Color? accentColor;

  Command({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.keywords,
    required this.onExecute,
    this.accentColor,
  });
}

class CommandPalette extends StatefulWidget {
  final List<Command> commands;
  final VoidCallback onClose;

  const CommandPalette({
    super.key,
    required this.commands,
    required this.onClose,
  });

  static void show(BuildContext context, {required List<Command> commands}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => CommandPalette(
        commands: commands,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<Command> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredCommands = widget.commands;
    _searchController.addListener(_onSearchChanged);

    // Focus the search field after animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCommands = widget.commands.where((command) {
        return command.title.toLowerCase().contains(query) ||
            command.subtitle.toLowerCase().contains(query) ||
            command.keywords.any((k) => k.toLowerCase().contains(query));
      }).toList();
      _selectedIndex = 0;
    });
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          _moveSelection(1);
          break;
        case LogicalKeyboardKey.arrowUp:
          _moveSelection(-1);
          break;
        case LogicalKeyboardKey.enter:
          if (_filteredCommands.isNotEmpty) {
            _executeCommand(_filteredCommands[_selectedIndex]);
          }
          break;
        case LogicalKeyboardKey.escape:
          widget.onClose();
          break;
      }
    }
  }

  void _moveSelection(int delta) {
    if (_filteredCommands.isEmpty) return;

    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(
        0,
        _filteredCommands.length - 1,
      );
    });

    // Guard: the ListView may not be mounted yet (e.g. opened with keyboard
    // shortcut before the 100 ms focus delay) or replaced by the empty state.
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    const itemExtent = 64.0;
    final offset = (_selectedIndex * itemExtent).clamp(0.0, maxScroll);
    _scrollController.animateTo(
      offset,
      duration: AppTheme.animFast,
      curve: Curves.easeOutCubic,
    );
  }

  void _executeCommand(Command command) {
    widget.onClose();
    Future.delayed(AppTheme.animFastest, () {
      // Guard: the widget tree may have been rebuilt or the command
      // callback may reference disposed state.
      if (!mounted) return;
      command.onExecute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child:
              Container(
                  width: 600,
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: AppTheme.getBlur(BlurDensity.high),
                        sigmaY: AppTheme.getBlur(BlurDensity.high),
                      ),
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMedium),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.search,
                                size: 20,
                                color: AppTheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppTheme.spaceSmall),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _focusNode,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'Type a command or search...',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceSmall),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.command,
                                      size: 12,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'K',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Commands list
                        Flexible(
                          child: _filteredCommands.isEmpty
                              ? _buildEmptyState()
                              : _buildCommandsList(),
                        ),

                        // Footer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMedium,
                            vertical: AppTheme.spaceSmall,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildFooterHint(
                                icon: LucideIcons.arrowUp,
                                label: 'Navigate',
                              ),
                              const SizedBox(width: AppTheme.spaceMedium),
                              _buildFooterHint(
                                icon: LucideIcons.cornerDownLeft,
                                label: 'Select',
                              ),
                              const SizedBox(width: AppTheme.spaceMedium),
                              _buildFooterHint(
                                icon: LucideIcons.x,
                                label: 'Close',
                              ),
                              const Spacer(),
                              Text(
                                '${_filteredCommands.length} commands',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
                .fade(duration: AppTheme.animMedium)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  duration: AppTheme.animMedium,
                  curve: Curves.easeOutBack,
                ),
        ),
      ),
    );
  }

  Widget _buildCommandsList() {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _filteredCommands.length,
      itemBuilder: (context, index) {
        final command = _filteredCommands[index];
        final isSelected = index == _selectedIndex;

        return _CommandItem(
              command: command,
              isSelected: isSelected,
              onTap: () => _executeCommand(command),
            )
            .animate()
            .fade(duration: AppTheme.animFast)
            .slideX(
              begin: -0.05,
              duration: AppTheme.animFast,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.searchX, size: 48, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'No commands found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Try a different search term',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterHint({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, size: 12, color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CommandItem extends StatefulWidget {
  final Command command;
  final bool isSelected;
  final VoidCallback onTap;

  const _CommandItem({
    required this.command,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CommandItem> createState() => _CommandItemState();
}

class _CommandItemState extends State<_CommandItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = widget.isSelected || _isHovering;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceSmall,
            vertical: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
          decoration: BoxDecoration(
            color: effectiveSelected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: effectiveSelected
                ? Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (widget.command.accentColor ?? AppTheme.primary)
                          .withValues(alpha: 0.3),
                      (widget.command.accentColor ?? AppTheme.primary)
                          .withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  widget.command.icon,
                  size: 18,
                  color: widget.command.accentColor ?? AppTheme.primary,
                ),
              ),

              const SizedBox(width: AppTheme.spaceSmall),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.command.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: effectiveSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: effectiveSelected
                            ? AppTheme.onBackground
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      widget.command.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              if (effectiveSelected)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppTheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
