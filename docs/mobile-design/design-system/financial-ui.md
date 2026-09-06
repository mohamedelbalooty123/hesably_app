# Financial UI — Hesably Design System

**Purpose:** rules for how amounts, dates, and the ledger behave visually — so a shop owner can scan quickly, never misread a number, and trust the data.
**Sources:** `ux/ux-states.md` §5 (financial trust), `typography.md` (numeric treatment), `color-system.md` (income/expense), `requirements.md` (Q-012), `business-rules.md` (BR-TRANS), `user-flow-mobile.md` (Transactions/Reports flow), `components.md` (amount row, ledger list, detail sheet).

---

## 1. EGP format (hard rule — Q-012)

| Rule | Value |
|---|---|
| Currency | EGP only (EGP MVP) |
| Display format | `1,250.50 ج.م` — comma thousands separator, period decimal, 2-decimal precision always |
| Digit script | **Latin digits** (0–9) — never Arabic-Indic |
| Unit placement | `ج.م` at the **leading end** (right side in RTL) of the number, with a space: `1,250.50 ج.م` |
| Right of the amount = category tag / label, NOT the unit | the unit `ج.م` is on the right (start/leading); the category chip is to the left (end/trailing) in a list row |
| Precision | stored as `numeric(14,2)` — never silently rounded on display |
| Live formatting | input field shows commas as the user types (`1000` → `1,000`); decimals show trailing zeros (`1,250.50` not `1,250.5`) |

**Anti-patterns:** `١٬٢٥٠٫٥٠ ج.م` (Arabic-Indic); `EGP 1,250.50` (wrong unit placement); `1250.5 ج.م` (missing trailing zero); `1,250.50ج.م` (no space before unit); right-aligning the unit `ج.م` to the left (it's always at the leading/right end in RTL).

## 2. Amount display sizing

- **Hero amount** (Detail SCR-07, Review SCR-10): `type.headline` — large, bold, primary ink. The amount is the most prominent element on the detail.
- **Row amount** (Transactions list): `type.body-strong` — slightly larger than the row subtitle, same line as party name + category tag.
- **Summary amount** (Reports SCR-11): `type.title` — inside a summary card; total at the bottom uses `type.headline`.
- **Tabular alignment:** amounts in a list or column must share the same alignment (right-aligned in RTL; the decimal point and thousands comma are visually aligned column-wise). Use tabular-nums font variant.

**Anti-patterns:** mixing font sizes for amounts across list and detail; center-aligning amounts in a column; using proportional (non-tabular) numerals for a column of amounts.

## 3. Income / expense / neutral visual rule (G5)

| Type | Color rule |
|---|---|
| **Income** | `color.status.success` background chip (`#D5F5E3` light / `#1A3D2A` dark); `text-on-success` label; income **never** uses primary green — save that for confirm actions |
| **Expense** | `color.surface-variant` neutral background chip (warm-gray); `text-secondary` label; expense **never** uses red — that's an error |
| **Neutral / unknown** | same as expense (neutral surface) |

- The **amount text itself** stays `text-primary` (authoritative ink) for all types — only the *chip tag* carries the color, never the number.
- **Never color-only:** income/expense must always have the label chip ("دخل" / "مصروف") alongside the color — color-blind + screen-reader invariant (G5).
- Income green and success green are **different tokens**: `income-container` / `expense-container` are surface fills; the number itself is `text-primary`.

**Anti-patterns:** a red amount for expense; a green amount for income (income is not "success"); a list row where the only income/expense indicator is a background tint; using `color.primary` green as an income marker (primary is for confirm actions).

## 4. Date display

| Context | Format |
|---|---|
| Transaction list row | `"الأحد 13 سبتمبر 2026"` — Arabic weekday, day Latin digits, full Arabic month, 4-digit Latin year |
| Transaction detail | same + time: `"الأحد 13 سبتمبر 2026 — 3:45 م"` |
| Report date range | `"1–13 سبتمبر 2026"` |
| Export/PDF header | `"من 2026-09-01 إلى 2026-09-13"` — ISO for machine; user-facing text Arabic |
| AI-extracted date (Review) | shown as entered by AI in the same format as above; user can edit via native picker |

- **First day of week:** Saturday (Egyptian standard — `rtl-localization.md`).
- **Time format:** 12h + Arabic `ص/م` suffix; never 24h in user-facing UI.

## 5. Ledger list — chronological rule (BR-TRANS-001)

- Primary sort: **date DESC** (newest first).
- Secondary sort (same date): **time DESC** (latest first within the same day).
- Grouping: **by date** — a date header ("الأحد 13 سبتمبر 2026") appears above the first transaction of that day; subsequent same-day transactions share the header (no repeated header).
- Empty dates: if no transactions on a day, that day has no header (the user doesn't see empty day sections in a filtered list).

## 6. Transaction row anatomy (detail)

```
┌──────────────────────────────────────────────────────┐
│ [Icon/Avatar]  Party name (type.body)  Amount (EGP)  │
│              Category tag (chip)  Type chip (chip)    │
└──────────────────────────────────────────────────────┘
```

- **Icon/avatar:** receipt thumbnail (8dp radius rounded-rect, max 48×48); if no receipt → a muted icon by type (income/expense/neutral).
- **Party name:** `body`, right-aligned in RTL. If empty → "بدون اسم".
- **Amount:** `body-strong`, left column (end in RTL), right-aligned within its column for tabular alignment.
- **Category tag:** compact chip, `type.label`, `color.surface-variant` background (neutral ink). If AI-suggested category → indigo `color.ai-container` chip (see `ai-patterns.md`).
- **Type chip:** `收入`/`مصروف` in `income-container` / `expense-container` chip (never color-only).
- Row tap → Detail (SCR-07).

## 7. Transaction detail (SCR-07)

| Field | Display |
|---|---|
| Amount (hero) | `type.headline`, `text-primary`, large, right-aligned |
| Type | chip ("دخل" / "مصروف") |
| Date + time | `type.body`, Arabic format |
| Party | `type.body`, "بدون اسم" if empty |
| Category | tappable chip → opens category sheet (OVR-01) for edit |
| Note | `type.body`, "لا ملاحظات" if empty, italicized `text-secondary` |
| Receipt | thumbnail + tap to open full receipt viewer (SCR-17) |
| AI provenance | `type.caption`, `color.ai` ink — "تم الاستخراج الذكي — راجعه عند الحفظ" (only for AI-sourced records) |
| Manual provenance | `type.caption`, `text-secondary` — "إدخال يدوي" |
| Created/modified | `type.caption`, `text-secondary` |

## 8. Reports (SCR-11) — financial summary cards

- **Period row:** `type.body`, Arabic format ("1–13 سبتمبر 2026"). Q-011 period options.
- **Total income card:** `income-container` background; total amount `type.title` `text-primary`; label "الدخل الكلي".
- **Total expense card:** `expense-container` background; total amount `type.title` `text-primary`; label "المصروفات الكلية".
- **Net:** `type.headline` at the bottom; positive = `text-primary`; negative = `text-secondary` (no red for negative net — that's a business tone, not an error).
- **Category breakdown:** list of category chips with total per category; bar chart optional (not a heavy chart — a simple horizontal bar per category, max 8 bars).

## 9. Financial trust invariants (recap from `ux-states.md`)

1. **Never auto-save AI numbers.** Every AI-extracted amount goes through the Review form (SCR-10) → user confirm → Save.
2. **Never silently round.** Precision is 2 decimals; if a value is `1,250.500` (impossible with 2-decimal input), display it as-is — don't round to `1,250.50` without showing the full value.
3. **Amounts are always right-aligned** in RTL lists and detail for visual scanning.
4. **Confidence on amounts:** if AI confidence < 80%, the amount field gets OVR-08 advisory (see `ai-patterns.md`); the amount itself is still editable.
5. **Export respects filters:** Q-014 — the export matches the user's current filtered view (same date range, same categories).

## 10. Anti-pattern summary

| Anti-pattern | Why |
|---|---|
| Arabic-Indic digits for amounts | Backend mismatch; ambiguity for Arabic-readers accustomed to Latin financial format |
| Red amount for expense | Confuses error with financial type (G5, `color-system.md`) |
| Green amount for income | Confuses income with success/confirm action |
| A number without `ج.م` unit | User can't tell the currency (Q-012) |
| Centered amounts in a list | Breaks column scanning and tabular alignment |
| A "confirm" button that applies an AI amount directly | Violates NFR-DATA-001 (AI never auto-saves) |
| A date without time on a detail screen | User can't distinguish same-day transactions |
| Rounding `1,250.50` to `1,250` on a summary card | Violates 2-decimal precision contract |