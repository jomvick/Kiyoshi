# ZenQuickEntry System - Technical Report

## Overview

The `ZenQuickEntry` (Prism-Bar) is a unified quick input widget used on the Dashboard and sub-pages for rapid task/block creation with smart syntax parsing.

---

## Architecture

### File Location
```
lib/src/shared/widgets/zen_quick_entry.dart
```

### Class Hierarchy
```
ZenQuickEntry (StatefulWidget)
    └── _ZenQuickEntryState (State with TickerProviderStateMixin)
```

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `onTaskCreated` | `Function` | Callback for task creation (dashboard mode) |
| `onBlockCreated` | `Function?` | Callback for block creation (canvas mode) |
| `focusNode` | `FocusNode?` | Optional external focus control |
| `isDashboard` | `bool` | true = always expanded, false = collapsible |

---

## Syntax Parser

### File Location
```
lib/src/features/canvas/application/zen_parser.dart
```

### Supported Syntax

| Input | Parsed As | Example |
|--------|----------|--------|
| `/note` | text block | `/note Ma note #projet1` |
| `/task` | todo block | `/task сделать #Core P1` |
| `#project` | project metadata | `#Design` |
| `P1-P3` | priority | `!1` |
| `@user` | assignee | `@john` |
| `# ` | heading | `# Titre` |
| `- [ ]` | todo unchecked | `- [ ] Acheter lait` |
| `- [x]` | todo checked | `- [x] Terminé` |

### Block Types
- `text` - Plain text note
- `heading` - Section heading  
- `todo` - Checkbox task
- `link` - URL link
- `image` - Image URL
- `code` - Code block (```dart)
- `divider` - Horizontal separator
- `database_view` - Kanban/board view

---

## Database Schema

### File Location
```
lib/src/core/database/database.dart
```

### Tables

#### 1. Blocks (Atomic Content)
```dart
class Blocks extends Table {
  TextColumn id      // UUID auto-generated
  TextColumn projectId // FK to Projects
  TextColumn type     // text, todo, link, image...
  TextColumn content  // The actual content
  TextColumn metadata // JSON (priority, assignee, etc.)
  RealColumn position // For ordering (1000, 2000...)
  TextColumn parentId // For nested blocks
  TextColumn createdAt // ISO timestamp
}
```

#### 2. Projects
```dart
class Projects extends Table {
  TextColumn id        // UUID
  TextColumn workspaceId // FK to Workspaces
  TextColumn title    // Project name
  TextColumn description
  TextColumn status   // not_started, in_progress, completed
  TextColumn deadline // ISO date
  TextColumn createdAt
  TextColumn updatedAt
}
```

#### 3. Workspaces
```dart
class Workspaces extends Table {
  TextColumn id
  TextColumn name
  TextColumn description
  TextColumn icon
  IntColumn colorValue  // Color as int
  RealColumn progress  // 0.0-1.0
}
```

#### 4. Tasks (Kanban)
```dart
class Tasks extends Table {
  TextColumn id
  TextColumn projectId
  TextColumn title
  TextColumn description
  TextColumn status     // todo, in_progress, done
  IntColumn priority   // 1-4 (P1=urgent)
  TextColumn dueDate
  RealColumn position
}
```

---

## Repository Layer

### File Location
```
lib/src/core/database/project_repository.dart
```

### Key Methods

```dart
// Blocks
addBlock(String projectId, ParsedBlock)
updateBlock(ZenBlock)
deleteBlock(ZenBlock)
getBlockById(String)
reorderBlocks(String, oldIndex, newIndex)

// Projects
addProject(Project) → String (id)
updateProject(Project)
deleteProject(String)
getProjectById(String) → Project?
watchProjectsForWorkspace(String) → Stream<List<Project>>

// Tasks
addTask(TodoTask) → String
updateTask(TodoTask)
deleteTask(String)
watchTasksForProject(String) → Stream<List<TodoTask>>

// Workspaces
addWorkspace(Workspace) → String
updateWorkspace(Workspace)
deleteWorkspace(String)
watchAllWorkspaces() → Stream<List<Workspace>>
```

---

## User Flow

### 1. Quick Entry Input
```
User types: "/note Ma note importante #Core P1 @john"
```

### 2. Parsing (ZenParser.parseRawInput)
```
type: "text"
content: "Ma note importante"
metadata: {
  "project": "Core",
  "priority": 1,
  "assignee": "john"
}
```

### 3. Block Creation
```
If onBlockCreated != null:
  → Call with (type, content, metadata)
  → Repository.addBlock(projectId, parsedBlock)
  
Else:
  → Call onTaskCreated for dashboard mode
```

### 4. Database Persistence
```dart
// In project canvas
await _repository.addBlock(projectId, ParsedBlock(
  type: 'text',
  content: 'Ma note importante',
  metadata: {'project': 'Core', 'priority': 1}
))
```

---

## UI States

### Collapsed (Sub-pages)
- Shows BotanicalLogo icon only
- Tap to expand

### Expanded (Dashboard + Focused)
- Full input bar with glass effect
- Animated prismatic border on focus
- Ghost menu (projects) above bar
- Slash menu (block types) above bar

### Visual Feedback (Badges)
| Badge | Color | Meaning |
|-------|-------|---------|
| `P1` | Pink | High priority |
| `P2` | Pink | Medium priority |
| `@john` | Teal | Assigned to user |
| `PROJ` | Primary | Project tagged |

---

## Ghost Menu (Project Selector)

### Trigger
- Types `#` in input

### Behavior
- Shows filtered list from `_projectSuggestions`
- Default: `['Design', 'Marketing', 'Core', 'Vision', 'Calm']`
- Tap to select → appends `#ProjectName ` with cursor positioned after

### Current Limitation
- Project list is static (hardcoded)
- To make dynamic: pass `projectList` from database via provider

---

## Integration Points

### Dashboard
- File: `lib/src/features/dashboard/kiyoshi_zen_dashboard_view.dart`
- Uses: `ZenQuickEntry` in expanded mode (always open)

### Canvas  
- File: `lib/src/features/canvas/presentation/block_canvas.dart`
- Uses: `_buildQuickEntry()` inline
- Has: `onCreateBlock` callback

### Project Detail
- File: `lib/src/features/projects/presentation/project_detail_view.dart`
- Uses: `ZenCanvas` with blocks

---

## Future Enhancements

### 1. Dynamic Project List
```dart
// Pass from provider
final projects = ref.watch(projectListProvider);
ZenQuickEntry(
  projectList: projects.map((p) => p.title).toList(),
  onBlockCreated: ...
)
```

### 2. Auto-Create Project
```dart
// In onBlockCreated
if (!projectExists(projectName)) {
  await projectRepository.addProject(Project(
    workspaceId: defaultWorkspace,
    title: projectName,
  ));
}
```

### 3. Priority Badges
```
P1 → #FF4D8D (urgent)
P2 → #FF4D8D (high)
P3 → #FFB800 (medium)
P4 → #22C55E (low)
```

---

## Implementation Status

### ✅ Complete Features

| Feature | Status |
|----------|--------|
| Static project list | Done |
| Dynamic project list from DB | ✅ Done |
| Auto-create project on submit | ✅ Done |
| Project selection from ghost menu | ✅ Done |
| Create from ghost menu | ✅ Done |
| Syntax parsing | ✅ Done |
| Block types | ✅ Done |
| Visual feedback badges | ✅ Done |

### Providers Added

```dart
// Get project titles for ghost menu
final quickEntryProjectsProvider = Provider<List<String>>((ref) {
  final workspace = ref.watch(selectedWorkspaceProvider);
  final projects = ref.watch(projectsForWorkspaceProvider(workspace.id));
  return projects.map((p) => p.title).toList();
});

// Create project callback
final createQuickEntryProjectProvider = Provider<Future<String?> Function(String)>((ref) {
  return (name) => repo.addProject(Project(...));
});
```

### Usage in Widget

```dart
ZenQuickEntry(
  onTaskCreated: ...,
  onBlockCreated: (type, content, metadata) {
    repo.addBlock(projectId, ParsedBlock(...));
  },
  projectList: ref.watch(quickEntryProjectsProvider),
  onCreateProject: ref.watch(createQuickEntryProjectProvider),
)
```

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_animate: ^4.5.0
  lucide_icons: ^0.257.0
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.21
  path_provider: ^2.1.3
  uuid: ^4.4.2
```

---

*Generated: May 2026*