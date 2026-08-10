/// Native tool registry for the Kiyoshi AI Agent.
///
/// Each tool has:
///   - a JSON Schema definition (sent to the LLM as function calling spec)
///   - an [execute] handler wired directly to [ProjectRepository]
library;

import 'package:kiyoshi/src/core/database/project_repository.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/todo_task.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:uuid/uuid.dart';

/// Definition of a single native tool (function) the agent can call.
class AgentTool {
  final String name;
  final String description;
  final Map<String, dynamic> parametersSchema;
  final Future<String> Function(
      Map<String, dynamic> args, ProjectRepository repo) execute;

  const AgentTool({
    required this.name,
    required this.description,
    required this.parametersSchema,
    required this.execute,
  });

  /// Converts this tool to the OpenAI / Ollama function-calling format.
  Map<String, dynamic> toOpenAiFunction() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parametersSchema,
        },
      };

  /// Converts this tool to the Anthropic function-calling format.
  Map<String, dynamic> toAnthropicTool() => {
        'name': name,
        'description': description,
        'input_schema': parametersSchema,
      };

  /// Converts this tool to the Gemini function declaration format.
  Map<String, dynamic> toGeminiFunctionDeclaration() => {
        'name': name,
        'description': description,
        'parameters': _cleanSchemaForGemini(parametersSchema),
      };

  static Map<String, dynamic> _cleanSchemaForGemini(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    if (copy.containsKey('type')) {
      copy['type'] = (copy['type'] as String).toUpperCase();
    }
    if (copy.containsKey('enum')) {
      copy['enum'] = (copy['enum'] as List).map((e) => e.toString()).toList();
    }
    if (copy.containsKey('properties')) {
      final props = copy['properties'] as Map<String, dynamic>;
      copy['properties'] = {
        for (final entry in props.entries)
          entry.key: _cleanSchemaForGemini(entry.value as Map<String, dynamic>),
      };
    }
    if (copy.containsKey('items')) {
      copy['items'] = _cleanSchemaForGemini(copy['items'] as Map<String, dynamic>);
    }
    return copy;
  }
}

/// Registry of all tools available to the AI Agent.
class AgentToolRegistry {
  static List<AgentTool> get all => [
        _createTask,
        _updateTaskStatus,
        _createProject,
        _createWorkspace,
        _listWorkspaceContent,
        _addCanvasNote,
        _summarizePendingTasks,
      ];

  // ─── CREATE TASK ──────────────────────────────────────────────────────────

  static final _createTask = AgentTool(
    name: 'create_task',
    description:
        'Creates a new task in a project. Use this when the user wants to add a to-do, action item, or task.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'The title of the task',
        },
        'project_id': {
          'type': 'string',
          'description':
              'The ID of the project to add the task to. Use "global" if no specific project is mentioned.',
        },
        'description': {
          'type': 'string',
          'description': 'Optional detailed description of the task',
        },
        'priority': {
          'type': 'integer',
          'description': '1 = High, 2 = Medium, 3 = Low',
          'enum': ['1', '2', '3'],
        },
        'status': {
          'type': 'string',
          'description': 'Initial status of the task',
          'enum': ['todo', 'in_progress', 'done'],
        },
        'due_date': {
          'type': 'string',
          'description': 'ISO 8601 date string for the due date (optional)',
        },
      },
      'required': ['title', 'project_id'],
    },
    execute: (args, repo) async {
      int priorityVal = 2;
      if (args['priority'] != null) {
        if (args['priority'] is int) {
          priorityVal = args['priority'] as int;
        } else {
          priorityVal = int.tryParse(args['priority'].toString()) ?? 2;
        }
      }

      final task = TodoTask(
        id: const Uuid().v4(),
        projectId: args['project_id'] as String? ?? 'global',
        title: args['title'] as String,
        description: args['description'] as String? ?? '',
        status: TodoTaskStatus.fromString(args['status'] as String? ?? 'todo'),
        priority: TodoTaskPriority.fromInt(priorityVal),
        dueDate: args['due_date'] != null
            ? DateTime.tryParse(args['due_date'] as String)
            : null,
        position: 0.0,
      );
      final id = await repo.addTask(task);
      return 'Task created with id: $id — "${task.title}"';
    },
  );

  // ─── UPDATE TASK STATUS ───────────────────────────────────────────────────

  static final _updateTaskStatus = AgentTool(
    name: 'update_task_status',
    description:
        'Updates the status of an existing task (e.g. mark as done, in progress, or back to todo).',
    parametersSchema: {
      'type': 'object',
      'properties': {
        'task_id': {
          'type': 'string',
          'description': 'The ID of the task to update',
        },
        'status': {
          'type': 'string',
          'enum': ['todo', 'in_progress', 'done'],
          'description': 'New status for the task',
        },
      },
      'required': ['task_id', 'status'],
    },
    execute: (args, repo) async {
      // Fetch all projects to find the task
      final projects = await repo.getAllProjects();
      for (final project in projects) {
        final tasks = await repo.getTasksForProject(project.id);
        final task = tasks.where((t) => t.id == args['task_id']).firstOrNull;
        if (task != null) {
          final updated = TodoTask(
            id: task.id,
            projectId: task.projectId,
            title: task.title,
            description: task.description,
            status:
                TodoTaskStatus.fromString(args['status'] as String? ?? 'todo'),
            priority: task.priority,
            dueDate: task.dueDate,
            position: task.position,
          );
          await repo.updateTask(updated);
          return 'Task "${task.title}" updated to ${args['status']}';
        }
      }
      return 'Task with id ${args['task_id']} not found';
    },
  );

  // ─── CREATE PROJECT ───────────────────────────────────────────────────────

  static final _createProject = AgentTool(
    name: 'create_project',
    description:
        'Creates a new project inside a workspace. Use when the user wants to start a new project.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'Name of the project',
        },
        'workspace_id': {
          'type': 'string',
          'description': 'The ID of the workspace to create the project in',
        },
        'description': {
          'type': 'string',
          'description': 'Optional description of the project',
        },
        'deadline': {
          'type': 'string',
          'description': 'ISO 8601 date for the project deadline (optional)',
        },
      },
      'required': ['title', 'workspace_id'],
    },
    execute: (args, repo) async {
      final project = Project.create(
        id: const Uuid().v4(),
        workspaceId: args['workspace_id'] as String,
        title: args['title'] as String,
        description: args['description'] as String? ?? '',
      );
      final id = await repo.addProject(project);
      return 'Project "${project.title}" created with id: $id';
    },
  );

  // ─── CREATE WORKSPACE ─────────────────────────────────────────────────────

  static final _createWorkspace = AgentTool(
    name: 'create_workspace',
    description:
        'Creates a new workspace (top-level container for projects). Use when the user wants a new workspace or team space.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        'name': {
          'type': 'string',
          'description': 'Name of the workspace',
        },
        'description': {
          'type': 'string',
          'description': 'Optional description',
        },
        'icon': {
          'type': 'string',
          'description': 'Emoji icon for the workspace (optional)',
        },
      },
      'required': ['name'],
    },
    execute: (args, repo) async {
      final workspace = Workspace(
        id: const Uuid().v4(),
        name: args['name'] as String,
        description: args['description'] as String? ?? '',
        icon: args['icon'] as String? ?? '🗂️',
      );
      final id = await repo.addWorkspace(workspace);
      return 'Workspace "${workspace.name}" created with id: $id';
    },
  );

  // ─── LIST WORKSPACE CONTENT ───────────────────────────────────────────────

  static final _listWorkspaceContent = AgentTool(
    name: 'list_workspace_content',
    description:
        'Lists all projects and their tasks in a workspace. Use to summarize what exists before creating duplicates.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        'workspace_id': {
          'type': 'string',
          'description': 'The ID of the workspace to list',
        },
      },
      'required': ['workspace_id'],
    },
    execute: (args, repo) async {
      final workspaceId = args['workspace_id'] as String;
      final projects = await repo.getProjectsForWorkspace(workspaceId);
      if (projects.isEmpty) {
        return 'Workspace has no projects yet.';
      }
      final buffer = StringBuffer();
      for (final project in projects) {
        buffer.writeln('📁 ${project.title} [${project.status.value}]');
        final tasks = await repo.getTasksForProject(project.id);
        for (final task in tasks) {
          buffer.writeln(
              '  - ${task.title} [${task.status.value}] (priority: ${task.priority.value})');
        }
      }
      return buffer.toString();
    },
  );

  // ─── ADD CANVAS NOTE ──────────────────────────────────────────────────────

  static final _addCanvasNote = AgentTool(
    name: 'add_canvas_note',
    description:
        'Adds a text note or content block to a project\'s canvas. Use when the user wants to add a note, idea, or memo.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        'project_id': {
          'type': 'string',
          'description': 'ID of the project to add the note to',
        },
        'content': {
          'type': 'string',
          'description': 'The text content of the note',
        },
        'type': {
          'type': 'string',
          'enum': ['text', 'todo', 'link'],
          'description': 'Type of block to add',
        },
      },
      'required': ['project_id', 'content'],
    },
    execute: (args, repo) async {
      final projectId = args['project_id'] as String;
      final content = args['content'] as String;
      final type = args['type'] as String? ?? 'text';

      final id = await repo.addBlock(
        projectId,
        ParsedBlock(type: type, content: content),
      );

      return 'Note added to project $projectId (block id: $id)';
    },
  );

  // ─── SUMMARIZE PENDING TASKS ──────────────────────────────────────────────

  static final _summarizePendingTasks = AgentTool(
    name: 'summarize_pending_tasks',
    description:
        'Returns a summary of all pending (todo and in_progress) tasks across the entire workspace. Use when the user asks what they need to do or what\'s pending.',
    parametersSchema: {
      'type': 'object',
      'properties': {
        'workspace_id': {
          'type': 'string',
          'description': 'The ID of the workspace to summarize',
        },
      },
      'required': ['workspace_id'],
    },
    execute: (args, repo) async {
      final workspaceId = args['workspace_id'] as String;
      final projects = await repo.getProjectsForWorkspace(workspaceId);
      final buffer = StringBuffer();
      int total = 0;
      for (final project in projects) {
        final tasks = await repo.getTasksForProject(project.id);
        final pending = tasks
            .where((t) =>
                t.status != TodoTaskStatus.done)
            .toList();
        if (pending.isNotEmpty) {
          buffer.writeln('📁 ${project.title}:');
          for (final task in pending) {
            buffer.writeln(
                '  • [${task.status.value}] ${task.title}');
            total++;
          }
        }
      }
      if (total == 0) {
        return '🎉 No pending tasks! Everything is done.';
      }
      return 'Found $total pending task(s):\n$buffer';
    },
  );
}


