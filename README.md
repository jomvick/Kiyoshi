# Kiyoshi

A minimalist glassmorphic workspace manager with a sophisticated "Zen Design System" aesthetic. Built with Flutter for desktop platforms.

![Kiyoshi](https://img.shields.io/badge/Platform-Flutter%20Desktop-blue)
![License](https://img.shields.io/badge/License-Private-red)

## Features

### Core Modules

- **Dashboard** - Studio overview with activity timeline and performance metrics
- **Workspaces** - Organize projects by workspace with custom themes
- **Projects** - Full project CRUD with deadlines and status tracking
- **Kanban Board** - Drag-and-drop task management with columns
- **Calendar** - Schedule view with due dates and events
- **Canvas** - Block-based content (text, heading, todo, link, image, file, divider, code)
- **Notes** - Quick notes with rich block types

### Special Modes

- **Zen Mode** - "The Monolith" focus session for deep work
- **Quick Entry** - Slash commands (`/`) for fast block creation
- **Command Palette** - Keyboard-driven navigation (`Cmd+K`)

## Design System

### Philosophy

Kiyoshi implements a unique **Zen Design System**:

| Principle | Implementation |
|-----------|---------------|
| Glassmorphism | Frosted glass panels with backdrop blur |
| No-Line Rule | Visual separation without borders |
| Editorial Typography | Display/Mono fonts with tight tracking |
| Spectral Palette | Calming sage/slate color system |

### UI Components

- `GlassCard` - Frosted glass container
- `GlassPrismPanel` - Prism-effect glass panel
- `PrismaticBorderPainter` - Animated spectral border
- `KanbanCard` - Apple-inspired task card
- `ZenQuickEntry` - Morphing input bar
- `MorphingZenBar` - Animated dock navigation

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State | flutter_riverpod |
| Database | Drift (SQLite) |
| Animations | flutter_animate |
| Calendar | table_calendar |
| Icons | lucide_icons |
| Fonts | Google Fonts |

## Installation

```bash
# Clone
git clone https://github.com/jomvick/Kiyoshi.git
cd Kiyoshi

# Install deps
flutter pub get

# Generate Drift code
flutter pub run build_runner build --delete-conflicting-outputs

# Run
flutter run
```

### Desktop Targets

```bash
flutter run -d linux    # Linux
flutter run -d macos    # macOS  
flutter run -d windows  # Windows
```

### Build Release

```bash
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## Architecture

```
lib/
├── main.dart                    # Entry point
└── src/
    ├── app/                    # KiyoshiApp routing
    ├── core/
    │   ├── constants/          # zen_colors, zen_typography
    │   ├── database/           # Drift + ProjectRepository
    │   ├── design_system/      # kiyoshi_zen_tokens
    │   ├── navigation/         # app_destinations
    │   ├── providers/         # Riverpod providers
    │   ├── services/          # vault, metadata
    │   └── theme/            # AppTheme
    ├── features/
    │   ├── analytics/         # AnalyticsScreen
    │   ├── calendar/         # CalendarScreen
    │   ├── canvas/          # BlockCanvas + block widgets
    │   ├── dashboard/       # KiyoshiZenDashboardView
    │   ├── kanban_board/    # KanbanBoardScreen
    │   ├── navigation/      # MorphingZenBar
    │   ├── notes/          # NotesScreen
    │   ├── projects/       # ProjectsScreen + detail
    │   ├── tasks/          # TasksScreen
    │   └── zen/            # TheMonolithWidget
    └── shared/
        ├── layout/         # AppDesktopShell
        └── widgets/        # Shared UI components
```

## Database Schema

```
Blocks       # text, todo, link, image, file blocks
Workspaces   # project workspaces
Projects    # projects within workspaces
Tasks       # Kanban tasks
```

## Testing

```bash
# Run all tests
flutter test

# Specific test file
flutter test test/providers_test.dart
```

## Recent Changes

### v1.0.0
- Initial release
- Glassmorphism UI system
- Drift SQLite database
- Riverpod state management
- Full CRUD for workspaces, projects, tasks
- Zen Mode (Monolith) for focus sessions
- Quick Entry with slash commands

## License

Private - All rights reserved

---

Built with Flutter 💙