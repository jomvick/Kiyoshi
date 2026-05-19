import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'database.g.dart';

@DataClassName('BlockData')
class Blocks extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get projectId => text()();
  TextColumn get type => text()(); // text, todo, link, image, file, divider
  TextColumn get content => text()();
  TextColumn get metadata => text().nullable()(); // JSON
  RealColumn get position => real()();
  TextColumn get parentId => text().nullable()();
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkspaceData')
class Workspaces extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text()();
  IntColumn get colorValue => integer()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProjectData')
class Projects extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get workspaceId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('not_started'))();
  TextColumn get deadline => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskData')
class Tasks extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get projectId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  TextColumn get dueDate => text().nullable()();
  RealColumn get position => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Blocks, Workspaces, Projects, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(blocks, blocks.position);
            await customStatement('UPDATE blocks SET position = rowid * 1000 WHERE position IS NULL');
          }
          if (from < 3) {
            await m.createTable(workspaces);
          }
          if (from < 4) {
            await m.createTable(projects);
          }
          if (from < 5) {
            await m.createTable(tasks);
          }
          if (from < 6) {
            await m.addColumn(blocks, blocks.parentId);
            await m.addColumn(blocks, blocks.createdAt);
          }
        },
      );

  // Blocks Queries
  Future<List<BlockData>> getBlocksForProject(String projectId) {
    return (select(blocks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
  }

  Stream<List<BlockData>> watchBlocksForProject(String projectId) {
    return (select(blocks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  Future<int> addBlock(BlocksCompanion block) => into(blocks).insert(block);
  Future updateBlock(BlockData block) => update(blocks).replace(block);
  Future deleteBlock(BlockData block) =>
      (delete(blocks)..where((t) => t.id.equals(block.id))).go();

  Future<BlockData?> getBlockById(String id) {
    return (select(blocks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<double?> getMaxPosition(String projectId) {
    return (select(blocks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull()
        .then((b) => b?.position);
  }

  // Workspaces Queries
  Future<List<WorkspaceData>> getAllWorkspaces() => select(workspaces).get();
  Stream<List<WorkspaceData>> watchAllWorkspaces() =>
      select(workspaces).watch();
  Future<int> addWorkspace(WorkspacesCompanion workspace) =>
      into(workspaces).insert(workspace);
  Future updateWorkspace(WorkspaceData workspace) =>
      update(workspaces).replace(workspace);
  Future deleteWorkspace(String id) =>
      (delete(workspaces)..where((t) => t.id.equals(id))).go();

  // Projects Queries
  Future<List<ProjectData>> getProjectsForWorkspace(String workspaceId) {
    return (select(projects)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<ProjectData>> watchProjectsForWorkspace(String workspaceId) {
    return (select(projects)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<ProjectData?> getProjectById(String id) {
    return (select(projects)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<ProjectData?> watchProjectById(String id) {
    return (select(projects)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<int> addProject(ProjectsCompanion project) =>
      into(projects).insert(project);
  Future updateProject(ProjectData project) =>
      update(projects).replace(project);
  Future deleteProject(String id) =>
      (delete(projects)..where((t) => t.id.equals(id))).go();

  // Tasks Queries
  Future<List<TaskData>> getTasksForProject(String projectId) {
    return (select(tasks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
  }

  Stream<List<TaskData>> watchTasksForProject(String projectId) {
    return (select(tasks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  Future<TaskData?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> addTask(TasksCompanion task) => into(tasks).insert(task);
  Future updateTask(TaskData task) => update(tasks).replace(task);
  Future deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kiyoshi.sqlite'));
    return NativeDatabase(file);
  });
}
