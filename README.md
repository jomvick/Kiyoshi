# Kiyoshi

A minimalist glassmorphic Kanban workspace manager with a sophisticated **Zen Design System** aesthetic. Built with Flutter for desktop (Linux, macOS, Windows).

![Platform](https://img.shields.io/badge/Platform-Flutter%20Desktop-blue)
![Version](https://img.shields.io/badge/Version-1.0.0-green)
![License](https://img.shields.io/badge/License-Private-red)

## Overview

Kiyoshi is a desktop productivity tool that blends Kanban task management, project organization, calendar scheduling, and a block-based canvas into a single, cohesive workspace. Its design philosophy centers on calm, focus, and visual clarity through glassmorphism and editorial typography.

## Features

### Core Modules

- **Dashboard** — Zen overview with activity timeline, performance metrics, and ambient background
- **Projects** — Full project CRUD with deadlines, status tracking (active/on-hold/completed/archived)
- **Kanban Board** — Drag-and-drop task management with customizable columns (To Do / In Progress / Done)
- **Calendar** — Schedule view with due dates and event mapping from blocks
- **Canvas** — Block-based content editor supporting text, heading, todo, link, image, file, divider, code
- **Notes** — Quick notes with rich block types
- **Analytics** — Progress tracking and statistics
- **Settings** — Full configuration panel with persistent preferences

### Smart Input

- **Quick Entry / MorphingZenBar** — Centralized input bar with slash commands:
  - `/task` — Create a task (type: todo)
  - `/note` — Create a note (type: text)
  - `/event` or `/schedule` — Navigate to Calendar
  - `/project` — Create a project
  - Date parsing (`today`, `tomorrow`, `at 3pm`)
  - Priority tagging (`!1`, `!2`, `!3`, `!4`)
  - Assignee tagging (`@name`)
  - Project mentions (`#project`)
- **Command Palette** — Keyboard-driven navigation (`Cmd+K`)
- **Focus Mode** — Toggle zen mode (`Cmd+F`)

### Special Modes

- **Zen Mode** — "The Monolith" focus session for deep work; collapses UI to essentials
- **Prismatic Borders** — Animated spectral rainbow borders on focus

## Design System

### Philosophy

| Principle | Implementation |
|-----------|---------------|
| Glassmorphism | Frosted glass panels with backdrop blur and opacity layers |
| No-Line Rule | Visual separation achieved through shadows, spacing, and color — not borders |
| Editorial Typography | Inter (body) + Montserrat (display) + JetBrains Mono (code) with tight tracking |
| Spectral Palette | Calming sage/slate/mint color system with warm accent tones |
| Frame Within a Frame | Content is always inset within a padded container for breathing room |

### UI Components

| Component | Description |
|-----------|-------------|
| `GlassCard` | Frosted glass container with backdrop blur |
| `GlassPrismPanel` | Prism-effect glass panel with spectral border |
| `PrismaticBorderPainter` | Animated rainbow gradient border using CustomPainter |
| `KanbanCard` | Apple-inspired task card with hover/expand animation |
| `MorphingZenBar` | Animated input bar that expands on focus |
| `ZenEditorialHeader` | Typographic header with label, title, and optional progress |
| `AmbientZenBackground` | Animated gradient orbs and noise texture |
| `ZenGlassCard` | Reusable glass card with configurable blur and opacity |
| `PrismaticBorderPainter` | Custom painter for animated rainbow borders |

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x (SDK ^3.11.4) |
| State | flutter_riverpod (StateNotifier + Providers) |
| Database | Drift (SQLite) with code generation |
| Animations | flutter_animate, animations package |
| Calendar | table_calendar |
| Icons | lucide_icons |
| Fonts | Google Fonts (Inter, Montserrat, JetBrains Mono) |
| Drag & Drop | flutter_draggable_gridview |
| Storage | shared_preferences |
| Build | build_runner + drift_dev |

## Architecture

```
lib/
├── main.dart                        # Entry point, Vault init, ProviderScope
└── src/
    ├── app/                         # KiyoshiApp with MaterialApp + theme routing
    ├── core/
    │   ├── constants/               # zen_colors, zen_typography
    │   ├── database/                # Drift database, ProjectRepository, Blocks/Workspaces/Projects/Tasks tables
    │   ├── design_system/           # kiyoshi_zen_tokens (spectral colors, glass tokens)
    │   ├── navigation/              # AppDestination enum (dashboard, projects, tasks, notes, calendar, analytics, settings)
    │   ├── providers/               # Riverpod providers (database, preferences, zen_mode)
    │   ├── services/                # VaultService, MetadataService, UpdateService
    │   └── theme/                   # AppTheme (light + dark, glass panel helpers, typography)
    ├── features/
    │   ├── analytics/               # Analytics screen
    │   ├── calendar/                # Calendar with table_calendar + block event loading
    │   ├── canvas/                  # Zen block system: ZenParser, ParsedBlock, ZenBlock entity
    │   ├── dashboard/               # KiyoshiZenDashboardView
    │   ├── kanban_board/            # Main shell: KanbanBoardScreen, Board/Task/TodoTask entities
    │   ├── navigation/              # MorphingZenBar with slash commands
    │   ├── notes/                   # Notes screen
    │   ├── projects/                # Projects CRUD: ProjectsScreen, ProjectDetailView, Workspace entity
    │   ├── tasks/                   # Tasks screen with Kanban columns
    │   ├── settings/                # Settings + update screen
    │   └── zen/                     # The Monolith focus widget
    └── shared/
        ├── layout/                  # AppDesktopShell (responsive sidebar + content), ZenStudioPageShell
        └── widgets/                 # Shared: Sidebar, KanbanCard, KanbanColumn, ZenGlassCard, CommandPalette, etc.
```

## Installation

### Download from CLI

```bash
# Get the latest release URL
LATEST=$(curl -s https://api.github.com/repos/jomvick/Kiyoshi/releases/latest | \
  grep -oP '"browser_download_url":\s*"\K[^"]+(?=")' | \
  grep AppImage | head -1)

# Download
curl -L "$LATEST" -o Kiyoshi.AppImage

# Make executable
chmod +x Kiyoshi.AppImage

# Run
./Kiyoshi.AppImage
```

### Build AppImage from Source

**Méthode recommandée — `appimage-builder`** (compatible toutes distros) :

```bash
# Fedora : installer dpkg (requis par appimage-builder)
sudo dnf install dpkg

# Ubuntu/Debian : déjà disponible

# Depuis la racine du projet
pip3 install appimage-builder
dart run build_runner build --delete-conflicting-outputs
flutter build linux --release
./build_appimage.sh
# Output: Kiyoshi-1.0.0-x86_64.AppImage
```

Le script `build_appimage.sh` détecte et installe `dpkg` automatiquement sur Fedora, puis utilise `appimage-builder`.

### Build from Source (raw binary)

```bash
git clone https://github.com/jomvick/Kiyoshi.git
cd Kiyoshi
flutter pub get
flutter build linux --release
./build/linux/x64/release/bundle/kiyoshi
```

> **Note:** Toutes les commandes `flutter` et `./build_appimage.sh` doivent être exécutées depuis la racine du projet (`Kiyoshi/`).

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+K` | Open Command Palette |
| `Cmd+F` | Toggle Focus / Zen Mode |
| `/` | Begin slash command in Quick Entry |

## Testing

```bash
flutter test
flutter test test/widget_test.dart
```

## Configuration

Preferences are persisted via `shared_preferences` and exposed through Riverpod:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Sidebar Expanded | bool | true | Show/hide the full sidebar |
| Sidebar Width | double | 280px | Adjustable sidebar width (200-400px) |
| Dark Mode | bool | false | Switch between light/dark themes |
| Prismatic Borders | bool | true | Animated rainbow borders on focus |
| Zen Mode Default | bool | false | Start app in focus mode |
| Notifications | bool | true | Show snackbar feedback |
| Default Page | string | projects | Startup destination |
| Auto-save | bool | true | Save changes automatically |
| Kanban Column Width | double | 300px | Default column width (250-500px) |
| Show Grid | bool | true | Display canvas grid lines |
| Snap to Grid | bool | true | Align blocks to grid |

## Auto-Update

Kiyoshi checks for updates automatically on startup via the GitHub Releases API. When a new version is available, a notification appears in the app.

### Mise à jour manuelle

```bash
# Télécharger la dernière version
wget https://github.com/jomvick/Kiyoshi/releases/latest/download/Kiyoshi-x86_64.AppImage

# Remplacer l'ancienne
chmod +x Kiyoshi-x86_64.AppImage
mv Kiyoshi-x86_64.AppImage ~/Applications/Kiyoshi.AppImage
```

### Via script CLI

```bash
LATEST=$(curl -s https://api.github.com/repos/jomvick/Kiyoshi/releases/latest | \
  grep -oP '"browser_download_url":\s*"\K[^"]+(?=")' | \
  grep AppImage | head -1)

curl -L "$LATEST" -o ~/Applications/Kiyoshi.AppImage
chmod +x ~/Applications/Kiyoshi.AppImage
```

### Publier une mise à jour (développeur)

```bash
echo "1.1.0" > VERSION
# Éditer pubspec.yaml : version: 1.1.0+2
git add .
git commit -m "release: v1.1.0"
git tag v1.1.0
git push origin master --tags
```

GitHub Actions build et publie l'AppImage automatiquement sur la Release.

## License

Private — All rights reserved

---

Built with Flutter
