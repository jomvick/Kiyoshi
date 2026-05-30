import 'package:flutter_test/flutter_test.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:flutter/material.dart';

void main() {
  group('Workspace', () {
    test('creates with required fields only', () {
      const workspace = Workspace(
        id: '1',
        name: 'Test Workspace',
      );

      expect(workspace.id, '1');
      expect(workspace.name, 'Test Workspace');
      expect(workspace.description, '');
      expect(workspace.icon, 'folder');
      expect(workspace.themeColor, Colors.blue);
      expect(workspace.progress, 0.0);
      expect(workspace.boardIds, isEmpty);
    });

    test('creates with all fields', () {
      const workspace = Workspace(
        id: '2',
        name: 'Full Workspace',
        description: 'A complete workspace',
        icon: 'folder',
        themeColor: Colors.green,
        progress: 0.75,
        boardIds: ['board1', 'board2'],
      );

      expect(workspace.id, '2');
      expect(workspace.name, 'Full Workspace');
      expect(workspace.description, 'A complete workspace');
      expect(workspace.icon, 'folder');
      expect(workspace.themeColor, Colors.green);
      expect(workspace.progress, 0.75);
      expect(workspace.boardIds, ['board1', 'board2']);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = Workspace(
        id: '1',
        name: 'Original',
        progress: 0.5,
      );

      final updated = original.copyWith(
        name: 'Updated',
        progress: 1.0,
      );

      expect(original.id, '1');
      expect(original.name, 'Original');
      expect(original.progress, 0.5);

      expect(updated.id, '1');
      expect(updated.name, 'Updated');
      expect(updated.progress, 1.0);
    });

    test('copyWith preserves unchanged fields', () {
      const original = Workspace(
        id: '1',
        name: 'Original',
        description: 'Description',
        icon: 'star',
        themeColor: Colors.red,
        progress: 0.3,
        boardIds: ['b1'],
      );

      final updated = original.copyWith(name: 'New Name');

      expect(updated.description, 'Description');
      expect(updated.icon, 'star');
      expect(updated.themeColor, Colors.red);
      expect(updated.progress, 0.3);
      expect(updated.boardIds, ['b1']);
    });

    test('has expected properties', () {
      const workspace = Workspace(
        id: 'test-id',
        name: 'Test Name',
        description: 'Test Description',
        icon: 'work',
        themeColor: Colors.purple,
        progress: 0.5,
        boardIds: ['board1'],
      );

      expect(workspace.id, isA<String>());
      expect(workspace.name, isA<String>());
      expect(workspace.description, isA<String>());
      expect(workspace.icon, isA<String>());
      expect(workspace.themeColor, isA<Color>());
      expect(workspace.progress, isA<double>());
      expect(workspace.boardIds, isA<List<String>>());
    });
  });
}