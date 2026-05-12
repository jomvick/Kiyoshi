import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';
import 'package:kiyoshi/src/core/providers/zen_mode_provider.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/features/analytics/analytics_screen.dart';
import 'package:kiyoshi/src/features/calendar/calendar_screen.dart';
import 'package:kiyoshi/src/features/dashboard/kiyoshi_zen_dashboard_view.dart';
import 'package:kiyoshi/src/features/notes/notes_screen.dart';
import 'package:kiyoshi/src/features/projects/presentation/projects_screen.dart';
import 'package:kiyoshi/src/features/tasks/tasks_screen.dart';
import 'package:kiyoshi/src/features/settings/settings_screen.dart';
import 'package:kiyoshi/src/shared/layout/app_desktop_shell.dart';
import 'package:kiyoshi/src/shared/widgets/command_palette.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

class KanbanBoardScreen extends ConsumerStatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> {
  Workspace? _selectedWorkspace;
  late AppDestination _selectedDestination;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode(debugLabel: 'kanban_keyboard_listener');
    final defaultDest = ref.read(preferencesProvider).defaultDestination;
    _selectedDestination = AppDestination.values.firstWhere(
      (d) => d.name == defaultDest,
      orElse: () => AppDestination.projects,
    );
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _showCommandPalette() {
    CommandPalette.show(
      context,
      commands: [
        Command(
          id: 'new-task',
          title: 'Create new task',
          subtitle: 'Add a task to the current board',
          icon: LucideIcons.plus,
          keywords: ['task', 'create', 'add'],
          accentColor: const Color(0xFF2A9D84),
          onExecute: () => _createNewTask(),
        ),
        Command(
          id: 'new-board',
          title: 'Create new board',
          subtitle: 'Add a new column to the workspace',
          icon: LucideIcons.layoutGrid,
          keywords: ['board', 'column', 'create'],
          accentColor: const Color(0xFF58BFA5),
          onExecute: () => _createNewBoard(),
        ),
        Command(
          id: 'focus-mode',
          title: 'Enter focus mode',
          subtitle: 'Start a Pomodoro session',
          icon: LucideIcons.timer,
          keywords: ['focus', 'pomodoro', 'timer'],
          accentColor: const Color(0xFF7AD9C0),
          onExecute: () => _toggleFocusMode(),
        ),
      ],
    );
  }

  void _createNewTask() {
    setState(() {
      _selectedDestination = AppDestination.tasks;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create new task'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }

  void _createNewBoard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create new board'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }

  void _toggleFocusMode() {
    final isZen = ref.read(zenModeProvider);
    ref.read(zenModeProvider.notifier).state = !isZen;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZen ? 'Exited focus mode' : 'Entered focus mode'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCreateWorkspace() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workspace'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Workspace Name',
            hintText: 'Enter workspace name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final repo = ref.read(projectRepositoryProvider);
      await repo.addWorkspace(Workspace(id: const Uuid().v4(), name: nameController.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workspace "${nameController.text}" created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(allWorkspacesProvider);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;

        if (event.logicalKey == LogicalKeyboardKey.keyK &&
            HardwareKeyboard.instance.isMetaPressed) {
          _showCommandPalette();
        } else if (event.logicalKey == LogicalKeyboardKey.keyF &&
            HardwareKeyboard.instance.isMetaPressed) {
          _toggleFocusMode();
        }
      },
      child: workspacesAsync.when(
        data: (workspaces) => AppDesktopShell(
          selectedWorkspace: _selectedWorkspace ?? (workspaces.isNotEmpty ? workspaces.first : null),
          workspaces: workspaces,
          onWorkspaceSelected: (workspace) {
            setState(() => _selectedWorkspace = workspace);
          },
          onCreateWorkspace: _onCreateWorkspace,
          selectedDestination: _selectedDestination,
          onDestinationSelected: (destination) {
            setState(() => _selectedDestination = destination);
          },
          child: _buildSelectedScreen(),
        ),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading data', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$err', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(allWorkspacesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedScreen() {
    // Lazy loading: use IndexedStack with mainIndex (only render visible screen)
    return IndexedStack(
      index: _selectedDestination.ordinal,
      sizing: StackFit.expand,
    children: const [
      KiyoshiZenDashboardView(),
      ProjectsScreen(),
      TasksScreen(),
      NotesScreen(),
      CalendarScreen(),
      AnalyticsScreen(),
      SettingsScreen(),
    ],
    );
  }
}
