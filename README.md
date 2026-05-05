# Kiyoshi

A minimalist glassmorphic Kanban productivity app with a sophisticated "Zen Design System" aesthetic. Built with Flutter for desktop platforms.

## Features

- **Dashboard** - Studio overview with activity timeline and metrics
- **Projects** - Workspace/project management
- **Tasks** - Kanban board with drag-and-drop cards
- **Calendar** - Calendar view for scheduling
- **Analytics** - Productivity metrics and insights
- **Canvas** - Block-based note/todo system with multiple block types

## Design System

Kiyoshi features a unique "Zen Design System" with:

- **Glassmorphism** - Frosted glass panels with backdrop blur
- **No-Line Rule** - Minimal borders, uses visual separation
- **Editorial Typography** - Montserrat (display), Inter (body), JetBrains Mono (code)
- **Sage/Slate Palette** - Calming, productivity-focused colors

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| State Management | flutter_riverpod |
| Database | Drift (SQLite) |
| UI/Animations | flutter_animate, animations |
| Calendar | table_calendar |
| Icons | lucide_icons |

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- Dart SDK 3.11+
- Desktop development tools (for Linux: `flutter doctor`)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate database code:
   ```bash
   flutter pub run build_runner build
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Desktop Targets

```bash
flutter run -d linux    # Linux
flutter run -d macos    # macOS
flutter run -d windows  # Windows
```

## Architecture

```
lib/
├── main.dart
└── src/
    ├── app/                    # App widget and routing
    ├── core/                   # Core utilities
    │   ├── constants/          # Colors, typography
    │   ├── database/           # Drift database + repositories
    │   ├── design_system/      # Design tokens
    │   ├── navigation/         # App destinations
    │   ├── providers/          # Riverpod providers
    │   ├── services/           # Vault, metadata services
    │   └── theme/              # AppTheme
    ├── features/               # Feature modules
    │   ├── analytics/
    │   ├── calendar/
    │   ├── canvas/
    │   ├── dashboard/
    │   ├── kanban_board/
    │   ├── projects/
    │   └── tasks/
    └── shared/                 # Shared UI
        ├── layout/             # Desktop shell, page shells
        └── widgets/           # Reusable widgets
```

## Testing

```bash
flutter test
```

## License

Private project - all rights reserved