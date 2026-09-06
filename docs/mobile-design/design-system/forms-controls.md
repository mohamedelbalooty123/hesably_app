# Forms & Controls — Hesably Design System

**Purpose:** consistent, accessible form controls for the Arabic-first financial app. Covers default/focused/filled/error/disabled/read-only/loading states; financial inputs must be easy to scan and hard to misinterpret.
**Sources:** `ux/interaction-model.md` §3, `ux/screen-inventory.md` (SCR-02/03/04/10/12/13/15/16), `ux/ux-states.md` (validation sub-state), `typography.md`, `color-system.md`.

---

## 0. Shared control rules

- **Fields:** every input has a **visible top-aligned label** (never placeholder-only) — interaction-model §3. Placeholder, when present, is lighter guidance text, never the only label.
- **Touch target:** text/numeric inputs ≥48dp tall; interactive areas ≥44dp hit region.
- **States** on every control: `default`, `focused` (border + accent focus ring, never color-only), `filled`, `error` (border + inline message), `disabled` (surface-variant fill on text-disabled, not color-only), `read-only` (same as filled + lock icon, non-interactive affordance), `loading` (inline progress; field disabled while in-flight).
- **Error placement:** inline below the field; re-announced to screen readers on submit (accessibility).
- **RTL:** text entry dir = current language; numeric/dates/phone keep LTR glyph order inside bidi isolation (interaction-model §7).
- **Arabic-first labels,** Latin digits for numbers/phone (Q-012).

---

## 1. Text field (business name, vendor/customer, category name, email)

| Aspect | Spec |
|---|---|
| Anatomy | label (`type.label`), text input (48dp, body), helper/counter optional, error slot below |
| Border | 1dp `color.border`, radius `radius.sm`; focus → 2dp `color.primary`; error → 2dp `color.status.error` + message |
| IME | Arabic default keyboard for Arabic name fields; email → email keyboard |
| Max length | name ≤ 60 chars, vendor ≤ 60, email validated (RFC-loose), no regex beyond cap (interaction-model §3) |
| RTL | text aligns start (right); Latin-only values (email, phone) align start too (bidi-safe) |

- **Anti-patterns:** placeholder-as-label; an X-clear button inside field-end that fights the RTL end-affordance; auto-capitalization on Arabic.

## 2. Numeric field (generic, e.g., any count)

- `type.body`, numeric keyboard, Latin digits. Live-format thousands separators when semantically numeric (not for codes).
- Input filtering: strip non-digits except allowed separators.

## 3. Amount input (financial — SCR-10/13)

- **Anatomy:** label "المبلغ", 48dp field, EGP unit `ج.م` at field-end (start glyph and end unit per RTL), numeric decimal keypad.
- **Formatting:** the field shows the entered value **live-formatted** with thousands separators (`1,250.50`); precision 2 decimals; round only at input-level to 2 decimals — never silently on display (Q-012).
- **Validation:** amount > 0 required; date required; category required. Invalid → inline message ("أدخل مبلغًا أكبر من صفر").
- **State note:** large amounts scale the number visibly (bigger than surrounding labels) — the field's value is the field's hero (Principle 6).
- **Anti-patterns:** currency symbol typed by the user; Arabic-Indic digits; rounding shown differently than stored.

## 4. Search field (SCR-06)

- **Anatomy:** rounded full, search icon at start, placeholder "ابحث باسم المورّد/العميل…", clear `×` at end when text present.
- **Behavior:** **350ms debounce** (interaction-model §8); results appear under the query = party-search (Q-022).
- **States:** default/focused/filled/cleared; no-results → search-empty variant (`ux-states.md` §4).
- **Anti-patterns:** live-search without debounce (flicker); search that matches transaction ids.

## 5. Dropdown / select — category, business type, format (sheets)

- **Purpose:** category selection (OVR-01), business type (SCR-04/13 radio — not dropdown), export format (OVR-02).
- **Anatomy:** field that opens a **bottom sheet** (category/format) — the field itself is a tappable trigger with chevron; selected value previews in the field.
- **State:** triggered field shows current selection; sheet shows groups; AI-suggestion badge on AI rows.
- **Rules:** a select is never a free-text field; category selection collapses sheet and fills field.
- **Anti-patterns:** a native `<select>`-styled dropdown that scrolls inline instead of using the app's sheet pattern (breaks consistency); duplicating controls.

## 6. Date trigger & date picker

- **Anatomy:** tappable field (48dp) with calendar icon at end; label; shows selected date formatted per locale.
- **Picker:** native Arabic calendar (interaction-model §3); default = today for new entries; validation start ≤ end for range (OVR-03).
- **States:** default, focused (picker open), disabled (read-only business — currency is read-only), error (invalid range).
- **Anti-patterns:** a homegrown cal UI instead of native; a text input where the user types a date string.

## 7. OTP input (SCR-03)

- **Anatomy:** 6 separate boxes, 48dp each, auto-advance focus, paste allowed (interaction-model §3).
- **States:** default, filled (each box), error (wrong code → all boxes error-border + inline "الرمز غير صحيح، حاول مجددًا"), resend cooldown **60s** with visible countdown → enabled link after (Q-001).
- **Rules:** Latin 6-digit code; a "تواجه مشكلة؟" support link present (FR-AUTH-005). Verify button enabled only when 6 digits present.
- **Anti-patterns:** a single non-segmented field; Arabic-Indic digits in OTP (backend expects Latin).

## 8. Checkbox (filter options, delete-account typed confirm)

- **Anatomy:** 24dp box + label at `space.2` gap; min tap area 44dp (box+label).
- **States:** checked/unchecked/disabled; RTL label right of box.
- **Rules:** in delete-account confirmation, typed-text match (not checkbox) is the MVP guard (OVR-05) — checkbox only for filter multiselect.
- **Anti-patterns:** a checkbox used as a switch (behavior mismatch).

## 9. Radio group (business type SCR-04/13, filter type)

- **Anatomy:** 24dp radio + label; vertically stacked rows ≥48dp; selection = primary dot fill.
- **Rules:** a default selection where required (business type has no default — user must choose); matches stored `business_types` domain (interaction-model §4).
- **Anti-patterns:** radio rows with a trailing chevron (they aren't navigational).

## 10. Switch (category show/hide, language toggle, web-access)

- **Anatomy:** 52×32dp thumb track; on = primary fill; off = surface-variant. Label + optional row (switch row = settings row style).
- **Rules:** switch = immediate state change with visible effect (language applies instantly; hide-category toggles lists). Confirmation needed only for destructive switches (unlink web).
- **Anti-patterns:** a switch that opens a dialog (that's an action/destructive → use button/dialog); silent state since last value not shown.

## 11. Filter chips (SCR-06 filter bar)

- Per `components.md` §chips: selectable, removable `×`, filter badge count optional. Applying a filter re-queries (debounced where search is combined).
- **Anti-patterns:** filter chips that trigger navigation; no clear-all.

## 12. Segmented control (period SCR-11)

- Per `components.md` §segmented: Q-011 options only; Custom opens OVR-03.

---

## 13. Financial input trust rules (recap + expanded)

1. **Latin digits** for all numeric entry (amounts, phone, OTP) — backend `numeric(14,2)` + phone checks (Q-012).
2. **Live formatting** as the user types (thousands separators, 2 decimals); never reformat on blur only (user scans the running total).
3. **EGP unit `ج.م`** is a fixed field-end affordance, not a character the user types.
4. Amounts ≥ 1,000 get comma separators immediately (`1,000`); decimals trailing `.00` shown (consistent precision).
5. A field error states the expected fix in plain Arabic ("أدخل مبلغًا أكبر من صفر").
6. **Never** convert fields silently (no "assumed 250 ج.م "); no default amounts injected by AI without a visible flag (see `ai-patterns.md`).

## 14. Form-level behavior (SCR-10, SCR-13, SCR-16, OVR-03)

- One column, fields stack, `space.4`/`space.5` vertical gaps.
- Save/Submit is full-width 48dp at the bottom; disabled only with explanation; shows "جارٍ الحفظ…" in-flight and blocks double-submit.
- Unsaved form exit → OVR-07 (Keep editing / Discard) when content exists (FR-REVIEW-001).
- Read-only currency note (EGP fixed, Q-012) shown as a caption on SCR-04/SCR-13, never an editable field.

## 15. Anti-pattern summary

| Anti-pattern | Why |
|---|---|
| Placeholder-only labels | Invisible for a scanning user (interaction-model §3) |
| Arabic-Indic digits in amount/phone/OTP | DB mismatch; ambiguity (Q-012) |
| Silent decimal rounding | Financial trust (Q-012) |
| Type fields instead of pickers for category/type | Free-text drift; AI/category matching breaks |
| Double-submit buttons | Duplicated records (FR-REVIEW save-in-flight) |
| Evil-composite controls (a toggle that fires a navigation) | Confusing semantics |
| Color-only validation | Color-blind + screen-reader silent (accessibility) |