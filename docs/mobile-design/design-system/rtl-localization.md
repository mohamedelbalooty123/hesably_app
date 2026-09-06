# RTL & Localization — Hesably Design System

**Purpose:** consistent right-to-left layout, bidirectional content handling, and Arabic-first localization rules — primary language Arabic (NFR-LANG-001, Q-019), English secondary only on explicit toggle (FR-SETTINGS-003).
**Sources:** `ux/interaction-model.md` §7, `ux/information-architecture.md`, `typography.md`, `color-system.md`, `iconography.md`, `requirements.md` (NFR-LANG-001), `feature-list.md` (settings language).

---

## 1. Layout direction (hard rule)

- **All surfaces are RTL by default.** Text aligns start = right; end = left; a flow of controls reads **right-to-left**: app bar title right-aligned, navigation trailing left, FAB bottom-left (start), back arrow on the right, forward/chevron points right.
- **No surface is LTR by default** — even screens that show mostly Latin content (phone entry OTP, email input) keep the overall scaffold RTL; the *field* may contain a left-aligned Latin string but the layout grid is RTL.
- **Anti-patterns:** centering all text (Arabic is start-aligned right); forcing a 50% mirror as a "fix" after building LTR (one-way correct: design RTL-first).

## 2. Mirror behavior — icon mirroring

Per `iconography.md` §2:

| Mirror in RTL | Don't mirror |
|---|---|
| `arrow_back`, `chevron_right`, `arrow_forward` | `search`, `menu`, `settings`, `add`, `check_circle`, `info`, `warning`, `error` |
| `sync` (mirror if showing direction) | `cloud_off`, `filter_list`, `visibility` |
| `open_in_new`/`logout` | `share` (symmetric), `attach_file` (symmetric) |
| `edit` (mirror if pen direction is directional) | `camera_alt` (symmetric) |

**Rule:** any icon that has an intrinsic horizontal direction (arrow, chevron, jump-to) must be mirrored via `matchTextDirection` in Flutter / `dir="auto"` in SVG markup. A symmetric icon is left as-is.

**Anti-patterns:** mirroring a chevron but not its container; a mirrored icon that now points the wrong direction for a RTL reader (the chevron-right → points left in RTL = correct for "next").

## 3. Bidi isolation (text that mixes scripts)

Use **Unicode bidi isolation** (or RTL framework attribute) whenever a mixed-language string appears:

- **Arabic text containing Latin/numbers:** `"1,250.50 ج.م"` → wrap the number in a `bidi-isolate` span so the number runs LTR (`1,250.50`) and the Arabic suffix runs RTL, without the number visually breaking the surrounding text.
- **OTP code:** six Latin digits in six boxes — each box is LTR; the overall OTP row is LTR; the surrounding prompt is RTL. Frame this in an LTR context (otp row dir=ltr) inside the RTL screen.
- **Confidence `%`:** Latin digits (`73%`) inside bidi isolation so it doesn't flip the surrounding Arabic.
- **Date/time:** Arabic month/day names are RTL; Latin day/week abbreviations are bidi-isolated.

**Anti-patterns:** a bare `1,250 ج.م` without bidi isolation causing the "ج.م" to float; rendering `٧٣%` (Arabic-Indic) instead of `73%`; a phone number formatted with spaces as if Arabic reading order.

## 4. Content alignment

| Scenario | Alignment |
|---|---|
| Arabic body text | right-aligned |
| Amount (EGP) | start-aligned (right) with `ج.م` at the leading end (right side of the number) — never a trailing unit (Q-012) |
| Date (Arabic) | right-aligned ("الأحد 13 سبتمبر 2026") |
| Date (Latin/ISO) | left-aligned inside bidi isolation ("2026-09-13") |
| Phone number | LTR inside bidi isolation (the digits themselves are LTR) |
| Single-word label | right-aligned |
| Subtitle/secondary text | same alignment as parent |

**Rule:** a number's alignment (Latin digits, always LTR) is determined by its bidi isolation, not by the surrounding layout direction.

## 5. Localization architecture (two-language MVP)

- **MVP:** Arabic primary; English secondary available via **toggle** (FR-SETTINGS-003) that changes the display language. RTL is *never* disabled; switching to English keeps the Arabic scaffold but replaces Arabic copy with English. (This is the design constraint: the scaffold is always RTL.)
- **Localization files:** one `.arb` per language; all user-facing copy goes through `AppLocalizations`. No hardcoded strings. A string key is always accessed via `AppLocalizations.of(context).stringKey`.
- **Fallback:** if an English translation is missing → fall back to Arabic (primary); never show a blank string.
- **Anti-patterns:** hardcoding `"إدخال يدوي"` inside a widget instead of using `l10n.enterManually`; locale-dependent format inside the tree; using the English UI as the default.

## 6. Time/date conventions

| Item | Format |
|---|---|
| Display date (Arabic) | `"الأحد 13 سبتمبر 2026"` — weekday Arabic, day Arabic-Indic? No: **Latin digits for day**, full month name Arabic, year 4-digit Latin. No Arabic-Indic digits in financial app. |
| Display date (English) | `"Sun, Sep 13, 2026"` or `"2026-09-13"` per locale |
| Time display | 12h format + "ص/م" Arabic suffix (e.g., "3:45 م"); no military time |
| Timestamp in logs/export | ISO 8601 (`2026-09-13T15:45:00Z`) — backend always; never shown raw to user without conversion |
| First day of week | Saturday (Egyptian standard) |

**Anti-patterns:** "١٣/٩/٢٠٢٦" (Arabic-Indic) for dates; 24h display in user-facing UI; Sunday as first day of week.

## 7. Number conventions

- **All user-facing numeric values: Latin digits** (Q-012). Arabic-Indic (`٠١٢٣٤٥٦٧٨٩`) are never used.
- **Thousands separator:** comma `,`; decimal point: period `.`; fixed 2-decimal precision for amounts.
- **Currency:** `ج.م` after the amount with a space: `1,250.50 ج.م`.
- **Confidence:** `73%` in Latin digits, LTR, inside bidi isolation.
- **Phone:** `01012345678` — no spaces, no formatting, LTR digits inside bidi isolation.
- **OTP:** six separate boxes, each LTR.

**Anti-patterns:** using `٢٥٠٫٥٠` (Arabic-Indic) in any financial context; formatting a phone number as `010 123 4567` with spaces (storage format is raw digits).

## 8. Navigation mirrors

Per `navigation-map.md` (live):

- **Bottom nav** (RTL): Home (home icon) at the right, Settings (gear) at the left.
- **Back button:** on the right (RTL) — `arrow_back_ios` icon (mirrored).
- **Forward chevron:** points right in RTL (navigating deeper into the content).
- **FAB:** bottom-left corner (start in RTL); the "add" icon inside the FAB is directionless (`add` is symmetric).

**Anti-patterns:** putting the FAB on the right (that's the forward/end position — the primary confirm is at start/bottom-left per G6); forgetting to mirror `arrow_back`.

## 9. Empty/loading layout under RTL

- Skeleton placeholders match the text alignment: a skeleton for a right-aligned title is right-aligned.
- Empty state illustration is always **centered** (center is language-neutral).
- A CTA button is full-width (no alignment bias) or start-aligned (right in RTL).

## 10. English secondary language notes

- English within an Arabic UI: **LTR fields** (phone, OTP, email) remain LTR even while the surrounding labels are RTL — this is bidi isolation, not a locale switch.
- When the user toggles to English: the scaffold remains RTL but **all Arabic copy becomes English** and the text direction of body content flips to LTR. The bottom nav remains RTL-ordered (it's still an Arabic product with English interface — or, if design decides, the nav reorders to LTR; note this as a design decision pending final spec).
- **Anti-patterns:** a half-English half-Arabic screen with mismatched alignments; right-aligning an English paragraph.

---

## 11. RTL design gate checklist

- [ ] Every screen is authored RTL-first; no center-aligned-only layouts.
- [ ] Directional icons mirror in RTL.
- [ ] All mixed-language strings (numbers, %, Latin words in Arabic) use bidi isolation.
- [ ] Amounts use Latin digits with `ج.م` at the right; no Arabic-Indic in financial context.
- [ ] Dates follow Egyptian locale (Saturday first, 12h, Arabic month names).
- [ ] No hardcoded strings; all copy goes through `AppLocalizations`.
- [ ] An English toggle changes the display language while keeping the Arabic scaffold.
- [ ] Empty skeletons and empty states align right (start) in RTL.
- [ ] OTP and phone fields are LTR inside an RTL scaffold via bidi isolation.