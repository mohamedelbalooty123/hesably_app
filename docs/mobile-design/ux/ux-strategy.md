# UX Strategy — Smart Invoice Assistant (Mobile)

**Phase:** UX Discovery & Information Architecture
**Companion docs:** `../README.md`, `information-architecture.md`, `navigation-map.md`, `screen-inventory.md`, `user-journeys.md`, `interaction-model.md`, `ux-states.md`, `../review/ux-discovery-review.md`
**Traceability:** FR-AUTH-001…007, FR-ONBOARD-001…005, FR-CAPTURE-001…007, FR-REVIEW-001…007, FR-AI-001…009, FR-TRANS-001…013, FR-DASH-001…007, FR-EXPORT-001…004, FR-CATEGORY-001…005, FR-SETTINGS-001…006; NFR-LANG-001, NFR-PERF-001, NFR-LOWDEV-001, NFR-DATA-001; Q-001…Q-022

---

## 1. Product premise

Hesably is an **AI-powered receipt/invoice capture and bookkeeping app for small Egyptian shop owners**. The user is a solo shop owner or micro-business owner with **no dedicated accountant**, who manages the business mostly from their phone, and for whom **trust in the numbers** ("did my books record what actually happened?") and **speed** ("capture it now, don't think about it") matter more than accounting sophistication.

The mobile app is the **source of truth for account creation and data entry** (FR-AUTH-001, Q-005/Q-017); the web dashboard is a companion read/edit surface. This strategy covers **mobile only**.

---

## 2. Product principles → UX contract

| Source principle | UX translation | Immutable? |
|---|---|---|
| **Arabic-first, RTL** (NFR-LANG-001, Q-019) | Every screen, label, empty state, error, and export is Arabic-first RTL; English is a secondary toggle. Direction-dependent icons (back, chevrons, order) reflect RTL. | Yes |
| **AI never auto-saves** (NFR-DATA-001, BR-CONFIRM-001, Q-008) | The capture flow always ends in a visible **Review & Save** step. "Saved" is only shown after the user's own confirm action. | Yes |
| **No dead end in AI processing** (FR-AI-005/006/008/009, Q-008/Q-009) | Every failure / timeout / non-receipt path yields a next action: retry or **enter manually**. | Yes |
| **Numbers you can trust** (Q-012, BR-REPORT-004) | One EGP format everywhere (`1,250.50 ج.م`); amounts never silently round; low-confidence AI fields are visibly flagged. | Yes |
| **Low/mid-spec Android friendly** (NFR-LOWDEV-001, NFR-PERF-001) | Lightweight interactions, no heavy animation, skeletons not spinners, debounced search, compressed images. | Yes |
| **Session persistence** (Q-003, FR-AUTH-006/007) | Returning users land directly on Home; no repeated login. | Yes |
| **Phone + OTP only** (FR-AUTH-002, BR-MVP-002) | No password/email login on mobile; 60-second resend cooldown (Q-001). | Yes |

---

## 3. UX goals (measurable)

These goals are the acceptance lens for the whole UX foundation. Wireframes and tests check against them.

| Goal | Definition of done | Source links |
|---|---|---|
| **G1 — First transaction in ≤ 3 minutes** | A new user records their first transaction within ~3 minutes of opening the app (OTP + business setup + one capture or manual entry). | FR-AUTH-001…005, FR-ONBOARD-001…005, FR-CAPTURE-001…007 |
| **G2 — One-tap entry** | "Add transaction" is reachable in one tap from Home (FAB) and never requires more than one deliberate field to start (the type choice). | FR-CAPTURE-001 |
| **G3 — Capture is never a dead end** | Every capture-stage outcome (success, low-confidence, failure, timeout, non-receipt, offline, network loss) has a visible next action. | FR-AI-001…009, FR-REVIEW-001…007 |
| **G4 — Confirm-before-trust** | AI data reaches the database only after the user's explicit confirm; low-confidence fields (<80%) are visibly flagged. | FR-REVIEW-002, FR-AI-003/004, BR-CONFIRM-001, NFR-DATA-001 |
| **G5 — Zero-training core loop** | Record / See this month's numbers / Find a past entry — usable without help text by a non-technical user. Core navigation ≤ 2 levels deep. | FR-TRANS-001…008, FR-DASH-001…003, FR-SETTINGS-001…006 |
| **G6 — Never-frozen loading** | Every wait ≥ ~400ms shows stable progress/skeleton; the AI wait shows a 15-second visible ceiling with immediate manual fallback. | FR-AI-007/008, NFR-PERF-001, Q-009 |
| **G7 — Destroyed data is intentional** | Deleting a transaction/account and unlinking web access always require explicit confirmation. | FR-TRANS-013, FR-SETTINGS-005/006, BR-TRANS-003/004, BR-WEB-006 |

---

## 4. Target user

Primary persona (drives all design decisions):

> **أصل / A.'s — Small-shop owner, micro business.** Grocery, cafeteria, pharmacy, or services shop. Android phone (mid/low spec). Arabic speaker. Comfortable with WhatsApp and the phone camera, **not** with accounting software. Wants to know "how much money came in and went out" and to keep receipts for suppliers and taxes. Low tolerance for confusing screens and for data that disappears.

Behaviors recorded in `assumptions.md` (ASM-001…ASM-016) that shape UX:

- **Phone-first, mobile-primary** (ASM-001): phone is the main device; screens are 360–412dp, portrait, single-handed.
- **No accountant in MVP** (ASM-006): reports/export are read by the owner first; an accountant is a Phase 2 reader.
- **Trust gap** (ASM-010, NFR-DATA-001): the owner will not trust auto-saved AI data; every AI result must be reviewable.
- **Low technical confidence**: avoid jargon ("extraction", "sync"); use plain words: "التقط صورة" (take a photo), "راجع البيانات" (review the data), "احفظ" (save).
- **Relational context**: suppliers/customers are referred to by name only (`party_name`, Q-022); no addresses, no multi-branch (Phase 2/3).

---

## 5. Experience pillars

| Pillar | Meaning | Primary flows |
|---|---|---|
| **Capture** — "open it, snap, done" | FAB at the thumb; camera first; quality guidance before AI; manual entry always available. | Home FAB → Type → Capture → Review (SCR-05 → SCR-08/09/10) |
| **Understand** — "see where the money went" | Current-month summary first; category breakdown; period comparison; one unified period model (Q-011). | Home (SCR-05), Reports (SCR-11) |
| **Find & fix** — "that supplier, last month" | Chronological grouped list; filters (date/category/type/amount); name search (party only, Q-022); read-only detail with edit/delete. | Transactions (SCR-06), Detail (SCR-07), Review (SCR-10) |
| **Maintain** — "my app, my business" | Business profile, categories, language, web access, logout, delete account. | Settings (SCR-12 → SCR-13…16) |
| **Trust** — "nothing happens without me" | Confirm-before-save; flagged low-confidence fields; explicit destructive confirmations; consistent EGP. | Capture flow, Transactions, Settings |

---

## 6. Information architecture stance

- **Shallow and task-first.** Primary tasks sit behind the bottom navigation (Home / Transactions / Reports / Settings) plus one global FAB. No second-level navigation inside the four tabs except Settings sub-pages and the focused view/edit/capture flows (see `information-architecture.md`).
- **One mental model for money:** everything is a **transaction** — Income (مبيعات / إيرادات) or Expense (مشتريات / مصروفات) — with an EGP amount and a category. Receipt and AI provenance are supporting detail, never separate user-facing models.
- **Arabic labeling governs.** Screens and labels are authored in Arabic first; English strings stay in lockstep (FR-SETTINGS-004).

---

## 7. Key trade-offs (decided, recorded)

| Decision | Rationale | Impact |
|---|---|---|
| **No undo/trash** for deleted transactions — confirmation dialog is the only safeguard (BR-TRANS-004). | MVP scope; simple model; destructive confirmations required. | G7; AC-TRANS covering delete |
| **Last Write Wins** for concurrent edits (Q-006). | No conflict UI in MVP; edits are rare and owner-only. | No merge/conflict UI surface |
| **Export scope = period + active filters** (Q-014). | Export always reflects exactly what the user is looking at. | Export Options sheet mirrors the applied filters |
| **AI processing always runs via the Edge Function** and is **online-only**; offline, capture works as a **device-local pending capture** that syncs + extracts AI when the connection returns (Q-018 flipped → IN MVP; ADR-007). | Predictable, secure boundary (AI never auto-persists; images never queued to the server); offline never bypasses review. | Local pending list + "waiting for connection" state; sync on reconnect |
| **4 bottom tabs + 1 FAB** (no middle-tab FAB). | 4 destinations is a navigable maximum that keeps the FAB unambiguous and the capture task globally reachable. | Navigation shell (SCR-05/06/11/12 + FAB) |

---

## 8. Success metrics (validation hooks for later phases)

| Metric | Target | Where it is validated |
|---|---|---|
| Time from app open (new user) to first saved transaction | ≤ 3 min (G1) | Usability test, launch analytics funnel |
| Capture-flow completion: started → saved | ≥ 80% | Analytics funnel (type → capture → review → saved) |
| Manual-entry fallback rate after AI start | ≤ 10% (goal) | Analytics (fallback is a feature, rate should stay low) |
| Delete/account-delete accidental-error reports | 0 (confirmations always present) | Support intake, test |
| Session resume without login | 100% (persistent session, Q-003) | Test/QA |

> These are targets for the **validation and build phases**, not this discovery phase.