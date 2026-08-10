import 'package:flutter_test/flutter_test.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/ai_config.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/chat_message.dart';
import 'package:kiyoshi/src/features/ai_agent/data/agent_tool_registry.dart';
import 'package:kiyoshi/src/features/ai_agent/presentation/ai_agent_providers.dart';

void main() {
  group('AI Agent Config & Entities', () {
    test('AiProvider has valid names and default base URLs', () {
      expect(AiProvider.openAI.displayName, 'OpenAI');
      expect(AiProvider.ollama.isLocal, true);
      expect(AiProvider.openAI.isLocal, false);
      expect(AiProvider.gemini.defaultBaseUrl, contains('googleapis.com'));
    });

    test('AiProviderConfig default models work per provider', () {
      final configOllama = AiProviderConfig(
        provider: AiProvider.ollama,
        model: AiProviderConfig.defaultModelFor(AiProvider.ollama),
      );
      expect(configOllama.model, 'llama3.2');
      expect(configOllama.baseUrl, 'http://localhost:11434');

      final configOpenAI = AiProviderConfig(
        provider: AiProvider.openAI,
        model: AiProviderConfig.defaultModelFor(AiProvider.openAI),
      );
      expect(configOpenAI.model, 'gpt-4o-mini');
    });

    test('AiSettings serialization and deserialization', () {
      const settings = AiSettings(
        activeProvider: AiProvider.ollama,
        autoExecute: true,
      );

      final json = settings.toJson();
      expect(json['activeProvider'], 'ollama');
      expect(json['autoExecute'], true);

      final restored = AiSettings.fromJson(json);
      expect(restored.activeProvider, AiProvider.ollama);
      expect(restored.autoExecute, true);
    });

    test('ChatMessage models user and assistant messages', () {
      final userMsg = ChatMessage.user('Create a task');
      expect(userMsg.role, ChatRole.user);
      expect(userMsg.content, 'Create a task');
      expect(userMsg.isStreaming, false);

      final assistantMsg = ChatMessage.assistant('Task created!');
      expect(assistantMsg.role, ChatRole.assistant);
      expect(assistantMsg.content, 'Task created!');

      final thinking = ChatMessage.thinking();
      expect(thinking.isStreaming, true);
    });

    test('AgentToolRegistry contains all required native tools', () {
      final tools = AgentToolRegistry.all;
      final toolNames = tools.map((t) => t.name).toList();

      expect(toolNames, contains('create_task'));
      expect(toolNames, contains('update_task_status'));
      expect(toolNames, contains('create_project'));
      expect(toolNames, contains('create_workspace'));
      expect(toolNames, contains('list_workspace_content'));
      expect(toolNames, contains('add_canvas_note'));
      expect(toolNames, contains('summarize_pending_tasks'));
    });

    test('AgentTool exports OpenAI schema correctly', () {
      final tool = AgentToolRegistry.all.firstWhere((t) => t.name == 'create_task');
      final schema = tool.toOpenAiFunction();

      expect(schema['type'], 'function');
      expect(schema['function']['name'], 'create_task');
      expect(schema['function']['parameters']['required'], contains('title'));
    });

    test('AgentTool exports Gemini schema with uppercase types and string enums', () {
      final tool = AgentToolRegistry.all.firstWhere((t) => t.name == 'create_task');
      final geminiSchema = tool.toGeminiFunctionDeclaration();

      expect(geminiSchema['name'], 'create_task');
      final params = geminiSchema['parameters'] as Map<String, dynamic>;
      expect(params['type'], 'OBJECT');
      final priorityProp = params['properties']['priority'] as Map<String, dynamic>;
      expect(priorityProp['type'], 'INTEGER');
      final enumValues = priorityProp['enum'] as List;
      for (final val in enumValues) {
        expect(val, isA<String>());
      }
    });
  });

  group('AI Agent Providers', () {
    test('AI Riverpod providers exist and are typed correctly', () {
      expect(aiSettingsRepositoryProvider, isNotNull);
      expect(aiSettingsProvider, isNotNull);
      expect(llmServiceProvider, isNotNull);
      expect(chatProvider, isNotNull);
      expect(aiDrawerOpenProvider, isNotNull);
      expect(aiIsLoadingProvider, isNotNull);
    });
  });
}
