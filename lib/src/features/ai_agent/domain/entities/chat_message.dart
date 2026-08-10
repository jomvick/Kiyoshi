/// Chat message domain entity used in the AI agent conversation.
library;

enum ChatRole { user, assistant, tool }

enum ToolCallStatus { pending, executing, success, error }

/// Represents one executed tool call (shown as a badge in the UI).
class ToolCallRecord {
  final String toolName;
  final Map<String, dynamic> arguments;
  final String? result;
  final ToolCallStatus status;

  const ToolCallRecord({
    required this.toolName,
    required this.arguments,
    this.result,
    this.status = ToolCallStatus.pending,
  });

  ToolCallRecord copyWith({
    String? result,
    ToolCallStatus? status,
  }) {
    return ToolCallRecord(
      toolName: toolName,
      arguments: arguments,
      result: result ?? this.result,
      status: status ?? this.status,
    );
  }

  /// A human-readable summary for display in the badge.
  String get displaySummary {
    return switch (toolName) {
      'create_task' => '✅ Tâche créée : ${arguments['title'] ?? ''}',
      'create_project' => '📁 Projet créé : ${arguments['title'] ?? ''}',
      'create_workspace' => '🏠 Espace créé : ${arguments['name'] ?? ''}',
      'update_task_status' => '🔄 Tâche mise à jour',
      'list_workspace_content' => '📋 Contenu de l\'espace chargé',
      'add_canvas_note' => '📝 Note ajoutée',
      'summarize_pending_tasks' => '📊 Résumé des tâches',
      _ => '⚡ $toolName',
    };
  }
}

/// A single message in the AI conversation.
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final List<ToolCallRecord> toolCalls;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.toolCalls = const [],
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? content,
    List<ToolCallRecord>? toolCalls,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      toolCalls: toolCalls ?? this.toolCalls,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  factory ChatMessage.user(String content) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content,
          {List<ToolCallRecord> toolCalls = const []}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.assistant,
        content: content,
        timestamp: DateTime.now(),
        toolCalls: toolCalls,
      );

  factory ChatMessage.thinking() => ChatMessage(
        id: 'thinking_${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
}
