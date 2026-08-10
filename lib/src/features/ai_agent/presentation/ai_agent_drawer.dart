/// Kiyoshi AI Agent — Glassmorphic Chat Drawer
///
/// A sliding panel that opens from the right side of the app and provides a
/// full conversational interface to the Kiyoshi AI Agent.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/ai_config.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/chat_message.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/ai_agent_providers.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/widgets/chat_bubble.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/widgets/tool_action_badge.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/ai_settings_dialog.dart';

class AiAgentDrawer extends ConsumerStatefulWidget {
  const AiAgentDrawer({super.key});

  @override
  ConsumerState<AiAgentDrawer> createState() => _AiAgentDrawerState();
}

class _AiAgentDrawerState extends ConsumerState<AiAgentDrawer>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.requestFocus();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final messages = ref.watch(chatProvider);
    final isOpen = ref.watch(aiDrawerOpenProvider);

    if (!isOpen) return const SizedBox.shrink();

    // listen to message changes and scroll
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Positioned.fill(
      child: Stack(
        children: [
          // Blur backdrop
          GestureDetector(
            onTap: () => ref.read(aiDrawerOpenProvider.notifier).state = false,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
              ),
            ),
          ),

          // Drawer panel
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 380,
            child: _buildPanel(isDark, scheme, messages),
          ),
        ],
      ),
    )
        .animate()
        .fade(duration: 200.ms)
        .slideX(begin: 0.05, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildPanel(
      bool isDark, ColorScheme scheme, List<ChatMessage> messages) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.75),
        border: Border(
          left: BorderSide(
            color: scheme.primary.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 48,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              _buildHeader(isDark, scheme),
              Expanded(child: _buildMessageList(isDark, scheme, messages)),
              _buildInputBar(isDark, scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme scheme) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: scheme.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // AI icon with pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A9D84),
                      const Color(0xFF5C8DAE),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A9D84).withValues(
                          alpha: 0.3 +
                              0.2 * _pulseController.value),
                      blurRadius:
                          8 + 6 * _pulseController.value,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 18,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiyoshi AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: scheme.onSurface,
                  ),
                ),
                _AiStatusBadge(),
              ],
            ),
          ),
          // Settings button
          IconButton(
            icon: Icon(LucideIcons.settings2, size: 18, color: scheme.onSurfaceVariant),
            tooltip: 'Configuration IA',
            onPressed: () => AiSettingsDialog.show(context),
          ),
          // Clear chat
          IconButton(
            icon: Icon(LucideIcons.trash2, size: 18, color: scheme.onSurfaceVariant),
            tooltip: 'Effacer la conversation',
            onPressed: () => ref.read(chatProvider.notifier).clearHistory(),
          ),
          // Close
          IconButton(
            icon: Icon(LucideIcons.x, size: 18, color: scheme.onSurfaceVariant),
            tooltip: 'Fermer',
            onPressed: () =>
                ref.read(aiDrawerOpenProvider.notifier).state = false,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
      bool isDark, ColorScheme scheme, List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState(isDark, scheme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatBubble(message: msg, isDark: isDark),
            if (msg.toolCalls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.toolCalls
                    .map((tc) => ToolActionBadge(record: tc))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.bot,
            size: 48,
            color: scheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Demandez-moi n\'importe quoi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Je peux créer des tâches, des projets, résumer votre travail et bien plus encore.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestionChips(scheme),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildSuggestionChips(ColorScheme scheme) {
    const suggestions = [
      '📋 Crée un projet "Refonte site web"',
      '✅ Ajoute 3 tâches prioritaires',
      '📊 Quelles sont mes tâches en attente ?',
      '📝 Ajoute une note dans mon canvas',
    ];

    return Column(
      children: suggestions
          .map((s) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                child: GestureDetector(
                  onTap: () {
                    _controller.text = s.replaceAll(RegExp(r'^[^ ]+ '), '');
                    _send();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildInputBar(bool isDark, ColorScheme scheme) {
    final isLoading = ref.watch(aiIsLoadingProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15)),
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    _send();
                  }
                },
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !isLoading,
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Que puis-je faire pour vous ?',
                    hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: isLoading ? null : (_) => _send(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isLoading
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2A9D84),
                        Color(0xFF5C8DAE),
                      ],
                    ),
              color: isLoading
                  ? scheme.surfaceContainerHigh
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: isLoading ? null : _send,
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : const Icon(
                          LucideIcons.arrowUp,
                          size: 18,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small status badge showing which AI provider is active.
class _AiStatusBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final provider = settings.activeProvider;
    final config = settings.activeConfig;

    final (color, icon) = switch (provider) {
      AiProvider.openAI => (const Color(0xFF10A37F), '🤖'),
      AiProvider.gemini => (const Color(0xFF4285F4), '✨'),
      AiProvider.anthropic => (const Color(0xFFD4A017), '🧠'),
      AiProvider.ollama => (const Color(0xFF6366F1), '🔒'),
    };

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$icon ${config.model}',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
