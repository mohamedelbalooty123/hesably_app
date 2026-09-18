# Theming

## What is the rule?
Use a semantic token-based theme. The primary color is `#0A7A3D` (current Stitch seed/custom color). Do not hardcode colors in widgets. Define roles like primary, surface, error inside ThemeData.

## Why does it exist?
To allow consistent visual application that matches the current Stitch design without manual duplication.

## Where does it apply?
`lib/app/theme/` and all widget build methods. Widgets read tokens via `Theme.of(context).colorScheme.*` — never raw hex values.

## Design Tokens (from CURRENT Stitch project `661013469764921318`)

| Role | Value | AppColor field |
|---|---|---|
| Primary | `#0A7A3D` | `primary` |
| On Primary | `#FFFFFF` | `onPrimary` |
| Background (canvas) | `#FAFAF8` | `background` |
| Surface | `#FFFFFF` | `surface` |
| On Background / On Surface | `#191C19` | `onBackground` |
| Outline | `#6F7A6E` | `outline` |
| Outline Variant | `#D0CFC8` | `outlineVariant` |
| Secondary | `#5E5F59` | `secondary` |
| Error | `#BA1A1A` | `error` |
| Surface Container Low | `#F3F4EF` | `surfaceContainerLow` |
| Surface Container | `#EDEEE9` | `surfaceContainer` |
| Pending / Amber (derived) | `#F59E0B` | (unverified hex — confirm when Reports/AI screens land) |

> **Obsolete tokens (do NOT use)**: `#004328`, `#0D5C3A`, `#006D37`, `#FAF8FF`, `#FAF8FF` surface — from the OLD Stitch project. `#F59E0B` amber is a derived placeholder from the "Green for paid, Amber for pending" guidance; its hex is unverified.

## Typography
- **Single family: Cairo** (proxied by Inter in Stitch for rendering only — never adopt Inter).
- Bundled TTFs: `Cairo-400/500/600/700` in `assets/fonts/`.
- **Tajawal dropped** — absent from the current Stitch project.
- Scales (from Kinetic token sheet):
  - headline-xs/display: 32/40, weight 700
  - headline-lg: 24/32, weight 700
  - headline-md: 20/28, weight 600
  - body-lg: 18/26, weight 400
  - body-md: 16/24, weight 400
  - body-sm: 14/20, weight 400
  - label-md: 14/16, weight 600
  - label-sm: 12/16, weight 500

## Layout / Geometry
- Reference viewport: **390 × 884** (Phone Entry canvas is 390 × 852).
- Base spacing grid: **4dp**. Screen margins: **16dp**.
- Touch targets: **48dp minimum** for all primary controls.
- Roundness: **8dp** for buttons/cards/text fields (Stitch project roundness is 4dp; the in-canvas Kinetic sheet specifies 8dp at component level — 8dp adopted).
- Inputs: 1dp border default, **2dp primary** border on focus.
- Bottom nav: 64dp, icon 24dp above label 12dp.
- FAB: 56dp circular, brand-primary fill, white icon.

## RTL
- **Always-on RTL** for Arabic-first UI. `MaterialApp` sets `locale: Locale('ar')`; direction resolves from the locale (no hardcoded `Directionality`).
- Primary UI language Arabic, English secondary (runtime toggle deferred to Settings feature).

## Example
```dart
color: Theme.of(context).colorScheme.primary
```
instead of `color: Color(0xFF0A7A3D)`.