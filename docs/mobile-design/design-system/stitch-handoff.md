# Stitch Handoff — Hesably Design System

**Purpose:** guidance for generating Stitch high-fidelity screens from this design system. Stitch is used for **visual prototyping only** — no production code, no real auth, no real API. This document tells the Stitch generation agent exactly what tokens, components, and screen structure to use.
**Sources:** all design-system files (tokens, components, color, typography, spacing, iconography, AI patterns, offline patterns, financial UI, RTL/localization).

---

## 1. Stitch project structure

- **One Stitch project:** "Hesably — Smart Invoice Assistant".
- **Design system:** one Stitch design-system asset created from `tokens.md` + `design-principles.md` (Stitch will use this to keep screens consistent).
- **Screen generation order** (per brief §32 Stitch readiness):

| Priority | Screen | Stitch ID | Notes |
|---|---|---|---|
| 1 | SCR-01 Splash | splash | static; brand mark + loading |
| 2 | SCR-02 Phone Entry | phone-entry | RTL-first; one field |
| 3 | SCR-03 OTP | otp | 6 boxes; RTL scaffold; LTR digits |
| 4 | SCR-04 Business Setup | biz-setup | form; radio group; read-only currency |
| 5 | SCR-05 Home (empty) | home-empty | empty state + CTA; FAB |
| 6 | SCR-05 Home (loaded) | home-loaded | summary cards + recent list |
| 7 | SCR-05 Home (pending offline) | home-offline | pending banner + pending chip |
| 8 | SCR-06 Transactions (empty) | txn-empty | empty state |
| 9 | SCR-06 Transactions (loaded) | txn-loaded | filter chips + list |
| 10 | SCR-06 Transactions (filtered) | txn-filtered | filter chip active; empty result |
| 11 | SCR-07 Transaction Detail | txn-detail | all fields; AI provenance note |
| 12 | SCR-08 Transaction Type | txn-type | radio group; income/expense |
| 13 | SCR-09 Capture (AI processing) | capture-processing | processing card + manual escape |
| 14 | SCR-10 Review & Save | review-save | AI provenance chip; pre-filled fields; Save |
| 15 | SCR-11 Reports (empty) | reports-empty | empty state |
| 16 | SCR-11 Reports (loaded) | reports-loaded | summary cards + breakdown |
| 17 | SCR-12 Settings | settings | rows; language toggle; web access |
| 18 | SCR-13 Category Management | categories | list; add; rename |
| 19 | SCR-15 Category Add/Rename | category-form | form |
| 20 | SCR-16 Web Access (enabled) | web-access-enabled | link-sent success |
| 21 | SCR-17 Receipt Viewer | receipt-viewer | image + annotation |
| 22 | OVR-01 Category Picker | overlay-cat-picker | bottom sheet; AI suggestion badge |
| 23 | OVR-02 Export Options | overlay-export | format + period |
| 24 | OVR-03 Date Range Picker | overlay-date-range | native-style calendar |
| 25 | OVR-04 Delete Confirm | overlay-delete-confirm | destructive dialog |
| 26 | OVR-05 Account Delete | overlay-account-delete | typed-confirm dialog |
| 27 | OVR-06 Logout Confirm | overlay-logout | dialog |
| 28 | OVR-07 Unsaved Changes | overlay-unsaved | Keep editing / Discard |
| 29 | OVR-08 AI Low-Confidence | overlay-ai-advisory | inline advisory on field |

---

## 2. Stitch design system configuration

| Parameter | Value |
|---|---|
| Primary color | `#0A7A3D` |
| Body font | Cairo |
| Headline font | Cairo (weights: 600/700) |
| Roundness | `ROUND_FOUR` (radius 4–8dp range) |
| Color mode | `LIGHT` default; `DARK` variant |
| Custom color (primary) | `#0A7A3D` |
| Custom color (AI) | `#5B5BD6` |
| Custom color (offline) | `#4A5A6A` |
| Custom color (pending) | `#7A5A9E` |
| Custom color (syncing) | `#2F6BB0` |
| Spacing | 4dp base (design MD section in Stitch should include space tokens) |

---

## 3. Screen generation rules (for Stitch agent)

1. **RTL-first:** every screen is authored RTL; the Stitch generation prompt must specify `RTL layout`.
2. **Arabic copy:** all labels, buttons, empty states use Arabic text from `ux-states.md` / `screen-inventory.md` / `interaction-model.md`. No placeholder text.
3. **Latin digits for numbers:** all amounts, phone, OTP, confidence use Latin digits.
4. **Tokens from `tokens.md`:** reference token names in the Stitch prompt (e.g., "use `text-primary` for amounts"); Stitch will map to actual hex values via the design system.
5. **Component anatomy:** follow `components.md` and `forms-controls.md` for every element. Don't invent new components.
6. **Empty states:** every list/surface has an empty-state variant first (§20).
7. **AI processing:** SCR-09/10 must follow `ai-patterns.md` strictly; AI is a draft, not a confirmation.
8. **Offline:** SCR-05 home-offline follows `offline-patterns.md`; pending chip = violet `#7A5A9E`.
9. **Financial UI:** amounts follow `financial-ui.md` (EGP format, right-aligned, `text-primary` ink, type chip on the side).
10. **No code:** Stitch screens are visual prototypes. No logic, no state management, no real data.
11. **Device type:** mobile (phone form factor, 393×852dp viewport per iOS 15 Pro).
12. **Dark mode:** generate both light and dark variants for the most important screens (Home, Transactions, Review & Save, Settings, Detail).

---

## 4. Stitch prompt templates (examples)

**Splash (SCR-01):**
> Generate an RTL mobile splash screen (393×852). Centered: brand mark (a stylized receipt/document icon in primary green `#0A7A3D`), app name "حسّابي" in Cairo 700 36sp text-primary, tagline "مساعد الفواتير الذكي" in Cairo 400 16sp text-secondary. Background: off-white `#FAFAF8`. Bottom: loading indicator. No other elements.

**Home — Empty (SCR-05):**
> Generate an RTL mobile Home screen (393×852). Top: app bar with title "الرئيسية" right-aligned, notification icon at the left end. Body: empty state — muted receipt illustration (120dp), title "ابدأ بأول معاملة" in Cairo 20sp 600 text-primary, subtitle "التقط صورة فاتورة أو أدخلها يدويًا" in Cairo 16sp 500 text-secondary, below it two CTAs: a full-width button "إضافة فاتورة" in brand-primary `#0A7A3D` text-on-primary, and a text link "إدخال يدوي" in brand-primary. Bottom: navigation bar with 4 items (الرئيسية/home icon selected/primary, المعاملات/transactions icon, التقارير/reports icon, الإعدادات/settings icon) — nav items are label+icon, selected item is primary green. Bottom-left: FAB (56dp, brand-primary bg, white `add` icon). No data cards.

**Review & Save — AI-sourced (SCR-10):**
> Generate an RTL mobile Review & Save screen (393×852). Top: app bar "مراجعة وحفظ" with back arrow on the right. Below: provenance chip (ai-container bg `#E9E9FB`, auto_awesome icon in `#5B5BD6`, label "تم الاستخراج الذكي" in Cairo 12sp caption), supporting text "راجع البيانات ثم احفظ — لن يُحفظ شيء قبل تأكيدك" in text-secondary caption. Body (form): fields stack vertically with 20dp gaps — "المبلغ" (amount input, dashed AI marker on the field border, value "1,250.50 ج.م" in body-strong text-primary), "التاريخ" (date, dashed AI marker, value "الأحد 13 سبتمبر 2026"), "الفئة" (category chip in ai-container, "أخرى"), "المورّد/العميل" (text field, dashed AI marker, value "مزرعة النيل"), "ملاحظات" (text area, empty, "لا ملاحظات" placeholder). Each AI-marked field has a small `warning_amber` icon + caption "راجع المبلغ قبل الحفظ" below (low-confidence advisory). Bottom: full-width button "احفظ" in brand-primary text-on-primary, and secondary text link "إدخال يدوي" in brand-primary above it. Body bg: `#FAFAF8`.

---

## 5. What NOT to generate in Stitch

- No real camera capture (use a placeholder image).
- No real OTP verification (static screen).
- No real Supabase calls (all data is static/mock).
- No real AI processing (the processing card is static).
- No export/share sheet (use a placeholder sheet with format chips).
- No motion animations (Stitch is static screens; describe motion in annotations).
- No keyboard overlays (design the screen without keyboard; note keyboard presence in annotations).
- No tablet layout (phone only for MVP).

---

## 6. Stitch → Flutter readiness

After Stitch screens are generated, they serve as:
1. **Visual reference** for the Flutter developer (pixel-accurate layout + tokens).
2. **Component catalog** to validate that Flutter components match the design system.
3. **Review artifact** for stakeholders (approve before any Flutter code is written).

The Stitch screens do NOT replace Flutter code — they are a **design handoff artifact**. The Flutter developer implements each screen using the design-system tokens and component specs, referencing the Stitch screen as the visual source of truth.