# Kiyoshi - Roadmap d'Améliorations

## 🎯 EN COURS — v1.5.0 : Dark Mode & Visual Polish

> Diagnostic (Juillet 2026) : le toggle "Dark Mode" existe dans Settings mais reste marqué
> `subtitle: 'Switch to dark theme (coming soon)'` dans `settings_screen.dart` — **ce n'est pas un simple
> label oublié : `AppTheme.darkTheme` est bien branché dans `app.dart`, mais la quasi-totalité des
> widgets (glass panels, settings tiles, sidebar, kanban cards...) consomment des constantes
> `AppTheme.xxx` / `ZenColors.xxx` statiques (donc figées en valeurs light) au lieu de
> `Theme.of(context).colorScheme`. Résultat : changer le toggle ne change quasiment rien à l'écran.**

### 1. Rendre le Dark Mode réellement fonctionnel

**✅ Fait (fondations + Settings) :**
- [x] Palette dark "Warm Charcoal" (inspirée de Claude) ajoutée dans `ZenColors`
      (`darkCanvas #262624`, `darkSurface #30302E`, texte chaud `#ECEBE4`, accent `darkPrimary #8FBDB8`...)
- [x] `_darkColorScheme` dans `app_theme.dart` reconstruit avec ces couleurs chaudes (fini le
      `Color(0xFF1E1E1E)` / `Colors.white` génériques)
- [x] `scaffoldBackgroundColor`, `cardTheme`, `iconTheme`, `appBarTheme` dark basculés sur la palette chaude
- [x] `_buildTextTheme` : texte dark n'utilise plus `Colors.white/white70/white60` (froid) mais des
      tons chauds `ZenColors.darkOnBackground` / `darkOnSurfaceVariant`
- [x] Ajout de `AppTheme.isDark(context)`, `glassFillOf(context)`, `glassBorderOf(context)` +
      paramètre `context:` optionnel sur `glassPanel/ultraGlass/floatingCard/glassButton/chip`
      pour un glassmorphism qui s'adapte (frost charbon au lieu de blanc sur fond sombre)
- [x] `settings_screen.dart` (écran complet) migré vers `Theme.of(context).colorScheme` — le
      toggle Dark Mode change maintenant réellement tous les tiles de cet écran
- [x] `settings_dialog.dart` (dialog Cmd+K → Settings) idem
- [x] Subtitle "Dark Mode" mis à jour ("coming soon" retiré)

**⏳ Reste à faire — même pattern à appliquer écran par écran, par ordre de priorité (visibilité) :**
- [x] `shared/widgets/zen_glass_card.dart`, `glass_prism_panel.dart` — composants glass de base
      réutilisés partout ; les corriger fait remonter le fix dans beaucoup d'écrans d'un coup
- [x] `shared/widgets/sidebar.dart` — navigation toujours visible, fort impact visuel
- [x] `shared/widgets/kanban_card.dart`, `kanban_column.dart` — écran Kanban (cœur de l'app)
- [x] `shared/widgets/ambient_zen_background.dart` — fond animé sauge/mint non brightness-aware,
      prévoir une variante sombre des "orbs"
- [x] `shared/widgets/command_palette.dart`, `morphing_zen_bar.dart` (Quick Entry / Cmd+K)
- [ ] `features/dashboard/kiyoshi_zen_dashboard_view.dart`
- [ ] `features/projects/presentation/*`, `features/canvas/presentation/widgets/*` (blocs)
- [ ] `features/zen/the_monolith_widget.dart` (mode focus)
- [ ] `KiyoshiZenTokens.canvas`/`glassFill`/`blurSigma` (design_system) — unifier avec les nouveaux
      helpers `AppTheme.glassFillOf`/`glassBorderOf` au lieu d'avoir deux sources de vérité du blur
- [ ] Tester chaque écran en dark mode une fois migré (Dashboard, Kanban, Calendar, Canvas, Notes,
      Analytics, Command Palette, Monolith/Zen mode)
- [ ] Vérifier le contraste WCAG AA des nouvelles couleurs chaudes (`darkOnSurfaceVariant` sur
      `darkSurface` notamment)

### 2. Polish visuel
- [ ] Micro-interactions `flutter_animate` sur actions clés (création tâche, drag & drop, sauvegarde)
- [ ] Empty states (actuellement absents/minimaux sur Projects, Tasks, Notes, Calendar)
- [ ] Cohérence des `radiusXxx` : vérifier que tous les composants utilisent bien les tokens
      (`radiusLarge = 20px` standard) plutôt que des valeurs codées en dur ponctuelles
- [ ] Prismatic borders : vérifier le rendu en dark mode (le gradient spectral pastel actuel est
      pensé pour fond clair)

### 3. Definition of Done v1.5.0 (axe visuel)
- [ ] Toggle Dark Mode change effectivement 100% de l'UI (aucun écran ne reste en light forcé)
- [ ] Aucune régression de contraste (AA minimum)
- [ ] Le glassmorphism reste lisible sur fond sombre
- [ ] `subtitle` du toggle mis à jour, plus de mention "coming soon"

---

## 🗺️ PLANIFIÉ — Freeform Canvas ("Excalidraw-like") pour Projects

> Objectif produit : transformer l'écran Projet en un vrai environnement de gestion d'idées
> type Obsidian/Notion mais **léger** — texte + todo tables (déjà fait via `ZenCanvas`/`ZenBlock`)
> **+ un canvas libre en 2D** (post-its, formes, flèches, connecteurs) pour poser des idées
> spatialement, à la Excalidraw. Cette dernière brique n'existe pas du tout aujourd'hui.

### 0. Existant à réutiliser (ne pas reconstruire)
- `ZenBlock` (`canvas/domain/entities/zen_block.dart`) : déjà un `type` + `metadata: Map<String, dynamic>`
  générique — un nouveau type `'whiteboard'` s'insère sans migration de schéma DB
- `ZenCanvas` (`canvas/presentation/block_canvas.dart`) : la palette de commandes `/` (`_showBlockCommandPalette`)
  et le switch `_buildBlock()` sont l'endroit exact où brancher le nouveau bloc
- `DatabaseViewWidget` : sert de précédent pour "un bloc qui contient un mini-écran interactif
  complet" — le whiteboard suit le même patron (widget autonome, embarqué dans un bloc)
- `BlockService` (`canvas/application/block_service.dart`) : `addBlock` / `updateBlock` existants
  suffisent pour persister les mises à jour du whiteboard (on met à jour `metadata` à chaque
  changement de shape, avec debounce pour éviter d'écrire en DB à chaque frame de drag)

### 1. Modèle de données (v1, scope volontairement réduit)
- [ ] Nouveau type de bloc `'whiteboard'` dans `ZenBlock` (`block.type == 'whiteboard'`)
- [ ] `block.metadata['shapes']` = `List<Map>` sérialisable JSON, une entrée par forme :
      `{ id, kind: 'rect'|'ellipse'|'arrow'|'text'|'sticky', x, y, width, height, color, text? }`
- [ ] `block.metadata['viewport']` = `{ offsetX, offsetY, zoom }` pour restaurer la position de la
      caméra à la réouverture
- [ ] Pas de nouvelle table Drift nécessaire pour la v1 (JSON dans `metadata` suffit à l'échelle
      d'un board par page projet) — à revisiter si les whiteboards deviennent très gros/nombreux

### 2. Widget (`canvas/presentation/widgets/whiteboard_block.dart`)
- [ ] `CustomPainter` pour le rendu des formes (rect/ellipse/flèche/texte) — reprendre les
      conventions de style de `PrismaticPainter`/`_ZenNoisePainter` déjà dans le projet
- [ ] `GestureDetector`/`Listener` pour : pan (glisser fond), zoom (scroll/pinch), dessiner
      (glisser en mode outil actif), sélectionner/déplacer une forme existante
- [ ] Mini-toolbar flottante (glass, cohérente avec `AppTheme.glassPanel`) : Sélection, Rectangle,
      Ellipse, Flèche, Texte, Sticky note, Couleur, Supprimer
- [ ] Zone de rendu bornée avec `ClipRect` + `InteractiveViewer` ou pan/zoom custom (à trancher :
      `InteractiveViewer` est plus rapide à implémenter mais moins de contrôle fin sur le
      "snap"/l'alignement)

### 3. Intégration
- [ ] Ajouter la commande "Whiteboard" dans `_showBlockCommandPalette` (icône `LucideIcons.penTool`
      ou `layoutDashboard`)
- [ ] Brancher le case `'whiteboard'` dans `ZenCanvas._buildBlock()`
- [ ] Le bloc whiteboard doit pouvoir prendre toute la largeur de la page (contrairement aux blocs
      texte) — prévoir une hauteur fixe redimensionnable (ex: 400px par défaut, poignée de resize)

### 4. Explicitement HORS SCOPE pour la v1 (à documenter comme tel pour ne pas déraper)
- Dessin à main levée pixel-perfect (type stylet) — seulement formes prédéfinies + texte
- Collaboration temps réel multi-utilisateurs
- Export PNG/SVG du whiteboard
- Snapping/alignement magnétique avancé (grille simple uniquement)

### 5. Definition of Done (v1 whiteboard)
- [x] Créer/déplacer/supprimer une forme, un sticky note, un texte libre (redimensionnement de
      forme individuelle pas encore fait — seule la hauteur du board se redimensionne)
- [x] Relier deux formes par une flèche (statique : ne suit pas automatiquement si l'une des
      formes liées est déplacée ensuite — amélioration possible plus tard)
- [ ] Pan + zoom fluides (non fait dans ce v1 — le board est borné à sa zone visible, pas de
      caméra infinie ; à ajouter si le besoin d'un board plus grand se confirme à l'usage)
- [x] Persistance : les formes + la hauteur du board sont sauvegardées dans `block.metadata`
      via `BlockService.updateBlock` (même mécanisme que les autres blocs, aucune migration DB)
- [x] Dark mode pris en compte dès la première version (`Theme.of(context).colorScheme` partout,
      sticky notes gardées lisibles avec texte foncé fixe sur fond couleur clair)

**✅ Livré :** `whiteboard_block.dart` (widget + painter), intégré dans `ZenCanvas` via la
commande `/whiteboard` et le `case 'whiteboard'` de `_buildBlock()`. Outils : sélection
(déplacer/supprimer), rectangle, ellipse, flèche, texte, sticky note, palette de 5 couleurs,
édition de texte par double-clic (formes existantes) ou automatiquement à la création, poignée
 de redimensionnement du board en bas à droite. Bug corrigé lors du debug : `shouldRepaint`
comparait la liste de formes par référence (toujours égale puisque mutée en place), empêchant
le repaint visuel lors d'un déplacement/suppression de forme.

**✅ UX — poignée de drag Notion-like :** `block_canvas.dart` affichait un réordonnancement
fonctionnel mais totalement invisible (long-press sur tout le bloc, aucun indice visuel). Ajout
d'une poignée `⋮⋮` (icon `gripVertical`) dans une gouttière à gauche de chaque bloc, visible
uniquement au survol (`AnimatedOpacity` + `IgnorePointer`), avec tooltip "Drag to reorder" —
pattern directement inspiré de Notion. Le drag est maintenant déclenché uniquement depuis cette
poignée (`ReorderableDragStartListener`) et non plus depuis tout le bloc, ce qui évite aussi les
conflits accidentels avec l'édition de texte.

**⏳ Reste pour une v1.1 :** pan/zoom, redimensionnement individuel des formes, flèches qui
suivent leurs formes liées, undo/redo.

### 6. Autres pistes UX "Notion-like" identifiées
- [x] **Menu `/` inline et filtrable** — remplacé le dialog plein écran (`CommandPalette.show`)
      par un menu ancré juste au-dessus du champ de saisie (`CompositedTransformFollower` +
      `OverlayPortal`), qui filtre en direct pendant la frappe, navigable au clavier
      (↑/↓/Entrée/Échap via `FocusNode.onKeyEvent`, avec double sécurité sur `onSubmitted`
      pour rester correct même en cas d'ordre de dispatch imprévu). Le bouton `+` ouvre le
      même menu (simule un `/`). Le dialog plein écran `CommandPalette` est conservé tel quel
      pour le raccourci global `Cmd+K` (cas d'usage légitime pour un vrai dialog).
- [x] **Rappel syntaxe markdown à la Obsidian** — ligne discrète sous le champ de saisie
      (`# heading · -[ ] todo · \`\`\` code · / more blocks`) pour rendre visible que la
      frappe directe marche aussi, sans passer par le menu.
- [x] Pas d'insertion "à cet endroit" — **fait.** Nouvelle méthode `addBlockAfter` (position
      fractionnaire, même logique que `reorderBlocks`) dans `IBlockRepository`/`ProjectRepository`/
      `BlockService`, exposée via `ZenCanvas.onCreateBlockAfter`. Bouton `+` dans la gouttière de
      chaque bloc (à côté de la poignée de drag), insère un bloc texte vide juste après.
- [x] Entrée clavier pour créer un nouveau bloc — **fait** pour les blocs texte et todo
      (`onEnterPressed` sur `NoteBlockWidget`/`TodoBlockWidget`, Shift+Entrée garde le retour à
      la ligne classique). Le focus clavier passe automatiquement au nouveau bloc
      (`_pendingFocusBlockId` + `autofocus`). Pas fait pour heading/code/link/etc. (moins
      prioritaire, comportement moins évident pour ces types).
- [x] Menu contextuel unifié par bloc (Supprimer/Dupliquer) — **fait.** Troisième icône ⋮ dans la
      gouttière (`PopupMenuButton`), fonctionne identiquement pour tous les types de blocs au lieu
      de la suppression au survol implémentée différemment par chaque widget. "Transformer en…"
      pas fait (changerait le `type` d'un bloc existant en préservant son contenu — plus complexe,
      à documenter séparément si besoin).

---

## 🌱 PLANIFIÉ — Rapprocher "Notes" (idées) et "Projects" (Notion/Obsidian-inspired)

> Constat (session du 08/08/2026) : `NotesScreen` (inbox globale d'idées non classées) et chaque
> `Project` sont des silos étanches — un `ZenBlock` appartient à exactement un `projectId`
> (`'global'` ou l'ID d'un projet), sans aucun pont ni lien croisé entre les deux.

### ✅ Fait — le pont manquant (rattacher une idée à un projet)
- [x] `IBlockRepository.moveBlockToProject` + implémentation `ProjectRepository` (recalcule la
      position en fin de liste du projet cible via `getMaxPosition`, pas de collision de position)
- [x] `BlockService.moveBlockToProject` exposé
- [x] `AppDatabase.getAllProjects`/`watchAllProjects` (tous workspaces confondus — n'existait pas)
- [x] `allProjectsProvider` (Riverpod)
- [x] Bouton "Attach to project" sur chaque carte de `NotesScreen` → dialog listant tous les
      projets → la note change de `projectId` et disparaît naturellement de l'inbox (le stream
      filtré sur `'global'` ne la voit plus, aucune UI supplémentaire nécessaire)

### ⏳ Reste à faire (par ordre de valeur probable)
- [x] Liens croisés `[[page]]` + panneau de rétroliens (Obsidian) — **fait, v1 en lecture seule.**
      `ZenParser.extractLinkTitles`/`containsLinkTo` détectent la syntaxe `[[Titre]]` dans
      n'importe quel bloc texte. `backlinksProvider` scanne tous les blocs de l'app (nouvelle
      requête `AppDatabase.watchAllBlocks`, n'existait pas) et filtre ceux qui référencent le
      titre du projet courant. Panneau "LINKED MENTIONS" affiché en bas de chaque page projet
      (nouveau paramètre `ZenCanvas.footer`, symétrique du `header` existant).
      **Limite assumée** : lecture seule, pas de clic-pour-naviguer vers la source, pas
      d'autocomplétion `[[` en tapant, pas de rendu du lien comme élément cliquable dans
      l'éditeur (le texte `[[Titre]]` reste du texte brut affiché tel quel).
- [ ] Tags transverses navigables (au-delà du `#projet` de `ZenParser`, qui n'est qu'un indice de
      saisie rapide non persisté/navigable)
- [ ] Hiérarchie de projets (`Project.parentId`, sous-projets à la Notion)
- [ ] Recherche unifiée idées + projets (aujourd'hui `NotesScreen` ne cherche que dans `'global'`)

### 🐛 Bug pré-existant repéré en chemin (pas corrigé, hors scope de cette session)
`NotesScreen._buildFileNoteCard` affiche `DateTime.fromMillisecondsSinceEpoch(note.position.toInt() * 1000)`
comme si `position` était un timestamp Unix — mais `position` suit en réalité le schéma
incrémental de `addBlock` (~1000, 2000, 3000…). La date affichée sur les cartes de notes est
donc probablement erronée (proche de 1970). À corriger séparément : soit stocker un vrai
`createdAt` (le champ existe déjà sur `ZenBlock` mais n'est pas utilisé ici), soit ne plus
réutiliser `position` comme timestamp.

---

## Phase 1: Stabilisation (v1.0.x)

### Bugs corrigés
- [x] **BuildContext async** - 4 occurrences dans `tasks_screen.dart` ✅ FIXED
- [x] **Curly braces** - 4 occurrences dans `zen_quick_entry.dart` ✅ FIXED

### Tests
- [ ] Couverture actuelle: 7 fichiers, faible couverture
- [ ] Ajouter tests pour: `ProjectRepository`, `BlockService`, providers

---

## Phase 2: Performance (v1.1.x)

### Nouvelles Fonctionnalités
- [x] **Settings Page** - Plein écran integré
  - Synchronisé avec les préférences de l'app
  - Sidebar, Zen Mode, Navigation defaults
  - Ajout de `darkMode`, `prismaticBorders`, `notifications`
- [x] **Sidebar reactive** - Largeur depuis `preferencesProvider`

### Optimisations
- [ ] **Lazy loading avancé**
  - Pré-chargement écran adjacent avec `preloadPageDistance`
- [ ] **Virtualisation** pour KanbanColumn
  - Only render visible cards in view
- [ ] **Memoization**
  - Cache des requêtes fréquentes (ex: recent activities)
- [ ] **Image caching**
  - network_image ou cached_network_image
- [ ] **Bundle size**
  - Tree-shakinggoogle_fonts
  - Lazy font loading

### Métriques à améliorer
| Métrique | Actuel | Cible |
|---------|-------|-------|
| App startup | ~2s | <1s |
| Memory (idle) | ~150MB | <100MB |
| Scroll FPS | 50 | 60 |

---

## Phase 3: Fonctionnalités (v1.2.x)

### Core Features
- [ ] **Drag & Drop avancées**
  - Multiple selection (shift+click)
  - Drop zones avec feedback visuel
- [ ] **Raccourcis clavier**
  - `Ctrl+N` new task
  - `Ctrl+S` save
  - `Ctrl+F` search
- [ ] **Recherche globale**
  - Command palette search
  - Filtres: type, date, projet

### Collaboration (Future)
- [ ] **Sync basique**
  - Export/Import JSON
  - Backup auto vers local storage
- [ ] **Tags/Labels**
  - Multi-tags par tâche
  - Filtre par tag

---

## Phase 4: UX/UI Polish (v1.3.x)

### Améliorations UI
- [ ] **Thème sombre**
  - Zen Dark Mode
  - Palette alternative
- [ ] **Animations fluides**
  - Plus de `flutter_animate`
  - Micro-interactions
- [ ] **Feedback haptiques**
  - Vibration sur mobile
- [ ] **Empty states**
  - Plus de placeholders vides

### Accessibilité
- [ ] Semantics labels
- [ ] Support keyboard navigation complète
- [ ] Contrast ratios WCAG AA

---

## Phase 5: Architecture (v2.0.0)

### Refactoring
- [ ] **Clean Architecture complète**
  - Séparer domain/data/presentation
  - Use cases
- [ ] **Bloc ou Riverpod bien structuré**
  - States-events explicites
- [ ] **Tests d'intégration**
  - Golden tests UI
  - Integration tests

### Infrastructure
- [ ] **CI/CD**
  - GitHub Actions
  - Auto test + build
- [ ] **Versioning**
  - Semantic release
- [ ] **Changelog auto**

---

## Priorités Recommandées

```
1. ✅ Bugs async corrigés (v1.0.1)
2. ✅ Settings Page ajoutée (v1.0.1)
3. Thème sombre (darkMode)
4. Performance (user experience)
5. CI/CD (DX)
6. Tests (stability)
```

---

## Tech Debt Actuel

| Issue | Impact | Temps |
|-------|--------|-------|
| BuildContext async | crash potentiel | 1h |
| Tests manquants | regression | 4h |
| CI manquant | DX | 2h |
| Theme sombre | feature gap | 3h |
| Performance | UX | 4h |

**Total estimé: ~14h de développement**