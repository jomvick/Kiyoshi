import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:kiyoshi/src/core/database/database.dart';
import 'package:kiyoshi/src/features/canvas/application/zen_parser.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/features/kanban_board/domain/entities/todo_task.dart';
import 'package:kiyoshi/src/features/canvas/domain/repositories/i_block_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// Unified repository for Atomic Blocks (Phase 3).
class ProjectRepository implements IBlockRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  ZenBlock _mapToEntity(BlockData block) {
    return ZenBlock(
      id: block.id,
      projectId: block.projectId,
      type: block.type,
      content: block.content,
      metadata: block.metadata != null ? jsonDecode(block.metadata!) : {},
      position: block.position,
      parentId: block.parentId,
      createdAt: block.createdAt != null ? DateTime.tryParse(block.createdAt!) : null,
    );
  }

  @override
  Stream<List<ZenBlock>> watchBlocksForProject(String projectId) {
    return _db.watchBlocksForProject(projectId).map(
        (blocks) => blocks.map(_mapToEntity).toList());
  }

  @override
  Future<String> addBlock(String projectId, ParsedBlock parsedBlock) async {
    final blocks = await _db.getBlocksForProject(projectId);
    
    final double nextPosition = blocks.isEmpty ? 1000.0 : (blocks.last.position + 1000.0);

    final companion = BlocksCompanion.insert(
      projectId: projectId,
      type: parsedBlock.type,
      content: parsedBlock.content,
      metadata: Value(jsonEncode(parsedBlock.metadata)),
      position: nextPosition,
      parentId: Value(parsedBlock.parentId),
      createdAt: Value(DateTime.now().toIso8601String()),
    );

    await _db.addBlock(companion);
    return "id-generated";
  }

  @override
  Future<void> updateBlock(ZenBlock block) async {
    await _db.updateBlock(BlockData(
      id: block.id,
      projectId: block.projectId,
      type: block.type,
      content: block.content,
      metadata: jsonEncode(block.metadata),
      position: block.position,
      parentId: block.parentId,
      createdAt: block.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    ));
  }

  @override
  Future<void> deleteBlock(ZenBlock block) async {
    await _db.deleteBlock(BlockData(
      id: block.id,
      projectId: block.projectId,
      type: block.type,
      content: block.content,
      metadata: jsonEncode(block.metadata),
      position: block.position,
      parentId: block.parentId,
      createdAt: block.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    ));
  }

  @override
  Future<ZenBlock?> getBlockById(String id) async {
    final block = await _db.getBlockById(id);
    return block != null ? _mapToEntity(block) : null;
  }

  @override
  Future<void> reorderBlocks(
      String projectId, int oldIndex, int newIndex) async {
    final blocks = await _db.getBlocksForProject(projectId);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = blocks[oldIndex];

    double newPosition;

    if (newIndex == 0) {
      // Move to start
      newPosition = blocks[0].position / 2;
    } else if (newIndex >= blocks.length - 1) {
      // Move to end
      newPosition = blocks.last.position + 1000.0;
    } else {
      // Move between two items
      final actualBlocks = List<BlockData>.from(blocks);
      actualBlocks.removeAt(oldIndex);

      if (newIndex == 0) {
        newPosition = actualBlocks[0].position / 2;
      } else if (newIndex >= actualBlocks.length) {
        newPosition = actualBlocks.last.position + 1000.0;
      } else {
        final prevPos = actualBlocks[newIndex - 1].position;
        final nextPos = actualBlocks[newIndex].position;
        newPosition = (prevPos + nextPos) / 2;
      }
    }

    await _db.updateBlock(item.copyWith(position: newPosition));
  }

  // Workspaces Implementation
  Stream<List<Workspace>> watchWorkspaces() {
    return _db.watchAllWorkspaces().map((list) => list
        .map((w) => Workspace(
              id: w.id,
              name: w.name,
              description: w.description ?? '',
              icon: w.icon,
              themeColor: Color(w.colorValue),
              progress: w.progress,
            ))
        .toList());
  }

  Future<String> addWorkspace(Workspace workspace) async {
    final id = const Uuid().v4();
    await _db.addWorkspace(WorkspacesCompanion.insert(
      id: Value(id),
      name: workspace.name,
      description: Value(workspace.description),
      icon: workspace.icon,
      colorValue: workspace.themeColor.toARGB32(),
      progress: Value(workspace.progress),
    ));
    return id;
  }

  Future<void> updateWorkspace(Workspace workspace) async {
    await _db.updateWorkspace(WorkspaceData(
      id: workspace.id,
      name: workspace.name,
      description: workspace.description,
      icon: workspace.icon,
      colorValue: workspace.themeColor.toARGB32(),
      progress: workspace.progress,
    ));
  }

  Future<void> deleteWorkspace(String id) async {
    await _db.deleteWorkspace(id);
  }

  // Projects Implementation
  Project _mapProjectToEntity(ProjectData p) {
    return Project(
      id: p.id,
      workspaceId: p.workspaceId,
      title: p.title,
      description: p.description ?? '',
      status: ProjectStatus.fromString(p.status),
      deadline: p.deadline != null ? DateTime.parse(p.deadline!) : null,
      createdAt: p.createdAt != null ? DateTime.parse(p.createdAt!) : DateTime.now(),
      updatedAt: p.updatedAt != null ? DateTime.parse(p.updatedAt!) : DateTime.now(),
    );
  }

  Stream<List<Project>> watchProjectsForWorkspace(String workspaceId) {
    return _db.watchProjectsForWorkspace(workspaceId).map(
        (list) => list.map(_mapProjectToEntity).toList());
  }

  Stream<Project?> watchProjectById(String id) {
    return _db.watchProjectById(id).map(
        (p) => p != null ? _mapProjectToEntity(p) : null);
  }

  Future<List<Project>> getProjectsForWorkspace(String workspaceId) async {
    final list = await _db.getProjectsForWorkspace(workspaceId);
    return list.map(_mapProjectToEntity).toList();
  }

  Future<Project?> getProjectById(String id) async {
    final p = await _db.getProjectById(id);
    return p != null ? _mapProjectToEntity(p) : null;
  }

  Future<String> addProject(Project project) async {
    final id = const Uuid().v4();
    await _db.addProject(ProjectsCompanion.insert(
      id: Value(id),
      workspaceId: project.workspaceId,
      title: project.title,
      description: Value(project.description),
      status: Value(project.status.value),
      deadline: Value(project.deadline?.toIso8601String()),
      createdAt: Value(project.createdAt.toIso8601String()),
      updatedAt: Value(project.updatedAt.toIso8601String()),
    ));
    return id;
  }

  Future<void> updateProject(Project project) async {
    await _db.updateProject(ProjectData(
      id: project.id,
      workspaceId: project.workspaceId,
      title: project.title,
      description: project.description,
      status: project.status.value,
      deadline: project.deadline?.toIso8601String(),
      createdAt: project.createdAt.toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<void> deleteProject(String id) async {
    await _db.deleteProject(id);
  }

  // Tasks Implementation
  TodoTask _mapTaskToEntity(TaskData t) {
    return TodoTask(
      id: t.id,
      projectId: t.projectId,
      title: t.title,
      description: t.description ?? '',
      status: TodoTaskStatus.fromString(t.status),
      priority: TodoTaskPriority.fromInt(t.priority),
      dueDate: t.dueDate != null ? DateTime.parse(t.dueDate!) : null,
      position: t.position,
    );
  }

  Stream<List<TodoTask>> watchTasksForProject(String projectId) {
    return _db.watchTasksForProject(projectId).map(
        (list) => list.map(_mapTaskToEntity).toList());
  }

  Future<List<TodoTask>> getTasksForProject(String projectId) async {
    final list = await _db.getTasksForProject(projectId);
    return list.map(_mapTaskToEntity).toList();
  }

  Future<String> addTask(TodoTask task) async {
    final id = const Uuid().v4();
    await _db.addTask(TasksCompanion.insert(
      id: Value(id),
      projectId: task.projectId,
      title: task.title,
      description: Value(task.description),
      status: Value(task.status.value),
      priority: Value(task.priority.value),
      dueDate: Value(task.dueDate?.toIso8601String()),
      position: Value(task.position),
    ));
    return id;
  }

  Future<void> updateTask(TodoTask task) async {
    await _db.updateTask(TaskData(
      id: task.id,
      projectId: task.projectId,
      title: task.title,
      description: task.description,
      status: task.status.value,
      priority: task.priority.value,
      dueDate: task.dueDate?.toIso8601String(),
      position: task.position,
    ));
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
  }
}
