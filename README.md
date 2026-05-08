# Kiyoshi

A minimalist glassmorphic workspace manager with a sophisticated "Zen Design System" aesthetic. Built with Flutter for desktop platforms.

![Kiyoshi](https://img.shields.io/badge/Platform-Flutter%20Desktop-blue)
![Version](https://img.shields.io/badge/Version-1.0.0-green)
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

### Quick Install (One-line)

```bash
# AppImage (recommended)
curl -L https://github.com/jomvick/Kiyoshi/releases/latest/download/Kiyoshi-1.0.0-linux-x86_64.AppImage -o Kiyoshi.AppImage && chmod +x Kiyoshi.AppImage && ./Kiyoshi.AppImage
```

### Option 2: Portable Archive

```bash
# Download and extract
curl -L https://github.com/jomvick/Kiyoshi/releases/latest/download/Kiyoshi-1.0.0-linux-x86_64.AppImage -o Kiyoshi.AppImage
chmod +x Kiyoshi.AppImage
./Kiyoshi.AppImage
```

### Option 3: Portable Archive

```bash
# Download and extract
curl -L https://github.com/jomvick/kiyoshi/releases/latest/download/kiyoshi-linux.tar.gz -o kiyoshi.tar.gz
tar -xzf kiyoshi.tar.gz
cd kiyoshi

# Run
./kiyoshi
```

### Option 3: Build from Source

```bash
# Clone
git clone https://github.com/jomvick/Kiyoshi.git
cd Kiyoshi

# Install deps
flutter pub get

# Build
flutter build linux --release

# Run
./build/linux/x64/release/bundle/kiyoshi
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

## Auto-Update

Kiyoshi checks for updates automatically on startup. When a new version is available:
- You'll see a notification in the app
- Go to **Settings > Updates** to download

### Manual Update (CLI)

```bash
# Download latest release
curl -L https://github.com/jomvick/kiyoshi/releases/latest/download/Kiyoshi-linux.tar.gz -o kiyoshi.tar.gz

# Backup and extract
tar -xzf kiyoshi.tar.gz
cp -r kiyoshi/* /opt/kiyoshi/

# Restart app
kiyoshi
```

## License

Private - All rights reserved

---

Built with Flutter 💙