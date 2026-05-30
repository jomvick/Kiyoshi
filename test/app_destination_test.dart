import 'package:flutter_test/flutter_test.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';

void main() {
  group('AppDestination', () {
    test('all destinations have valid labels', () {
      for (final destination in AppDestination.values) {
        expect(destination.label, isNotEmpty);
        expect(destination.label.length, greaterThan(0));
      }
    });

    test('all destinations have valid icons', () {
      for (final destination in AppDestination.values) {
        expect(destination.icon, isNotNull);
      }
    });

    test('all destinations are unique', () {
      final labels = AppDestination.values.map((d) => d.label).toList();
      final uniqueLabels = labels.toSet();

      expect(uniqueLabels.length, equals(labels.length));
    });

    test('dashboard is the first destination', () {
      expect(AppDestination.values.first, AppDestination.dashboard);
    });

    test('each destination has correct type', () {
      for (final destination in AppDestination.values) {
        expect(destination, isA<AppDestination>());
      }
    });

    test('known destinations exist', () {
      for (final destination in AppDestination.values) {
        expect(AppDestination.values.contains(destination), isTrue);
      }
    });

    test('dashboard label is "Dashboard"', () {
      expect(AppDestination.dashboard.label, 'Dashboard');
    });

    test('projects label is "Projects"', () {
      expect(AppDestination.projects.label, 'Projects');
    });

    test('tasks label is "Tasks"', () {
      expect(AppDestination.tasks.label, 'Tasks');
    });

    test('notes label is "Notes"', () {
      expect(AppDestination.notes.label, 'Notes');
    });

    test('calendar label is "Calendar"', () {
      expect(AppDestination.calendar.label, 'Calendar');
    });

    test('analytics label is "Analytics"', () {
      expect(AppDestination.analytics.label, 'Analytics');
    });

    test('settings label is "Settings"', () {
      expect(AppDestination.settings.label, 'Settings');
    });

    test('has exactly 7 destinations', () {
      expect(AppDestination.values.length, 7);
    });
  });
}