/// Multi-provider LLM Service for the Kiyoshi AI Agent.
///
/// Handles communication with:
///   - OpenAI (GPT-4o-mini, GPT-4o, …)
///   - Google Gemini (gemini-2.0-flash, …)
///   - Anthropic Claude (claude-3-5-haiku, …)
///   - Ollama (local llama3.2, mistral, …)
///
/// Implements the tool-calling loop:
///   User message → LLM → Tool calls → Execute → Tool results → LLM → Response
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kiyoshi/src/features/ai_agent/data/agent_tool_registry.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/ai_config.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/chat_message.dart';
import 'package:kiyoshi/src/core/database/project_repository.dart';

typedef ToolCallHandler = Future<String> Function(
    String toolName, Map<String, dynamic> args);

/// Result from one call to the LLM service.
class LlmResponse {
  final String text;
  final List<ToolCallRecord> toolCalls;

  const LlmResponse({required this.text, this.toolCalls = const []});
}

class LlmService {
  final AiSettings settings;
  final ProjectRepository repository;

  LlmService({required this.settings, required this.repository});

  AiProviderConfig get _cfg => settings.activeConfig;

  List<Map<String, dynamic>> get _tools =>
      AgentToolRegistry.all.map((t) => t.toOpenAiFunction()).toList();

  List<Map<String, dynamic>> get _anthropicTools =>
      AgentToolRegistry.all.map((t) => t.toAnthropicTool()).toList();

  List<Map<String, dynamic>> get _geminiTools => [
        {
          'functionDeclarations': AgentToolRegistry.all
              .map((t) => t.toGeminiFunctionDeclaration())
              .toList(),
        }
      ];

  /// Send a chat to the active provider, executing any tool calls that come back.
  /// Returns the final assistant text + records of all tool calls.
  Future<LlmResponse> chat(List<ChatMessage> history, String userMessage) async {
    return switch (settings.activeProvider) {
      AiProvider.openAI => _chatOpenAiCompat(history, userMessage),
      AiProvider.ollama => _chatOpenAiCompat(history, userMessage),
      AiProvider.anthropic => _chatAnthropic(history, userMessage),
      AiProvider.gemini => _chatGemini(history, userMessage),
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OpenAI-compatible (also used for Ollama which mirrors the OpenAI API)
  // ──────────────────────────────────────────────────────────────────────────

  Future<LlmResponse> _chatOpenAiCompat(
      List<ChatMessage> history, String userMessage) async {
    final isOllama = settings.activeProvider == AiProvider.ollama;
    final baseUrl = _cfg.baseUrl;
    final model = _cfg.model;

    final systemPrompt = _buildSystemPrompt();
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map(_toChatGptMessage),
      {'role': 'user', 'content': userMessage},
    ];

    final toolCallRecords = <ToolCallRecord>[];
    String finalText = '';
    int maxIterations = 6;

    while (maxIterations-- > 0) {
      final body = {
        'model': model,
        'messages': messages,
        if (!isOllama || _cfg.model.contains('llama') || _cfg.model.contains('qwen'))
          'tools': _tools,
        'temperature': 0.4,
      };

      final response = await _post(
        '$baseUrl/chat/completions',
        body,
        isOllama ? null : _cfg.apiKey,
      );

      final choice = response['choices']?[0];
      final msg = choice?['message'] as Map<String, dynamic>?;
      if (msg == null) {
        finalText = 'Erreur: réponse vide du modèle.';
        break;
      }

      final toolCalls = msg['tool_calls'] as List<dynamic>?;

      if (toolCalls == null || toolCalls.isEmpty) {
        finalText = msg['content'] as String? ?? '';
        break;
      }

      // Execute tool calls
      messages.add({
        'role': 'assistant',
        'tool_calls': toolCalls,
        'content': msg['content'],
      });

      for (final tc in toolCalls) {
        final fn = tc['function'] as Map<String, dynamic>;
        final toolName = fn['name'] as String;
        final args = jsonDecode(fn['arguments'] as String) as Map<String, dynamic>;
        final callId = tc['id'] as String;

        final record = ToolCallRecord(
          toolName: toolName,
          arguments: args,
          status: ToolCallStatus.executing,
        );

        String result;
        ToolCallStatus status;
        try {
          result = await _executeTool(toolName, args);
          status = ToolCallStatus.success;
        } catch (e) {
          result = 'Error executing $toolName: $e';
          status = ToolCallStatus.error;
          debugPrint('[KiyoshiAI] Tool error: $e');
        }

        toolCallRecords.add(record.copyWith(result: result, status: status));
        messages.add({
          'role': 'tool',
          'tool_call_id': callId,
          'content': result,
        });
      }
    }

    return LlmResponse(text: finalText, toolCalls: toolCallRecords);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Anthropic Claude
  // ──────────────────────────────────────────────────────────────────────────

  Future<LlmResponse> _chatAnthropic(
      List<ChatMessage> history, String userMessage) async {
    final model = _cfg.model;
    final toolCallRecords = <ToolCallRecord>[];

    final messages = [
      ...history.map(_toAnthropicMessage),
      {'role': 'user', 'content': userMessage},
    ];

    String finalText = '';
    int maxIterations = 6;

    while (maxIterations-- > 0) {
      final body = {
        'model': model,
        'max_tokens': 1024,
        'system': _buildSystemPrompt(),
        'tools': _anthropicTools,
        'messages': messages,
      };

      final response = await _post(
        '${_cfg.baseUrl}/messages',
        body,
        _cfg.apiKey,
        headers: {
          'anthropic-version': '2023-06-01',
          'x-api-key': _cfg.apiKey,
          'content-type': 'application/json',
        },
      );

      final stopReason = response['stop_reason'] as String?;
      final content = response['content'] as List<dynamic>? ?? [];

      if (stopReason != 'tool_use') {
        finalText = content
            .where((c) => c['type'] == 'text')
            .map((c) => c['text'] as String)
            .join('');
        break;
      }

      // Process tool uses
      messages.add({'role': 'assistant', 'content': content});
      final toolResults = <Map<String, dynamic>>[];

      for (final block in content) {
        if (block['type'] != 'tool_use') continue;
        final toolName = block['name'] as String;
        final args = block['input'] as Map<String, dynamic>;
        final useId = block['id'] as String;

        final record = ToolCallRecord(toolName: toolName, arguments: args, status: ToolCallStatus.executing);
        String result;
        ToolCallStatus status;
        try {
          result = await _executeTool(toolName, args);
          status = ToolCallStatus.success;
        } catch (e) {
          result = 'Error: $e';
          status = ToolCallStatus.error;
        }
        toolCallRecords.add(record.copyWith(result: result, status: status));
        toolResults.add({'type': 'tool_result', 'tool_use_id': useId, 'content': result});
      }

      messages.add({'role': 'user', 'content': toolResults});
    }

    return LlmResponse(text: finalText, toolCalls: toolCallRecords);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Google Gemini
  // ──────────────────────────────────────────────────────────────────────────

  Future<LlmResponse> _chatGemini(
      List<ChatMessage> history, String userMessage) async {
    final rawModel = _cfg.model.trim();
    final model = rawModel.startsWith('models/')
        ? rawModel.substring(7)
        : (rawModel.isEmpty ? 'gemini-2.0-flash' : rawModel);

    final candidateModels = [
      model,
      if (model == 'gemini-1.5-flash') 'gemini-1.5-flash-latest',
      if (model != 'gemini-2.0-flash') 'gemini-2.0-flash',
    ].toSet().toList();

    for (int mIndex = 0; mIndex < candidateModels.length; mIndex++) {
      final currentModel = candidateModels[mIndex];
      try {
        return await _chatGeminiWithModel(history, userMessage, currentModel);
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('404') && mIndex < candidateModels.length - 1) {
          debugPrint(
              '[KiyoshiAI] Model $currentModel returned 404, auto-retrying with ${candidateModels[mIndex + 1]}');
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Gemini API call failed for model $model.');
  }

  Future<LlmResponse> _chatGeminiWithModel(
      List<ChatMessage> history, String userMessage, String model) async {
    final apiKey = _cfg.apiKey.trim();
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final toolCallRecords = <ToolCallRecord>[];
    String finalText = '';
    int maxIterations = 6;

    final contents = <Map<String, dynamic>>[
      ...history.map(_toGeminiContent),
      {
        'role': 'user',
        'parts': [{'text': userMessage}],
      },
    ];

    while (maxIterations-- > 0) {
      final body = {
        'system_instruction': {
          'parts': [{'text': _buildSystemPrompt()}]
        },
        'contents': contents,
        'tools': _geminiTools,
        'generationConfig': {'temperature': 0.4},
      };

      final response = await _post(url, body, null);
      final candidate = (response['candidates'] as List<dynamic>?)?.firstOrNull;
      final parts = (candidate?['content']?['parts'] as List<dynamic>?) ?? [];

      final functionCalls =
          parts.where((p) => p['functionCall'] != null).toList();

      if (functionCalls.isEmpty) {
        finalText = parts
            .where((p) => p['text'] != null)
            .map((p) => p['text'] as String)
            .join('');
        break;
      }

      // Add model turn
      contents.add({'role': 'model', 'parts': parts});
      final responseParts = <Map<String, dynamic>>[];

      for (final part in functionCalls) {
        final fc = part['functionCall'] as Map<String, dynamic>;
        final toolName = fc['name'] as String;
        final args = fc['args'] as Map<String, dynamic>? ?? {};

        final record = ToolCallRecord(toolName: toolName, arguments: args, status: ToolCallStatus.executing);
        String result;
        ToolCallStatus status;
        try {
          result = await _executeTool(toolName, args);
          status = ToolCallStatus.success;
        } catch (e) {
          result = 'Error: $e';
          status = ToolCallStatus.error;
        }
        toolCallRecords.add(record.copyWith(result: result, status: status));
        responseParts.add({
          'functionResponse': {
            'name': toolName,
            'response': {'result': result},
          }
        });
      }

      contents.add({'role': 'user', 'parts': responseParts});
    }

    return LlmResponse(text: finalText, toolCalls: toolCallRecords);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _executeTool(
      String toolName, Map<String, dynamic> args) async {
    final tool = AgentToolRegistry.all.firstWhere(
      (t) => t.name == toolName,
      orElse: () => throw Exception('Unknown tool: $toolName'),
    );
    return tool.execute(args, repository);
  }

  String _buildSystemPrompt() {
    return settings.systemPrompt.replaceAll(
      '{{date}}',
      DateTime.now().toLocal().toString().split(' ').first,
    );
  }

  Map<String, dynamic> _toChatGptMessage(ChatMessage msg) => {
        'role': msg.role == ChatRole.user ? 'user' : 'assistant',
        'content': msg.content,
      };

  Map<String, dynamic> _toAnthropicMessage(ChatMessage msg) => {
        'role': msg.role == ChatRole.user ? 'user' : 'assistant',
        'content': msg.content,
      };

  Map<String, dynamic> _toGeminiContent(ChatMessage msg) => {
        'role': msg.role == ChatRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ],
      };

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
    String? bearerToken, {
    Map<String, String>? headers,
  }) async {
    final effectiveHeaders = {
      'content-type': 'application/json',
      if (bearerToken != null && bearerToken.isNotEmpty)
        'authorization': 'Bearer $bearerToken',
      if (headers != null) ...headers,
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: effectiveHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[KiyoshiAI] HTTP ${response.statusCode}: ${response.body}');
      throw Exception(
          'LLM API error ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
