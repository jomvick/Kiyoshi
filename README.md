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

Kiyoshi est disponible en téléchargement pour Linux, Windows et macOS depuis la page des [Releases GitHub](https://github.com/jomvick/Kiyoshi/releases).

### Formats pris en charge

| Plateforme | Format de fichier | Description |
|------------|-------------------|-------------|
| **Linux** | `.AppImage` | Portable, fonctionne sur toutes les distributions (Recommandé) |
| **Linux** | `.rpm` | Paquet natif pour Fedora, RedHat, CentOS (Installation système) |
| **Windows** | `.zip` | Archive portable, à décompresser et lancer (Sans installation) |
| **macOS** | `.dmg` | Image disque classique, binaire universel (Apple Silicon et Intel) |

---

### 🐧 Linux

#### Option 1 : AppImage (portable — toutes distributions)
```bash
# Télécharger la dernière version
LATEST=$(curl -s https://api.github.com/repos/jomvick/Kiyoshi/releases/latest | \
  grep -oP '"browser_download_url":\s*"\K[^"]+(?=")' | \
  grep AppImage | head -1)
curl -L "$LATEST" -o Kiyoshi.AppImage
chmod +x Kiyoshi.AppImage
./Kiyoshi.AppImage
```

#### Option 2 : RPM (Fedora / RHEL / CentOS)
```bash
# Télécharger et installer la dernière version
LATEST_RPM=$(curl -s https://api.github.com/repos/jomvick/Kiyoshi/releases/latest | \
  grep -oP '"browser_download_url":\s*"\K[^"]+(?=")' | \
  grep '\.rpm' | head -1)
sudo dnf install "$LATEST_RPM"

# Lancer l'application
kiyoshi
```

---

### 🪟 Windows

1. Téléchargez le fichier ZIP `Kiyoshi-1.0.1-windows-x64.zip` depuis les Releases.
2. Extrayez l'archive dans le dossier de votre choix (ex: `C:\Program Files\Kiyoshi` ou votre dossier utilisateur).
3. Double-cliquez sur `kiyoshi.exe` pour lancer l'application.

> [!NOTE]
> **Windows SmartScreen** : Lors du premier lancement, Windows peut afficher un avertissement de sécurité car l'exécutable n'est pas signé numériquement. Cliquez sur **Informations complémentaires** puis sur **Exécuter quand même**.

---

### 🍏 macOS

1. Téléchargez le fichier DMG `Kiyoshi-1.0.1-macos.dmg`.
2. Ouvrez le fichier DMG et glissez-déposez **Kiyoshi** dans votre dossier **Applications**.
3. Lancez l'application depuis votre Launchpad ou votre dossier Applications.

> [!IMPORTANT]
> **Contourner macOS Gatekeeper** : L'application n'étant pas signée avec un certificat de développeur Apple payant, macOS bloquera le premier lancement avec un message d'erreur.
> * **Méthode graphique** : Faites un **clic droit** (ou `Ctrl+clic`) sur l'icône de l'application Kiyoshi, sélectionnez **Ouvrir**, puis confirmez l'ouverture dans la boîte de dialogue.
> * **Méthode Terminal** : Si le blocage persiste, exécutez la commande suivante dans le Terminal pour lever la quarantaine :
>   ```bash
>   xattr -d com.apple.quarantine /Applications/Kiyoshi.app
>   ```

---

## Compilation depuis les sources

Pour compiler Kiyoshi vous-même, vous devez avoir installé le **SDK Flutter** ainsi que les outils de build de votre plateforme.

### Prérequis communs
Avant de compiler, exécutez la génération de code Drift :
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 🐧 Linux
```bash
# Installer les dépendances système de build
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libblkid-dev libjsoncpp-dev libsecret-1-dev

# Compiler le binaire
flutter build linux --release

# Optionnel : Créer l'AppImage
./build_appimage.sh

# Optionnel : Créer le paquet RPM
./build_rpm.sh
```

### 🪟 Windows
```bash
# Compiler l'application pour Windows
flutter build windows --release

# Les fichiers compilés se trouvent dans : build\windows\x64\runner\Release\
```

### 🍏 macOS
```bash
# Compiler l'application pour macOS (produit un binaire universel x64/arm64)
flutter build macos --release

# Optionnel : Créer l'image disque DMG
hdiutil create -volname "Kiyoshi" -srcfolder "build/macos/Build/Products/Release/kiyoshi.app" -ov -format UDZO "Kiyoshi-macos.dmg"
```

---

## Raccourcis Clavier

| Raccourci | Action |
|-----------|--------|
| `Cmd+K` / `Ctrl+K` | Ouvrir la palette de commandes |
| `Cmd+F` / `Ctrl+F` | Activer/Désactiver le mode Zen / Focus |
| `/` | Démarrer une commande slash dans la barre de saisie rapide |

## Configuration

Les préférences utilisateur sont persistées localement et modifiables via l'onglet Settings.

---

## 🚀 Publier une mise à jour (Développeurs)

Le processus de release est entièrement automatisé à l'aide de GitHub Actions. Dès qu'un tag de version est poussé, le workflow compile et package l'application pour tous les OS.

1. Mettez à jour le fichier `VERSION` (ex: `1.0.2`).
2. Mettez à jour la version dans le fichier `pubspec.yaml` (ex: `version: 1.0.2+2`).
3. Créez un commit et un tag git :
   ```bash
   git add .
   git commit -m "release: v1.0.2"
   git tag v1.0.2
   ```
4. Poussez le commit et le tag sur GitHub :
   ```bash
   git push origin master --tags
   ```

GitHub Actions prendra le relais pour :
* Compiler pour Linux (génère `.AppImage` et `.rpm`).
* Compiler pour Windows (génère `.zip`).
* Compiler pour macOS (génère `.dmg` universel).
* Créer une Release GitHub et y attacher automatiquement tous ces packages.

## License

MIT — Voir [LICENSE](./LICENSE) pour plus de détails.

---

Built with Flutter

