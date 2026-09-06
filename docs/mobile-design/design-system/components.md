# Components — Hesably Design System

**Purpose:** the canonical component inventory for the Hesably mobile app. Every component in the inventory maps to an approved screen/overlay (SCR-xx/OVR-xx) and a state in `ux-states.md`. A component not justified by the approved UX does not exist.
**Sources:** `ux/screen-inventory.md` (SCR/OVR), `ux/interaction-model.md`, `ux/ux-states.md`, `ux/navigation-map.md`, `ai-patterns.md`, `offline-patterns.md`, `color-system.md`, `spacing-layout.md`.

---

## 0. Grouping

```
Foundation     → tokens, type, color roles (see tokens.md / typography.md / color-system.md)
Navigation     → bottom nav, app bar, back, sheets, dialogs, FAB, full-screen flow
Actions        → buttons, icon buttons, chips, segmented control, link
Inputs         → text/numeric/amount/search fields, dropdown, date trigger, OTP, checkbox, radio, switch (see forms-controls.md)
Data Display   → list rows, KPI/summary cards, receipt preview, category row, group headers, skeletons, empty states
Feedback       → inline error, snackbar, banner, validation, retry patterns
AI             → processing, extraction result, confidence, flags, suggestion, provenance (see ai-patterns.md)
Offline        → offline banner, pending states, sync states, retry (see offline-patterns.md)
Receipt Capture→ camera, quality gate, upload progress
Financial      → amount text, net/income/expense figures, comparison (see financial-ui.md)
Overlays       → bottom sheet, alert dialog, date-range picker, export options, receipt viewer, discard guard
```

Each component below documents: **purpose · variants · states · anatomy · usage rules · anti-patterns.**

---

# NAVIGATION

## Bottom Navigation (SCR-05/06/11/12)

- **Purpose:** the four global destinations (Home, Transactions, Reports, Settings). Tab identity is state, not stack (navigation-map §1).
- **Variants:** default (4 items, labeled).
- **States:** active (primary color + filled icon), inactive (text-secondary + outline icon). No count badge in MVP.
- **Anatomy:** 64dp + inset; 4 equal items; icon 24dp above label 12dp (`type.caption`).
- **Usage rules:** only 4 destinations, no middle FAB, no badges; switching replaces content but preserves each tab's in-memory state (filters/scroll). Order in RTL: Settings ← Reports ← Transactions ← Home (Home at the right edge — information-architecture §7).
- **Anti-patterns:** adding a 5th tab; putting the FAB into the bar; clearing filters on tab switch.

## App Bar

- **Purpose:** contextual header for pushed/flow screens (Detail, Settings sub-pages, Review form, Reports).
- **States:** with back (pushed screens), with action (Edit/Delete on Detail), plain title.
- **Anatomy:** `type.headline` title (start-aligned in RTL), leading back at 48dp, optional trailing actions at 48dp.
- **Rules:** title truncates if long (ellipsis); back is `arrow_back` mirrored — never a custom glyph. No big decorative header on Data surfaces (transactions/reports read better with the app bar slim).
- **Anti-patterns:** giant blurdrome headers that wash content; hidden back.

## FAB

- **Purpose:** the single global action — Add Transaction (G2).
- **Variants:** extended (icon + label "إضافة معاملة") default; icon-only on very narrow (<320dp).
- **States:** default; disabled is never shown (always valid to begin add).
- **Anatomy:** 56×56dp; margin `space.6` from bottom inset, `space.4` from start edge (bottom-start in RTL).
- **Rules:** FAB lives on Home only; while a flow is open it is not reachable (flow is full-screen).
- **Anti-patterns:** FABs on Transactions/Reports/Settings; center-FAB in the tab bar.

## Bottom Sheet (modal) — OVR-01, OVR-02, OVR-03, SCR-15

- **Purpose:** category picker, export options, date-range picker, and category add/rename.
- **Variants:** menu sheet (list), picker sheet (with search), form sheet (SCR-15).
- **States:** open (drags up), collapsing, dismiss. Content states: loading/empty/error per `ux-states.md`.
- **Anatomy:** grab handle, header (title + optional close), scrollable body, sticky action row (when needed). Rounded top corners `radius.lg`.
- **Rules:** blocks interaction until dismissed; system back dismisses the sheet only (navigation-map §7); a sheet never holds a confirmation for a destructive action (dialogs do).
- **Anti-patterns:** stacking two sheets; a sheet that navigates; a sheet body taller than 90% of screen without scrolling.

## Alert Dialog — OVR-04, OVR-05, OVR-06, OVR-07

- **Purpose:** destructive and data-losing confirmations. Every destructive action is a two-step tap → confirm (G7).
- **Variants:** delete confirmation (OVR-04), account-delete (OVR-05, typed confirm), logout (OVR-06), discard review (OVR-07).
- **States:** content, (for delete-account) disabled confirm until typed text matches.
- **Anatomy:** title, body restating the record/value + irreversibility, actions row: escape ("إلغاء") + confirm (destructive color). Confirm on the **left** in RTL (primary position mirror), cancel on the right.
- **Rules:** a dialog always has exactly one primary affirmative; destructive confirm is `color.status.error` filled; body states exact data scope for delete-account ("سيتم حذف كل بياناتك نهائيًا").
- **Anti-patterns:** neutral-colored destructive confirm; auto-dismiss; more than one destructive button; using a sheet for destructive confirm.

## Full-screen flow (Add Transaction) — SCR-08 → 09 → 10

- **Purpose:** the single global capture pipeline (type → capture → review/save), plus manual-entry shortcut. Linear, finish-and-return.
- **Anatomy:** steps carry their own app-bar/header; back behavior per `navigation-map.md` §3 (type preserved on back from Capture; Review exit guarded by OVR-07).
- **Rules:** never a modal overlay — it is a proper route stack so system back works. Processing is in-flow (SCR-09) with the 15s ceiling.
- **Anti-patterns:** wizard-style step indicators (progress dots) that add visual noise on a 3-step linear flow; replacing the back stack.

---

# ACTIONS

## Button — Primary / Secondary / Tertiary / Destructive

- **Variant table:**

| Variant | Fill | Content | Use |
|---|---|---|---|
| **Primary** | `color.primary` | `color.on-primary` | Save, Send code, Verify, Continue, Date-range apply, final Export |
| **Secondary** | outline `color.secondary` / surface | `color.secondary` | secondary flow action (retry on inline message, manual fallback button, "keep editing") |
| **Tertiary / Text** | transparent | `color.primary` | inline link-actions, "إدخال يدوي" in capture, secondary-in-row |
| **Destructive** | `color.status.error` | white | Confirm-delete dialogs (OVR-04/05), row "Delete" action (text/icon) |

- **Sizes:** height **48dp** (primary/secondary/destructive, full-width or content-width), compact 40dp allowed **only** within rows/sheets (still ≥44dp tappable). Icon size 20dp + gap `space.2`.
- **States:** default; pressed (slightly darken/scale 0.98); **loading** (spinner replaces icon, label "جارٍ الحفظ…", disabled — no double submit); **disabled** (text-disabled on surface-variant, not color-only); **focused** (accent ring).
- **Rules:** one primary CTA per flow step. A button never silently succeeds — always resolves to success or error. Save button disables during in-flight.
- **Anti-patterns:** two primary buttons on one surface; a disabled Save without explanation; destructive tertiary on a read surface; icon-only primary action (add label or go icon-button pattern).

## Icon Button

- **Purpose:** toolbar/row actions (edit, delete, close, more, share).
- **Anatomy:** 48×48dp hit box, glyph 24dp.
- **Variants:** standard (on-surface), tonal (primary-container tint for accent actions), destructive (error color, only for confirmed-destructive context).
- **States:** default/pressed/disabled/focused (accent ring); never silent.
- **Rules:** icon buttons carry a `Semantics` label always; a destructive icon button is only for actions validated by a confirmation dialog.
- **Anti-patterns:** icon bars without labels when meaning isn't universally obvious; destructive icon on a list row without a confirm.

## Chip — Filter / Suggestion / Status

- **Purpose:** compact selectable states and badges.
- **Variants:**
  - **Filter chip** (Transactions filter bar): selectable, shows applied filter, removable `×`.
  - **Suggestion chip** (AI-suggested category in OVR-01): indigo `color.ai-container` + AI glyph, non-dismissing, indicates "AI suggests".
  - **Status chip** (pending/syncing/offline): see `offline-patterns.md`.
- **Anatomy:** `type.label`; padding `space.2`/`space.3`; radius full; icon 16–18dp; touch target ≥32dp chip but guaranteed ≥44 tap (enlargeable).
- **States:** default / selected (check or filled) / disabled / focused.
- **Rules:** chips are for selection & status, not for navigation; a filter chip always has a clear affordance to remove the filter.
- **Anti-patterns:** chips that toggle screens; chips as the only control for permanently-important filters; a chip labeled only by icon.

## Segmented Control — period selector (SCR-11)

- **Purpose:** unified period choice (This Week / This Month / Last Month / YTD / Custom) — interaction-model §4 / Q-011.
- **Anatomy:** equal segments, selected = primary-container fill + primary text; unselected on surface-variant.
- **States:** default, selected, disabled (rare), focused. Scrollable horizontally if labels overflow on 360dp.
- **Rules:** exactly the five Q-011 options; Custom opens OVR-03.
- **Anti-patterns:** a dropdown hamburger instead of visible segments; extra periods beyond Q-011.

## Link / text action

- **Purpose:** resend code (with countdown), "تواجه مشكلة؟" support link, "enter manually" in AI terminal states, retry links.
- **Anatomy:** text-only, `color.primary`, `type.body`/`label`, min 44dp hit area.
- **Rules:** a link is not a button — no fill. Countdown resend shows remaining seconds (`إعادة الإرسال بعد ٤٨ ث`), enabled after 60s (Q-001).
- **Anti-patterns:** making links look like primary buttons; a disabled resend without the countdown.

---

# DATA DISPLAY

## List Row — base (used by Transactions, Categories, Settings, breakdown)

- **Anatomy:** leading visual (thumbnail 40×40 / icon / checkbox), text block (single-line truncate, secondary caption below), trailing (amount or chevron or toggle). Min height 48dp; padding `space.4`. Dividers 1dp `color.border` (or flush groups).
- **Variants:** tappable row (chevron), switch row (settings), checkbox row (filters), removal row.
- **States:** default / pressed (surface-variant wash) / disabled / selected; no hover.
- **Rules:** row tap target = full row height ≥48dp; truncation uses `…`; category-row secondary shows transaction count or usage (SCR-14 usage display).
- **Anti-patterns:** cards per row; secondary action vs primary-tap ambiguity (never both delete-icon and row chevron without 8dp+ separation); over-truncating the party name (keep full on Detail).

## Transaction Row (SCR-06)

- **Anatomy:** thumb (40×40 rounded), party name (`body-strong`, truncated), category caption below, trailing: date caption + **amount** (`body-strong`, income success-green / expense neutral), optional low-confidence flag icon.
- **Rules:** income/expense indicated by icon + label + amount color — never color alone. Grouped by date with sticky group headers.
- **Anti-patterns:** red expense; amount as the only distinguishing element between two rows; date+category stacked twice.

## KPI / Summary Card — Home & Reports

- **Purpose:** glanceable current-month income / expenses / net; Report period summaries.
- **Anatomy:** label (caption), value (`type.display`/`title`), optional delta chip ("+15% vs last month"). Compact card `color.surface`, radius `radius.md`, padding `space.4`.
- **Variants:** static; interactive (tap→Transactions with date filter — navigation-map). Value vs label always 2-step contrast (Principle 6).
- **States:** loading (skeleton mirrors geometry), content, error (per-surface retry).
- **Rules:** Net is the hero on Home (`type.display`); Income success-green ✔, Expense neutral, Net primary/neutral (dark: adjusted). Delta chip: up = success green for income, down = success green for expense (direction-aware — see `financial-ui.md`).
- **Anti-patterns:** a decorative gradient behind the value; animate counting that stutters on low-spec (count-up only if cheap; default static).

## Category Breakdown Row — Home / Reports

- **Anatomy:** category label + progress bar (proportional share, `color.primary-container`-track → primary fill) + amount + percent.
- **Bar fill rule:** progress bars fill LTR even in RTL (interaction-model §7).
- **Anti-patterns:** donut charts on 360dp (list + share bars per approved UX); bar label rotated.

## Receipt Preview Card — SCR-07/10/17

- **Anatomy:** image 16:9 or contain, rounded `radius.md`; overlay/tap opens full-screen viewer (SCR-17); caption "صورة الفاتورة".
- **States:** loading (placeholder shimmer), loaded, error → "تعذر تحميل صورة الفاتورة" + retry (receipt-not-found variants), offline → blocked note + retry (image requires network).
- **Rules:** image is private-bucket only; aspect preserved; never crops a receipt blindly.
- **Anti-patterns:** full-bleed hero receipt on Detail (it is supporting data, not the hero).

## AI Extraction Result Block (SCR-10, AI path)

- See `ai-patterns.md` — the block is the pre-filled form area with: provenance chip ("تم الاستخراج الذكي"), confidence flags per field, and the "راجع قبل الحفظ" advisory. Not a separate component file, defined there.

## Sync / Pending State Card — Pending list

- See `offline-patterns.md` — pending capture card: thumbnail, "تم الحفظ محليًا", status chip (waiting/syncing/failed), "مزامنة الآن" action, delete-local `×` (confirmation).

## Group Header / Section Header

- **Anatomy:** `type.caption` secondary text on a `space.4` above gap, 8dp below. Pinned on scroll in long lists (optional).
- **Rules:** header text is plain and specific ("هذا الشهر", "اليوم", category group name); never decorative.
- **Anti-patterns:** animate section headers; use headers where a single title + list would do.

## Empty State

- **Purpose:** first-time, no-transactions, no-matches, no-search-results, no-reports-data, no-pending, no-customs, no-web. (Copy per `ux-states.md` §4.)
- **Anatomy:** centered: single icon/illustration (≤120dp, outline glyph or flat illustration in muted colors), headline (`type.headline`), supporting message (`type.body` secondary), **primary CTA** (button or FAB-hint), optional secondary text-action.
- **Rules:** EMPTY always carries an action (state invariant #2). What the CTA is depends on surface:
  - Home empty → FAB visible + “ابدأ بأول معاملة” with FAB CTA.
  - Transactions empty → clear filters action + add hint.
  - Search no results → clear-search/reset action (never a dead end).
  - Reports no data → “لا توجد بيانات لهذه الفترة” + change-period action.
  - Pending empty → "لا توجد معاملات بانتظار المزامنة".
- **Anti-patterns:** oversized illustration pushing the CTA off-screen; a dead-end empty (no action); decorative illustration that implies a state ("success") where none exists.

## Skeleton

- **Purpose:** LOADING placeholder on content surfaces (list/Home/Reports/Categories).
- **Anatomy:** grey rounded blocks mirroring the final layout 1:1 (same row heights, same grouping); subtle 1.2s slow pulse, **not** a fast shimmer sweep (low-spec). 
- **Rules:** skeletons over spinners on scrollable content; skeletons inherit the same margins so no reflow on content arrival.
- **Anti-patterns:** animated marquee shimmer (expensive); skeleton shapes that don't match the data geometry (jump); a full-screen spinner where a skeleton fits.

---

# FEEDBACK

## Inline Field Error

- **Purpose:** per-field validation (interaction-model §3).
- **Anatomy:** below the field, 12dp: `error_outline` 16dp + `type.caption` error text; field border shifts to error.
- **States:** on blur/commit and on re-submit; re-announced to screen reader.
- **Rules:** inline per-field, Arabic, actionable; a single field error never blocks the whole screen with a banner.
- **Anti-patterns:** global error banner for a field error; errors only on submit with no per-field hints; red borders with no message.

## Snackbar

- **Purpose:** success outcomes (save success, link sent, sync done) and transient status.
- **Anatomy:** bottom-anchored (above nav or keyboard), `color.surface`/`inverse-*`, `type.body`, optional action ("عرض", "تراجع" — none for MVP except dismiss), `space.4` margins, radius `radius.sm`. Auto-dismiss ~4s (success) / 10s (important).
- **Rules:** snackbar ≠ error placement — errors go inline near the trigger; snackbar never communicates a destructive outcome as “success”. Success snackbar appears **only after user's own confirm** (G4).
- **Anti-patterns:** snackbar for field validation; stacking snackbars; snackbar that requires a tap to dismiss with no timeout.

## Banner — persistent (offline, web-access notes)

- **Purpose:** persistent non-blocking state (offline) — see `offline-patterns.md`.
- **Anatomy:** below app bar or above content, `color.warning-container`-ish or offline-tinted, icon + message + optional action; dismissible where the state allows.
- **Rules:** a persistent banner is for states that persist (offline), not for one-off events.
- **Anti-patterns:** a banner for every transient error; banners that push a FAB out of reach (position above bottom nav or below top bar carefully).

## Retry Pattern

- **Purpose:** every failure/error/empty (non-terminal) exposes an explicit retry or alternate path (G3, state invariant #3).
- **Variants:** inline retry next to the error (row/block), full retry on ERROR state banner, "إعادة المحاولة" button.
- **Rules:** retry preserves the user's entered data; a failed POST never clears the form.
- **Anti-patterns:** a silent auto-retry loop with no user visibility; a retry that loses context.

## Validation feedback (form-level)

- **Anatomy:** on submit, all invalid fields highlight + inline errors appear; a single non-blocking summary line is allowed above the Save only when several fields are wrong, still with inline per-field errors.
- **Rules:** validation is per-field; required markers visible; submit is blocked with inline message and no silent pass.
- **Anti-patterns:** disabling Save with zero explanation; collecting errors into one undeletable banner.

---

# RECEIPT CAPTURE (SCR-09)

## Camera Viewfinder

- **Anatomy:** full-bleed camera preview, reticle/guidelines (align receipt), shutter 64dp center-bottom, gallery + manual icons flanking at 48dp.
- **States:** initializing, ready, permission-denied (message + "فتح الإعدادات"), gallery-unavailable (message + manual), capturing.
- **Rules:** camera is primary capture path; manual entry always reachable (FR-CAPTURE-007).
- **Anti-patterns:** overlaying content on the viewfinder that fights the shutter; hiding gallery behind a menu.

## Image Quality Card — PASS/WARNING/REJECT (Q-020)

- **Purpose:** advisory gate before AI; on-device heuristic.
- **States:**
  - **PASS** — green `check_circle` + caption "الصورة واضحة — متابعة".
  - **WARNING** — warning `warning_amber` + "الصورة غير واضحة — قد لا تُقرأ بدقة. متابعة على أي حال؟" → continue or retake.
  - **REJECT** — error `cancel` + guidance "أعد التصوير… (إضاءة أوضح/إمالة أفقية)" + actions Retake / Choose again / Manual.
- **Rules:** quality states are **guidance, not errors** (ux-states matrix SCR-09). Reject is guidance → retake; non-terminal.
- **Anti-patterns:** blocking the manual path; scoring UI that looks like a camera bug.

## Upload / Processing Progress (in-flow)

- See `ai-patterns.md` processing view: determinate-ish progress + "جارٍ المعالجة…" + 15s ceiling + "أدخل يدويًا" always visible.
- **Anatomy:** card with AI glyph + status text + thin progress + escape link.
- **Anti-patterns:** a frozen spinner with no ceiling; no escape.

---

# OVERLAYS (complete)

- **Bottom Sheet** — navigation section above (OVR-01/02/03, SCR-15).
- **Alert Dialog** — navigation section above (OVR-04/05/06/07).
- **Date-Range Picker** (OVR-03): calendar grid (native Arabic calendar), start ≤ end validation, quick toggles + custom; inline.
- **Export Options** (OVR-02): format choice (PDF/Excel/CSV), period row defaults to current view (Q-014), Export action → share sheet.
- **Category Picker** (OVR-01): defaults group → customs group; AI-suggestion badge on AI-suggested row; optional search; selection collapses sheet.
- **Receipt Viewer** (SCR-17): full-screen image, pinch/zoom, close; loading/error/offline states per matrix.
- **Discard Guard** (OVR-07): "سيفقد ما لم تحفظه" — Keep editing / Discard. Applied on back with unsaved form or just-captured photo.

All overlays follow the shared states (loading/empty/error/offline), the destructive-dialog rules, and the one-primary-action rule.

---

## 1. Component count discipline (no explosion)

Allowed additions to a screen must be **reused components only** — the inventory is closed. To add a component: get approval per `design-system-governance` rules (see README/§governance), meeting tests: maps to an approved state, reusable ≥2 screens, no overlap with an existing component, and stays within the anti-pattern rules. No one-off bespoke widgets.

## 2. Cross-cutting invariants (all components)

- Touch target ≥48dp for primary/icon actions; ≥44dp never below (interaction-model §1).
- Interactive neighbors ≥8dp apart.
- Every state is LOADING/CONTENT/EMPTY/ERROR/OFFLINE-or-transitional coherent (ux-states taxonomy) — a component cannot invent a new primary state.
- No double-submit; every in-flight button is disabled + labeled.
- Destructive = two-step + destructive color + stated consequence (G7).
- Direction-aware icon mirroring (iconography §4); income/expense never color-only.
- AI never presented as confirmed; offline never presented as synced (see dedicated files).
- Arabic-first copy; Latin digits for numbers (Q-012).