import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/features/canvas/domain/entities/zen_block.dart';

void main() {
  group('Database Provider Structure', () {
    test('databaseProvider exists and is properly typed', () {
      expect(databaseProvider, isNotNull);
      expect(databaseProvider, isA<Provider>());
    });

    test('projectRepositoryProvider exists and is properly typed', () {
      expect(projectRepositoryProvider, isNotNull);
      expect(projectRepositoryProvider, isA<Provider>());
    });

    test('blockRepositoryProvider exists and is properly typed', () {
      expect(blockRepositoryProvider, isNotNull);
      expect(blockRepositoryProvider, isA<Provider>());
    });

    test('metadataServiceProvider exists and is properly typed', () {
      expect(metadataServiceProvider, isNotNull);
      expect(metadataServiceProvider, isA<Provider>());
    });

    test('vaultServiceProvider exists and is properly typed', () {
      expect(vaultServiceProvider, isNotNull);
      expect(vaultServiceProvider, isA<Provider>());
    });

    test('blockServiceProvider exists and is properly typed', () {
      expect(blockServiceProvider, isNotNull);
      expect(blockServiceProvider, isA<Provider>());
    });

    test('allWorkspacesProvider is a StreamProvider', () {
      expect(allWorkspacesProvider, isNotNull);
      expect(allWorkspacesProvider, isA<StreamProvider<List<Workspace>>>());
    });

    test('globalStatsProvider is a StreamProvider', () {
      expect(globalStatsProvider, isNotNull);
      expect(globalStatsProvider, isA<StreamProvider<Map<String, dynamic>>>());
    });

    test('latestActivitiesProvider is a StreamProvider', () {
      expect(latestActivitiesProvider, isNotNull);
      expect(latestActivitiesProvider, isA<StreamProvider<List<ZenBlock>>>());
    });

    test('calendarEventsProvider is a StreamProvider', () {
      expect(calendarEventsProvider, isNotNull);
      expect(calendarEventsProvider, isA<StreamProvider<List<ZenBlock>>>());
    });

    test('projectBlocksProvider is a family StreamProvider', () {
      expect(projectBlocksProvider, isNotNull);
    });

    test('allWorkspacesProvider is not equal to globalStatsProvider', () {
      expect(allWorkspacesProvider, isNot(equals(globalStatsProvider)));
    });

    test('latestActivitiesProvider is not equal to calendarEventsProvider', () {
      expect(latestActivitiesProvider, isNot(equals(calendarEventsProvider)));
    });
  });
}