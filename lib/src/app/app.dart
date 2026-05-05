import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/kanban_board/kanban_board_screen.dart';

class KiyoshiApp extends StatelessWidget {
  const KiyoshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiyoshi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const KanbanBoardScreen(),
    );
  }
}
