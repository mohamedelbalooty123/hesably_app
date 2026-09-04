# API & Data Access Contract Review

Smart Invoice Assistant — MVP. A rigorous architectural and security review of the existing `docs/api/` contracts (data-access, auth, web-access, transaction, category, report, export, storage, and AI Edge Function) against the finalized requirements, architecture, and database design, performed **before** the application implementation phase begins.

| | |
|---|---|
| **Review date** | 2026-09-04 |
| **Reviewer** | Senior Backend / Supabase Architect |
| **Scope** | `docs/api/**` (data-access, auth, web-access, category, transaction, report, export, storage, AI Edge Function contracts; API ADRs 001–003) |
| **Result** | **APPROVED WITH CONDITIONS** |
| **Inputs** | `docs/requirements/*`, `docs/architecture/*`, `docs/database/*`, `docs/api/*`, AGENTS.md |

---

## 1. Review Scope

Review-only. **No application code was written; no Edge Function deployed; no Supabase project modified; no migrations/RLS/storage changed.** Only `docs/api/**` were corrected (3 files). `docs/requirements/**`, `docs/architecture/**`, and `docs/database/**` were consulted as cross-check sources and were **NOT** modified.

Reviewed source of truth:

- **Requirements**: `requirements.md`, `business-rules.md`, `assumptions.md`, `open-questions.md` (Q-001…Q-022), `acceptance-criteria.md`, `feature-list.md`, `user-flow-mobile.md`, `user-flow-dashboard.md`
- **Architecture**: `system-architecture.md`, `backend-architecture.md`, `ai-architecture.md`, `mobile-architecture.md`, `dashboard-architecture.md`, `decisions/ADR-001…006`
- **Database**: `schema.md`, `relationships.md`, `rls-matrix.md`, `indexes.md`, `storage-design.md`, `data-access-patterns.md`, `migration-plan.md`, `database-review.md`, `database-implementation-plan.md`, `database-implementation-report.md`, `decisions/ADR-DB-001…005`
- **API contracts (review targets)**: `data-access-contracts.md`, `auth-contracts.md`, `transaction-contracts.md`, `category-contracts.md`, `report-contracts.md`, `export-contracts.md`, `storage-contracts.md`, `ai-edge-function-contract.md`, `web-access-contract.md`, `decisions/README.md`, `decisions/ADR-API-001…003`

---

## 2. Executive Summary

The `docs/api/**` contracts are **fundamentally sound and implementation-ready**. They correctly implement the approved architecture (ADR-API-001): **direct Supabase client access** from Flutter and Next.js with **no traditional REST API layer**; the only custom server-side component is the `extract-receipt` Edge Function mediating Gemini (ADR-API-002). RLS is correctly delegated as the authorization layer at the database level (ADR-API-003, `rls-matrix.md`); web-access gating is correctly treated as a per-request server-side gate, not an RLS relaxation (Q-015, ADR-006). All 9 contract documents are internally consistent with the database implementation report, which is **COMPLETE** (13 migrations applied, all review conditions HIGH-01/HIGH-02/MEDIUM-01/MEDIUM-02/LOW-03 satisfied).

The review surfaced **0 CRITICAL**, **0 HIGH**, **2 MEDIUM**, and **3 LOW** findings. The MEDIUM findings are documentation-locality/drift issues that would mislead implementers; both have concrete single-file corrections applied to `docs/api/**`. The LOW findings are minor copy/consistency notices, one of which (stale Gemini model name in `AGENTS.md`) is outside the editable scope and reported only.

Because both MEDIUM findings are already **closed by the corrections applied in this review** (and were not architectural defects — the contracts' *behavior* already matched the database), the gate condition is documentation correctness, now satisfied. **APPROVED WITH CONDITIONS** is granted on the basis that implementers treat the corrected `docs/api/**` (this review's §18) as authoritative.

### Summary of findings

| Sev | ID | Title | File(s) | Status |
|-----|----|-------|---------|--------|
| MEDIUM | API-M1 | RLS table matrix in ADR-API-003 overstated access classes | `decisions/ADR-API-003` | FIXED (doc) |
| MEDIUM | API-M2 | AI persistence ordering omitted `ai_extractions` and the provenance-guard same-call constraint | `data-access-contracts.md` §2.4 | FIXED (doc) |
| LOW | API-L1 | Default category Arabic `name` labels drifted from the seeded (`categories.name`) values | `category-contracts.md` §2 | FIXED (doc) |
| LOW | API-L2 | Email-linking "Edge Function" mediation listed in ADR-API-003 Layer 3 contradicts the accepted direct-client flow | `decisions/ADR-API-003` | FIXED (doc) (folded into corrections) |
| LOW | API-L3 | `AGENTS.md` stale Gemini model ("2.5 Flash-Lite") vs approved "3.1 Flash-Lite" (Q-007) | `AGENTS.md` (out of scope) | REPORT ONLY — not edited |

---

## 3. Requirements Coverage

Legend: ✅ Supported · 🟡 Partially supported · ⚪ Not supported · ➖ Out of MVP scope (correctly unmodeled)

| Requirement area | Contract support | Contracts / ADRs | Status | Issue |
|---|---|---|---|---|
| Phone + OTP auth | signInWithOtp/verifyOTP, 60s cooldown, persistent session | `auth-contracts.md`, `data-access-contracts.md` §2.1, ADR-API-003 | ✅ | Q-001/002/003 honored |
| Onboarding gate | business create + auto-seed defaults | `auth-contracts.md` §2.3, `data-access-contracts.md` §2.2 | ✅ | BR-BUS-001..003 |
| Receipt capture (manual) | INSERT transactions + items | `transaction-contracts.md` §2, `data-access-contracts.md` §2.4 | ✅ | FR-CAPTURE-007; no web create (Q-005) |
| AI extraction / confidence | Edge Function → Gemini 3.1 Flash-Lite; <80% flag; <50% fail; 15s timeout | `ai-edge-function-contract.md`, `data-access-contracts.md` §2.8, ADR-API-002 | ✅ | Q-007/008/009 honored; model correct (3.1, not 2.5) |
| Review / Edit + confirm boundary | ephemeral extraction; persist only after confirm | `ai-edge-function-contract.md` §9, `transaction-contracts.md` §3, `data-access-contracts.md` §2.4 | ✅ | NFR-DATA-001, BR-CONFIRM-001 |
| AI provenance | `ai_extractions` snapshot post-confirm; guard trigger | `transaction-contracts.md` §10, `data-access-contracts.md` §2.4 | ✅ | MEDIUM-01 honored (after API-M2 fix) |
| Categories | defaults + custom, hideable, custom rename/delete | `category-contracts.md`, `data-access-contracts.md` §2.3 | ✅ | HIGH-01 (custom rename) honored; Q-010/021 |
| Transactions | income/expense, list/filter/search/detail/update/delete | `transaction-contracts.md`, `data-access-contracts.md` §2.4 | ✅ | party_name trgm search (Q-022); LWW (Q-006) |
| Line items | optional batch items | `transaction-contracts.md` §10 | ✅ | |
| Receipt images | private bucket, path `{biz}/{txn}/receipt.ext`, row-first | `storage-contracts.md`, `data-access-contracts.md` §2.4 | ✅ | ADR-DB-004, ADR-005 |
| Reports | period + category/type/amount aggregates; unified periods | `report-contracts.md`, `data-access-contracts.md` §2.5 | ✅ | Q-011 unified periods; Q-012 EGP |
| Exports | client-side, period + active-filter scope | `export-contracts.md`, `data-access-contracts.md` §2.6 | ✅ | Q-013/014 |
| Settings / profile | editable business | `data-access-contracts.md` §2.2 | ✅ | FR-SETTINGS-001, FR-WEB-SETTINGS-001 |
| Web access | opt-in email linking, magic link, per-request re-check | `web-access-contract.md`, `auth-contracts.md` §3, `data-access-contracts.md` §2.7 | ✅ | Q-004/015/016; BR-WEB-001..006 |
| Web transaction edit/delete | same RLS identity | `web-access-contract.md` §7, `data-access-contracts.md` §2.4 | ✅ | Q-017 |
| Web transaction create | blocked in app/UI; not a DB distinction | `web-access-contract.md` §7, `transaction-contracts.md` §11 | 🟡 | matches DB limitation; enforced client-side (BR-WEB-005) |
| Account deletion | admin Edge Function, service_role, cascade | `auth-contracts.md` §5, `data-access-contracts.md` §2.9 | ✅ | ADR-DB-005, FR-SETTINGS-006 |
| Storage security | no public URLs, owner-scoped, immutable | `storage-contracts.md`, ADR-API-003 | ✅ | NFR-SEC-001/002 |
| Offline | N/A MVP | `data-access-contracts.md` §3.4 | ➖ | Q-018 |
| Real-time | N/A MVP (LWW) | `data-access-contracts.md` §3.3 | ➖ | Q-006 |

---

## 4. Architecture Boundaries

| Boundary | Contract statement | Authority | Status |
|---|---|---|---|
| No custom REST/GraphQL API | N/A — direct access | ADR-API-001, backend-architecture | ✅ |
| Only server-side component = `extract-receipt` Edge Function | AI extraction | ADR-API-002 | ✅ |
| Edge Function never persists business data | ai-edge-function-contract §9 | ADR-API-002, NFR-DATA-001 | ✅ |
| Service role never client-side | ADR-API-003 | rls-matrix §2, ADR-DB-005 | ✅ |
| RLS is the authorization layer | ADR-API-003 | rls-matrix | ✅ |
| Web-access gating is a server-side gate, not RLS | web-access-contract §5, auth-contracts §6 | rls-matrix §1 note, ADR-006 | ✅ |
| Next.js SSR client for dashboard | data-access-contracts §1 | dashboard-architecture | ✅ |
| Flutter Mobile source of account creation | web-access-contract §1 | BR-WEB-001, Q-016, ADR-006 | ✅ |

---

## 5. Requirement Coverage Matrix

(Consolidated traceability verified per contract; each contract's own Traceability section was cross-checked against `requirements.md`/`business-rules.md`/`open-questions.md`.)

| Contract | Key requirements/decisions covered | Gap |
|---|---|---|
| `auth-contracts.md` | FR-AUTH-001..007, FR-ONBOARD-001..005, FR-SETTINGS-003/005/006, FR-WEB-AUTH-001..004, BR-AUTH-001..004, BR-BUS-001..003, BR-WEB-001..004/006, Q-001..004, Q-015, Q-016 | none |
| `web-access-contract.md` | FR-SETTINGS-003, FR-WEB-AUTH-001..004, FR-WEB-SETTINGS-002, BR-WEB-001..006, Q-004/015/016/017 | none |
| `transaction-contracts.md` | FR-CAPTURE-007, FR-TRANS-001..013, FR-REVIEW-001..007, FR-AI-001..009, FR-WEB-TRANS-001..006, BR-REC-002, BR-CONFIRM-001, BR-TRANS-001..007, BR-AI-001, NFR-DATA-001, Q-005/006/017/022 | none |
| `category-contracts.md` | FR-CATEGORY-001..005, FR-WEB-CATEGORY-001..003, BR-CATEGORY-001..008, Q-010/021 | API-L1 (labels) |
| `report-contracts.md` | FR-DASH-001..007, FR-WEB-DASH-001..005, FR-WEB-REPORT-001..002, BR-REPORT-001..004, Q-011/012/019 | none |
| `export-contracts.md` | FR-EXPORT-001..004, FR-WEB-REPORT-003, BR-EXPORT-001..003, Q-012/013/014 | none |
| `storage-contracts.md` | FR-REVIEW-005/006, FR-TRANS-009/013, FR-WEB-TRANS-004, BR-REC-003/004, BR-CONFIRM-001, BR-TRANS-003, NFR-SEC-001/002, NFR-DATA-001 | none |
| `ai-edge-function-contract.md` | FR-AI-001..009, FR-CATEGORY-002, BR-AI-001..005, BR-CONFIRM-001, NFR-DATA-001, NFR-PERF-001, Q-007/008/009 | none |
| `data-access-contracts.md` | all CRUD + auth + AI + settings + account | API-M2 (ordering) |

**Requirement coverage verdict:** Complete. No required MVP behavior is unmodeled. The two gaps (web create, offline/real-time) are correctly *scoped out*, matching the concluded decisions.

---

## 6. Client / Server / Edge / Gemini Responsibility Matrix

| Operation | Flutter Mobile | Next.js Dashboard | Edge Function | Gemini | Persisted |
|---|---|---|---|---|---|
| Phone OTP auth | ✅ direct (Auth SDK) | — | — | — | auth |
| Magic-link login | — | ✅ direct (Auth SDK/SSR) | — | — | auth |
| Onboarding (create business) | ✅ direct (INSERT) | — | — | — | businesses + defaults (trigger) |
| Read/update business profile | ✅ | ✅ | — | — | businesses |
| Enable web access (link email) | ✅ direct (Auth identity + UPDATE) | — | — | — | auth identity + businesses |
| Disable/unlink web access | ✅ | ✅ | — | — | businesses |
| Receipt capture → AI | ✅ (capture + POST) | — | ✅ `extract-receipt` | ✅ | none (ephemeral) |
| Review & Edit → confirm save | ✅ direct (multi-INSERT + storage) | — | — | — | transactions/items/receipts/ai_extractions + storage |
| Manual entry | ✅ direct | ❌ (Q-005) | — | — | transactions/items |
| List/filter/search transactions | ✅ | ✅ | — | — | read |
| Read transaction detail | ✅ | ✅ | — | — | read |
| Update transaction | ✅ | ✅ | — | — | transactions/items |
| Delete transaction | ✅ | ✅ (storage + DB) | — | — | delete |
| Reports (summary/breakdown/comparison) | ✅ | ✅ | — | — | read (aggregate) |
| Export (PDF/Excel/CSV) | ✅ client-side | ✅ client-side | — | — | file (no server) |
| Category CRUD | ✅ | ✅ (SELECT/INSERT/UPDATE/DELETE per RLS) | — | — | categories |
| View receipt image | ✅ (signed URL) | ✅ (signed URL) | — | — | read (storage) |
| Account deletion | ✅ request | — | ✅ admin (`service_role`) | — | delete |

**Verdict:** The matrix is fully consistent with ADR-API-001/002/003 and `web-access-contract.md` §7. No operation is assigned to a boundary that contradicts its accepted design. The only server-side component is the `extract-receipt` Edge Function (AI) and the admin account-deletion Edge Function (deletion).

---

## 7. Security Review

| Control | Contract | Authority | Status |
|---|---|---|---|
| Anon key in clients is not a secret (project identifier) | ADR-API-003 | Supabase model | ✅ |
| RLS per-owner isolation on all 6 tables | ADR-API-003 §Layer 2 | rls-matrix §4 | ✅ (API-M1 corrected) |
| `current_business_id()` injection via JWT; no client `business_id` | data-access-contracts §1 | rls-matrix §3 | ✅ |
| Immutable tables (receipts) no UPDATE | storage-contracts §6, ADR-API-003 | rls-matrix §4 | ✅ (API-M1 corrected) |
| AI provenance (ai_extractions) no UPDATE/DELETE | ADR-API-003, transaction-contracts | rls-matrix §4 | ✅ (API-M1 corrected) |
| businesses no DELETE (admin account removal) | ADR-API-003, auth-contracts §5 | rls-matrix §4, ADR-DB-005 | ✅ (API-M1 corrected) |
| Private storage, owner-prefixed paths, no public URLs | storage-contracts | storage-design, NFR-SEC-002 | ✅ |
| Web-access gate is server-side per-request, not RLS relaxation | web-access-contract §5, auth-contracts §6 | rls-matrix §1, ADR-006, Q-015 | ✅ |
| Gemini key server-side only | ai-edge-function-contract §10 | BR-AI-005, Q-007 | ✅ |
| Service role only in admin Edge Function | ADR-API-003, auth-contracts §5 | ADR-DB-005 | ✅ |
| JWT verified (`verify_jwt=true`) on Edge Function | ai-edge-function-contract §3.1 | ADR-API-002 | ✅ |
| Business-ownership check before AI spend | ai-edge-function-contract §10 | ADR-API-002 | ✅ |
| Email linking is a direct client operation (no Edge Function) | auth-contracts §3.3, web-access-contract §2 | ADR-006, Q-016 | ✅ (API-L2 fixed) |
| No secrets in client bundles/logs | auth-contracts §6, ADR-API-003 | | ✅ |

**Verdict:** The security boundary is correct and consistent. The RLS matrix in `ADR-API-003` overstated access to `businesses` (DELETE), `receipts` (UPDATE), and `ai_extractions` (matched), and listed email linking as Edge Function–mediated; both are corrected. No security regression risk remains.

---

## 8. Authentication Flows

| Flow | Contract | Authority | Status |
|---|---|---|---|
| Mobile phone + OTP (sign-up/login merged) | auth-contracts §2.1 | FR-AUTH-001..005, Q-001/002 | ✅ |
| 60s resend cooldown | auth-contracts §2.1/§7 | Q-001 | ✅ |
| Persistent session, no inactivity timeout | auth-contracts §2.2 | Q-003 | ✅ |
| Splash routing by session | auth-contracts §2.2 | FR-AUTH-007 | ✅ |
| Onboarding gate → business + seeded defaults | auth-contracts §2.3 | FR-ONBOARD-001..005 | ✅ |
| Web magic link, no self-signup | auth-contracts §3.1, web-access-contract §3 | BR-WEB-001, Q-004 | ✅ |
| Unlinked-email pre-check | auth-contracts §3.1, web-access-contract §3 | FR-WEB-AUTH-002 | ✅ |
| Web per-request re-check | auth-contracts §3.2, web-access-contract §5 | Q-015, BR-WEB-006 | ✅ |
| Enable/unlink (web_email lifecycle) | auth-contracts §3.3, web-access-contract §2/§6 | MEDIUM-02 (implementation report §4) | ✅ |
| Logout (mobile + web) | auth-contracts §4 | FR-SETTINGS-005, FR-WEB-SETTINGS-003 | ✅ |
| Account deletion via admin Edge Function | auth-contracts §5 | ADR-DB-005 | ✅ |

**Verdict:** All auth flows match the accepted decisions and the implemented schema (`businesses.web_access_enabled`, `web_email` partial UNIQUE; unlink clears both — verified PASS in implementation report §4).

---

## 9. Data Access Review

| Operation | Contract | RLS predicate | Index | Status |
|---|---|---|---|---|
| Create transaction (manual/AI confirm) | transaction-contracts §2/§3, data-access §2.4 | `business_id = current_business_id()` | — | ✅ (API-M2 corrected) |
| List (default month) | transaction-contracts §4 | same | I1 `(business_id, transaction_date)` | ✅ |
| Filter (date/category/type/amount) | transaction-contracts §5 | same | I1/I2/I3/I4 | ✅ |
| Search party_name | transaction-contracts §6 | same | I6 trgm `lower(party_name)` | ✅ (Q-022) |
| Read detail (items/receipt/extraction) | transaction-contracts §7 | same (all tables) | — | ✅ |
| Update transaction | transaction-contracts §8 | UPDATE USING+CHECK | — | ✅ LWW (Q-006) |
| Delete transaction (+cascade+storage) | transaction-contracts §9 | DELETE USING | — | ✅ |
| Categories CRUD | category-contracts §3–§7 | owner/custom guards | U3, I3 | ✅ (HIGH-01) |
| Reports aggregates | report-contracts | `business_id = current_business_id()` | I1/I2/I3 | ✅ |
| Exports | export-contracts | data already scoped | — | ✅ |

**Verdict:** All data-access paths resolve through `current_business_id()`, align with the index plan (indexes.md), and honor the certified constraints (CHECKs, UNIQUE U1–U8, composite FKs, RESTRICT on category delete, CASCADE on items/receipts/extractions). Cross-checked against `database-implementation-report.md` §3–§5.

---

## 10. Storage Review (`receipts` bucket)

| Aspect | Contract | Authority | Status |
|---|---|---|---|
| Private bucket, no public URLs | storage-contracts §1 | storage-design, NFR-SEC-002 | ✅ |
| Path `{business_id}/{transaction_id}/receipt.ext` | storage-contracts §2 | storage-design, ADR-DB-004 | ✅ |
| Uniqueness (`storage_path`, `transaction_id`) | storage-contracts §2, transaction-contracts §10 | indexes U6/U7 | ✅ |
| Row-first upload ordering | storage-contracts §3, transaction-contracts §3.2 | data-access-patterns §1.4 | ✅ (API-M2 clarifies AI ordering) |
| Owner-scoped SELECT/INSERT/DELETE; no UPDATE | storage-contracts §6 | rls-matrix §5 | ✅ |
| 20 MB max, image MIME CHECK | storage-contracts §1 | schema CHECKs | ✅ |
| Account deletion enumerates bucket | storage-contracts §7 | ADR-DB-005 | ✅ |
| No pre-confirmation upload | storage-contracts §3 | BR-CONFIRM-001, NFR-DATA-001 | ✅ |

**Verdict:** Storage contract is complete and matches the implemented private bucket and policies (implementation report §4/§5). No `UPDATE` policy, no public access, owner-prefix auth all correct.

---

## 11. AI Extraction & Edge Function Review

| Aspect | Contract | Authority | Status |
|---|---|---|---|
| Model = Gemini 3.1 Flash-Lite | ai-edge-function-contract §4/§13 | Q-007 (approved 3.1, not 2.5) | ✅ |
| Single Edge Function, stateless, no persistence | ai-edge-function-contract §1/§9 | ADR-API-002 | ✅ |
| `verify_jwt=true`, ownership check before AI | ai-edge-function-contract §3.1 | ADR-API-002 | ✅ |
| Multipart request (image, transaction_type, category_list) | ai-edge-function-contract §2.2 | data-access §2.8 | ✅ |
| Structured JSON output with confidences | ai-edge-function-contract §4.2 | FR-AI-002/003 | ✅ |
| <80% field flag; <50% or missing-required = failure | ai-edge-function-contract §6 | Q-008 | ✅ |
| 15s client-visible timeout; distinct server timeout | ai-edge-function-contract §7 | Q-009, FR-AI-008 | ✅ |
| Manual entry fallback (no dead ends) | ai-edge-function-contract §8 | FR-AI-005/006/008/009 | ✅ |
| Client confirms → then persist (multi-step row-first) | ai-edge-function-contract §9 | NFR-DATA-001, BR-CONFIRM-001 | ✅ (API-M2 clarifies `ai_extractions` ordering) |

**Verdict:** AI contract is fully consistent with the approved model selection and the confirm-before-persist rule. The Edge Function never persists data; the client performs the confirmed multi-table commit. The DB `ai_extractions` provenance is inserted by the client in that same commit (guarded by MEDIUM-01).

---

## 12. Web Access Review

| Aspect | Contract | Authority | Status |
|---|---|---|---|
| Optional, mobile-driven enablement | web-access-contract §1 | FR-SETTINGS-003, BR-WEB-002 | ✅ |
| Same `auth.uid()` (one user/one business) | web-access-contract §1 | Q-016, ADR-006 | ✅ |
| Magic link, no independent signup | web-access-contract §3 | BR-WEB-001, Q-004 | ✅ |
| Per-request re-check; no real-time disconnect | web-access-contract §5 | Q-015, BR-WEB-006 | ✅ |
| Unlink clears `web_email` + `web_access_enabled` | web-access-contract §6 | MEDIUM-02 (implementation verified) | ✅ |
| Web read/edit/delete; no create | web-access-contract §7 | Q-005/017 | ✅ |
| Not an RLS layer | web-access-contract §10 | rls-matrix §1, ADR-006 | ✅ |

**Verdict:** Web access contract exactly mirrors the accepted model and the implemented web-email lifecycle. No RLS complication is introduced; the gate is purely per-request server-side.

---

## 13. Edge-Function Boundary Review (coverage of server-side operations)

| Server-side operation | Mediation | Contract | Authority | Status |
|---|---|---|---|---|
| AI extraction | Edge Function (`extract-receipt`) | ai-edge-function-contract | ADR-API-002 | ✅ |
| Account deletion | Edge Function (`account-deletion`, service_role) | auth-contracts §5, data-access §2.9 | ADR-DB-005 | ✅ |
| Web-access per-request gate | Next.js server (data-access path) gate, not SDK-less; on requests | web-access-contract §5, auth-contracts §3.2 | ADR-006 | ✅ |
| Email linking | **NOT an Edge Function — direct client** | auth-contracts §3.3, web-access-contract §2 | ADR-006, Q-016 | ✅ (API-L2/API-M2 corrected in ADR-API-003) |

**Comment:** ADR-006 §"Implementation notes" and `auth-contracts` confirm email linking is direct client (Supabase Auth identity linking + RLS UPDATE businesses). ADR-API-003's Layer 3 had incorrectly listed it as Edge Function–mediated; corrected. The Next.js per-request web-access gate lives in the dashboard's server data-access path as an authorization gate (not a database object).

---

## 14. RLS Consistency: `docs/api` vs `docs/database/rls-matrix.md`

| Table | rls-matrix (authority) | ADR-API-003 (before) | ADR-API-003 (after) | Verdict |
|---|---|---|---|---|
| `businesses` | SELECT/INSERT/UPDATE (no DELETE) | SELECT/UPDATE/DELETE (no INSERT) | SELECT/INSERT/UPDATE (no DELETE) | FIXED |
| `categories` | SELECT/INSERT/UPDATE/DELETE | ✓ | ✓ | ✅ |
| `transactions` | SELECT/INSERT/UPDATE/DELETE | ✓ | ✓ | ✅ |
| `transaction_items` | SELECT/INSERT/UPDATE/DELETE | ✓ | ✓ | ✅ |
| `receipts` | SELECT/INSERT/DELETE (no UPDATE) | SELECT/INSERT/UPDATE/DELETE | SELECT/INSERT/DELETE (no UPDATE) | FIXED |
| `ai_extractions` | SELECT/INSERT (no UPDATE/DELETE) | SELECT/INSERT | SELECT/INSERT (no UPDATE/DELETE) | ✅ |

**Verdict:** ADR-API-003 now matches the DB authority. Every policy predicate is owner-scoped; immutable tables (receipts) have no UPDATE; provenance and businesses have no DELETE where required. This resolves the candidate RLS finding.

---

## 15. Transaction / Category Model Review

| Aspect | Contract | Authority | Status |
|---|---|---|---|
| `type IN ('income','expense')` | transaction-contracts §1/§10 | ADR-DB-002, schema | ✅ |
| `amount numeric(14,2) > 0`, EGP pinned | transaction-contracts §10 | schema | ✅ |
| `party_name` nullable ≤255 | transaction-contracts §10 | LOW-03 (implementation verified) | ✅ |
| `entry_source IN ('manual','ai')` + provenance pairing | transaction-contracts §10 | MEDIUM-01 (guard) | ✅ (API-M2 makes ordering explicit) |
| No invariant `SUM(items)=amount` | transaction-contracts §10 | ADR-DB-002 | ✅ |
| `updated_at` trigger on mutable tables only | transaction-contracts §10 | schema, implementation report | ✅ |
| Category: defaults seeded, undeletable, custom editable | category-contracts §1/§2 | HIGH-01, Q-010/021 | ✅ (API-L1 labels fixed) |
| Custom rename works; default rename blocked | category-contracts §5.2 | HIGH-01 (verified PASS) | ✅ |
| Hidden-not-deleted; valid for history/filters | category-contracts §5.1 | Q-010 | ✅ |
| In-use category delete blocked (RESTRICT) | category-contracts §6 | composite FK | ✅ |

**Verdict:** Fully aligned. The transaction `type` display labels (`income`→"مبيعات / إيرادات" Sale/Income; `expense`→"مشتريات / مصروفات" Purchase/Expense) are transaction-type labels distinct from category names and are consistent across contracts and the Edge Function's `transaction_type` param.

---

## 16. Seed Data / Defaults Review

| Aspect | Contract | Authority | Status |
|---|---|---|---|
| 10 default categories (Q-010 English list) | category-contracts §2 | Q-010 | ✅ |
| Arabic `categories.name` matches seeded values | category-contracts §2 | database-design §seed, ADR-DB-003, migration 009 | ✅ (API-L1 fixed: `مرتبات`, `فواتير`, `نقل`, `ضرائب ورسوم`) |
| Seeder via AFTER INSERT trigger, trigger-only | category-contracts §2 | HIGH-02 (implementation verified) | ✅ |
| Insert-only `type='custom'` RLS | category-contracts §4, ADR-API-003 | rls-matrix §4 | ✅ |
| Duplicate names blocked via `name_key` | category-contracts §4 | U3, Q-021 | ✅ |

**Verdict:** The default list's English names match Q-010 exactly. Arabic labels now match the authoritative `/seeded` `categories.name` values (the strings clients will read, display, and pass to Gemini category matching). Corrected in this review.

---

## 17. Edge Cases / Offline / Real-time / Error Handling

| Case | Contract position | Authority | Status |
|---|---|---|---|
| Offline capture | not MVP; block with message | Q-018 | ✅ |
| Real-time sync | not MVP; LWW concurrency | Q-006 | ✅ |
| Web mid-session unlink | next request rejected → disabled state | Q-015 | ✅ |
| AI timeout (15s) | manual-entry fallback, no dead end | Q-009 | ✅ |
| Extraction failure + non-receipt | route to manual entry | Q-008, FR-AI-009 | ✅ |
| Orphan image on partial write | best-effort cleanup by app | storage-design §5/§8 | ✅ |
| RLS denial | empty result / 403, no leak | data-access §3.1 | ✅ |
| Constraint violation | 400 with PG error code | data-access §3.1 | ✅ |
| Auth failure | 401 → login route | data-access §3.1 | ✅ |
| Zero-division in comparison | handled client-side | report-contracts §4 | ✅ |
| Duplicate category name | 409/400 friendly | category-contracts §4, data-access §2.3 | ✅ |

**Verdict:** Every error path has a defined recovery; no dead ends. Matches the architecture's "no dead ends" principle (ADR decisions README).

---

## 18. Corrections Applied (Before → After → Reason)

All corrections are confined to `docs/api/**`. No requirements/architecture/database doc was modified.

### API-M1 — RLS matrix overstated access in `ADR-API-003` (MEDIUM)

- **File:** `docs/api/decisions/ADR-API-003-client-security-boundary.md` §"Layer 2: Authorization (RLS Policies)".
- **Before:** `businesses` → SELECT/UPDATE/DELETE; `receipts` → SELECT/INSERT/UPDATE/DELETE; `ai_extractions` → SELECT/INSERT.
- **After:** `businesses` → SELECT/INSERT/UPDATE (owner `owner_id = auth.uid()`, no DELETE); `receipts` → SELECT/INSERT/DELETE (immutable, no UPDATE); `ai_extractions` → SELECT/INSERT (immutable provenance, no UPDATE/DELETE), plus a note pinning access classes to `rls-matrix.md` §4/§6.
- **Reason:** Contract must be implementable without an implementer re-deriving the security model; a developer following the old table would have created missing/incorrect policies (e.g., a `businesses` DELETE or a `receipts` UPDATE policy) that contradict the reviewed, implemented RLS.

### API-M2 — AI persistence ordering in `data-access-contracts.md` §2.4 (MEDIUM)

- **File:** `docs/api/data-access-contracts.md`, operation "Create Transaction (after confirmation)", Security row.
- **Before:** "Row-first ordering: INSERT transaction → upload image → INSERT receipt + ai_extractions".
- **After:** "Row-first ordering: INSERT transaction → INSERT ai_extractions → upload image → INSERT receipt; all within the confirmation commit (the `transactions_ai_provenance_guard` trigger requires an `entry_source='ai'` transaction to be accompanied by its matching `ai_extractions` row, so both inserts share the same client call/transaction — see `data-access-patterns.md` §1.4); on failure: compensate by deleting partial rows, clean orphan image best-effort."
- **Reason:** The `<80%`/MEDIUM-01 provenance-guard means `ai_extractions` must be inserted in the same client call/transaction as the `entry_source='ai'` transaction INSERT, and the canonical order (data-access-patterns §1.4) places it immediately after the transaction and **before** the storage upload. The old wording implied `receipt` + `ai_extractions` were inserted together after upload, which is both out-of-order and risks violating the guard. (This matches the already-correct `transaction-contracts.md` §3.2 and `ai-edge-function-contract.md` §9.)

### API-L1 — Default category Arabic labels drifted in `category-contracts.md` (LOW)

- **File:** `docs/api/category-contracts.md` §2 table.
- **Before:** `مشتريات / مخزون`, `رواتب`, `مرافق (كهرباء، مياه، etc.)`, `نقل ومواصلات`, `ضروب ورسوم`.
- **After:** `مبيعات`, `مشتريات`, `إيجار`, `مرتبات`, `فواتير`, `نقل`, `تسويق`, `صيانة`, `ضرائب ورسوم`, `أخرى` (matching the authoritative/`seeded` list in `database-design.md` §Seed list, `ADR-DB-003`, and migration `009`).
- **Reason:** These are the stored `categories.name` values that clients display in pickers and that Gemini's `suggested_category` matches against; the contract must use the exact strings the seeder writes. English names already matched Q-010.

### API-L2 — Email-linking mediation in `ADR-API-003` Layer 3 (LOW, folded into API-M1's file edit)

- **File:** `docs/api/decisions/ADR-API-003-client-security-boundary.md` §"Layer 3: Server-Side Mediation".
- **Before:** listed "Email linking | Edge Function | Auth identity management".
- **After:** removed email linking from the Edge Function table (retains only AI extraction and account deletion), and added an explicit note that email linking is a direct client operation (Supabase Auth identity link + RLS UPDATE `businesses`) per `auth-contracts.md` §3.3, `web-access-contract.md` §2, and `ADR-006`.
- **Reason:** ADR-006, auth-contracts, web-access-contract, and Q-016 all specify direct client linking; listing an Edge Function would lead an implementer to build a non-existent endpoint. No Edge Function is required for enable/disable.

### API-L3 — Stale Gemini model in `AGENTS.md` (LOW — **not edited**)

- **Location:** `AGENTS.md` (repo root) design summary: "Gemini 2.5 Flash-Lite".
- **Authority:** `Q-007`, `open-questions.md`, `ai-architecture.md`, `ai-edge-function-contract.md`, and `ADR-API-002` all say **Gemini 3.1 Flash-Lite**.
- **Status:** REPORT ONLY. `AGENTS.md` is outside `docs/api/**` and was not modified per the review constraint. The contracts (the actionable deliverable) are correct. Recommend updating `AGENTS.md` in a separate task so future agents don't act on the stale model name.

---

## 19. Approval Status & Gate Criteria

### Gate criteria (none may be failing for APPROVED)

| Gate | Result |
|---|---|
| No unresolved CRITICAL findings | ✅ none present |
| No unresolved HIGH findings | ✅ none present |
| No unresolved MEDIUM findings | ✅ API-M1, API-M2 closed by corrections |
| Contracts implementable without re-deriving decisions | ✅ after corrections |
| RLS model matches DB authority | ✅ after API-M1 |
| AI model / confidence / timeout match approved values | ✅ 3.1 Flash-Lite, <80%, <50%, 15s |
| No REST API layer; only `extract-receipt` (+ admin delete) | ✅ |
| Web-access gating not conflated with RLS | ✅ |
| Confirm-before-persist honored in all AI paths | ✅ (API-M2 makes ordering explicit) |

### Status

**APPROVED WITH CONDITIONS**

The `docs/api/**` contracts are correct, complete, and implementation-ready relative to the approved requirements, architecture, and the **COMPLETE** database implementation. The two MEDIUM and two LOW documentation defects were corrected in this review (all confined to `docs/api/**`); the only open item, the stale Gemini model string in `AGENTS.md`, is outside the editable scope and is reported for a follow-up.

### Conditions

1. **Implement `docs/api/**` as corrected in this review.** Future agents/developers must treat the corrected ADR-API-003 RLS matrix, the AI persistence ordering in `data-access-contracts.md` §2.4, and the `category-contracts.md` default list as authoritative.
2. **Update `AGENTS.md`** to use "Gemini 3.1 Flash-Lite" (aligning with Q-007) in a separate `docs/` task, so repo-level guidance matches the approved model.
3. **No new server-side operations may be introduced** beyond the `extract-receipt` Edge Function and the account-deletion admin function without a new ADR under `docs/api/decisions/` (the scenario of Option B persistence in ADR-API-002 remains rejected).
4. **Web-access gating remains a per-request server-side check** (Next.js server data path), not an RLS/DB layer — any future change must go through a new ADR.

---