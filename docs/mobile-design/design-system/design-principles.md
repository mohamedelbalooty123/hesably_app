# Design Principles — Hesably Design System

**Phase:** Design System (foundation before high-fidelity visual execution)
**Scope:** Flutter mobile app (MVP) + readiness for the web dashboard companion.
**Sources:** `feature-list.md`, `user-flow-mobile.md`, `user-flow-dashboard.md`, `mobile-design/ux/*`, `mobile-design/review/ux-discovery-review.md`, `change-management/offline-mvp-change-impact.md`.

These principles are the **decision filter** for every component, token, and pattern in this system. If a design choice conflicts with a principle, the principle wins unless a higher-priority principle or a hard product requirement/constraint overrides it.

---

## Principle 1: Clarity over decoration

**What it means in Hesably.** The app records business money for an owner who may not be numerically sophisticated. Every screen should make "what am I looking at, what should I do next, what happened" ambiguous-free. Visual decoration (shadows, gradients, illustration, brand slants) is only justified when it improves recognition of a *state* or *action* — never for fashion.

**Where it matters.**
- Financial figures: the largest text on the page is always a number, not a label.
- Save/delete/retry actions: unambiguous color + label (never icon-only destructive actions).
- Loading/empty/error/offline states: the message is the medium, clear copy beats a pretty illustration.

**What to avoid.**
- Decorative gradients behind monetary totals.
- Illustrated empty states that compete with the single CTA.
- Shadows/elevation on every card.
- Micro-brand flourishes inside data-dense screens.

**Traceability:** NFR-LANG-001 (plain Arabic for non-technical user), UX persona (low technical confidence → no jargon).

---

## Principle 2: Speed over complexity

**What it means in Hesably.** The core loop — *snap, review, save* — must feel instant. Any extra tap, field, or animation is friction against a shop owner mid-transaction. The app optimizes for input latency on low/mid-spec Android.

**Where it matters.**
- Add flow is one FAB tap away (G2) and requires only one deliberate field (the type choice).
- Skeletons over spinners on scrollable content (interaction-model §2).
- Debounced search (350ms), compressed images at capture (interaction-model §9).
- No heavy animations — micro-motion for feedback only.

**What to avoid.**
- Multi-step wizards that aren't required by the approved flow.
- Decorative page transitions.
- Asking the user to confirm things they can't get wrong.

**Traceability:** G2, NFR-PERF-001, NFR-LOWDEV-001, interaction-model §2/§9.

---

## Principle 3: Trust over automation

**What it means in Hesably.** The product's core value is *dependable books*. Users must trust that what the app shows is what actually happened. Where the app is uncertain, it says so clearly and hands control back to the owner. Nothing financial becomes "real" without a human in the loop.

**Where it matters.**
- AI extraction is **never** silently persisted — it always routes through a visible Review step before Save (NFR-DATA-001, BR-CONFIRM-001).
- Low-confidence AI fields (<80%) are visibly flagged with an advisory (OVR-08).
- Destructive actions always require confirmation with stated consequences (G7).

**What to avoid.**
- Auto-saving "suggestions."
- Presenting AI output as if it were verified fact.
- Hiding a delete/account-loss behind a single tap.

---

## Principle 4: Human confirmation over AI assumptions

**What it means in Hesably.** AI is an assistant that drafts; the owner issues the final word. This is a **trust invariant**, not a preference: AI-generated data may exist as a *draft* but never as a *record* without the user's own confirm action.

**Where it matters.**
- Review & Save (SCR-10) is the single form for AI prefill, manual entry, and edit — one form, three sources.
- The "Save" action is the only thing that persists; there is no auto-save anywhere.
- AI's category suggestion is a badge in the picker, not a locked selection.
- Offline pending captures route through the same online review — offline never confirms AI (FR-OFFLINE-008, BR-OFFLINE-004).

**What to avoid.**
- Any visual treatment that implies an AI-drafted field is "confirmed."
- Auto-submitting an AI result after a timer.
- A separate "AI mode" that bypasses the shared review form.

---

## Principle 5: Progressive disclosure

**What it means in Hesably.** Depth ≤ 2 levels from any tab. Core tasks (record, see this month, find a past entry) are on the surface; detail (line items, AI provenance, data sources) is revealed only when the user asks.

**Where it matters.**
- List rows show thumbnail, party, category, amount, date — not the full story.
- Detail (SCR-07) is read-only; Edit is an explicit action.
- Line items and AI provenance are supporting detail, revealed under the record.

**What to avoid.**
- Cramming every field of a transaction onto a list row.
- Exposing "ai_extraction" or sync internals as user-facing surface.
- Settings sub-pages deeper than one push.

---

## Principle 6: Strong visual hierarchy

**What it means in Hesably.** On every screen, one element is visually dominant and that element answers the user's question (usually a number, a CTA, or a state). Sizes, weights, and color treatment create a clear reading path.

**Where it matters.**
- Home dashboard: the current-month Net figure is the hero number.
- Amounts are bold on read surfaces; labels are secondary (interaction-model §3).
- Primary CTA is the most prominent action on the screen; destructive actions rank below it.

**What to avoid.**
- Two equally-weighted CTAs.
- Numbers rendered at the same size as their captions.
- A screen where a border/badge competes with the data.

---

## Principle 7: Consistent feedback

**What it means in Hesably.** The same state must look and behave the same everywhere. Success is always a success treatment; a failure always has a retry; loading is always skeleton or labeled inline progress. Users learn the language once.

**Where it matters.**
- One success toast treatment, one error treatment, one offline banner treatment.
- In-flight buttons are always disabled + labeled ("جارٍ الحفظ…"), never double-submit.
- Every failure resolves to retry or manual (G3 — no dead ends).

**What to avoid.**
- A snackbar on one screen and a dialog on another for the same outcome.
- Silent failures anywhere.

---

## Principle 8: Accessible touch targets

**What it means in Hesably.** Primary actions are ≥ 48×48dp; inline/tertiary may drop to 44dp but never below; interactive neighbors are ≥ 8dp apart (interaction-model §1). Critical actions live in the bottom half of the screen for one-handed reach.

**Where it matters.**
- FAB, bottom nav, Save/Confirm, back — all ≥ 48dp and reachable by the thumb.
- Confirmation dialogs put the primary action in thumb zone.

**What to avoid.**
- Small icon-only actions with no label and no expanded hit area.
- Stacked controls closer than 8dp.

---

## Principle 9: Arabic readability

**What it means in Hesably.** Arabic is the primary language (NFR-LANG-001). All copy is authored Arabic-first, RTL is the default layout direction, and typography is chosen for Arabic legibility (script joins, vertical proportions, generous x-height). Numbers/dates/phone keep LTR numeric order with bidi isolation (interaction-model §7).

**Where it matters.**
- Font family selection supports Arabic properly (see `typography.md`).
- Every screen lays out right-to-left; direction icons mirror.
- Mixed Arabic/English labels stay legible via bidi isolation.

**What to avoid.**
- An LTR-first design "flipped" at the end.
- Fonts without Arabic script support.
- Numerals rendered as Arabic-Indic digits (backend expects Latin digits — Q-012).

---

## Principle 10: Low cognitive load

**What it means in Hesably.** The user is a shop owner, not an accountant. Jargon is banned ("syncing", "extraction", "confidence" are replaced with plain words or hidden behind states). One mental model: everything is a transaction (income/expense, amount, category).

**Where it matters.**
- Copy uses "التقط صورة", "راجع البيانات", "احفظ" — plain verbs (ux-strategy §4).
- Emojis are avoided in UI; iconography stays familiar.
- Pickers show the same category list everywhere (one source of truth).

**What to avoid.**
- Technical terms in user-facing copy.
- Introducing a new concept (e.g., "pending capture") without a plain-language anchor.

---

## Principle 11: Graceful offline behavior

**What it means in Hesably.** Offline is a first-class, supported state, never a crash. Capture works offline as a device-local pending capture (Q-018 flipped, ADR-007); the pending list is the honest surface showing "waiting for connection" with sync/retry. Data already loaded remains visible (cached, read-only) with a clear "you're offline" banner — never implying cloud sync.

**Where it matters.**
- Capture screen offline → local pending capture, no error (BR-OFFLINE-001).
- Pending list distinguishes local vs synced vs waiting (BR-OFFLINE-003).
- Offline banner on cached Home/Transactions says data is saved locally, not that it reached the server (FR-OFFLINE-009).

**What to avoid.**
- Claiming a local capture is "saved to the server."
- Hiding the pending queue.
- Offering offline export/analytics/cross-device (BR-OFFLINE-008).

---

## Principle 12: AI is assistive, not authoritative (derived)

**What it means in Hesably.** AI surfaces read as helpful drafts: neutral tokens, advisory flags, and a human path always visible. The visual system never implies AI output is pre-trusted. (Detailed in `ai-patterns.md`.)

**Where it matters.**
- AI processing view (15s ceiling + manual escape).
- Low-confidence field flags (OVR-08).
- AI-category suggestion badge.

**What to avoid.**
- A "robot-is-in-charge" visual metaphor.
- Confidence percentage styling that resembles confirmed financial data.

---

## Principle 13: Financial information is unambiguous (derived from Q-012)

**What it means in Hesably.** Money is always `1,250.50 ج.م` — a unified format, never a bare number, never a conflicting currency (Q-012). Amounts never silently round; negative values and income/expense colors are always explicitly labeled. (Detailed in `financial-ui.md`.)

**Where it matters.**
- Amount inputs, summary cards, list rows, report figures, export output.
- Date/period labels.

**What to avoid.**
- Two formatting styles of EGP.
- Color-only indication of income vs expense without a label/icon.
- Silent decimal rounding.

---

## Priority order (when principles conflict)

1. **Trust invariants** — Human confirmation over automation (P4), financial unambiguity (P13), graceful offline honesty (P11). These are absolute.
2. **Product requirements / UX architecture** — anything that changes approved IA/navigation/business rules.
3. **Speed & cognitive load** (P2, P10) — honored unless a trust invariant requires the extra step.
4. **Polish** — Clarity/hierarchy/consistency (P1, P6, P7) apply on top of the above without adding steps or risk.

---

## Anti-patterns (reject during any review)

| Anti-pattern | Why it fails |
|---|---|
| Auto-save AI data "to be helpful" | Breaks NFR-DATA-001; destroys user trust |
| Icon-only destructive action | Ambiguous + tiny; violates P1, P7, P8, G7 |
| Spinner over a data list | Feels slower on mid devices (interaction-model §2) |
| "Sync", "AI", "confidence" as user copy | Breaks the plain-word persona rule |
| Mirrored-LTR app instead of native RTL | Legibility + localization debt (P9) |
| A second "AI screen" beside the review form | Fragments one mental model (P4, D-03) |
| Claiming an offline capture is synced | Breaks trust (P11) and BR-OFFLINE-003 |

---

## Consistency check

Every design-system decision in the companion docs traces to a principle above. A change that can't be mapped to a principle and a source requirement is out of scope. Reviewers challenge any pattern that violates two or more principles.