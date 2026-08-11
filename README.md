# Kiyoshi

A minimalist glassmorphic Kanban workspace manager with a sophisticated **Zen Design System** aesthetic. Built with Flutter for desktop (Linux, macOS, Windows).

![Platform](https://img.shields.io/badge/Platform-Flutter%20Desktop-blue)
![Version](https://img.shields.io/badge/Version-1.0.1-green)
![License](https://img.shields.io/badge/License-MIT-green)
![AppImage](https://img.shields.io/badge/AppImage-ready-blue)
![RPM](https://img.shields.io/badge/RPM-ready-blue)

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

Kiyoshi is available for download for Linux, Windows, and macOS from the [GitHub Releases](https://github.com/jomvick/Kiyoshi/releases) page.

### Supported Formats

| Platform | File Format | Description |
|------------|-------------------|-------------|
| **Linux** | `.AppImage` | Portable, works on all distributions (Recommended) |
| **Linux** | `.rpm` | Native package for Fedora, RedHat, CentOS (system installation) |
| **Windows** | `.zip` | Portable archive, unzip and run (no installation required) |
| **macOS** | `.dmg` | Classic disk image, universal binary (Apple Silicon and Intel) |

---

### 🐧 Linux

#### Option 1: AppImage (portable — all distributions)
```bash
# Download the latest release
LATEST=$(curl -s https://api.github.com/repos/jomvick/Kiyoshi/releases/latest | \
  grep -oP '"browser_download_url":\s*"\K[^"]+(?=")' | \
  grep AppImage | head -1)
curl -L "$LATEST" -o Kiyoshi.AppImage
chmod +x Kiyoshi.AppImage
./Kiyoshi.AppImage
```

#### Option 2: RPM (Fedora / RHEL / CentOS)
```bash
# Download and install the latest release
LATEST_RPM=$(curl -s https://api.github.com/repos/jomvick/Kiyoshi/releases/latest | \
  grep -oP '"browser_download_url":\s*"\K[^"]+(?=")' | \
  grep '\.rpm' | head -1)
sudo dnf install "$LATEST_RPM"

# Launch the app
kiyoshi
```

---

### 🪟 Windows

1. Download the ZIP file `Kiyoshi-1.0.1-windows-x64.zip` from the Releases page.
2. Extract the archive to a folder of your choice (e.g., `C:\Program Files\Kiyoshi` or your user folder).
3. Double-click `kiyoshi.exe` to launch the application.

> [!NOTE]
> **Windows SmartScreen**: On first launch, Windows may show a security warning because the executable is not digitally signed. Click **More info** then **Run anyway**.

---

### 🍏 macOS

1. Download the DMG file `Kiyoshi-1.0.1-macos.dmg`.
2. Open the DMG file and drag-and-drop **Kiyoshi** into your **Applications** folder.
3. Launch the app from your Launchpad or your Applications folder.

> [!IMPORTANT]
> **Bypassing macOS Gatekeeper**: Since the app is not signed with a paid Apple developer certificate, macOS will block the first launch with an error message.
> * **Graphical method**: **Right-click** (or `Ctrl+click`) on the Kiyoshi app icon, select **Open**, then confirm the open in the dialog box.
> * **Terminal method**: If the block persists, run the following command in Terminal to remove the quarantine:
>   ```bash
>   xattr -d com.apple.quarantine /Applications/Kiyoshi.app
>   ```

---

## Building from Source

To build Kiyoshi yourself, you need the **Flutter SDK** and your platform's build tools installed.

### Common Prerequisites
Before building, run the Drift code generation:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 🐧 Linux
```bash
# Install system build dependencies
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libblkid-dev libjsoncpp-dev libsecret-1-dev

# Build the binary
flutter build linux --release

# Optional: Create the AppImage
./build_appimage.sh

# Optional: Create the RPM package
./build_rpm.sh
```

### 🪟 Windows
```bash
# Build the app for Windows
flutter build windows --release

# The compiled files are located in: build\windows\x64\runner\Release\
```

### 🍏 macOS
```bash
# Build the app for macOS (produces a universal x64/arm64 binary)
flutter build macos --release

# Optional: Create the DMG disk image
hdiutil create -volname "Kiyoshi" -srcfolder "build/macos/Build/Products/Release/kiyoshi.app" -ov -format UDZO "Kiyoshi-macos.dmg"
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|-----------|--------|
| `Cmd+K` / `Ctrl+K` | Open the command palette |
| `Cmd+F` / `Ctrl+F` | Toggle Zen / Focus mode |
| `/` | Start a slash command in the quick entry bar |

## Configuration

User preferences are persisted locally and editable via the Settings tab.

---

## 🚀 Publishing a Release (Developers)

The release process is fully automated using GitHub Actions. As soon as a version tag is pushed, the workflow builds and packages the app for all OSes.

1. Update the `VERSION` file (e.g., `1.0.2`).
2. Update the version in the `pubspec.yaml` file (e.g., `version: 1.0.2+2`).
3. Create a commit and a git tag:
   ```bash
   git add .
   git commit -m "release: v1.0.2"
   git tag v1.0.2
   ```
4. Push the commit and the tag to GitHub:
   ```bash
   git push origin master --tags
   ```

GitHub Actions will then:
* Build for Linux (generates `.AppImage` and `.rpm`).
* Build for Windows (generates `.zip`).
* Build for macOS (generates universal `.dmg`).
* Create a GitHub Release and automatically attach all these packages.

## License

MIT — See [LICENSE](./LICENSE) for details.

---

Built with Flutter
