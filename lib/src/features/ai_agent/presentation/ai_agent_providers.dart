/// Riverpod providers for the AI Agent feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/features/ai_agent/data/ai_settings_repository.dart';
import 'package:kiyoshi/src/features/ai_agent/data/llm_service.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/ai_config.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/chat_message.dart';

// ─── Settings ─────────────────────────────────────────────────────────────

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiSettingsRepository(prefs);
});

final aiSettingsProvider =
    NotifierProvider<AiSettingsNotifier, AiSettings>(AiSettingsNotifier.new);

class AiSettingsNotifier extends Notifier<AiSettings> {
  @override
  AiSettings build() {
    return ref.read(aiSettingsRepositoryProvider).load();
  }

  Future<void> setActiveProvider(AiProvider provider) async {
    state = state.copyWith(activeProvider: provider);
    await ref.read(aiSettingsRepositoryProvider).save(state);
  }

  Future<void> updateProviderConfig(AiProviderConfig config) async {
    state = state.withProviderConfig(config);
    await ref.read(aiSettingsRepositoryProvider).save(state);
  }

  Future<void> setSystemPrompt(String prompt) async {
    state = state.copyWith(systemPrompt: prompt);
    await ref.read(aiSettingsRepositoryProvider).save(state);
  }

  Future<void> setAutoExecute(bool value) async {
    state = state.copyWith(autoExecute: value);
    await ref.read(aiSettingsRepositoryProvider).save(state);
  }
}

// ─── LLM Service ──────────────────────────────────────────────────────────

final llmServiceProvider = Provider<LlmService>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  final repo = ref.watch(projectRepositoryProvider);
  return LlmService(settings: settings, repository: repo);
});

// ─── Chat Loading State ───────────────────────────────────────────────────

final aiIsLoadingProvider = StateProvider<bool>((ref) => false);

// ─── Chat Conversation ────────────────────────────────────────────────────

final chatProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (ref.read(aiIsLoadingProvider)) return;
    ref.read(aiIsLoadingProvider.notifier).state = true;

    // Add user message
    final userMsg = ChatMessage.user(text.trim());
    state = [...state, userMsg];

    // Add thinking placeholder
    final thinking = ChatMessage.thinking();
    state = [...state, thinking];

    try {
      final llm = ref.read(llmServiceProvider);
      // Build history excluding the thinking placeholder
      final history = state
          .where((m) => !m.isStreaming && m.id != thinking.id)
          .toList();

      final response = await llm.chat(history, text.trim());

      state = [
        ...state.where((m) => m.id != thinking.id),
        ChatMessage.assistant(response.text, toolCalls: response.toolCalls),
      ];
    } catch (e) {
      state = [
        ...state.where((m) => m.id != thinking.id),
        ChatMessage.assistant(
            '⚠️ Erreur de connexion au modèle IA.\n\n$e\n\nVérifiez votre configuration dans les paramètres IA.'),
      ];
    } finally {
      ref.read(aiIsLoadingProvider.notifier).state = false;
    }
  }

  void clearHistory() {
    state = [];
  }
}

// ─── Drawer state ─────────────────────────────────────────────────────────

final aiDrawerOpenProvider = StateProvider<bool>((ref) => false);
