# RAPPORT TECHNIQUE AVANCÉ - KIYOSHI ZEN STUDIO

## 1. RÉSUMÉ EXÉCUTIF

**Kiyoshi** est une application de productivité desktop Flutter avec un design "glassmorphic zen" unique. Elle combine gestion de tâches Kanban, blocs atomiques, calendrier et analytics dans un environnement minimaliste inspiré de l'esthétique japonaise.

**Version** : 1.0.0+1  
**Stack** : Flutter 3.11+ / Dart 3.11+ / Drift (SQLite) / Riverpod

---

## 2. ARCHITECTURE TECHNIQUE

### 2.1 Structure des Modules

```
lib/src/
├── app/                    # Point d'entrée (KanbanBoardScreen)
├── core/
│   ├── constants/          # ZenColors, ZenTypography
│   ├── database/           # Drift (database.dart + project_repository.dart)
│   ├── design_system/      # KiyoshiZenTokens
│   ├── navigation/         # AppDestination enum
│   ├── providers/          # Tous les Riverpod providers
│   ├── services/          # VaultService, MetadataService
│   └── theme/             # AppTheme avec glassmorphism
├── features/
│   ├── analytics/         # Écrans analytiques
│   ├── calendar/          # TableCalendar integration
│   ├── canvas/            # Block-based editor (domaine/application/presentation)
│   ├── dashboard/         # Vue principale
│   ├── kanban_board/      # Domain entities (Board, Task)
│   ├── navigation/        # MorphingZenBar
│   ├── projects/          # Workspace management
│   ├── tasks/             # Kanban board view
│   └── zen/               # TheMonolithWidget (focus mode)
└── shared/
    ├── layout/            # AppDesktopShell, ZenStudioPageShell
    └── widgets/           # 15+ composants réutilisables
```

### 2.2 Design Patterns

- **Clean Architecture** : Domain/Application/Presentation separation
- **Repository Pattern** : ProjectRepository (implémente IBlockRepository)
- **Provider Pattern** : Riverpod pour state management
- **Entity Pattern** : ZenBlock, Workspace, Board, Task

---

## 3. SYSTÈME DE BASE DE DONNÉES

### 3.1 Schema Drift

| Table | Colonnes |
|-------|----------|
| **Blocks** | id (UUID), projectId, type, content, metadata (JSON), position |
| **Workspaces** | id (UUID), name, description, icon, colorValue, progress |

### 3.2 Migration Strategy (schema v1 → v3)

- `v2` : Ajout colonne `position` (indexation fractionnaire)
- `v3` : Création table `Workspaces`

### 3.3 Queries Principales

- `watchBlocksForProject()` : Stream reactif
- `watchAllWorkspaces()` : Subscribe aux changements
- `reorderBlocks()` : Indexation fractionnaire pour reorder O(1)

---

## 4. SYSTÈME DE BLOCS ATOMIQUES (Phase 3)

### 4.1 Types de Blocs Supportés

| Type | Description | Commandes |
|------|-------------|-----------|
| `text` | Note classique | Saisie libre |
| `todo` | Task avec checkbox | `- [ ] ` / `- [x] ` |
| `heading` | Titre | `# ` |
| `link` | Lien URL | `https://...` |
| `image` | Image URL | `/img URL` ou `.png/.jpg` |
| `code` | Bloc code | ` ```lang ` |
| `file` | Fichier | (via UI) |
| `divider` | Séparateur | (via UI) |

### 4.2 ZenParser - Analyse Sémantique

```
# Meeting notes !1 @john #project → heading + priority + assignee + project
```

- Expressions régulières pré-compilées pour performance
- Extraction de métadonnées : priority (!1-4), assignee (@name), project (#name)
- Détection d'intent : slash commands, mentions projet

---

## 5. INTERFACE UTILISATEUR

### 5.1 Zen Design System

- **Palette** : Sauge (#C8E6C9) / Ardoise (#1E293B) / Canvas (#F5F5F5)
- **Glassmorphism** : blurSigma=10, glassFill=40% blanc, glassBorder=30% blanc
- **Typographie** : Montserrat (display), Inter (body), JetBrains Mono (code)
- **Corner Radius** : Standardisé à 20px (radiusLarge)
- **Animations** : Fast=200ms, Medium=350ms, Slow=500ms

### 5.2 Écrans Principaux

1. **Dashboard** : Studio overview avec timeline + metrics
2. **Projects** : Gestion workspaces
3. **Tasks** : Kanban board (To Do / In Progress / Done)
4. **Calendar** : TableCalendar avec events
5. **Analytics** : Métriques d'efficacité

### 5.3 Widgets Clés

- `BotanicalLogo` : Logo avec halo prismatique
- `GlassPrismPanel` / `ZenGlassCard` : Containers glass
- `PrismaticBorderPainter` : Bordure iridescente animée
- `AmbientZenBackground` : Gradients de fond
- `TheMonolithWidget` : Mode focus immersif

---

## 6. FONCTIONNALITÉS AVANCÉES

### 6.1 Command Palette (⌘K)

- Raccourci clavier global
- Actions : New task, New board, Focus mode
- Recherche par keywords

### 6.2 Zen Mode

- Mode focus immersif (sidebar masquée)
- Widget "Monolith" centré
- Sortie via bouton ou raccourci (⌘F)

### 6.3 Drag & Drop

- ReorderableList pour blocs canvas
- Kanban columns pour tasks
- Indexation fractionnaire pour persistance

### 6.4 Quick Entry Bar

- Saisie rapide sur dashboard
- Parsing sémantique automatique
- Création instantanée de blocs

---

## 7. DÉPENDANCES

### 7.1 Packages Principaux

| Package | Version | Usage |
|---------|---------|-------|
| `flutter_riverpod` | ^2.5.1 | State management |
| `drift` | ^2.14.1 | ORM SQLite |
| `sqlite3_flutter_libs` | ^0.5.18 | Bindings SQLite |
| `flutter_animate` | ^4.5.0 | Animations |
| `table_calendar` | ^3.1.2 | Calendrier |
| `lucide_icons` | ^0.257.0 | Icônes |
| `google_fonts` | ^6.1.0 | Typographie |
| `metadata_fetch` | ^0.4.2 | Métadonnées URL |
| `uuid` | ^4.5.3 | Génération IDs |

### 7.2 Dev Dependencies

| Package | Version | Usage |
|---------|---------|-------|
| `drift_dev` | ^2.14.1 | Génération code |
| `build_runner` | ^2.4.8 | Code generation |
| `flutter_lints` | ^6.0.0 | Analyse statique |

---

## 8. ÉTAT DE L'APPLICATION

### 8.1 Statut Actuel

| Aspect | État |
|--------|------|
| Build | ✅ Linux release compilé |
| Tests | ✅ 5 fichiers test |
| Database | ✅ Drift + migrations |
| UI | ✅ Glassmorphism complet |
| Features | ⚠️ Partiellement implémenté |

### 8.2 Points à Noter

- `main.dart` non trouvé (point d'entrée dans `lib/src/`)
- Certaines features (canvas blocks) non connectées à l'UI principale
- Kanban board limité à 3 colonnes hardcodées
- Calendar dépend des métadonnées `dueDate` dans blocks

---

## 9. RECOMMANDATIONS

### 9.1 Améliorations Prioritaires

1. **Connecter le canvas** à l'UI principale (actuellement Dashboard/Tasks/Projects ne l'utilisent pas)
2. **Implémenter drag & drop** complet pour Kanban
3. **Ajouter persistence** des préférences (SharedPreferences non utilisé)
4. **Internationalisation** (intl importé mais non utilisé)

### 9.2 Optimisations

- Lazy loading pour les listes
- Pagination pour les blocs
- Mise en cache des métadonnées URL

### 9.3 Tests

- Tests unitaires pour ZenParser
- Tests d'intégration pour les repositories
- Tests widget pour les composants UI

### 9.4 Sécurité

- Valider les URLs avant fetch metadata
- Échapper les inputs utilisateur dans le parser
- Ajouter rate limiting sur les requêtes metadata

---

## 10. ENTITÉS DE DOMAINE

### 10.1 ZenBlock

```dart
class ZenBlock {
  final String id;
  final String projectId;
  final String type;           // text, todo, heading, link, image, file, code, divider
  final String content;
  final Map<String, dynamic> metadata;
  final double position;     // Indexation fractionnaire pour reorder
}
```

### 10.2 Workspace

```dart
class Workspace {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Color themeColor;
  final double progress;
  final List<String> boardIds;
}
```

### 10.3 Board & Task

```dart
class Board {
  final String id;
  final String workspaceId;
  final String title;
  final int order;
}

enum TaskPriority { low, medium, high }
enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  final String boardId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final List<String> tags;
  final String? timeIndicator;
  final int? progress;
}
```

---

## 11. COMPOSANTS UI (WIDGETS)

### 11.1 Conteneurs Glassmorphism

| Widget | Description |
|--------|-------------|
| `GlassPrismPanel` | Panel frost avec blur 10, spectral outline optionnel |
| `ZenGlassCard` | Carte glass avec padding et enfants |
| `GlassCard` | Carte de base avec thème |
| `AmbientZenBackground` | Fond misty avec orbes sage/mint + bruit |

### 11.2 Navigation & Layout

| Widget | Description |
|--------|-------------|
| `AppDesktopShell` | Shell desktop (sidebar + contenu) |
| `ZenStudioPageShell` | Wrapper pour écrans feature |
| `BotanicalLogo` | Logo botanique avec halo prismatique optionnel |

### 11.3 Kanban

| Widget | Description |
|--------|-------------|
| `KanbanColumn` | Colonne Kanban (To Do/In Progress/Done) |
| `KanbanCard` | Carte task glass avec animations, checkbox, priority |

### 11.4 Canvas Blocks

| Widget | Description |
|--------|-------------|
| `NoteBlockWidget` | Bloc note texte |
| `TodoBlockWidget` | Bloc todo avec checkbox |
| `HeadingBlockWidget` | Bloc titre |
| `LinkBlockWidget` | Bloc lien avec favicon |
| `ImageBlockWidget` | Bloc image |
| `FileBlockWidget` | Bloc fichier |
| `CodeBlockWidget` | Bloc code |
| `DividerBlockWidget` | Séparateur |

### 11.5 Utilitaires

| Widget | Description |
|--------|-------------|
| `CommandPalette` | Palette de commandes (⌘K) |
| `PrismaticBorderPainter` | Bordure arc-en-ciel animée |
| `PrismaticPainter` | Effet "light leak" réactif à la souris |
| `SettingsDialog` | Dialog paramètres |
| `ZenQuickEntry` | Barre de saisie rapide |
| `SmartBarController` | Controller pour saisies intelligentes |

---

## 12. SERVICES

### 12.1 VaultService

Gestion des fichiers (images, documents) avec copie locale.

```dart
class VaultService {
  Future<String> copyToVault(String originalPath);
  Future<void> deleteFromVault(String vaultPath);
}
```

**Chemin** : `~/Documents/kiyoshi/vault/`

### 12.2 MetadataService

Enrichissement asynchrone des liens (extraction titre, favicon).

```dart
class MetadataService {
  Future<void> enrichBlockIfNeeded(String blockId);
}
```

---

## 13. PROVIDERS (Riverpod)

| Provider | Type | Description |
|----------|------|-------------|
| `databaseProvider` | `Provider<AppDatabase>` | Instance Drift |
| `projectRepositoryProvider` | `Provider<ProjectRepository>` | Repository principal |
| `blockRepositoryProvider` | `Provider<IBlockRepository>` | Alias |
| `metadataServiceProvider` | `Provider<MetadataService>` | Service métadonnées |
| `vaultServiceProvider` | `Provider<VaultService>` | Service fichier |
| `blockServiceProvider` | `Provider<BlockService>` | Service blocs |
| `projectBlocksProvider` | `StreamProvider.family<List<ZenBlock>, String>` | Blocs par projet |
| `allWorkspacesProvider` | `StreamProvider<List<Workspace>>` | Tous workspaces |
| `globalStatsProvider` | `StreamProvider<Map<String, dynamic>>` | Stats globales |
| `latestActivitiesProvider` | `StreamProvider<List<ZenBlock>>` | Activités récentes |
| `calendarEventsProvider` | `StreamProvider<List<ZenBlock>>` | Événements calendrier |
| `zenModeProvider` | `StateProvider<bool>` | Mode focus activé |

---

## 14. FONCTIONNALITÉS PAR ÉCRAN

### 14.1 Dashboard (`kiyoshi_zen_dashboard_view.dart`)

- Overview studio avec timeline activité
- Métriques : total blocks, tasks, completed, efficiency
- Quick Entry bar pour création rapide
- Bouton "Enter Zen" pour mode focus

### 14.2 Projects (`projects_screen.dart`)

- Liste des workspaces
- Création workspace via dialog
- Sélection workspace dans sidebar

### 14.3 Tasks (`tasks_screen.dart`)

- Kanban board 3 colonnes : To Do / In Progress / Done
- Drag & drop entre colonnes
- Reorder des tâches
- Création tâche via dialog

### 14.4 Calendar (`calendar_screen.dart`)

- TableCalendar (month view)
- Agenda jour sélectionnée
- Événements depuis métadonnées `dueDate`

### 14.5 Analytics (`analytics_screen.vue`)

- Métriques clés en grid
- CircularProgress efficacité
- Data summary

### 14.6 Canvas (`block_canvas.dart`)

- Liste de blocs réordonnables (drag & drop)
- Quick entry avec parser sémantique
- Types multiples (text, todo, heading, link, image, code, file, divider)

---

## 15. ÉTAT DES COMPOSANTS

| Composant | Statut | Notes |
|----------|-------|-------|
| Database Drift | ✅ | Schema v3 avec migrations |
| Providers Riverpod | ✅ | Stream reactif |
| ZenParser | ✅ | 8 types de blocs |
| Dashboard | ✅ | Métriques + timeline |
| Kanban Board | ✅ | 3 colonnes, drag & drop |
| Calendar | ✅ | TableCalendar integré |
| Analytics | ✅ | Métriques de base |
| Canvas | ✅ | Blocks réordonnables |
| Command Palette | ✅ | ⌘K shortcut |
| Zen Mode | ✅ | Mode focus immersif |
| Vault Service | ✅ | Copie fichiers locale |
| Metadata Fetch | ✅ | Enrichissement liens |

---

## 16. SHORTCUTS CLAVIER

| Raccourci | Action |
|----------|-------|
| `⌘K` | Ouvrir Command Palette |
| `⌘F` | Toggle Focus/Zen Mode |

---

## 17. FICHIERS CLÉS

| Fichier | Description |
|---------|-------------|
| `lib/src/app/app.dart` | Point d'entrée MaterialApp |
| `lib/src/core/database/database.dart` | Schema Drift + migrations |
| `lib/src/core/database/project_repository.dart` | Repository pattern |
| `lib/src/core/theme/app_theme.dart` | Design system complet |
| `lib/src/features/canvas/application/zen_parser.dart` | Parser sémantique |
| `lib/src/shared/layout/app_desktop_shell.dart` | Layout desktop |
| `lib/src/features/kanban_board/kanban_board_screen.dart` | Navigation + état global |
| `lib/src/shared/widgets/kanban_card.dart` | Carte Kanban avec animations |
| `lib/src/shared/widgets/command_palette.dart` | Palette de commandes |
| `lib/src/shared/widgets/ambient_zen_background.dart` | Fond misty orbes |
| `lib/src/features/zen/the_monolith_widget.dart` | Widget mode focus |

---

**Rapport généré** : Avril 2026  
**Analyste** : opencode  
**Fichiers analysés** : 65+ fichiers Dart, 1 pubspec.yaml