# Iconography — Hesably Design System

**Purpose:** consistent, semantic icon direction for a financial, Arabic-first app. One icon family, clear stroke/fill strategy, fixed sizes, RTL mirroring rules, and a reserved vocabulary for financial, AI, and offline/sync states.
**Sources:** `ux/ux-states.md` (state icons), `ux/interaction-model.md` (RTL mirror), `ux/information-architecture.md` (nav), `ai-patterns.md`/`offline-patterns.md` (special repertoires).

---

## 1. Icon family

**Primary:** **Material Symbols — Outlined** (Google, free, native to Flutter via `material` icons; web-compatible via backport webfont/`@material-symbols`).

- **Stroke = outline** for all content icons; filled variant reserved for **active state** (bottom nav, selected chip) only.
- Geometry: stroke weight ≈ 1.75 (at 24dp optical), rounded caps/joins.
- Do not mix icon families; a single set keeps recognition fast (Principle 1, P7).

> DESIGN INFERENCE: Material Symbols is chosen for zero-cost Flutter/web alignment and RTL-aware directional glyphs. No requirement names a vendor; the standard Flutter glyph set + RTL-aware `matchTextDirection` handles the mirroring rules below.

---

## 2. Icon sizes (tokens)

| Token | Size | Typical use |
|---|---|---|
| `icon.xs` | 16dp | inline with caption, badge dot, small helper |
| `icon.sm` | 20dp | list leading (thumbnail-adjacent), chip, field-end adornment |
| `icon.md` | 24dp | standard control icon, bottom nav, FAB icon, empty-state visual |
| `icon.lg` | 28dp | section header action, sheet content leading |
| `icon.xl` | 32dp+ | empty-state illustration core, hero visual (≤48dp) |

Rules:
- Icons are optically aligned to text cap-height where inline (baseline → 0.2em offset), never floating mid-line unevenly.
- Icon buttons are **48dp touch targets** even when the glyph is 20–24dp (invisible expanded hit area).
- No 14dp icons anywhere (unreadable; violates Principle 8).

---

## 3. Semantic vocabulary (canonical set)

### 3.1 Navigation / global
| Icon | Use | RTL note |
|---|---|---|
| `home` | Home tab | stable |
| `receipt_long` | Transactions tab | stable |
| `bar_chart` / `query_stats` | Reports tab | stable |
| `settings` | Settings tab | stable |
| `add` | FAB "إضافة معاملة" | stable |
| `arrow_back` / `arrow_forward` | Back / forward | **mirrors** (matchTextDirection) |

### 3.2 Actions
`save` (Save), `edit` (Edit), `delete` (Delete — destructive only), `close` (`×`, direction-free), `search` (search), `filter_list` (filter bar), `refresh` (retry), `more_vert` (overflow), `check` (confirm), `chevron_right` (disclosure — mirrors), `download` (export), `share` (share sheet).

### 3.3 Financial
`currency_pound`/`payments` (EGP context), `trending_up` (income), `trending_down` (expense — see note), `account_balance_wallet` (net), `sell`/`local_mall` (sales/purchases), `receipt_long` (receipt), `category` (category). 

> **Expense icon note:** use `trending_down` or a neutral `remove`/`arrow_downward` in **secondary/grey** tint, not red — aligns with the "expense ≠ danger" color rule. Income uses `add`/`trending_up` in success green.

### 3.4 AI
`auto_awesome` (sparkles — reserved AI marker), `document_scanner` (capture/extraction), `psychology`/`smart_toy` (AI assist — use sparingly), `lightbulb` (suggestion), `rule`/`fact_check` (confidence flag). These are **reserved**: no other surface uses the AI glyph.

### 3.5 Offline / sync
`cloud_off` (offline), `cloud_queue` / `cloud_done` (pending/synced), `sync` (syncing), `sync_problem` (failed sync), `pending_actions`/`schedule` (waiting — "في انتظار الاتصال"), `download_done` (local only). Reserved for offline/sync surfaces.

### 3.6 Status
`check_circle` (success), `error_outline` (error), `warning_amber` (warning/advisory), `info_outline` (info), `hourglass_top` (processing-inline), `cancel` (rejected/failed).

### 3.7 Capture
`photo_camera` (camera), `photo_library` (gallery), `document_scanner` (scan), `camera_alt` (shutter).

---

## 4. RTL icon rules

- **Directional** icons (arrows, chevrons, next/back, order, sort) **mirror** automatically under RTL via Material's `matchTextDirection`/Directionality. Always author them at the semantic level (`arrow_back`) and let the framework flip — never hard-code a mirrored variant in a screen.
- The FAB `add` (`+`), close `×`, status glyphs, search magnifier, camera — **do not mirror** (visually symmetric or direction-free).
- Sort/filter indicators: a `arrow_downward`+“asc/desc” label mirrors the arrow; keep the glyph tied to the semantics, not the screen corner.
- In mixed LTR strings (dates, phone), icons **do not** flip during bidi — only layout direction semantics flip, not glyph internals.

---

## 5. Consistency rules

1. **One icon family** across the app; no per-screen pick.
2. **Semantic reservation:** AI glyphs only on AI surfaces; sync/offline glyphs only on sync/offline surfaces; status glyphs only on status.
3. **Glyph + label pairing for meaning.** A status/state icon must be accompanied by text (or a `Semantics` label) on every state — never color-only or glyph-only (Principle 7, accessibility).
4. **Filled vs outline:** outline is the default; filled used for active nav/chip only. Keep a consistent switch: when an outline icon is "on", it becomes filled — do not switch between two unrelated glyphs for on/off.
5. **Sizes follow the token set**; never `Icon(size: 19)` (Principle 8).
6. **Decorative icon reuse** must map to a real approved state; don't invent new glyphs for illustration-only.

---

## 6. Anti-patterns

| Anti-pattern | Why |
|---|---|
| Two icon families (e.g., Material + custom) | Inconsistent visual weight; recognition cost |
| Hand-mirrored arrows in RTL | Fragile; breaks when direction flips |
| Red expense glyph | Expense ≠ error (color rule §color-system) |
| Icon-only destructive confirm | Ambiguous + fails accessibility (needs label) |
| Random custom SGV per empty state | Inflation; un-versionable |