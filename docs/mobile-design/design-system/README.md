# Hesably Design System

**Project:** Hesably — Smart Invoice Assistant (Flutter mobile · Supabase · Gemini Vision API)
**Audience:** designers, Flutter developers, Stitch agents, reviewers
**Language:** Arabic-first; English secondary only via user toggle

---

## 1. Purpose

This design system defines the **visual, interaction, and behavioral language** for Hesably's mobile app — consistent across every screen, every state, every user. It is the single source of truth for how the app looks, behaves, and earns trust.

**Key invariants this system enforces:**

- AI is assistive, never authoritative (NFR-DATA-001)
- Arabic-first RTL throughout (NFR-LANG-001, Q-019)
- Low-end Android friendly — no heavy animation (NFR-LOWDEV-001)
- Income/expense never color-only (G5)
- AI never auto-saves — every extraction goes through user confirm (Q-008, BR-CONFIRM-001)
- Every offline capture has a visible pending queue with retry (Q-018 flipped, CI-OFFLINE-001)
- Every surface has an action in its empty state (state invariant #2)

---

## 2. File map

| File | What it defines |
|---|---|
| `design-principles.md` | 13 practical principles; the decision filter for all other files |
| `color-system.md` | Semantic color tokens: light/dark, status, income/expense, AI, offline/sync/pending |
| `typography.md` | Cairo font, type scale, numeric treatment, hierarchy rules |
| `spacing-layout.md` | 4dp spacing scale, screen margins, layout rules, RTL-aware layout |
| `iconography.md` | Material Symbols Outlined vocabulary, RTL mirroring, reserved glyphs |
| `components.md` | Canonical component inventory: navigation, actions, data display, feedback, capture, overlays |
| `forms-controls.md` | Form inputs, field states, financial input rules, form-level behavior |
| `feedback-states.md` | Unified status language, feedback mechanisms, empty states, loading system |
| `ai-patterns.md` | AI visual language: processing, extraction result, confidence, provenance |
| `offline-patterns.md` | Offline capture, pending queue, deferred sync, online-only surfaces |
| `rtl-localization.md` | RTL layout, bidi isolation, Arabic-first localization, date/number conventions |
| `accessibility.md` | Touch targets, contrast, screen reader semantics, copy rules |
| `motion.md` | Minimal motion: transitions, haptics, skeletons, progress — low-end safe |
| `financial-ui.md` | EGP format, amount display, income/expense visual rule, ledger chronology |
| `tokens.md` | **Single-source-of-truth** for all design tokens (color, type, space, radius, border, icon, control, opacity, motion, breakpoint) |
| `stitch-handoff.md` | Stitch generation rules, screen order, design system config, prompt templates |
| `flutter-handoff.md` | Flutter conceptual mapping: theme, components, RTL, state patterns, low-end constraints |

---

## 3. How to use this system

1. **Start with `design-principles.md`** — every design decision must pass the 13 principles.
2. **Consult `tokens.md`** before using any value — never invent a token outside this file.
3. **Follow the component doc** (`components.md` + `forms-controls.md` + `ai-patterns.md` + `offline-patterns.md` + `financial-ui.md`) for the specific surface you're building.
4. **Check `rtl-localization.md`** for any mixed-content or alignment question.
5. **Check `feedback-states.md`** for any loading/error/empty/success state.
6. **Check `accessibility.md`** before shipping any interactive element.
7. **Check `motion.md`** before adding any animation or transition.

---

## 4. Design gate checklist (pre-ship)

Use this checklist before any screen ships to Stitch or Flutter:

- [ ] Passes all 13 design principles (design-principles.md)
- [ ] All tokens from `tokens.md` — no magic values
- [ ] RTL-first layout; directional icons mirrored; bidi isolation on mixed content
- [ ] Arabic-first labels; Latin digits for numbers/phone/OTP
- [ ] Touch targets ≥48dp primary / 44dp tertiary; gaps ≥8dp
- [ ] Status never color-only (icon + label + text)
- [ ] Income/expense chips carry labels, not just color
- [ ] AI elements use `color.ai`/`ai-container`; confirmed data uses normal ink
- [ ] AI processing ≤15s ceiling + manual escape always visible
- [ ] Offline pending queue visible with retry; no false sync claims
- [ ] Empty states carry an action
- [ ] Errors have retry; no dead ends (G3)
- [ ] Destructive actions two-step with consequence (G7)
- [ ] Amounts: `1,250.50 ج.م` format, Latin digits, right-aligned, tabular
- [ ] No placeholder-only labels
- [ ] Skeletons pulse slow (1.2s), no shimmer
- [ ] No full-screen indeterminate spinner
- [ ] All user-facing strings via `AppLocalizations`
- [ ] Accessibility labels on all icon-only buttons
- [ ] Error messages announced to screen readers

---

## 5. Traceability index

Design decisions in this system trace back to approved requirements and UX architecture documents. Key traceability IDs referenced across the design system:

### 5.1 Non-functional requirements

| ID | Requirement | Design-system file(s) |
|---|---|---|
| NFR-LANG-001 | Primary UI language Arabic, RTL throughout | `rtl-localization.md`, `typography.md`, all files |
| NFR-PERF-001 | AI extraction ≤15s; no frozen screen | `ai-patterns.md`, `motion.md` |
| NFR-LOWDEV-001 | Low-end Android; no heavy animation | `motion.md`, `flutter-handoff.md`, `spacing-layout.md` |
| NFR-DATA-001 | AI never auto-saves extracted data | `ai-patterns.md`, `financial-ui.md`, `components.md` |

### 5.2 Product decisions (Q-IDs)

| ID | Decision | Design-system file(s) |
|---|---|---|
| Q-001 | Phone + OTP auth only | `forms-controls.md` (OTP §7), `rtl-localization.md` (§7) |
| Q-008 | Review & Save mandatory before persistence | `ai-patterns.md` (§3), `components.md` (SCR-10) |
| Q-011 | Report period options (This Week / This Month / Last Month / Year-to-Date / Custom Range) | `components.md` (segmented), `financial-ui.md` |
| Q-012 | EGP `1,250.50 ج.م` format; Latin digits | `financial-ui.md`, `tokens.md`, `typography.md` |
| Q-014 | Export respects current filters | `financial-ui.md` (§9), `components.md` (OVR-02) |
| Q-018 | Offline capture IN MVP (flipped) | `offline-patterns.md`, `ai-patterns.md` (§8) |
| Q-019 | Arabic-first RTL | `rtl-localization.md`, all files |
| Q-020 | Image quality gates (pass/retry/reject) | `ai-patterns.md` (§2), `feedback-states.md` |
| Q-022 | Party search = party name, not trans id | `forms-controls.md` (§4), `components.md` (search) |

### 5.3 Global requirements (G-IDs)

| ID | Rule | Design-system file(s) |
|---|---|---|
| G3 | No dead ends — every surface has a next action | `feedback-states.md` (§8), `ai-patterns.md` (§2), `offline-patterns.md` (§4) |
| G5 | Never color-only | `accessibility.md` (§1), `color-system.md`, `financial-ui.md` (§3) |
| G6 | Primary confirm at bottom-start (RTL = bottom-left) | `components.md` (FAB), `spacing-layout.md` (§8) |
| G7 | Destructive = two-step + destructive color + stated consequence | `feedback-states.md` (§6), `components.md` (dialogs) |

### 5.4 Business rules (BR-IDs)

| ID | Rule | Design-system file(s) |
|---|---|---|
| BR-CONFIRM-001 | AI data never saved without user confirm | `ai-patterns.md` (§§1,3) |
| BR-OFFLINE-001–008 | Offline capture rules (pending never auto-confirmed, etc.) | `offline-patterns.md` (§§4,5) |
| BR-TRANS-001 | Transactions sorted by date DESC, time DESC | `financial-ui.md` (§5) |

### 5.5 Screens and overlays (SCR / OVR)

All screen IDs (SCR-01 through SCR-17) and overlay IDs (OVR-01 through OVR-08) are referenced in `components.md` (§§4–32) and in `stitch-handoff.md` (§3 screen table).

### 5.6 Offline-specific (FR-OFFLINE / AC-OFFLINE / CI-OFFLINE)

All offline requirements (FR-OFFLINE-001–008), acceptance criteria (AC-OFFLINE-001–007), and consistency invariant (CI-OFFLINE-001) are covered in `offline-patterns.md` and `ai-patterns.md` (§8).

---

## 6. Status

**DESIGN SYSTEM STATUS:** APPROVED (all 17 files complete; quality gate passed)

**Stitch readiness:** READY WITH BRAND APPROVAL PENDING — `stitch-handoff.md` provides screen order, token config, and prompt templates. Brand values (`#0A7A3D`, Cairo) are confirmed as the design baseline for prototyping; formal brand approval is pending. All values are internally consistent for Stitch consumption.

**Flutter readiness:** READY — `flutter-handoff.md` provides theme setup, component mapping, RTL handling, and low-end constraints.