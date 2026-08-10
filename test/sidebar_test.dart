import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/shared/widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Sidebar Widget', () {
    late Workspace testWorkspace;
    late List<Workspace> testWorkspaces;
    late AppDestination selectedDestination;
    late SharedPreferences testPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      testPrefs = await SharedPreferences.getInstance();
      testWorkspace = const Workspace(id: '1', name: 'Studio');
      testWorkspaces = [
        const Workspace(id: '1', name: 'Studio'),
        const Workspace(id: '2', name: 'Work'),
      ];
      selectedDestination = AppDestination.dashboard;
    });

    Widget wrap(Widget child) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(testPrefs),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('renders Kiyoshi logo text', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrap(
          Sidebar(
            selectedWorkspace: testWorkspace,
            workspaces: testWorkspaces,
            onWorkspaceSelected: (_) {},
            onCreateWorkspace: () {},
            onDestinationSelected: (_) {},
            selectedDestination: selectedDestination,
          ),
        ),
      );

      expect(find.text('Kiyoshi'), findsOneWidget);
    });

    testWidgets('renders all navigation destinations', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrap(
          Sidebar(
            selectedWorkspace: testWorkspace,
            workspaces: testWorkspaces,
            onWorkspaceSelected: (_) {},
            onCreateWorkspace: () {},
            onDestinationSelected: (_) {},
            selectedDestination: selectedDestination,
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('calls onDestinationSelected when destination tapped', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      AppDestination? tappedDestination;

      await tester.pumpWidget(
        wrap(
          Sidebar(
            selectedWorkspace: testWorkspace,
            workspaces: testWorkspaces,
            onWorkspaceSelected: (_) {},
            onCreateWorkspace: () {},
            onDestinationSelected: (dest) {
              tappedDestination = dest;
            },
            selectedDestination: selectedDestination,
          ),
        ),
      );

      await tester.tap(find.text('Projects'));
      await tester.pump();

      expect(tappedDestination, AppDestination.projects);
    });

    testWidgets('displays Dashboard as selected by default', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrap(
          Sidebar(
            selectedWorkspace: testWorkspace,
            workspaces: testWorkspaces,
            onWorkspaceSelected: (_) {},
            onCreateWorkspace: () {},
            onDestinationSelected: (_) {},
            selectedDestination: AppDestination.dashboard,
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('handles empty workspaces list', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrap(
          Sidebar(
            selectedWorkspace: null,
            workspaces: [],
            onWorkspaceSelected: (_) {},
            onCreateWorkspace: () {},
            onDestinationSelected: (_) {},
            selectedDestination: selectedDestination,
          ),
        ),
      );

      expect(find.text('Kiyoshi'), findsOneWidget);
    });
  });
}