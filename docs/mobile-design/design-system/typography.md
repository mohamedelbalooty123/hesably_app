# Typography System — Hesably Design System

**Purpose:** Arabic-first typography hierarchy for a mobile financial app. Defines font family, sizes, weights, line heights, letter spacing, and numeric handling — optimized for Arabic readability, EGP amounts, dates, confidence percentages, and receipt-extraction fields. Secondary English support stays in lockstep (NFR-LANG-001, FR-SETTINGS-004).
**Sources:** `ux/information-architecture.md` (labeling), `ux/interaction-model.md` §3 (formats, bold money), `ux/ux-strategy.md` (persona, plain language).

---

## 1. Font family

**Primary (Arabic + Latin):** **Cairo** (Google Fonts; Supports Arabic and Latin, geometric sans, weights 200–900, legible at small sizes on mobile, free, offline-bundleable).

**Fallback stack (bundled first, then system):**
`Cairo` → `Noto Sans Arabic` (system Android Arabic default) → `system-ui`/sans-serif.

Notes:
- **Bundle Cairo in the app** (a single .ttf with the needed weights, ~200–400KB) so low-end devices don't fetch webfonts at runtime (NFR-LOWDEV-001).
- If Cairo is unavailable, the system Arabic font must be an acceptable render; the design never depends on unavailable weights being synthesized at runtime (avoid `FontWeight.w700` fake on a 400-only bundle).
- **Latin**: Cairo covers Latin numerals and Latin script adequately for embedded strings like `J.م`, brand name, and English-secondary mode. For English-heavy number columns, tabular figures preferred.

> DESIGN INFERENCE (confirmed as design baseline for prototyping; formal brand approval pending): Cairo is the recommended family because it (a) ships Arabic + Latin in one family (avoids font-switching mid-string), (b) is designed for UI, (c) is freely bundled. No requirement mandates a specific font; this is an inference, overridable by a brand decision.

---

## 2. Type scale (mobile, dp)

Base unit: `sp`-relative; these token names are used in `tokens.md`. Line heights are multiples (Arabic needs vertical room).

| Token | Usage | Size | Weight | Line | Letter-spacing |
|---|---|---|---|---|---|
| `type.display` | Hero number — Home Net, big totals, "no transactions" headline | 36 | **700** | 1.2 | 0 |
| `type.headline` | Screen titles, empty-state leader | 24 | **700** | 1.3 | 0 |
| `type.title` | Card titles, section headers, dashboard KPI title | 18 | **600** | 1.4 | 0 |
| `type.body` | Body text, list content, inputs | 16 | 400 | 1.6 | 0 |
| `type.body-strong` | Emphasis within body (amounts, names) | 16 | **600** | 1.6 | 0 |
| `type.label` | Field labels, buttons, tabs, badges, filter chips | 14 | 500 | 1.4 | 0.01em (Latin only) |
| `type.caption` | Supporting text, meta, date ranges, AI notes | 12 | 400 | 1.4 | 0 |

**Rules:**
- **Arabic letter-spacing stays 0.** Positive tracking breaks Arabic script joins. Never add tracking to Arabic strings.
- Line height for Arabic body ≥ 1.5 (calligraphic ascenders/descenders overhang). Body/headline above follows 1.6/1.3.
- Max 3 distinct sizes on one screen (display/headline/body, or headline/body/label) — hierarchy, not clutter (Principle 6).

---

## 3. Numeric / financial treatment

| Element | Rule |
|---|---|
| **Large totals (Home, Reports)** | `type.display` bold; `text-primary`; right-aligned in RTL (start-aligned). Use **tabular/fixed-width digits** where the font supports them for stable reading of columns. |
| **Bold money** | Money figures on read surfaces are `body-strong` or heavier; never lighter than surrounding text (interaction-model §3 "amounts bold on read surfaces"). |
| **EGP formatting** | Always `1,250.50 ج.م` (Q-012). No bare numbers. Decimal separator `.`, thousands `,`. No silently rounded amounts. |
| **Amount input** | Arabic-input keyboard with **Latin digits** (`0123456789`) for amounts/phone (interaction-model §7, Q-012). Show live-formatted value `1,250.50` as the user types. |
| **Negative/currency** | `-1,200.00 ج.م` for negative; sign adjacent to the amount, inside the bidi isolation (see `rtl-localization.md`). |
| **Phone** | `+20 1 2345 6789` (Latin digits, LTR inside RTL). |
| **Dates** | Locale-driven display: Arabic `١٤/٠٩/٢٠٢٦` from backend `DATE` → display as e.g. `الخميس, ٥ سبتمبر ٢٠٢٦` per `intl` Arabic locale. Numeric dates keep Latin-digit `2026-09-05` where a compact form is needed. |
| **Confidence %** | Numerals read LTR: `73%` is rendered in Latin digits with a percent sign placed after (standard, inside bidi isolation). |

---

## 4. Special-purpose type

| Context | Treatment |
|---|---|
| Low-confidence flag (OVR-08) | `type.caption`/`body-strong` advisory in warning color with a flag icon; never distracts from the field's value (see `ai-patterns.md`). |
| AI suggestion badge | `type.caption` chip; distinct from confirmed labels (indigo `color.ai` container). |
| Pending/offline states | `type.body` message + `type.caption` supporting text; status chip readable at caption size, tappable at full 48dp where it's a control. |
| Sync percentage/progress | Numeric inline at `type.caption`/body in the row, left of a progress bar (see `offline-patterns.md`). |

---

## 5. Hierarchy rules

1. **One hero number per read surface.** Home shows Net as hero; Reports shows current-period Net as hero; a list row's amount is the row's strong text — never two competing large figures.
2. Labels are smaller/lighter than their values (label → value → unit order). A caption labels a body value; a body labels a numeric display.
3. Buttons and tabs use `type.label` (14, 500) — not body — for compactness.
4. Truncation: long Arabic labels truncate with ellipsis `…`; keep the full value reachable (long-press/tooltip) where it's a core identity (vendor names) — see `rtl-localization.md`.

---

## 6. English-secondary (when language toggle = English)

- Same type scale and weights; letter-spacing returns to normal Latin tracking (0.01em on labels/caps).
- Numeric/currency/date rules are identical (EGP `1,250.50 EGP`, Latin digits).
- The hierarchy does not change; only the character set and direction do.

---

## 7. Low-spec performance

- **Preload** the type scale at startup via theme; no runtime font download.
- **No animated text/letter-spacing** transitions (NFR-LOWDEV-001).
- Font subsetting: bundle only Arabic + Latin glyphs.
- Keep to ≤ 3 weights in the actual bundle (e.g., 400/500/700) to bound memory; use weight-tracking rules to fake emphasis elsewhere (never at rest).

---

## 8. Anti-patterns

| Anti-pattern | Why |
|---|---|
| Pairing a display serif per screen | Adds a second visual voice; decorative (Principle 1) |
| Letter-spacing on Arabic | Broken joins; illegible |
| Arabic-Indic digits (٠١٢٣) for amounts | Mismatch with backend `numeric(14,2)` (Q-012) |
| Light-weight money (300/400 grey) | Unreadable at a glance; weak hierarchy |
| A hi-lo italic for Arabic | Arabic has no italic; avoid fake oblique |
| Synthesized weights not in bundle | Faux-bold/faux-light artifacts on low-spec rendering |

---

## 9. Fonts source

- **Cairo**: Google Fonts / GitHub (free, open source). Weights bundled: 400 (Regular), 500 (Medium), 700 (Bold). Optional 600 (SemiBold) if budget allows.
- Fallback: system `Noto Sans Arabic` on Android ≥ 5 Lollipop default.
- Web dashboard (Next.js): include Cairo via self-hosted `next/font` to avoid FOIT and match mobile metrics.