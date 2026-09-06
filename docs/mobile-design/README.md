# Mobile Design — UX Discovery & Information Architecture

**Phase:** UX Discovery & Information Architecture (foundation before visual design)
**Scope:** Flutter mobile app only (MVP). The Next.js dashboard has its own design path (`docs/architecture/dashboard-architecture.md`, `docs/requirements/user-flow-dashboard.md`).
**Inputs:** All completed requirements, business-rule, architecture, database, and API-contract documents (see [Source of truth](#source-of-truth)).
**Deliverables:** 7 UX foundation documents + 1 self-review.

> **What this phase is NOT:** No visual design, no color/typography tokens, no Flutter widget code, no Stitch/design-system generation. It defines **what** the mobile experience is, **how** the screens are organized, **how** the user moves between them, and **what states** every screen must handle — the contract that visual design and implementation build against.

---

## 1. Deliverable map

| Doc | Purpose | Reads best when |
|---|---|---|
| [`ux/ux-strategy.md`](ux/ux-strategy.md) | UX goals, principles, personas, success criteria | Starting the phase; reviewing trade-offs |
| [`ux/information-architecture.md`](ux/information-architecture.md) | Content model, areas, organization scheme, labeling (Ar/En) | Deciding what goes where and what it's called |
| [`ux/navigation-map.md`](ux/navigation-map.md) | Global nav, bottom tabs, flows, back behavior, routing | Building the navigation shell and route guard |
| [`ux/screen-inventory.md`](ux/screen-inventory.md) | Every screen + overlay: purpose, content, actions, entries/exits | Writing screen specs / wireframes |
| [`ux/user-journeys.md`](ux/user-journeys.md) | End-to-end journeys (onboarding, capture, browse, reports, settings) | Validating flows against acceptance criteria |
| [`ux/interaction-model.md`](ux/interaction-model.md) | Touch targets, feedback, forms, pickers, confirmations, states, RTL behavior | Designing components and interactions |
| [`ux/ux-states.md`](ux/ux-states.md) | State taxonomy, per-screen state matrix, copy patterns | Handling loading/empty/error/offline everywhere |
| [`review/ux-discovery-review.md`](review/ux-discovery-review.md) | Consistency verification, decisions made, open items, next steps | Reviewing the phase before visual design |

---

## 2. Source of truth

Resolve any conflict in this order (highest authority first):

1. `docs/requirements/requirements.md` — 109 functional requirements (FR-*)
2. `docs/requirements/business-rules.md` — business rules (BR-*)
3. `docs/requirements/acceptance-criteria.md` — testable Given/When/Then (AC-*)
4. `docs/requirements/open-questions.md` — resolved decisions (Q-001…Q-022)
5. `docs/requirements/assumptions.md` — assumptions (ASM-001…)
6. `docs/architecture/*` + `docs/database/*` + `docs/api/*` — design/contracts (ADR-*)

Where requirements and contracts conflict, the **acceptance criteria and resolved decisions** win; the UX documents prefer the simplest experience that satisfies both. Any UX decision that deviates from the source is recorded explicitly in `review/ux-discovery-review.md`.

---

## 3. Non-negotiable product constraints (honored here)

| Constraint | Where it lands in these docs |
|---|---|
| Arabic-first, RTL, English secondary | `ux-strategy.md` §2, `info-architecture.md` labeling + RTL, `interaction-model.md` §RTL |
| AI extraction never auto-saves — always user confirmation | `ux-strategy.md`, `navigation-map.md` capture flow, `user-journeys.md` J2/J3, `ux-states.md` AI state machine |
| Confidence <80% flagged for review; <50% = failure | `user-journeys.md` J2/J3, `ux-states.md` |
| 15-second client-visible extraction ceiling; never a dead end | `user-journeys.md` J3, `interaction-model.md` loading, `ux-states.md` |
| RLS / private storage — no public surface ever exposed to the UI | Cross-cutting; affects only which reads the UI can rely on |
| Phone + OTP only on mobile MVP; 60s resend cooldown | `user-journeys.md` J1, `ux-states.md` auth states |
| Low/mid-spec Android — lightweight, no heavy animation | `ux-strategy.md` principles, `interaction-model.md` performance |
| Offline capture: **device-local pending queue + deferred sync** (MVP; Q-018 flipped, ADR-007) | `ux-states.md` offline + pending machine, `interaction-model.md` errors, `navigation-map.md` add flow, `user-journeys.md` J13 |
| Web dashboard is companion only; creation mobile-only | `navigation-map.md` (scope boundary) |
| Unified report periods: This Week / This Month / Last Month / Year-to-Date / Custom Range | `info-architecture.md`, `screen-inventory.md` (Reports) |

---

## 4. Conventions used across these documents

- **Screen IDs** `SCR-xx` and **overlay IDs** `OVR-xx` are defined in `screen-inventory.md` and reused by every other document.
- **Arabic copy** is provided alongside English everywhere it matters (labels, empty states, errors). Arabic is the primary; English secondary.
- **Traceability**: each document references FR-*/BR-*/Q-*/AC-* IDs from the source-of-truth docs.
- **RTL**: all layouts, direction-dependent icons, back/forward semantics, and scrolling assume a right-to-left base direction that mirrors only on deliberate language switch.