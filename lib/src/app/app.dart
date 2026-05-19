import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/features/kanban_board/kanban_board_screen.dart';

class KiyoshiApp extends ConsumerWidget {
  const KiyoshiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp(
      title: 'Kiyoshi',
      debugShowCheckedModeBanner: false,
      theme: prefs.darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      builder: (context, child) => _ErrorBoundary(child: child!),
      home: const KanbanBoardScreen(),
    );
  }
}

class _ErrorBoundary extends StatelessWidget {
  final Widget child;
  const _ErrorBoundary({required this.child});

  @override
  Widget build(BuildContext context) => child;
}
