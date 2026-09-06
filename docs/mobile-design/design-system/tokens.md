# Design Tokens — Hesably Design System

**Purpose:** single-source-of-truth reference for every design token used across the app. All other design-system docs reference this file; no token is defined inline outside this file. Flutter and Stitch implementations consume these values.
**Sources:** `color-system.md`, `typography.md`, `spacing-layout.md`, `iconography.md`, `forms-controls.md`, `motion.md`.

---

## 1. Color tokens (light / dark)

### 1.1 Brand & surface

| Token | Light | Dark | Use |
|---|---|---|---|
| `brand-primary` | `#0A7A3D` | `#4CB878` | primary brand; buttons, FAB, active nav, links — all interactive-primary surfaces |
| `brand-dark` | `#0A7A3D` | `#4CB878` | alias for dark-mode brand-primary (perceptual shift) |
| `background` | `#FAFAF8` | `#121914` | app background; off-black in dark mode (not pure #000000) |
| `surface` | `#FFFFFF` | `#1E2A20` | card/sheet/chip fill |
| `surface-variant` | `#F0EFEA` | `#2A3830` | secondary surface (skeletons, disabled fields, chips) |
| `border` | `#D0CFC8` | `#3A4A40` | default borders (1dp) |
| `border-strong` | `#A8A79E` | `#4E5E54` | focused/error borders (2dp) |

### 1.2 Text

| Token | Light | Dark | Use |
|---|---|---|---|
| `text-primary` | `#181B18` | `#F2F2F2` | headings, amounts, body text — authoritative ink |
| `text-secondary` | `#5A5C58` | `#A0A0A0` | captions, timestamps, secondary info |
| `text-disabled` | `#9A9A94` | `#5A5A5A` | disabled labels; on disabled fill |
| `text-on-primary` | `#FFFFFF` | `#121914` | text on `brand-primary` fill (buttons, FAB) |
| `text-on-success` | `#0A3D1F` | `#D5F5E3` | text on success chip |
| `text-on-surface` | `#181B18` | `#F2F2F2` | text on surface fill (skeletons, chips) |

### 1.3 Status

| Token | Light | Dark | Use |
|---|---|---|---|
| `status-success` | `#16A34A` | `#4ADE80` | success icon, success border |
| `status-success-container` | `#D5F5E3` | `#1A3D2A` | success chip background, income chip bg |
| `status-error` | `#DC2626` | `#F87171` | error icon, error border |
| `status-error-container` | `#FEE2E2` | `#3D1A1A` | error chip background |
| `status-warning` | `#B07414` | `#F5C563` | warning icon, low-confidence advisory, review-required |
| `status-warning-container` | `#FFF3CD` | `#3D2E0A` | warning chip background |
| `status-info` | `#2563EB` | `#60A5FA` | info icon, info chip |
| `status-info-container` | `#DBEAFE` | `#1A2A3D` | info chip background |

### 1.4 Income & expense (financial-only surfaces)

| Token | Light | Dark | Use |
|---|---|---|---|
| `income-container` | `#D5F5E3` | `#1A3D2A` | income type chip bg |
| `expense-container` | `#E8E6E1` | `#2E2C28` | expense type chip bg (neutral warm-gray; never red) |

### 1.5 AI

| Token | Light | Dark | Use |
|---|---|---|---|
| `ai` | `#5B5BD6` | `#818CF8` | AI icon, AI text, provenance text |
| `ai-container` | `#E9E9FB` | `#2A2A4A` | AI chip bg, AI field marker bg |

### 1.6 Offline / sync / pending (reserved palette)

| Token | Light | Dark | Use |
|---|---|---|---|
| `offline` | `#4A5A6A` | `#8A9AAA` | offline banner bg, offline icon |
| `syncing` | `#2F6BB0` | `#5B9BD5` | syncing progress, syncing chip |
| `pending` | `#7A5A9E` | `#A882C8` | pending chip bg, pending icon |

### 1.7 Focus & interactive

| Token | Value | Use |
|---|---|---|
| `focus-ring` | `brand-primary` (2dp outline, 2dp offset) | keyboard/TalkBack focus |
| `interactive-pressed` | `opacity 0.08` overlay on `text-primary` | press state overlay |

---

## 2. Typography tokens

### 2.1 Type scale

| Token | Size | Weight | Line height | Use |
|---|---|---|---|---|
| `type.display` | 36 | 700 | 1.1 | hero/hero-amount; splash tagline |
| `type.headline` | 28 | 600 | 1.2 | screen titles (optional), detail hero amount |
| `type.title` | 20 | 600 | 1.3 | card titles, section headers |
| `type.body` | 16 | 500 | 1.5 | body text, form fields, row primary text |
| `type.body-strong` | 16 | 600 | 1.5 | emphasized body (amounts in rows, bold labels) |
| `type.label` | 14 | 500 | 1.3 | field labels, chip text, nav labels, tab labels |
| `type.caption` | 12 | 400 | 1.3 | timestamps, captions, AI provenance, helper text |

### 2.2 Font stack

| Language | Primary | Fallback |
|---|---|---|
| Arabic | **Cairo** (400/500/600/700) | Noto Sans Arabic → system |
| Latin (secondary) | same Cairo | system-ui → sans-serif |

- Arabic `letter-spacing: 0` always.
- Latin labels (English toggle): optional 0.5–1px tracking, uppercase.
- Tabular numerals: `font-variant-numeric: tabular-nums` on all amount columns.

### 2.3 Max sizes per screen

No screen uses more than **3 distinct type scale tokens** (e.g., title + body + caption).

---

## 3. Spacing tokens (4dp base)

| Token | Value | Use |
|---|---|---|
| `space.0` | 0 | — |
| `space.1` | 4 | inline icon gap, tiny spacing |
| `space.2` | 8 | chip internal padding, tight row gap |
| `space.3` | 12 | checkbox/radio label gap, field helper-text gap |
| `space.4` | 16 | screen margin, card internal padding, row vertical padding |
| `space.5` | 20 | form field vertical gap, section internal padding |
| `space.6` | 24 | section vertical gap, FAB bottom offset |
| `space.7` | 32 | large section separation |
| `space.8` | 40 | screen top padding (below app bar) |
| `space.9` | 48 | hero spacing (detail amount above, bottom nav clearance) |

---

## 4. Border radius tokens

| Token | Value | Use |
|---|---|---|
| `radius.xs` | 4 | chips, small badges |
| `radius.sm` | 8 | text fields, small cards, avatars |
| `radius.md` | 12 | cards, buttons, bottom sheets |
| `radius.lg` | 16 | large cards, dialogs |
| `radius.xl` | 20 | FAB, bottom nav (if rounded) |
| `radius.full` | 9999 | pills, circular avatars |

---

## 5. Border & elevation tokens

| Token | Value | Use |
|---|---|---|
| `border.default` | 1dp `border` color | card borders, dividers, field borders (default state) |
| `border.strong` | 2dp `border-strong` color | focused fields, error fields |
| `elevation.none` | none | flat surfaces (cards on the same plane) |
| `elevation.low` | 0dp 1dp `border` (no shadow) | cards, bottom nav — shadow-free for low-end GPU |
| `elevation.mid` | 0dp 2dp `border-strong` | dialogs, bottom sheets — subtle elevation via border, no blur-shadow |
| `elevation.high` | 0dp 4dp rgba(0,0,0,0.12) | FAB only — the sole use of a soft shadow in the app |

**Note:** shadows are intentionally minimal (NFR-LOWDEV-001); elevation is communicated by border/overlay, not by `elevation` property shadows.

---

## 6. Icon size tokens

| Token | Value | Use |
|---|---|---|
| `icon.xs` | 16 | inline badges, AI mark, confidence flag |
| `icon.sm` | 20 | field trailing icons, chip icons, date/calendar |
| `icon.md` | 24 | standard icons (app bar, nav, row actions) |
| `icon.lg` | 32 | empty-state primary icon |
| `icon.xl` | 40 | FAB icon (large target for low-end) |

---

## 7. Control height tokens

| Token | Value | Use |
|---|---|---|
| `control.sm` | 32 | chips, compact inline buttons |
| `control.md` | 40 | secondary buttons, search field, filter chips |
| `control.lg` | 48 | primary buttons, text fields, bottom nav item, FAB |
| `control.xl` | 56 | large CTA (save, submit), full-width buttons |

---

## 8. Opacity tokens

| Token | Value | Use |
|---|---|---|
| `opacity.disabled` | 0.38 | disabled state fill/icon |
| `opacity.pressed` | 0.08 | press overlay on interactive elements |
| `opacity.skeleton-pulse-low` | 0.04 | skeleton pulse (light mode) |
| `opacity.skeleton-pulse-high` | 0.08 | skeleton pulse (light mode peak) |

---

## 9. Breakpoint tokens

| Token | Value | Use |
|---|---|---|
| `bp.phone` | 0–599dp | primary target; portrait-first |
| `bp.tablet` | 600dp+ | responsive expansion (optional; not MVP-primary) |

- `bp.phone` is the assumed default for all screens.
- Content max-width (tablet): 600dp, centered.

---

## 10. Motion timing tokens (see `motion.md`)

| Token | Value | Use |
|---|---|---|
| `motion.cut` | 0ms | instant content swap (tab switch, filter apply) |
| `motion.fade` | 200–300ms ease-in-out | skeleton → content, error → success |
| `motion.sheet-enter` | 250–300ms ease-out | bottom sheet slide-up |
| `motion.sheet-exit` | 200ms ease-in | bottom sheet dismiss |
| `motion.dialog-enter` | 200–250ms ease-out | destructive confirm scale+fade |
| `motion.toast-enter` | 200ms ease-out | snackbar slide-up |
| `motion.toast-exit` | 150ms ease-in | snackbar dismiss |
| `motion.skeleton-pulse` | 1200ms cycle | skeleton opacity oscillation |

---

## 11. Token naming convention

All tokens follow: `category.variant` (e.g., `type.body`, `space.4`, `radius.md`, `status.error-container`, `ai`, `offline`).

**Flutter mapping:** tokens map 1:1 to Dart constants in a `theme/tokens.dart` file; no magic strings. Stitch mapping: tokens are exported as Tailwind-compatible variables where possible, or as named tokens in DESIGN.md.