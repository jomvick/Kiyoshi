# Kiyoshi Clean Architecture

## Architecture Overview

```
lib/
├── main.dart              # Application Entry Point
├── domain.dart           # Domain Layer - Entities & Repository Interfaces
├── data.dart            # Data Layer - Database & Services
├── core.dart            # Core Layer - Design System & Theme
├── presentation/
│   ├── screens.dart     # Screen exports
│   ├── widgets.dart    # Widget exports
│   └── providers.dart  # Riverpod providers (unified)
└── src/               # Original structure (legacy, for backward compatibility)
```

## Layer Responsibilities

### Domain Layer (`domain.dart`)
- **Entities**: Core business objects
  - `ZenBlock` - Canvas block content
  - `Workspace` - Project workspace
  - `Project` - Project within workspace  
  - `Task` / `TodoTask` - Kanban tasks
  - `Board` - Kanban board
- **Repositories**: Abstract interfaces
  - `IBlockRepository` - Block data operations

### Data Layer (`data.dart`)
- **Database**: Drift SQLite (auto-generated)
  - `AppDatabase` - Main database instance
  - `ProjectRepository` - Project CRUD operations
- **Services**: Application services
  - `BlockService` - Block operations
  - `ZenParser` - Block parsing
  - `MetadataService` - Link metadata
  - `VaultService` - Secret management

### Core Layer (`core.dart`)
- **Design System**
  - `ZenColors` - Color palette
  - `ZenTypography` - Font system
  - `KiyoshiZenTokens` - Design tokens
  - `AppTheme` - Material theme
- **Navigation**
  - `AppDestination` - Route destinations

### Presentation Layer
- **Screens** (`screens.dart`)
  - Dashboard, Projects, Tasks, Notes, Calendar, Analytics
  - Kanban Board, Canvas, Monolith
- **Widgets** (`widgets.dart`)
  - Shared UI components
  - Layout shells
- **Providers** (`providers.dart`)
  - Unified state management with Riverpod

## Migration Guide

### Old Import Style
```dart
import 'package:kiyoshi/src/features/projects/domain/entities/workspace.dart';
import 'package:kiyoshi/src/core/database/project_repository.dart';
```

### New Import Style (Recommended)
```dart
import 'package:kiyoshi/domain.dart';
import 'package:kiyoshi/data.dart';
```

Or specific exports:
```dart
import 'package:kiyoshi/presentation/screens.dart';
import 'package:kiyoshi/presentation/providers.dart';
```

## Benefits

1. **Separation of Concerns**: Clear layer boundaries
2. **Modularity**: Easy to replace implementations
3. **Testability**: Mock any layer
4. **Maintainability**: Single source of truth per layer
5. **Scalability**: Independent layer evolution