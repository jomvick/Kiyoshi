import 'dart:convert';

/// Represents the raw parsed result before saving to DB.
class ParsedBlock {
  final String type;
  final String content;
  final Map<String, dynamic> metadata;
  final String? parentId;

  ParsedBlock({
    required this.type,
    required this.content,
    this.metadata = const {},
    this.parentId,
  });
}

/// The pure logic processor for Kiyoshi.
/// Identifies intent from raw text and structures it into a ParsedBlock.
class ZenParser {
  // Pre-compiled Regular Expressions for performance
  static final _imageExtRegex = RegExp(r'\.(jpeg|jpg|gif|png|webp)(\?.*)?$', caseSensitive: false);
  static final _priorityRegex = RegExp(r'!([1-4])');
  static final _assigneeRegex = RegExp(r'@(\w+)');
  static final _projectRegex = RegExp(r'#(\w+)');

  /// Analyzes raw input synchronously and returns a structured Block representation.
  static ParsedBlock parseRawInput(String input) {
    String text = input.trim();
    if (text.isEmpty) {
      return ParsedBlock(type: 'text', content: '');
    }

    final Map<String, dynamic> metadata = {};

    // 0. Detect Slash Command Intent
    String intent = 'text';
    final slashCmdMatch = RegExp(r'^\/(note|task|event|schedule|project)\b', caseSensitive: false).firstMatch(text);
    if (slashCmdMatch != null) {
      final cmd = slashCmdMatch.group(1)!.toLowerCase();
      if (cmd == 'note') intent = 'text';
      if (cmd == 'task') intent = 'todo';
      if (cmd == 'event' || cmd == 'schedule') intent = 'event';
      if (cmd == 'project') intent = 'project';
      
      text = text.replaceFirst(slashCmdMatch.group(0)!, '').trim();
      metadata['intent'] = intent;
    }

    // 0b. Detect Date & Time
    final dateMatch = RegExp(r'\b(today|tomorrow|tonight)\b', caseSensitive: false).firstMatch(text);
    if (dateMatch != null) {
      metadata['date_str'] = dateMatch.group(1)!.toLowerCase();
      text = text.replaceFirst(dateMatch.group(0)!, '').trim();
    }

    final timeMatch = RegExp(r'\bat\s+(\d{1,2}(?::\d{2})?(?:\s?[ap]m)?)\b', caseSensitive: false).firstMatch(text);
    if (timeMatch != null) {
      metadata['time_str'] = timeMatch.group(1)!.toLowerCase();
      text = text.replaceFirst(timeMatch.group(0)!, '').trim();
    }

    // 1. Detect Code block (``` prefix)
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      String? language;
      String code;

      // Extract language from first line if present: ```dart
      final firstLine = lines.first.substring(3).trim();
      if (firstLine.isNotEmpty && !firstLine.contains(' ')) {
        language = firstLine;
        code = lines.skip(1).join('\n').trim();
      } else {
        code = lines.skip(1).join('\n').trim();
      }

      // Remove trailing ``` if present
      if (code.endsWith('```')) {
        code = code.substring(0, code.length - 3).trim();
      }

      if (language != null) metadata['language'] = language;

      return ParsedBlock(
        type: 'code',
        content: code.isNotEmpty ? code : text,
        metadata: metadata,
      );
    }

    // 2. Detect Image or Link
    final isImage = text.startsWith('/img ') || 
                    _imageExtRegex.hasMatch(text);
    
    if (text.startsWith('http://') || text.startsWith('https://') || text.startsWith('/img ')) {
      String content = text;
      if (text.startsWith('/img ')) {
        content = text.substring(5).trim();
      }
      
      return ParsedBlock(
        type: isImage ? 'image' : 'link',
        content: content,
        metadata: isImage ? {} : {'status': 'pending_metadata'},
      );
    }

    // 3. Extract Priority (!1, !2, !3, !4)
    final priorityMatch = _priorityRegex.firstMatch(text);
    if (priorityMatch != null) {
      metadata['priority'] = int.parse(priorityMatch.group(1)!);
      text = text.replaceFirst(priorityMatch.group(0)!, '').trim();
    }

    // 4. Extract Assignee (@name)
    final assigneeMatch = _assigneeRegex.firstMatch(text);
    if (assigneeMatch != null) {
      metadata['assignee'] = assigneeMatch.group(1);
      text = text.replaceFirst(assigneeMatch.group(0)!, '').trim();
    }

    // 5. Extract Project (#name)
    final projectMatch = _projectRegex.firstMatch(text);
    if (projectMatch != null) {
      metadata['project'] = projectMatch.group(1);
      text = text.replaceFirst(projectMatch.group(0)!, '').trim();
    }

    // 6. Detect Heading (# prefix)
    if (text.startsWith('# ')) {
      return ParsedBlock(
        type: 'heading',
        content: text.substring(2).trim(),
        metadata: metadata,
      );
    }

    // 6b. Detect Database View block (/kanban or /board)
    if (text.startsWith('/kanban') || text.startsWith('/board')) {
      return ParsedBlock(
        type: 'database_view',
        content: 'kanban',
        metadata: {'view': 'kanban', 'source': 'tasks'},
      );
    }

    // 7. Detect Todo - unchecked
    if (text.startsWith('- [ ] ')) {
      metadata['checked'] = false;
      return ParsedBlock(
        type: 'todo',
        content: text.substring(6).trim(),
        metadata: metadata,
      );
    }

    // 8. Detect Todo - checked
    if (text.startsWith('- [x] ')) {
      metadata['checked'] = true;
      return ParsedBlock(
        type: 'todo',
        content: text.substring(6).trim(),
        metadata: metadata,
      );
    }

    // Default to intent if specified, otherwise plain text
    if (intent == 'todo') {
      metadata['checked'] = false;
    }
    
    return ParsedBlock(
      type: intent,
      content: text,
      metadata: metadata,
    );
  }

  /// Returns true if the parser detects a "slash command" intent.
  /// Only shows the menu when the user typed "/" or "/partial" (no space yet).
  /// Once a command is selected and space follows (e.g. "/note "), the menu hides.
  static bool isSlashIntent(String input) {
    if (!input.startsWith('/')) return false;
    // If there is a space after the slash-command, the command is committed — hide menu.
    final afterSlash = input.substring(1);
    return !afterSlash.contains(' ');
  }

  /// Returns true if the parser detects a "project mention" intent (e.g., typing #).
  static bool isProjectIntent(String input) {
    return input.contains('#') && !input.split('#').last.contains(' ');
  }

  /// Extracts the project query from the input (text after #).
  static String getProjectQuery(String input) {
    if (!input.contains('#')) return '';
    return input.split('#').last.toLowerCase();
  }

  /// Converts a ParsedBlock metadata map to JSON string.
  static String metadataToJson(Map<String, dynamic> metadata) {
    return jsonEncode(metadata);
  }
}
