import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kiyoshi/src/core/database/database.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/todo_task.dart';
import 'package:kiyoshi/src/features/canvas/domain/repositories/i_block_repository.dart';
import 'package:kiyoshi/src/features/canvas/application/block_service.dart';
import 'package:kiyoshi/src/core/services/metadata_service.dart';
import 'package:kiyoshi/src/core/database/project_repository.dart';
import 'package:kiyoshi/src/core/services/vault_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Consolidated Repository
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectRepository(db);
});

// Alias for IBlockRepository
final blockRepositoryProvider = Provider<IBlockRepository>((ref) {
  return ref.watch(projectRepositoryProvider);
});

final metadataServiceProvider = Provider<MetadataService>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return MetadataService(repo);
});

final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService();
});

final blockServiceProvider = Provider<BlockService>((ref) {
  final repo = ref.watch(blockRepositoryProvider);
  final metadata = ref.watch(metadataServiceProvider);
  final vault = ref.watch(vaultServiceProvider);
  return BlockService(repo, metadata, vault);
});

final projectBlocksProvider =
    StreamProvider.autoDispose.family<List<ZenBlock>, String>((ref, projectId) {
  final service = ref.watch(blockServiceProvider);
  return service.watchBlocks(projectId);
});

/// Blocks anywhere else in the app (excluding [params.excludeProjectId])
/// that reference [params.title] via `[[Page Title]]` syntax — backs the
/// "Linked mentions" panel on project pages, Obsidian-style backlinks.
final backlinksProvider = StreamProvider.autoDispose
    .family<List<ZenBlock>, ({String excludeProjectId, String title})>((ref, params) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchAllBlocks().map((blocks) => blocks
      .where((b) =>
          b.projectId != params.excludeProjectId &&
          ZenParser.containsLinkTo(b.content, params.title))
      .toList());
});

/// Every `#tag` used anywhere in the app, with how many blocks use each —
/// powers a simple Obsidian-style tag browser. Previously `#tag` only fed a
/// one-off quick-entry hint (`ZenParser._projectRegex`), never a persisted
/// or browsable index.
final allTagsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchAllBlocks().map((blocks) {
    final counts = <String, int>{};
    for (final b in blocks) {
      for (final tag in ZenParser.extractHashtags(b.content)) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  });
});

/// All blocks anywhere in the app tagged with [tag] (case-insensitive).
final blocksForTagProvider =
    StreamProvider.autoDispose.family<List<ZenBlock>, String>((ref, tag) {
  final repo = ref.watch(projectRepositoryProvider);
  final normalized = tag.toLowerCase();
  return repo.watchAllBlocks().map((blocks) => blocks
      .where((b) => ZenParser.extractHashtags(b.content).contains(normalized))
      .toList());
});

final allWorkspacesProvider = StreamProvider.autoDispose<List<Workspace>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchWorkspaces();
});

final globalStatsProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchBlocksForProject('global').map((blocks) {
    final todos = blocks.where((b) => b.type == 'todo').toList();
    final done = todos.where((t) => t.metadata['status'] == 'done').toList();
    
    return {
      'totalBlocks': blocks.length,
      'totalTasks': todos.length,
      'completedTasks': done.length,
      'efficiency': todos.isEmpty ? 0.0 : (done.length / todos.length),
    };
  });
});

final latestActivitiesProvider = StreamProvider.autoDispose<List<ZenBlock>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchBlocksForProject('global').map((blocks) {
    final sorted = blocks.toList()..sort((a, b) => b.position.compareTo(a.position));
    return sorted.take(10).toList();
  });
});

final calendarEventsProvider = StreamProvider.autoDispose<List<ZenBlock>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchBlocksForProject('global').map((blocks) {
    return blocks.where((b) => b.metadata['dueDate'] != null).toList();
  });
});

// Projects Providers
final allProjectsProvider = StreamProvider.autoDispose<List<Project>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchAllProjects();
});

final projectsForWorkspaceProvider =
    StreamProvider.autoDispose.family<List<Project>, String>((ref, workspaceId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjectsForWorkspace(workspaceId);
});

final projectByIdProvider = StreamProvider.autoDispose.family<Project?, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjectById(projectId);
});

// Tasks Providers
final tasksForProjectProvider =
    StreamProvider.autoDispose.family<List<TodoTask>, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchTasksForProject(projectId);
});

final selectedWorkspaceProvider = StateProvider<Workspace?>((ref) => null);

final selectedProjectProvider = StateProvider<Project?>((ref) => null);

// Ghost Menu Projects (for ZenQuickEntry)
final quickEntryProjectsProvider = Provider<List<String>>((ref) {
  final selectedWorkspace = ref.watch(selectedWorkspaceProvider);
  if (selectedWorkspace == null) {
    return ['Design', 'Marketing', 'Core', 'Vision', 'Calm'];
  }
  
  final projectsAsync = ref.watch(projectsForWorkspaceProvider(selectedWorkspace.id));
  return projectsAsync.when(
    data: (projects) => projects.map((p) => p.title).toList(),
    loading: () => ['Design', 'Marketing', 'Core', 'Vision', 'Calm'],
    error: (e, s) => ['Design', 'Marketing', 'Core', 'Vision', 'Calm'],
  );
});

// Create project for quick entry
final createQuickEntryProjectProvider = Provider<Future<String?> Function(String)>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  final selectedWorkspace = ref.watch(selectedWorkspaceProvider);
  
  return (String projectName) async {
    if (selectedWorkspace == null) return null;
    
    final project = Project(
      id: '',
      workspaceId: selectedWorkspace.id,
      title: projectName,
      description: 'Created from quick entry',
      status: ProjectStatus.notStarted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return await repo.addProject(project);
  };
});
