# Kiyoshi - Roadmap d'Améliorations

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