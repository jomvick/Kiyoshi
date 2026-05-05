# Kiyoshi Zen Studio — design system

Concise reference aligned with Flutter implementation.

## Canvas & atmosphere

| Token | Value | Usage |
|-------|-------|--------|
| `KiyoshiZenTokens.canvas` | `#F5F5F5` | Matte off-white base field |
| Mist orbs | `#C8E6C9` → `#E0F2F1` | Large, soft, out-of-frame radial gradients |
| Depth | Multi-layer blur | “Misty forest” — soft focus, ambient light only |

**Widget:** `AmbientZenBackground` — stacks canvas + diffused orbs + optional 1–2% noise.

## Glass-Prism (cards & modals)

| Rule | Value |
|------|--------|
| Corner radius | **20px** (`KiyoshiZenTokens.radiusCard`) |
| Backdrop blur | **sigma 10** (`ImageFilter.blur`) — lighter than early drafts so text stays legible on busy backgrounds |
| Fill | Semi-white + subtle internal light gradient (“frosted polish”) |
| Default border | 1px slate-tinted for separation from the canvas |

**Widget:** `GlassPrismPanel` — `spectralOutline: true` for active / high-priority: razor-thin **SweepGradient** (cyan → violet → rose) + very light outer glow.

## Typography

| Role | Font | Notes |
|------|------|--------|
| Display / headline / title | **Montserrat** | Editorial weights 500–700 |
| Body / label | **Inter** | UI readability |
| Optional numeric emphasis | **JetBrains Mono** | Wide letter-spacing for large data (where used) |

**Theme:** `AppTheme.lightTheme` merges Montserrat (display–title) with Inter (body–label).

## Logo

**Widget:** `BotanicalLogo` — vector three-leaf mark (`BotanicalLogoPainter`).  
**Zen Studio sidebar:** `showPrismaticHalo: true` — fine spectral ring + soft glow around the glyph.

## Component map (Flutter)

| Design | Implementation |
|--------|----------------|
| Mist background | `AmbientZenBackground` |
| Glass card | `GlassPrismPanel` |
| Zen dashboard mockup | `KiyoshiZenDashboardView` |
| Tokens | `lib/core/design_system/kiyoshi_zen_tokens.dart` |

Reference images (`image_0.png`, `image_31.jpg`) are optional assets; the app uses the vector logo and token colors unless assets are added under `pubspec.yaml`.
