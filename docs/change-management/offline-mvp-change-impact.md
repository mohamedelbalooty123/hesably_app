# Change-Impact Analysis — Promote Offline Receipt Capture to MVP

| | |
|---|---|
| **Change ID** | CI-OFFLINE-001 |
| **Change Type** | Documentation-only scope change (no code/SQL/implementation) |
| **Author** | Change Management Agent |
| **Status** | Analysis complete — pending edits |
| **Branch** | `docs/offline-mvp-scope` |
| **Target Branch** | `master` (via PR) |

---

## 1. Change Request

Promote **offline receipt capture** (currently a Phase 2 / post-MVP capability) into **MVP scope** across the entire documentation set, alongside two minor corrections discovered during requirements analysis:

1. **Change A — Offline receipt capture moves to MVP.** Capture (image + minimal metadata) must be possible without connectivity, deferring AI extraction and server persistence until the device is back online. Every relevant design doc must be updated so the offline capability is no longer described as out-of-scope.
2. **Change B — Traceability correction: Q-013 → Q-012 (6 references).** Six documents cite decision Q-013 (export *content*) where the topic is actually Q-012 (currency / number *format*). Fix exactly these six references.
3. **Change C — Web Access state model.** Standardize the four Web Access states used across UX/API docs (`WEB_ACCESS_DISABLED`, `WEB_EMAIL_PENDING`, `WEB_ACCESS_ENABLED`, `UNLINK_CONFIRMATION`) with a shared state/action/error definition. No new feature — purely a documentation normalization.

---

## 2. Scope & Boundaries

### 2.1 In scope
- All documentation under `docs/` that states offline capture is out of MVP or implies it.
- Traceability IDs across `requirements.md`, `business-rules.md`, `acceptance-criteria.md`, `feature-list.md`, `open-questions.md`.
- Architecture/design docs (`system-architecture.md`, `mobile-architecture.md`, `backend-architecture.md`, `ai-architecture.md`, `dashboard-architecture.md`).
- Database docs (design, review, implementation report).
- API contract docs (data access, storage, transaction, AI edge function, web access, export, API review).
- UX docs (`ux/`, `mobile-design/`, `review/`).
- One new ADR: `docs/architecture/decisions/ADR-007-offline-capture.md`.
- Two change-management artifacts: this analysis + `post-change-consistency-matrix.md`.

### 2.2 Out of scope (explicitly NOT changing)
- **No application code** — `apps/`, `supabase/` directories are not touched.
- **No live SQL / migrations** — the Supabase database is already implemented; DB docs are updated to reflect the policy change but the *deployed schema is unchanged*.
- **No new export feature** — Q-013 export content remains as designed; only the 6 mis-attributed references are corrected.
- **No dashboard offline mode** — the web dashboard remains online-only; only Web Access *state naming* is normalized.
- **No visual design / screens** — Stitch is not used; no UI mockups generated.
- **No conflict resolution feature** — offline sync uses last-write-wins + queue semantics, no merge UI.

### 2.3 Offline capability boundary (canonical definition)
The following is the **single source of truth** for what "offline MVP" means across all edited docs:

| Capability | MVP? |
|---|---|
| Capture receipt image offline (camera/gallery) | ✅ YES |
| Store image + minimal metadata locally on device | ✅ YES |
| Create local "pending capture" entry; view pending list | ✅ YES |
| Retry sync manually + background retry when connectivity returns | ✅ YES |
| Basic local status (pending / syncing / failed) | ✅ YES |
| Gemini AI extraction | ❌ NO — requires connectivity (runs after sync) |
| Storage upload of receipt image | ❌ NO — requires connectivity |
| Server-side persistence (transactions/items/receipts/ai_extractions) | ❌ NO — requires connectivity |
| Cross-device sync | ❌ NO — MVP remains single-device (Q-018 context) |
| Reports / analytics that reflect unsynced data | ❌ NO — reports are online server-side |

**Data trust invariant (must survive offline):** AI-extracted data is **NEVER** saved without user confirmation. Offline flow must defer *all* AI work to the online, reviewable path — offline never auto-confirms anything.

---

## 3. Current State Assessment (per module)

This section records exactly what each document says **today**, with file + line references, so reviewers can verify the "before" state.

### 3.1 Requirements package

| Doc | Current state | Key locations |
|---|---|---|
| `feature-list.md` | Offline = Phase 2 item "Basic offline mode: capture receipts offline, sync + AI-process when back online" | line 71 |
| `requirements.md` | §4.2 "Basic offline mode" listed as Post-MVP; Q-018 "Offline capture (queue + sync) is out of MVP"; capability count "101 MVP" excludes offline | lines 73, 88, 95, 974; edge-case table line 881; §9 index line 985 |
| `business-rules.md` | BR-MVP-004 explicitly declares offline capture OUT of MVP; BR-MVP-006 scopes MVP around online-only capture | BR-MVP-004 lines 396–401; BR-MVP-006 lines 405–409 |
| `acceptance-criteria.md` | No offline ACs; AC count = 84 (traceability section) | §"Traceability Matrix" |
| `open-questions.md` | Q-018 (decision record) states offline is out-of-MVP; Q-012 at ~line 419 (currency format, EGP); Q-013 at ~line 465 (export content) | Q-018 lines 668–702 |
| `assumptions.md` | No assumption records offline behavior (16 assumptions today) | throughout |

### 3.2 Architecture / design docs

| Doc | Current state | Key locations |
|---|---|---|
| `system-architecture.md` | §9.3 Create Transaction flow has offline note; failure table lists offline capture case; §14 out-of-MVP list includes offline capture; §15 post-MVP extensibility mentions offline | lines 260, 413, 453, 470, 501, 514 |
| `mobile-architecture.md` | "Offline capture is OUT of MVP (Q-018)" prominent; Phase 2 has offline sync seam | lines 12–13, 52, 111, 224, 282, 323, 336, 346 |
| `backend-architecture.md` | AI extraction described online-only; export logic references Q-013 (legit) | lines 182, 214, 245, 248 |
| `ai-architecture.md` | Server-side Gemini via Edge Function; 15s timeout; never-auto-save; no offline mention | line 258 |
| `dashboard-architecture.md` | Companion-only; web access gated; Q-013 reference | line 196, 184, 236 |
| ADRs 001–006 | No offline-related ADR exists | — |

### 3.3 Database docs

| Doc | Current state | Key locations |
|---|---|---|
| `database-review.md` | BR-MVP-004 row states offline "not modeled"; follow-up rows & migration plan rows touch offline-adjacent concerns | rows ~90, 226, 263, 271–276 |
| `database-design.md` | Receipt storage path `{business_id}/{transaction_id}/receipt.ext`; row-first upload | lines 82, 88 |
| `database-implementation-plan.md` | Migration ordering; offline not addressed | line 111 |
| `indexes.md` | GIN trigram on `party_name`; no offline concern | line 45 |
| `database-implementation-report.md` | Documents **already-deployed** schema; must NOT be rewritten to pretend offline exists | — |

### 3.4 API contracts

| Doc | Current state | Key locations |
|---|---|---|
| `data-access-contracts.md` | §3.4 "Offline" states client-side queue is NOT MVP; network-failure error cases per operation; Q-012 ref for currency; row-first ordering | §3.4 lines 465–467; Q-012 lines 341; network errors throughout §3 |
| `storage-contracts.md` | Private bucket; path scheme; row-first upload ordering | forward references |
| `transaction-contracts.md` | Create transaction flow; error "network failure" for request outcomes | §network errors |
| `ai-edge-function-contract.md` | Gemini structured JSON; timeouts; never-auto-save; base64 input | throughout |
| `web-access-contract.md` | Email-magic-link gating; state definitions need normalization | state refs |
| `export-contracts.md` | Export content = Q-013 (legit, lines 40, 41); line 37 mis-cites Q-013 for currency format → Q-012 | 37, 40, 41 |
| `api-contract-review.md` | Q-013 at line 65 (legit, export content); Q-012 at 72, 108 | 65, 72, 108, 313, 317 |

### 3.5 UX docs

| Doc | Current state | Key locations |
|---|---|---|
| `mobile-design/README.md` | Deliverable map line 22 mentions offline in `ux-states`; constraint table line 53: "Offline capture out of scope" | 22, 53 |
| `ux/ux-strategy.md` | "Numbers you can trust" line 24 mis-cites Q-013 alongside Q-012 (fix) | 24 |
| `ux/interaction-model.md` | Three mis-cited Q-013 references for currency/formatting/never-round | 41, 46, 99 |
| `ux/ux-states.md` | AI state machine `IDLE → CAPTURED → (PASS|WARNING|REJECT) → PROCESSING`; no offline capture states | §2 |
| `ux/screen-inventory.md` | SCR-09 capture screen, SCR-16 pending/review; no offline variants | SCR-09, SCR-16 |
| `ux/user-journeys.md` | J13 capture journey online-only | J13 |
| `ux/navigation-map.md` | No offline entry point noted | — |
| `ux/information-architecture.md` | No offline bucket defined | — |
| `review/ux-discovery-review.md` | Line 55 mis-cites Q-013 for currency (fix) | 55 |
| `requirements/user-flow-mobile.md` | Capture + review flow; spec starts at line 16 (junk lines 1–15 known, left untouched) | 16+ |
| `requirements/user-flow-dashboard.md` | Web access flows; state model needs normalization | throughout |

---

## 4. Proposed State (per module)

| Module | Proposed change |
|---|---|
| **Requirements** | New `FR-OFFLINE-*` ID block in `requirements.md`; Q-018 flipped to *in*-MVP decision; offline capability added to MVP count (101 → new total); `feature-list.md` moves line 71 item into Phase 1 §2 Receipt Capture; new `BR-OFFLINE-*` rules; reverse BR-MVP-004; update BR-MVP-006; new `AC-OFFLINE-*` Given/When/Then; optional ASM record for device-local storage |
| **Architecture** | Flip offline statements in `system-architecture.md` + `mobile-architecture.md`; document offline flow, sync state machine, duplicate-prevention, account-isolation rule; create `ADR-007-offline-capture.md` |
| **Database** | NO schema change. `database-review.md` rows updated to state "pending capture is client-side; server schema unchanged"; append a clearly-marked follow-up note to `database-implementation-report.md` (do NOT rewrite as if offline existed at deploy time) |
| **API** | `data-access-contracts.md` §3.4 rewritten to define the client-side pending queue as MVP; network-failure sections annotated to reference pending-capture semantics; `web-access-contract.md` normalizes 4-state model |
| **UX** | Offline states added to `ux-states.md`; SCR-09/SCR-16 variants; J13 journey extended with offline branch; README constraint table line 53 flipped; Web Access states normalized; interaction-model/strategy/UX-review Q-013→Q-012 fixed |
| **Traceability** | Q-013 stays for export-*content* refs (12 keep list); exactly 6 refs corrected to Q-012 |

---

## 5. Detailed Impact Analysis

### 5.1 Files edited (count: 19 files edited + 2 created)

| # | File | Change |
|---|---|---|
| 1 | `docs/requirements/requirements.md` | FR-OFFLINE-* block; §4.2 flip; Q-018 ref update; edge-case table row; §9 index; count update |
| 2 | `docs/requirements/feature-list.md` | Move offline item from Phase 2 → Phase 1 §2 |
| 3 | `docs/requirements/business-rules.md` | Reverse BR-MVP-004; add BR-OFFLINE-001..00n; update BR-MVP-006 |
| 4 | `docs/requirements/acceptance-criteria.md` | AC-OFFLINE-* block; count 84 → new; traceability rows |
| 5 | `docs/requirements/open-questions.md` | Q-018 decision flipped (keep original question/rationale/affected/source) |
| 6 | `docs/requirements/assumptions.md` | Optionally add ASM for device-local only |
| 7 | `docs/architecture/system-architecture.md` | Flip §9.3 note, failure table, §14, §15; add offline flow pointer to ADR |
| 8 | `docs/architecture/mobile-architecture.md` | Flip lines 12–13, 52, 111; upgrade §Phase-2 seam to MVP; add sync states |
| 9 | `docs/architecture/backend-architecture.md` | Minor: note AI runs only online (already true); verification |
| 10 | `docs/architecture/ai-architecture.md` | Minor: confirm offline never bypasses review (already true) |
| 11 | `docs/architecture/dashboard-architecture.md` | Minor: Web Access state normalization note |
| 12 | `docs/architecture/decisions/ADR-007-offline-capture.md` | **NEW** — decision record |
| 13 | `docs/database/database-review.md` | Update "not modeled" rows → "client-side queue; schema unchanged" |
| 14 | `docs/database/database-implementation-report.md` | **Append** follow-up note (marked clearly as post-deployment) |
| 15 | `docs/api/data-access-contracts.md` | §3.4 rewrite; annotate network-failure cases |
| 16 | `docs/api/web-access-contract.md` | 4-state normalization |
| 17 | `docs/api/export-contracts.md` | Line 37 Q-013 → Q-012 |
| 18 | `docs/mobile-design/ux/ux-states.md` | Add offline capture states |
| 19 | `docs/mobile-design/ux/screen-inventory.md`, `ux/user-journeys.md`, `ux/navigation-map.md`, `ux/information-architecture.md`, `mobile-design/README.md` | Offline variants/flip |
| 20 | `docs/change-management/post-change-consistency-matrix.md` | **NEW** — after edits |

### 5.2 Q-013 → Q-012 exact fix set (6)

| Doc | Line | Today | Should be |
|---|---|---|---|
| `review/ux-discovery-review.md` | 55 | Currency/number formatting cites Q-013 | Q-012 |
| `ux/interaction-model.md` | 41 | "never rounds silently" cites Q-013 | Q-012 |
| `ux/interaction-model.md` | 46 | "1,250.50 ج.م everywhere" cites Q-013 | Q-012 |
| `ux/interaction-model.md` | 99 | Latin-digits/amount formatting cites Q-013 | Q-012 |
| `ux/ux-strategy.md` | 24 | "Numbers you can trust" cites Q-013 alongside Q-012 | drop Q-013 (keep Q-012) |
| `api/export-contracts.md` | 37 | "Currency: EGP format" cites (Q-013, BR-EXPORT-003) | Q-012 |

### 5.3 Q-013 — deliberately KEPT (export-content refs, 12 locations)

`requirements.md:541,552` · `business-rules.md:308` · `open-questions.md:465` · `export-contracts.md:40,41` · `api-contract-review.md:65,103` · `backend-architecture.md:245` · `system-architecture.md:326,328,329,330,508` · `mobile-architecture.md:158,159,160,342` · `dashboard-architecture.md:184,236` · export section of `data-access-contracts.md` (export-content lines, excluding the Q-012 currency cite at 341).

---

## 6. Offline Design Specification

This section is the **canonical spec** every edited doc must conform to.

### 6.1 Offline capture flow
```
[Offline] Camera/gallery pick → image + type + optional note → local pending capture
        → shown in "Pending" list (SCR-16) with status
[Online] User taps "Sync now" (or automatic when connectivity returns)
        → upload image to storage; create DB rows (row-first: transaction → items → receipt → ai_extraction)
        → call AI Edge Function → structured JSON + confidence
        → route through REVIEW flow (REQUIREMENT: never auto-save)
        → user confirms → CONFIRMED/SYNCED
[Any time, before sync] user may delete pending capture locally
```

### 6.2 Sync state machine (add to `ux-states.md`)
Internal machine for a pending capture:

```
LOCAL_CAPTURED → WAITING_FOR_NETWORK → UPLOADING → PROCESSING_AI → READY_FOR_REVIEW
                                                                   ↘ REVIEW_REQUIRED (low confidence <80%)
READY_FOR_REVIEW / REVIEW_REQUIRED → (user confirms) → CONFIRMED → SYNCED
Any step failure → FAILED (retryable)
UPLOADING failure due to connectivity → back to WAITING_FOR_NETWORK
```

Optional merge with existing AI machine `IDLE → CAPTURED → (PASS|WARNING|REJECT) → PROCESSING`; keep the SET MINIMAL — a pending capture may reuse the existing capture states once the AI run begins. Docs must not invent extra states beyond the above unless justified.

### 6.3 Duplicate prevention (required, cross-doc)
- Each local pending capture is assigned a **client-generated UUID** at capture time.
- Sync is **idempotent**: re-sync of an already-synced capture UUID is a no-op (server holds a unique constraint on client UUID).
- "Sync retry" and "concurrent edit" are treated distinctly (LWW; no conflict-resolution UI in MVP).

### 6.4 Account isolation (required, cross-doc — CRITICAL)
- Pending local captures are bound to the **current business owner** identity.
- On **logout / account deletion / expiry / device switch**: pending captures must never be visible to or syncable under a different account. Document the *logical rule* (docs-only; implementation agent enforces in code).
- No cross-account contamination, per business-scoped RLS invariant.

### 6.5 Mandatory rules
1. **AI never trusted without confirmation** — offline must not create a bypass; all AI output routes through review.
2. **LWW; no conflict resolution** — distinguish sync-retry vs concurrent edit; no merge UI.
3. **Images never stored in PostgreSQL**; no public Storage URLs (unchanged).
4. **Offline ≠ offline dashboard/sync of filters** — export/reports remain online; correction #1 allows locally *cached previously-loaded* data in Home (never implying cloud sync); the guaranteed offline capability is capture + deferred sync only.
5. **No invented offline capabilities** (no offline analytics, no offline cross-device).
6. **DB schema unchanged** — pending queue is client-side state only.

---

## 7. Requirements Traceability & ID Plan

### 7.1 New IDs to add
- `FR-OFFLINE-001` … `FR-OFFLINE-00n` — functional requirements; *Conventions: follow existing `FR-*` numeration, do not invent numbering gaps that break the 101-count*. Recommended set:
  - FR-OFFLINE-001: capture image offline
  - FR-OFFLINE-002: local storage of image + metadata
  - FR-OFFLINE-003: pending capture list with status
  - FR-OFFLINE-004: manual + automatic sync retry
  - FR-OFFLINE-005: sync is idempotent (client UUID dedup)
  - FR-OFFLINE-006: pending captures are account-scoped and never cross accounts
  - FR-OFFLINE-007: AI/upload/persistence require connectivity
  - FR-OFFLINE-008: offline never bypasses AI review
  - FR-OFFLINE-009: local-only cache for previously-loaded Home data (no cloud sync implication)
- `BR-OFFLINE-001` … `BR-OFFLINE-00n` — business rules (each maps to ≥1 FR).
- `AC-OFFLINE-001` … — Given/When/Then (each maps to FR + BR), added to the AC traceability matrix and count.
- `ASM-OFFLINE-001` (optional) — device-local storage assumption.
- Decision: update Q-018 (flip), keep Q-012/Q-013 content, fix Q-013 mis-cites.

### 7.2 Count impact
- `requirements.md` MVP capability count: **101 → 109** (if 8 FR-OFFLINE added) — must recompute and update the total + §9 index + feature-list Phase labels. **Verify actual count at edit time; do not hardcode.**
- `acceptance-criteria.md`: 84 → new total (recommend parity with AC-OFFLINE count).

---

## 8. Conflict & Consistency Analysis

| # | Potential conflict | Disposition |
|---|---|---|
| 1 | `data-access-contracts.md` §3.4 says queue is NOT MVP while FR-OFFLINE mandates it | Resolve: rewrite §3.4 to define MVP pending queue |
| 2 | `mobile-architecture.md` line 13 "(Q-018)" used to justify exclusion | Resolve: after Q-018 flip, remove the exclusion cite; Q-018 now supports inclusion |
| 3 | BR-MVP-004 (out of MVP) vs new BR-OFFLINE-* | Resolve: reverse BR-MVP-004 to state offline capture IS in MVP; renumber/annotate |
| 4 | `ux-states.md` two state machines | Resolve: merge via shared states, keep minimal set |
| 5 | Export Q-013 mis-cites | Resolve: 6 fixes per §5.2; keep-list per §5.3 |
| 6 | "101 MVP requirements" totals | Resolve: recompute at edit time |
| 7 | DB implementation report already deployed | Resolve: append note only; never rewrite history |
| 8 | Web Access state naming varies | Resolve: single 4-state model in `web-access-contract.md` + UX docs |

---

## 9. Security Impact

Docs-only analysis (no code). Offline introduces a **new local-state attack surface**; the following must be stated in edited docs (primarily `mobile-architecture.md`, `ADRs`, and `docs/security/` if it exists):

- **Local images/PII**: receipt images plus vendor names stay on device; document encryption-at-rest as an architectural requirement (derive: platform keystore / SQLCipher; flag as implementation-agent guidance).
- **Logout / deletion**: pending data must be purged or cryptographically bound to the owner; document both paths.
- **Reinstall / device transfer**: pending queue does NOT survive reinstall (no server copy) — explicit UX consequence to document.
- **Sync integrity**: idempotent insert keyed on client UUID; server ignores re-uploads of known UUIDs.
- No change to RLS; storage remains private; no public URLs (invariants preserved).

---

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Docs drift after edits (consistency matrix incomplete) | Med | High | Post-change global grep audit (todo includes `docs/implementation/`, `docs/security/`) |
| ID/count drift in requirements totals | Med | Medium | Recompute all totals at edit time; cross-check matrix |
| BR-MVP-004 reversal creates ambiguity (was a decision record) | Med | Medium | Clear annotation "reversed by Q-018 decision flip" |
| DB "no schema change" statement later contradicted | Low | Medium | Consistent phrasing: "client-side queue only; schema unchanged" |
| Over-engineered offline states | Med | Med | Minimal state set per §6.2; UI/UX Pro Max skill gate |
| Q-013 accidental over-correction | Low | Med | Keep-list is explicit (§5.3); grep verify after edits |

---

## 11. Migration / Edit Plan

Order (each produces a commit; branch `docs/offline-mvp-scope`):

1. ADR-007 (decision first, gives rationale to all edits)
2. `requirements.md` FR-OFFLINE + flips + count
3. `business-rules.md` (reverse BR-MVP-004, add BR-OFFLINE, update BR-MVP-006)
4. `acceptance-criteria.md` AC-OFFLINE + traceability
5. `open-questions.md` Q-018 flip; `assumptions.md` (ASM-OFFLINE optional)
6. `feature-list.md` move item to Phase 1 §2
7. Architecture docs + system-architecture flips
8. Database docs (review rows + implementation-report NOTE append)
9. API contracts (§3.4, web-access state, export Q-013)
10. UX docs (states, screens, journeys, nav, IA, README, strategy/interaction/UX-review Q-013 fix)
11. `post-change-consistency-matrix.md`
12. Global grep audit → fix stragglers
13. Final status report + git commit/branch hygiene + PR

---

## 12. Validation Plan

- **Grep audit (mandatory, post-edit):** search all docs for residual `Q-013` near currency/formatting terms; residual offline-as-out-of-MVP phrases (`out of MVP`, `not in MVP`, `post-MVP`, `Phase 2`, `out-of-scope` + `offline`); verify 6 fix targets changed and keep-list intact.
- **Count audit:** recompute requirements count, AC count, feature-list phase counts.
- **ID audit:** every FR-OFFLINE/BR-OFFLINE/AC-OFFLINE has a traceability row; no orphan IDs.
- **DB audit:** confirm no edited doc claims a schema change was applied; implementation-report has append-only note.
- **Skill gate:** UI/UX Pro Max skill for UX-state reasoning consistency; UI/UX Designer as reviewer of UX edits.

---

## 13. Rollback Plan

- Each edit is a separate commit on `docs/offline-mvp-scope`; the full set is one PR against `master`.
- **Rollback** = do not merge the PR, or revert the PR. All changes are docs-only; no data/schema impact; `master` remains deployable at all times (per AGENTS.md contract).
- `database-implementation-report.md` has append-only note → reverting the note restores original text cleanly (no destructive edit to deployed-state history).

---

## 14. Recommendation & Approval Gate

**Recommendation: APPROVED** — the change is confined to documentation, preserves the AI-trust and account-isolation invariants, requires no schema change, and every affected doc has a mapped edit. Execution is gated on: (a) UI/UX Pro Max skill engagement for the UX-state design, (b) recomputed totals, (c) full post-change grep audit including `docs/implementation/` and `docs/security/`.

**Final status** (to be recorded in the final report after all edits): `APPROVED` / `APPROVED WITH CONDITIONS` / `REQUIRES REVISION` / `BLOCKED`.