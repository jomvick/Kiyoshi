import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/database/database.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
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
    StreamProvider.family<List<ZenBlock>, String>((ref, projectId) {
  final service = ref.watch(blockServiceProvider);
  return service.watchBlocks(projectId);
});

final allWorkspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchWorkspaces();
});

final globalStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
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

final latestActivitiesProvider = StreamProvider<List<ZenBlock>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchBlocksForProject('global').map((blocks) {
    final sorted = blocks.toList()..sort((a, b) => b.position.compareTo(a.position));
    return sorted.take(10).toList();
  });
});

final calendarEventsProvider = StreamProvider<List<ZenBlock>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchBlocksForProject('global').map((blocks) {
    return blocks.where((b) => b.metadata['dueDate'] != null).toList();
  });
});

// Projects Providers
final projectsForWorkspaceProvider =
    StreamProvider.family<List<Project>, String>((ref, workspaceId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjectsForWorkspace(workspaceId);
});

final projectByIdProvider = StreamProvider.family<Project?, String>((ref, projectId) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjectById(projectId);
});

// Tasks Providers
final tasksForProjectProvider =
    StreamProvider.family<List<TodoTask>, String>((ref, projectId) {
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
