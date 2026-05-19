import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/features/projects/domain/entities/project.dart';
import 'package:kiyoshi/src/core/providers/database_provider.dart';
import 'package:kiyoshi/src/shared/layout/zen_studio_page_shell.dart';
import 'package:kiyoshi/src/shared/widgets/project_card.dart';
import 'package:kiyoshi/src/features/projects/presentation/project_detail_view.dart';
import 'package:uuid/uuid.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  Workspace? _selectedWorkspace;

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(allWorkspacesProvider);

    return ZenStudioPageShell(
      title: 'PROJECTS',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.plus),
          onPressed: _showCreateProjectDialog,
        ),
      ],
      child: workspacesAsync.when(
        data: (workspaces) {
          if (workspaces.isEmpty) {
            return _buildEmptyState(context);
          }

          _selectedWorkspace ??= workspaces.first;

          return _buildWorkspaceContent(context, _selectedWorkspace!);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Could not load workspaces.')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.briefcase,
              size: 36,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No workspaces yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onBackground.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a workspace to organize your projects',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateProjectDialog,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('CREATE WORKSPACE'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceContent(BuildContext context, Workspace workspace) {
    final projectsAsync = ref.watch(projectsForWorkspaceProvider(workspace.id));

    return projectsAsync.when(
        data: (projects) => _buildProjectsList(context, projects, workspace),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Could not load projects.')),
      );
  }

  Widget _buildProjectsList(
    BuildContext context,
    List<Project> projects,
    Workspace workspace,
  ) {
    if (projects.isEmpty) {
      return _buildNoProjectsState(context, workspace);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProjectsHeader(projects.length),
        const SizedBox(height: AppTheme.spaceMedium),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: projects.length,
            itemExtent: 140, // Increased: header(40) + title(24) + desc(40) + footer(30) = ~134px + margin
            itemBuilder: (context, index) {
              final project = projects[index];
              return ProjectCard(
                project: project,
                onTap: () => _openProject(project),
                onEdit: () => _showEditProjectDialog(project),
                onDelete: () => _deleteProject(project),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoProjectsState(BuildContext context, Workspace workspace) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.folderPlus,
              size: 28,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No projects in this workspace',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onBackground.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project to get started',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateProjectDialog(workspaceId: workspace.id),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('CREATE PROJECT'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsHeader(int count) {
    return Row(
      children: [
        Text(
          'PROJECTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground.withValues(alpha: 0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _openProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailView(
          project: project,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showCreateProjectDialog({String? workspaceId, Workspace? workspace}) {
    showDialog(
      context: context,
      builder: (context) => _CreateProjectDialog(
        workspaceId: workspaceId,
        workspace: workspace ?? _selectedWorkspace,
      ),
    );
  }

  void _showEditProjectDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => _EditProjectDialog(project: project),
    );
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(project.id);
      } catch (e) {
        debugPrint('Could not delete project: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete project.')),
          );
        }
      }
    }
  }
}

class _CreateProjectDialog extends ConsumerStatefulWidget {
  final String? workspaceId;
  final Workspace? workspace;

  const _CreateProjectDialog({this.workspaceId, this.workspace});

  @override
  ConsumerState<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<_CreateProjectDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final workspaceId = widget.workspaceId ?? widget.workspace?.id;
    if (_titleController.text.trim().isEmpty || workspaceId == null) return;

    final project = Project.create(
      id: const Uuid().v4(),
      workspaceId: workspaceId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _deadline,
    );

    try {
      await ref.read(projectRepositoryProvider).addProject(project);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to create project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create project.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: AppTheme.glassPanel(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEW PROJECT',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                hintText: 'Enter project title',
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter project description',
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Deadline',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _deadline = date);
                    }
                  },
                  child: Text(
                    _deadline != null
                        ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                        : 'Set deadline',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleCreate,
                  child: const Text('CREATE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProjectDialog extends ConsumerStatefulWidget {
  final Project project;

  const _EditProjectDialog({required this.project});

  @override
  ConsumerState<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends ConsumerState<_EditProjectDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _deadline;
  late ProjectStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _descriptionController = TextEditingController(text: widget.project.description);
    _deadline = widget.project.deadline;
    _status = widget.project.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_titleController.text.trim().isEmpty) return;

    final updated = widget.project.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _deadline,
      status: _status,
    );

    try {
      await ref.read(projectRepositoryProvider).updateProject(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to update project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update project.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: AppTheme.glassPanel(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EDIT PROJECT',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Project Title',
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                DropdownButton<ProjectStatus>(
                  value: _status,
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                  items: ProjectStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleUpdate,
                  child: const Text('SAVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}