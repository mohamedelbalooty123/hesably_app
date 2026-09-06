# Spacing & Layout System — Hesably Design System

**Purpose:** A systematic spacing scale and layout rules for the mobile-first Arabic/RTL Hesably app. Avoids arbitrary values; every gap, pad, and inset traces to a token.
**Sources:** `ux/interaction-model.md` (touch targets 48dp, ≥8dp gaps, bottom-half positioning, safe areas), `ux/information-architecture.md` (grouped sections), `ux/ux-strategy.md` (360–412dp single-handed).

---

## 1. Base unit and scale

Base unit **4dp**. Spacing tokens are multiples of 4.

| Token | Value | Typical use |
|---|---|---|
| `space.0` | 0 | — |
| `space.1` | 4dp | tight icon-to-text gap, checkbox label |
| `space.2` | 8dp | plus, gap between grouped inline elements, chip gaps |
| `space.3` | 12dp | small card padding, list-row internal gaps |
| `space.4` | 16dp | **screen horizontal margin, card padding, list-row padding** |
| `space.5` | 20dp | section separations within a screen |
| `space.6` | 24dp | section spacing between content blocks, form-field spacing |
| `space.7` | 32dp | large separation (empty-state block, hero-to-content) |
| `space.8` | 40dp | generous separations (top of empty states, deep section breaks) |
| `space.9` | 48dp | bottom-sheet handle spacing, max list-row gaps |

> DESIGN INFERENCE: 4dp base (rather than 8dp) permits fine control of compact Arabic labels and dense but breathable list rows; the "≥8dp between interactive neighbors" rule is preserved at the component level (interaction-model §1).

---

## 2. Standard layout constants

| Constant | Value | Notes |
|---|---|---|
| Screen horizontal margin | `space.4` (16dp) | fixed content inset from screen edges |
| Content max width | 600dp | for large phones/tablets; centered, same margins apply |
| Card padding | `space.4` | standard card content inset |
| Compact card padding | `space.3` | small chips/meta cards |
| Section gap (vertical) | `space.6` (24dp) | between logical content blocks on a screen |
| List-row padding | `space.4` vert / `space.4` horiz | thumb 48 + text + trailing chevron |
| Form-field gap | `space.4`/`space.5` | vertical between fields |
| Bottom-sheet handle gap | `space.4` | from handle to content |
| FAB bottom offset | `space.6` (24dp) | above the bottom safe-inset |
| Bottom nav height | 64dp + safe inset | 4 tabs + labels |

---

## 3. Screen layout rules

- **Portrait default**, first-class. Landscape is explicitly out of main flow (see §Landscape).
- **One thumb rule:** primary action (FAB, Save, Confirm) sits in the bottom half, reachable single-handed; margins disable accidental taps at the hard edges.
- **Height budget:** at 360dp wide, target content scrolls rather than compresses; no horizontal squeeze — never reduce touch targets below 44dp in compact mode.
- **Safe areas:** respect display cutout, system gesture bar, and bottom inset. Content and FAB clear the bottom system inset by `space.6`. Bottom nav adds its own inset padding.
- **Keyboard:** amount/date/review fields are reachable above the keyboard; fields scroll into view; Save floats with the keyboard (button anchored to the keyboard top when it appears), per interaction-model §3 forms.
- **Status bar / app bar:** content clears the status bar via standard Scaffold; app bar (if any) is `type.headline` with back affordance at 48dp square.

---

## 4. RTL-aware layout

- All spacing is **direction-agnostic** (space tokens are magnitudes). Layout flips via `Directionality`/`TextDirection` — never via mirrored padding values.
- In RTL, "start" = right, "end" = left. FAB sits at **bottom-start** in RTL (bottom-right visually) — the mirror of LTR bottom-end (interaction-model §1).
- Chevrons/back mirror; the horizontal rhythm of rows stays start-aligned.
- Leading visual weight (icons, thumbnails) sits at **start** (right in RTL); trailing meta (amount, chevron) sits at **end** (left in RTL).
- Reading order in split bars (progress) stays LTR in render (interaction-model §7 progress fills left→right).

---

## 5. When to use a card vs a flat row vs a section (anti-over-card)

| Surface | Rules |
|---|---|
| **Card** | Dashboard KPI cards, summary cards, empty-state panels, AI extraction result block, category breakdown tile. Max ~3 cards stacked on a screen before switching to a flat list. |
| **Flat list row** | Transactions, categories, settings rows, filter chips. Divider = `color.border` 1dp. Rows are `space.4` padded, 48dp min height, tappable full-width. |
| **Grouped section** | Settings groups, category defaults/customs, Reports breakdown groups. Section header = caption + 8dp below. Never more than one card per logical block. |
| **Expandable section** | Only where an approved flow needs it (line items in Detail). Default collapsed; reveals supporting data (Principle 5). |

> Rule: **one surface type per logical block.** If a list is flattened, do not wrap each row in a card; if a summary is a card, don't card-ify its children.

---

## 6. Dashboard layout (Home)

```
[Status bar]
[App bar / Title]                       ← space.6 below
[Summary cards row: Income | Expenses | Net]   ← horizontal 16dp margins
[Category breakdown list]               ← section header + rows
[Recent entries]                        ← section header + rows
                    [FAB]               ← bottom-start, space.6 from inset
[Bottom nav 64dp + inset]
```

- Summary cards: three equal cards in one row on ≥ 360dp; on narrow (<360dp), Income/Expense side-by-side and Net full-width below.
- KPI value uses `type.display`/`title`; label `type.caption` on `color.text-secondary`.

---

## 7. Form layout

- One column, fields stack vertically with `space.4`/`space.5` gap.
- Label above field (always visible, not placeholder-only — interaction-model §3).
- Amount field: compact width, bigger number; unit `ج.م` inside the field end.
- Date field: tappable trigger with calendar icon at end.
- Save button full-width at bottom (48dp height), spaced `space.5` above keyboard.

---

## 8. List layout (Transactions / Categories / Settings)

- Row min height 48dp; touch target fills the row (padding may expand).
- Thumbnail 40×40dp rounded 8 at start; text block takes remaining width with single-line truncation; trailing amount + chevron.
- Between-row gap: none (they are contiguous with a 1dp divider or flush), interactive-neighbor gap ≥8dp enforced only between separate interactive controls (filters/search chips).
- Group headers pinned on scroll for large lists (optional; performance-friendly).

---

## 9. FAB

- Size 56×56dp, margin `space.6` from bottom inset, `space.4` from start edge (`bottom-start` in RTL).
- Extended FAB with label ("إضافة معاملة") preferred for discoverability; collapses to icon on very narrow screens.
- Not part of the tab bar; owns the global Add flow (navigation-map §1).

---

## 10. Bottom navigation

- Height 64dp + system inset padding.
- 4 items, labeled (Arabic), icon 24dp + label `type.caption` (12). Touch target ≥48dp per item.
- Active color `color.primary` (dark: blended); inactive `color.text-secondary`.
- Selection is a state, tab identity replaces content (navigation-map §1) — no swipe-away, no depth.

---

## 11. Landscape & tablet policy

- **Landscape:** supported but not optimized; the app favors portrait. In landscape, enforce keyboard-first focus and reflow (amount/dates remain reachable); bottoms sheets become side-anchored; FAB stays bottom-start.
- **Tablets (>600dp min):** content max-width 600dp centered; lists may expand columns only if the approved UX offers no multi-pane (it doesn't) — so cap content width, keep single-column rhythm for MVP. Dashboard may lay KPI row wider.

---

## 12. Empty/loading spacing

- Empty state block centered: illustration (≤120dp), headline, caption, CTA — `space.6`/`space.7` gaps.
- Skeleton elements mirror the real layout's geometry exactly (same margins/rows), so the transition to content avoids jumps (see `feedback-states.md`).

---

## 13. Anti-patterns

| Anti-pattern | Why |
|---|---|
| 8dp everywhere | Loses hierarchy; bigger gaps read as sections |
| Card per list row | Visual noise; slows scan (Principle 1) |
| Content touching screen edges | Reduces legibility; breaks safe-area rules |
| Mirrored padding via RTL | Duplication + drift; use direction-agnostic tokens |
| Bottom nav without inset | FAB/gesture overlap; input blocked by system bar |
| Compressing touch targets when space is tight | Accessibility + tap-error regression (Principle 8) |