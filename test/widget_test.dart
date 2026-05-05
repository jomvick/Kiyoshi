import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/shared/widgets/sidebar.dart';

void main() {
  testWidgets('Sidebar renders primary navigation items', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Sidebar(
            selectedWorkspace: Workspace(id: '1', name: 'Studio'),
            workspaces: [Workspace(id: '1', name: 'Studio')],
            onWorkspaceSelected: (_) {},
            onCreateWorkspace: () {},
            onDestinationSelected: (_) {},
            selectedDestination: AppDestination.dashboard,
          ),
        ),
      ),
    );

    expect(find.text('Kiyoshi'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
  });
}