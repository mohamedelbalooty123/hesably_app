# UX Discovery Review — Smart Invoice Assistant (Mobile)

**Status:** UX Discovery & IA phase complete (docs). Next phase: interaction/visual design + build.
**Companion docs:** `../README.md`, `ux/ux-strategy.md`, `ux/information-architecture.md`, `ux/navigation-map.md`, `ux/screen-inventory.md`, `ux/user-journeys.md`, `ux/interaction-model.md`, `ux/ux-states.md`.

---

## 1. What was produced

- **Strategy:** product premise → 7 UX goals (G1–G7), persona, 5 experience pillars, trade-offs, success metrics (`ux-strategy.md`).
- **IA:** content model, 4 destination tabs, ≤2-levels hierarchy, authoritative Ar/En labels, default categories, RTL rules (`information-architecture.md`).
- **Navigation:** guards (session/onboarding), add-flow, browse→detail→edit/delete, reports→export, back-stack rules and invariants (`navigation-map.md`).
- **Screens:** 17 routes + 8 overlays precisely scoped (`screen-inventory.md`).
- **Journeys:** 14 end-to-end flows with coverage matrix (`user-journeys.md`).
- **Interactions:** touch/feedback/forms/pickers/confirmations/back/RTL/offline + performance (`interaction-model.md`).
- **States:** taxonomy, AI state machine, per-screen matrix, canonical copy (`ux-states.md`).

---

## 2. Consistency matrix (self-check across docs)

| Theme | Strategy | IA | Nav | Screens | Journeys | Interaction | States |
|---|---|---|---|---|---|---|---|
| 4 tabs + FAB | §6/§7 | §2/§3 | §1 | SCR-05,06,11,12 | all | — | §3 |
| Add flow = one FAB | G2 | §4 | §3 | SCR-08→09→10 | J1,J2 | §6 | §2 |
| AI: never auto-save | §5, G4 | §8 | §3 | SCR-10 | J1,J4 | §5 | §2 |
| AI ceilings ≤15s | G3,G6 | — | §3 | SCR-09 | J4,J5 | §2 | §2 |
| Low-conf <80% flagged | G4 | — | §3 | OVR-08 | J3 | §5 | §2 |
| Confirm-before-delete | G7 | — | §4 | OVR-04/05/06 | J7,J14 | §5 | — |
| Period model (Q-011) | — | §3 | §5 | SCR-11, OVR-03 | J9,J10 | §4 | §3 |
| EGP `1,250.50 ج.م` | §5 | §5 | — | SCR-05/07/10 | — | §3 | — |
| Phone+OTP, 60s | §2, G1 | — | §2 | SCR-02/03 | J1 | §3 | §3 |
| Session persistence | §2 | — | §2 | SCR-01/05 | J2 | — | §3 |
| RTL Arabic-first | §2 | §5/§7 | §1 | all labels | — | §7 | §4 (copy) |
| Back never broken | — | — | §7/§8 | — | — | §6 | — |
| Offline (no queue) | §7 | — | §3 | SCR-09 | J13 | §8 | §3 |
| Export honors filters | §7 | — | §5 | OVR-02 | J9 | — | §3 |

> No contradictions found. One seam to watch: **web-access linking live state** (BR-WEB-006 unlink) is only confirmed from SCR-16 — the dashboard-side state isn't visible in a mobile-only MVP beyond the explicit "linked" confirmation.

---

## 3. UX decisions made (recorded, with rationale)

| # | Decision | Rationale |
|---|---|---|
| D-01 | 4 tabs + global FAB (Home hosts the FAB, not the tab bar) | G2 one-tap entry; avoids mis-taps next to a center-FAB |
| D-02 | Add flow is full-screen linear (Type → Capture → Review) | Match the mental step count; scalable AI states to one pipeline |
| D-03 | Review form doubles as: AI prefill / manual entry / edit-existing | One form, three sources — consistent engineering + UX |
| D-04 | OVR-02 export sheet defaults the period to the current view | Q-014: export always mirrors what the user sees |
| D-05 | Empty-state AI hints & "Enter manually" reachable from every AI terminal state | G3 no-dead-ends invariant |
| D-06 | Category picker reuses default-then-custom order + AI suggestion badge | One source of truth for the category list |
| D-07 | Skeletons over spinners on content lists; inline progress on actions | NFR-LOWDEV/PREF; perceived latency on mid devices |
| D-08 | Camera errored / offline = explicit blocked message, never silent | Q-018 offline out of scope; predictable boundary |
| D-09 | Latin digits kept for amounts/phone even inside Arabic-first UI | Backend `numeric(14,2)` + phone checks (Q-013) |
| D-10 | No FR-REPORT-* exists in MVP — reports anchor to FR-DASH-004…007 | Traceability hygiene caught and corrected in-review |

---

## 4. Open items & risks

| Risk / open item | Impact | Mitigation / note |
|---|---|---|
| R-01 Real-woman/merchant device variance (360 vs 412dp, one-hand) | Density assumptions may shift | Design must explicitly test 360dp smallest-width during wireframes |
| R-02 AI prefill accuracy for Arabic handwritten receipts | Review burden; possible confusion | Confidence flagging (OVR-08) + strong EMPTY/MANUAL escape; measure fallback rate (metric §8) |
| R-03 Delete-account irreversible + storage images | Permanent loss panic / support load | OVR-05 full scope warning + typed confirmation; edge-function purge needed (storage) |
| R-04 Export clipping long receipt lists in PDF/Excel | Wrong/incomplete file | Client-side caps by format (report-contracts §6); document cap in next phase |
| R-05 "This week → last month" period mental-model drift | Misreading net figures | Segment labels + explicit period title on Reports |
| R-06 OTP SMS cost/latency (Egypt) | Sign-up friction | 60s cooldown + resend + support link (FR-AUTH-004/005) |
| O-01 Back-gesture behavior vs in-app explicit navigation on mixed stacks (Viewer modal vs sheet) | QA burden | Pin system rules in `navigation-map.md` §7; verify in device QA |
| O-02 Arabic strings single-sourcing for build | Duplication risk | `ux-states.md` §4 = canonical copy source for i18n extraction |

---

## 5. Verdict against the phase contract

| Discovery-phase delivery | Status |
|---|---|
| Understands target users & context | ✅ persona + assumptions |
| Opportunity/goal framing (measurable) | ✅ G1–G7 + metrics |
| Information architecture | ✅ content model, areas, labels, RTL |
| Navigation map & back-stack | ✅ full map + invariants |
| Screen inventory (all routes/overlays) | ✅ 17 + 8 |
| User journeys & flows | ✅ 14 + coverage matrix |
| Interaction model (touch/forms/confirmations/loading) | ✅ contract + invariants |
| State model (empty/loading/error/offline/AI) | ✅ taxonomy + machine + copy |
| No visual design / no Flutter code / no Stitch | ✅ (out of scope, by mandate) |
| Traceability to FR/BR/AC/NFR/Q | ✅ per-doc links; verified IDs via grep |

---

## 6. Next steps (hand-off for the next phase)

1. **Wireframes/low-fidelity screens** for all 17 routes + 8 overlays (node-level, Arabic-first copy from this doc set).
2. **Flutter state/routing skeleton** per `navigation-map.md` (4-tab shell + guarded flows; system back mapped).
3. **i18n seed** from `ux-states.md` §4 + `information-architecture.md` §5 label table.
4. **Device QA checklist** for back-stack, RTL mirror, 360dp, and AI-ceiling behaviors (from invariants in both docs).
5. No design system / brand work here — hand to the visual design phase with these behavioral constraints.