import 'package:flutter_test/flutter_test.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';

void main() {
  group('ZenBlock', () {
    test('creates with required fields only', () {
      final block = ZenBlock(
        id: '1',
        projectId: 'proj1',
        type: 'text',
        content: 'Hello World',
        metadata: {},
        position: 1000.0,
      );

      expect(block.id, '1');
      expect(block.projectId, 'proj1');
      expect(block.type, 'text');
      expect(block.content, 'Hello World');
      expect(block.metadata, isEmpty);
      expect(block.position, 1000.0);
    });

    test('creates with all fields', () {
      final block = ZenBlock(
        id: '2',
        projectId: 'proj2',
        type: 'todo',
        content: 'Complete task',
        metadata: {'status': 'done', 'priority': 'high'},
        position: 2000.0,
      );

      expect(block.id, '2');
      expect(block.projectId, 'proj2');
      expect(block.type, 'todo');
      expect(block.content, 'Complete task');
      expect(block.metadata, {'status': 'done', 'priority': 'high'});
      expect(block.position, 2000.0);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = ZenBlock(
        id: '1',
        projectId: 'proj1',
        type: 'text',
        content: 'Original',
        metadata: {'key': 'value'},
        position: 1000.0,
      );

      final updated = original.copyWith(
        content: 'Updated',
        type: 'todo',
        position: 2000.0,
      );

      expect(original.id, '1');
      expect(original.content, 'Original');
      expect(original.type, 'text');
      expect(original.position, 1000.0);

      expect(updated.id, '1');
      expect(updated.content, 'Updated');
      expect(updated.type, 'todo');
      expect(updated.position, 2000.0);
      expect(updated.metadata, {'key': 'value'});
    });

    test('copyWith preserves unchanged fields', () {
      final original = ZenBlock(
        id: '1',
        projectId: 'proj1',
        type: 'link',
        content: 'https://example.com',
        metadata: {'url': 'https://example.com', 'title': 'Example'},
        position: 1500.0,
      );

      final updated = original.copyWith(content: 'New content');

      expect(updated.id, '1');
      expect(updated.projectId, 'proj1');
      expect(updated.type, 'link');
      expect(updated.metadata, {'url': 'https://example.com', 'title': 'Example'});
      expect(updated.position, 1500.0);
    });

    test('supports various block types', () {
      final types = ['text', 'todo', 'link', 'image', 'file', 'divider', 'code', 'heading'];
      
      for (final type in types) {
        final block = ZenBlock(
          id: '1',
          projectId: 'proj1',
          type: type,
          content: 'Content for $type',
          metadata: {},
          position: 1000.0,
        );
        expect(block.type, type);
      }
    });

    test('handles complex metadata', () {
      final block = ZenBlock(
        id: '1',
        projectId: 'proj1',
        type: 'todo',
        content: 'Complex task',
        metadata: {
          'status': 'in_progress',
          'dueDate': '2024-12-31',
          'assignee': 'John Doe',
          'tags': ['urgent', 'work'],
          'subtasks': [
            {'id': '1', 'title': 'Subtask 1', 'done': false},
            {'id': '2', 'title': 'Subtask 2', 'done': true},
          ],
        },
        position: 1000.0,
      );

      expect(block.metadata['status'], 'in_progress');
      expect(block.metadata['dueDate'], '2024-12-31');
      expect(block.metadata['tags'], ['urgent', 'work']);
      expect((block.metadata['subtasks'] as List).length, 2);
    });

    test('has expected properties with correct types', () {
      final block = ZenBlock(
        id: 'test-id',
        projectId: 'project-id',
        type: 'text',
        content: 'Test content',
        metadata: {'key': 'value'},
        position: 1500.0,
      );

      expect(block.id, isA<String>());
      expect(block.projectId, isA<String>());
      expect(block.type, isA<String>());
      expect(block.content, isA<String>());
      expect(block.metadata, isA<Map<String, dynamic>>());
      expect(block.position, isA<double>());
    });
  });
}