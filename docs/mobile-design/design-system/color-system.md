# Color System — Hesably Design System

**Purpose:** Semantic color tokens for the Hesably FLutter mobile app (Arabic-first, RTL). Provides the light theme, the dark-theme strategy, semantic usage rules, and contrast requirements. Colors are **semantic roles** (`color.primary`, `color.status.error`), never screen-specific hex.
**Sources:** `ux/ux-strategy.md` (trust, plain-language, low-end-device), `ux/interaction-model.md` (contrast AA for money/warnings, income/expense color-coding), `ux/screen-inventory.md` (states), `ai-patterns.md`, `offline-patterns.md`.

---

## 1. Design intent

Hesably is financial/productivity software for a non-technical small-shop owner on a low/mid-spec Android phone. The palette must feel:

- **Trustworthy** — calm surfaces, restrained accent, high legibility of money figures.
- **Modern but not toy-like** — a single strong primary, no rainbow.
- **Clear at a glance** — income vs expense, flags, alerts are instantly distinguishable.
- **Low-energy** — dark mode reduces OLED battery use and glare in a shop.

**Number of colors:** deliberately compact. 12 semantic roles in light mode + dark derivations, plus a small set of special-purpose roles (AI, offline, sync, pending, review). No more than necessary — every color must earn a place.

> DESIGN INFERENCE: The brand color (a deep trusted green family) is a design-system decision rather than a sourced requirement. The repo has no brand-color spec. Green reads as "money/success/professional" in the Egyptian small-business context and gives a calm, trustworthy baseline distinct from the red "danger" end. It is an inference, flagged, and is overridable if a brand palette arrives later.

---

## 2. Role definitions and tokens

### 2.1 Core semantic roles (light theme baseline)

| Token | Usage | Light (raw) | Dark (raw) |
|---|---|---|---|
| `color.primary` | Primary actions (Save, FAB, selected nav), links | Deep green `#0A7A3D` | `#4CB878` |
| `color.on-primary` | Content on primary | White `#FFFFFF` | Very dark green `#0B3D20` |
| `color.primary-container` | Selected chips, soft primary fills, badge backgrounds | Pale green `#D6F5DF` | `#1F5C39` |
| `color.on-primary-container` | Text on primary-container | Dark green `#0B3D20` | `#D6F5DF` |
| `color.secondary` | Secondary actions (secondary button, picker reset) | Muted teal `#2F6B5E` | `#8BC0B2` |
| `color.on-secondary` | Content on secondary | White | `#08312B` |
| `color.accent` | Highlights, focus rings, links on surfaces | Amber `#E9A23B` | `#FFC96B` |
| `color.background` | App screen background | Near-white `#F7F9F8` | `#121914` |
| `color.surface` | Cards, sheets, filled inputs | White `#FFFFFF` | `#1E2621` |
| `color.surface-variant` | Secondary surfaces, grouped sections, chips | `#EDF1EE` | `#2B342E` |
| `color.border` | Dividers, input outlines, card hairlines | `#DCE3DE` | `#3A463F` |
| `color.text-primary` | Primary text | `#1B211D` | `#E6EDE8` |
| `color.text-secondary` | Secondary text, captions | `#5A6560` | `#AAB5AE` |
| `color.text-disabled` | Disabled text/placeholder | `#A3ACA6` | `#6E7A72` |

### 2.2 Status roles

| Token | Usage | Light | Dark |
|---|---|---|---|
| `color.status.success` | Success text/icons | `#1E7D4F` | `#5BC491` |
| `color.status.warning` | Advisory, caution, low-confidence flag | `#B07414` | `#E2A63C` |
| `color.status.error` | Errors, destructive actions, delete | `#C13B2D` | `#F08A7C` |
| `color.status.info` | Neutral informational notes | `#2F6B5E` (secondary) | `#8BC0B2` |

### 2.3 Special-purpose roles

| Token | Usage | Light | Dark |
|---|---|---|---|
| `color.ai` | AI-specific accents (processing, AI suggestion badge, AI-provenance note) | Indigo `#5B5BD6` | `#9A9AE8` |
| `color.ai-container` | AI soft fills | `#E9E9FB` | `#2B2B55` |
| `color.offline` | Offline/pending/local-only accent | Slate `#4A5A6A` | `#9FB0C0` |
| `color.syncing` | Syncing/waiting progress | Blue `#2F6BB0` | `#6FA6E0` |
| `color.pending` | Pending locally-stored (used with offline family) | `#7A5A9E` (muted violet) | `#B49CD8` |
| `color.review-required` | Review-required flag on low-confidence fields | `#B07414` (warning) | `#E2A63C` |

> The AI, offline, and sync roles are **derived visual language** defined to make `ai-patterns.md` and `offline-patterns.md` concrete; they expand the core palette by exactly the states the approved UX names. No additional decorative colors are added.

---

## 3. Income / expense color coding

- **Income (مبيعات/إيرادات):** displayed in `color.status.success` tinted surface + a success glyph; amount text `color.status.success` (dark: `color.status.success` on dark surfaces).
- **Expense (مشتريات/مصروفات):** displayed with `color.text-primary` on a neutral surface; amount is **not** painted error-red by default. Expense ≠ danger; only destructive actions and genuine errors are red. A small icon + Arabic label distinguishes the two. (Design choice: avoid implying expenses are "bad" with red.)
- **Rule:** income/expense is never indicated **only** by color — always paired with a label and/or icon (accessibility, low-vision, grayscale, screen-reader).

---

## 4. Brands of the AI/offline/sync treatment

- **AI:** indigo family. AI processing, AI-suggestion badge, AI-provenance note. Never used for confirmed data.
- **Offline / pending / local-only:** slate + muted violet family. Distinct from "error" and from "syncing".
- **Syncing / waiting-for-connection:** blue family. Distinct from AI and offline.
- These families are reserved: a surface must not casually use `color.ai` for a decorative accent.

---

## 5. Light theme

- Background `#F7F9F8`, surface `#FFFFFF`. Cards and sheets are surface; screen background is background. Contrast between them is subtle (no hard drop shadows) — elevation/shadow strategy is in `tokens.md`/`spacing-layout.md`.
- Primary green is used for **primary actions and the selected bottom-nav tab**, never for large decorative blocks (avoid washing the screen).

---

## 6. Dark theme strategy

- Plan for dark mode **from the start** so tokens are authored in both directions; do not bolt dark on later.
- Dark surfaces reduce glare and OLED drain on low-end devices.
- Dark-mode tokens invert surfaces (background darkest, surface/darker), raise text contrast (light-on-dark), and shift status roles toward lighter tints for readability on dark.
- Too much pure black causes halo/ghosting on AMOLED with white text; use `#121914`-style off-black background, not `#000000`.
- Consider honoring the device's dark setting with a system default toggle; MVP ships **light default** with dark available (perf/legibility), per DESIGN INFERENCE (no requirement mandates a default mode).

---

## 7. Contrast requirements

- All **text** and **money figures** must meet **WCAG AA** (≥ 4.5:1 normal text, ≥ 3:1 large text/bold ≥ 18.66px equivalent) against their background in both themes.
- `color.text-secondary` `#5A6560` on white yields ~5.9:1 (passes AA). `color.border` is not used for text.
- Status colors on their container backgrounds are checked for AA for the text used within them.
- **Money figures are always text-primary** (near-black) on light, text-primary on dark; never low-contrast tints.
- Larger money hero numbers may use text-primary at large size (≥ 3:1 AA). Advisory/flag text uses warning at AA on its container.

---

## 8. Usage rules

- **Primary actions** = `color.primary` fill with `color.on-primary` content. One primary accent per screen flow.
- **Secondary actions** = `color.secondary` outline/text on `color.surface` (see `components.md`).
- **Destructive actions** = `color.status.error` fill (confirm) or error text; never a neutral gray that hides severity.
- **Disabled** = `color.text-disabled` content on `color.surface-variant`; no color-only state (also use `enabled:false` semantics / reduced emphasis).
- **Focus ring** = `color.accent`; focus is never indicated by color alone (add border/shape change).

---

## 9. Anti-patterns

| Anti-pattern | Why |
|---|---|
| Red for expense amounts | Implies "bad"; blurs into error language |
| More than one primary accent per screen | Dilutes hierarchy (Principle 6) |
| Green everywhere (primary fill on every card) | Washes trust; reduces scannability |
| Using `color.ai` for decoration | Falsely labels non-AI content as AI |
| Bare hex in screens | Breaks token discipline; drift |
| Status color without icon/label | Unreadable for color-blind; screen-reader silent |