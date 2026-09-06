# Accessibility — Hesably Design System

**Purpose:** mobile-first accessibility for a Flutter app used by small shop owners, many on low-end devices with screen glare. Covers contrast, touch, readability, screen-reader semantics, and copy — no heavy Web/ARIA semantics.
**Sources:** `ux/ux-strategy.md` (accessibility notes), `ux/interaction-model.md` §3, `ux/ux-states.md` (invariants), `color-system.md` (contrast), `typography.md`, `feedback-states.md`.

---

## 1. Color & contrast

| Rule | Target |
|---|---|
| Body text on background | ≥ **4.5:1** (WCAG AA) — guaranteed by color tokens: `text-primary` on `background` ≥ 7:1; `text-secondary` on background ≥ 4.5:1 |
| Large text / headings ≥ 24dp bold or ≥ 30dp | ≥ **3:1** (WCAG AA large) |
| Status chips (success/error/warning) on their container | ≥ **4.5:1** for the label; icon ≥ **3:1** against its container |
| Interactive border (focus ring, error ring) on background | ≥ **3:1** |
| Never rely on color alone | status = icon + label + text; income/expense ≠ color-only; validation = border + message (G5) |
| Dark mode: `background (#121914)` + `text-on-surface (#F2F2F2)` | ≈ 15.3:1 |
| Light mode: `background (#FAFAF8)` + `text-primary (#181B18)` | ≈ 14:1 |

**Contrast gate:** every new semantic color combination must pass at least AA before shipping. If unsure, choose the **higher-contrast** combination (`design-principles.md` §7).

**Anti-patterns:** red/green only for income/expense; status indicated only by background tint; a subtle difference between two border states that only a sighted user can distinguish.

## 2. Touch targets & spacing

| Target | Minimum size | Notes |
|---|---|---|
| Primary actions (Save, FAB, bottom nav items) | **48 × 48 dp** | Absolute minimum for fingers in motion |
| Secondary / tertiary (inline links, row actions) | **44 × 44 dp** | Minimum; wider tap area behind the visible element |
| Icon-only buttons | **48 × 48 dp** touch area | Icon rendered 24dp, padded to 48dp |
| Neighboring targets gap | **≥ 8 dp** | Prevents mis-taps on low-end touch panels |
| FAB clear zone | ≥ 24dp from bottom nav, ≥ 16dp from screen edges | Prevents mis-taps during capture flow |
| Switch row / radio row | 48dp height (tap to toggle, not just the thumb) | The entire row is the tap target |

**Anti-patterns:** a 24dp tappable icon with no padding; two tappable rows stacked with <8dp gap; a decorative illustration overlapping the FAB tap zone.

## 3. Readability

- **Body weight ≥ 500** for touch clarity and glare resistance; body text uses `type.body` (16/500) which already satisfies this.
- **Line height ≥ 1.5** for body text; ≥ 1.2 for headings.
- **Labels are always visible** — never placeholder-only (interaction-model §3): a field's purpose is readable before the user taps.
- **Letterspacing for Arabic:** always 0; never condensed (typography.md).
- **Latin letterspacing for labels:** `0.5–1px` tracking, uppercase — optional for English-only surfaces only.
- **Max 3 type sizes per screen** — keeps scanning predictable (typography.md).
- **No long body copy on mobile** — keep instructional copy ≤ 2 lines; move detail to a footnote (ux-strategy.md).
- **Glare resistance:** high-contrast text (`design-principles.md` §7) is specifically tuned for outdoor market use.

## 4. Screen reader semantics (TalkBack / VoiceOver)

- **Every icon-only button** has an accessibility label (`Semantics(label: "...")` in Flutter): `arrow_back` → "رجوع" / "Back"; `add` → "إضافة"; `settings` → "الإعدادات".
- **Icon + text pairs:** the parent is labeled once; the icon gets `excludeFromSemantics: true` to avoid double announcements.
- **Status chips:** labeled with full text (`Semantics(label: "في انتظار الاتصال" + "بانتظار المزامنة")`) — don't rely on color to communicate state.
- **Amounts:** announce as formatted numbers ("ألف ومئتان وخمسون جنيهًا وخمسون قرشًا" / "one thousand two hundred fifty pounds fifty piastres") — see `financial-ui.md`.
- **Form fields:** every field has a `Semantics(label: "المبلغ")` or equivalent; error messages are linked via `Semantics.liveRegion` so they're announced on appearance.
- **Dialogs:** the dialog title is the focus target; buttons are announced in reading order.
- **Empty states:** the empty-state heading is announced; the CTA button is focusable and labeled.
- **Navigation:** bottom nav items are announced with their label and selected state (`Semantics(selected: true)`).
- **Toast/snackbar:** announced via `Semantics.liveRegion` so screen readers catch transient confirmations.
- **Splash:** `excludeFromSemantics: true` on the full splash screen (it auto-navigates; announcement would confuse).
- **Confidence %:** announced as a number ("نسبة دقة 73 بالمئة") with the label, not just a bare number.

**Anti-patterns:** a decorative image with no alt text and no `excludeFromSemantics` (causes noise); an icon button with no label; an error message that appears visually but isn't announced; reading out a raw `color.primary` as "blue".

## 5. Copy rules (for accessible, plain language)

- **Plain Egyptian Arabic** — no jargon. "استخراج ذكي" not "تحليل صورة بالذكاء الاصطناعي".
- **Verbs first** in button labels: "إضافة", "حفظ", "احذف", not "حفظ المعاملة الجديدة".
- **Never use "click"** — say "اضغط" (tap) or rephrase: "أدخل المبلغ" (no "اضغط هنا").
- **A11y labels** are concise but descriptive: "رجوع" for back, "العودة إلى الشاشة الرئيسية" for Home selected.
- **Financial terms** in Arabic are familiar to the audience ("فاتورة", "معاملة", "分类") — don't invent English loanwords.
- **Latin digits** in amounts/phone/OTP — screen readers handle them correctly in Arabic context when they're inside bidi isolation.

## 6. Motor & dexterity

- **Single-hand reach:** the FAB and bottom nav are reachable from the bottom half of the screen (bottom nav is already at the bottom; FAB is bottom-start with 24dp clearance).
- **No long-press as the only path** — long-press may be used as an accelerator (e.g., scan receipt from the transaction list) but a primary path must always be a single tap.
- **No precise drag gestures** as the only interaction (e.g., reordering categories by drag — not in MVP; avoid if added later).
- **Swipe-to-dismiss** is only an accelerator for delete-confirm, never the only path.

## 7. Cognitive & low-literacy

- **Consistent affordances** across screens (Principle 7): a FAB is always the add-entry; a row-action is always a chevron or overflow.
- **No time pressure** except the explicit 15s AI ceiling (which has a manual escape, not a forced choice).
- **Confirming destructive actions** always states the consequence in plain language (OVR-04/05/06) — no "Are you sure?" without a concrete explanation.
- **Progress feedback** is always visible (inline progress or processing card) — never leave the user guessing.

## 8. Localization + RTL accessibility

- **RTL layout** is the default; a screen reader in Arabic reads right-to-left naturally — no extra ARIA/LRO marks needed.
- **Phone/OTP fields** are LTR inside bidi isolation — the screen reader reads the digits left-to-right, which is correct for phone numbers globally.
- **A language toggle** is accessible via the same Settings row pattern; the toggle announces its state.

---

## 9. Accessibility gate checklist

- [ ] Every interactive element has a minimum 48dp (primary) / 44dp (tertiary) touch target.
- [ ] Every icon-only button has a `Semantics` label.
- [ ] Status is never communicated by color alone.
- [ ] Error messages are announced on appearance (`Semantics.liveRegion`).
- [ ] Body text meets AA contrast (≥4.5:1); headings meet large-text AA (≥3:1).
- [ ] Amounts are announced correctly (formatted number + currency label).
- [ ] No placeholder-only labels on any form field.
- [ ] Destructive actions always state the consequence.
- [ ] Splash screen is excluded from semantics.
- [ ] Confident % is labeled and announced with context.