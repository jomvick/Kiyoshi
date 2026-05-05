import 'package:flutter_test/flutter_test.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';

void main() {
  group('AppPreferences', () {
    test('creates with default values', () {
      const prefs = AppPreferences();

      expect(prefs.sidebarExpanded, true);
      expect(prefs.zenModeEnabled, false);
      expect(prefs.defaultDestination, 'projects');
      expect(prefs.sidebarWidth, 280);
    });

    test('creates with custom values', () {
      const prefs = AppPreferences(
        sidebarExpanded: false,
        zenModeEnabled: true,
        defaultDestination: 'dashboard',
        sidebarWidth: 320,
      );

      expect(prefs.sidebarExpanded, false);
      expect(prefs.zenModeEnabled, true);
      expect(prefs.defaultDestination, 'dashboard');
      expect(prefs.sidebarWidth, 320);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = AppPreferences(
        sidebarExpanded: true,
        zenModeEnabled: false,
        defaultDestination: 'projects',
        sidebarWidth: 280,
      );

      final updated = original.copyWith(
        sidebarExpanded: false,
        zenModeEnabled: true,
      );

      expect(original.sidebarExpanded, true);
      expect(original.zenModeEnabled, false);

      expect(updated.sidebarExpanded, false);
      expect(updated.zenModeEnabled, true);
      expect(updated.defaultDestination, 'projects');
      expect(updated.sidebarWidth, 280);
    });

    test('copyWith preserves unchanged fields', () {
      const original = AppPreferences(
        sidebarExpanded: true,
        zenModeEnabled: false,
        defaultDestination: 'projects',
        sidebarWidth: 280,
      );

      final updated = original.copyWith(defaultDestination: 'dashboard');

      expect(updated.sidebarExpanded, true);
      expect(updated.zenModeEnabled, false);
      expect(updated.defaultDestination, 'dashboard');
      expect(updated.sidebarWidth, 280);
    });

    test('has expected property types', () {
      const prefs = AppPreferences();

      expect(prefs.sidebarExpanded, isA<bool>());
      expect(prefs.zenModeEnabled, isA<bool>());
      expect(prefs.defaultDestination, isA<String>());
      expect(prefs.sidebarWidth, isA<double>());
    });
  });
}