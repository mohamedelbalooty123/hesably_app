# Database Design Review

Smart Invoice Assistant — MVP. A rigorous architectural and security review of the existing `docs/database/` design against the finalized requirements and architecture, performed **before** any implementation.

| | |
|---|---|
| **Review date** | 2026-08-31 |
| **Reviewer** | Senior Database Architect / Supabase Architect / Database Reviewer |
| **Scope** | Supabase (PostgreSQL) schema, RLS, storage, indexes, migrations |
| **Result** | **APPROVED WITH CONDITIONS** |
| **Inputs** | `docs/requirements/*`, `docs/architecture/*`, `docs/database/*`, AGENTS.md |

---

## 1. Review Scope

Review-only. **No SQL was executed; no migrations created; no Supabase project modified.** Only `docs/database/**` were consulted and (where corrected) updated.

Reviewed source of truth:

- **Requirements**: `requirements.md`, `business-rules.md`, `assumptions.md`, `open-questions.md`, `acceptance-criteria.md`, `feature-list.md`, `user-flow-mobile.md`, `user-flow-dashboard.md`
- **Architecture**: `system-architecture.md`, `backend-architecture.md`, `ai-architecture.md`, `mobile-architecture.md`, `dashboard-architecture.md`, `decisions/*.md`
- **Database design**: `database-design.md`, `schema.md`, `relationships.md`, `rls-matrix.md`, `indexes.md`, `storage-design.md`, `data-access-patterns.md`, `migration-plan.md`, `decisions/ADR-DB-001…005`

---

## 2. Executive Summary

The existing design is **fundamentally sound and secure**. It correctly implements all six business tables with composite same-tenant foreign keys, Row Level Security on every table and the private storage bucket, confirm-gated AI persistence, a private owner-scoped receipt bucket, `numeric(14,2)` money, `TEXT+CHECK` enums, and a clean additive migration path. The ownership chain (`auth.uid() → businesses → business data`), composite-FK isolation, and storage path ownership are all correctly designed; no **CRITICAL** issue was found.

The review surfaced **2 HIGH** findings, **3 MEDIUM** findings, and **3 LOW** findings. Both HIGH findings have concrete, single-file corrections (documented in §18 and applied to `docs/database/**`):

1. **Category guard trigger over-reach** — it currently blocks renaming *custom* categories, contradicting FR-CATEGORY-004 / BR-CATEGORY-005 (custom categories are editable).
2. **`SECURITY DEFINER` seeder EXECUTE exposure** — the seeder lives in `public` and is technically callable by `authenticated` via the Data API, allowing cross-tenant default-category insertions; the design must revoke EXECUTE.

Neither requires a redesign. The conditions that gate approval are listed in §18 and encoded in `database-implementation-plan.md`.

---

## 3. Requirements Coverage

Legend: ✅ Supported · 🟡 Partially supported · ⚪ Not supported · ➖ Out of MVP scope (correctly unmodeled)

| Requirement area | Database support | Entities | Status | Issue |
|---|---|---|---|---|
| Phone + OTP authentication | tenant root per authed user | `businesses.owner_id`, Supabase Auth | ✅ | auth itself lives in Supabase Auth; DB stores ownership |
| Business onboarding | create business + auto-seed defaults | `businesses`, trigger → `categories` | ✅ | |
| Receipt capture | manual entry path exists; camera/gallery is client | `transactions` (`entry_source='manual'`) | ✅ | |
| AI extraction | immutable provenance snapshot post-confirm | `ai_extractions` | ✅ | written only after confirmation |
| Review / Edit | transactions + line items editable | `transactions`, `transaction_items` | ✅ | |
| Categories | defaults + custom, hideable, undeletable defaults | `categories` | ✅ | see HIGH-01 (custom rename) |
| Transactions | income/expense ledger events | `transactions` | ✅ | |
| Line items | optional items | `transaction_items` | ✅ | |
| Receipt images | 0..1 per transaction, private bucket | `receipts` + `storage` | ✅ | |
| Reports | period + category/type/amount aggregates | `transactions` + indexes | ✅ | live aggregation; no report tables |
| Exports | period + active-filter scoped reads | `transactions` | ✅ | client-side generation from RLS reads |
| Settings / profile | editable business | `businesses` | ✅ | |
| Web access | opt-in flag + linked email, server-side gate | `businesses.web_access_*` | ✅ | see MEDIUM-02 (unlink lifecycle) |
| Web transaction edit/delete | same RLS identity, owner-scoped | `transactions`, RLS | ✅ | |
| Web transaction create | blocked at application layer (not DB) | — | 🟡 | DB cannot distinguish mobile vs web (same auth.uid()); see LOW-03 |
| Search (vendor/customer) | trigram GIN on `lower(party_name)` | `transactions` + I6 | ✅ | |
| Filtering (date/category/type/amount) | composite indexes | `transactions` indexes | ✅ | |
| Date ranges | `DATE` type + date-range queries | `transactions` | ✅ | |

No MVP requirement is unmodeled. No unnecessary/out-of-scope feature is modeled.

---

## 4. Business Rule Coverage

| Business rule | Enforced by | Status |
|---|---|---|
| BR-AUTH-001/002 phone+OTP only | Supabase Auth / app (not schema) | ✅ (not a DB concern) |
| BR-BUS-001 mandatory business on first login | `businesses` INSERT, RLS `WITH CHECK owner=auth.uid()` | ✅ |
| BR-BUS-003 default currency EGP | `currency_code CHECK = 'EGP'` | ✅ |
| BR-TRANS-001 transaction type | `type CHECK IN ('income','expense')` | ✅ |
| BR-TRANS-003 delete removes record + image | RLS DELETE + storage DELETE / cascade | ✅ |
| BR-REC-004 private bucket | private bucket + owner-path policies | ✅ |
| BR-AI-001 confirm before save | `ai_extractions` written only post-confirm (RLS + app) | ✅ |
| BR-CONFIRM-001 confirm before persistence | row-first, confirm-gated commit | ✅ |
| BR-CATEGORY-001 defaults seeded | AFTER INSERT trigger | ✅ |
| BR-CATEGORY-004 defaults hidden not deleted | RLS DELETE `type='custom'`; `is_hidden` editable | ✅ |
| BR-CATEGORY-005 custom editable/deletable | **blocked by guard trigger** | 🟡 → **HIGH-01** |
| BR-CATEGORY-006 shared category table | single `categories` table | ✅ |
| BR-CATEGORY-008 no duplicate after normalization | `UNIQUE(business_id, name_key)` | ✅ |
| BR-REPORT-001 breakdown sorted by spend | aggregate queries | ✅ |
| BR-EXPORT-001/002 export scope + formats | RLS-scoped reads + client generation | ✅ |
| BR-WEB-002 email links to existing user | `web_email` + Supabase identity link | ✅ |
| BR-SEC-001 data isolation by owner | RLS on all 6 tables | ✅ |
| BR-MVP-004 offline OUT | not modeled | ✅ correctly absent |
| BR-MVP-005 web create OUT | app-level guard | ✅ (see LOW-01) |

---

## 5. Schema Review

Six business tables: `businesses`, `categories`, `transactions`, `transaction_items`, `receipts`, `ai_extractions`. This is exactly the right MVP surface — no double-entry, no inventory, no payroll, no multi-currency, no audit tables, no soft delete. See §15 for scope verification.

**Approved schema** (with the corrections in §18 applied):

| Table | Mutability | Key integrity |
|---|---|---|
| `businesses` | mutable | `owner_id` UNIQUE (1:1); `currency_code='EGP'`; partial UNIQUE `web_email` |
| `categories` | mutable | `UNIQUE(business_id,name_key)`; `UNIQUE(id,business_id)`; `type` default/custom; guard trigger |
| `transactions` | mutable | `amount>0`; `type`; `transaction_date`; composite FK to categories RESTRICT |
| `transaction_items` | mutable | composite FK to transactions CASCADE; `description`, optional `amount>0` |
| `receipts` | immutable | UNIQUE `transaction_id`; UNIQUE `storage_path`; mime/size CHECK |
| `ai_extractions` | immutable | UNIQUE `transaction_id`; confidence CHECK; no UPDATE/DELETE |

Schema is **normalized appropriately** — the only denormalization is the intentional `business_id` carried on child tables to power RLS predicates and composite same-tenant FKs (documented in `relationships.md` §7, ADR-DB-001).

---

## 6. Relationships Review

**10 foreign keys** (4 single-column tenant-scoping CASCADE + `businesses.owner_id` + 5 composite same-tenant FKs). The composite same-tenant FKs are the strongest isolation guarantee in the design: a child write carries both `business_id` and the parent id, and the FK validates *both* match a same-tenant parent row. **A cross-tenant reference is impossible to construct**, even through a bug or compromised session, independent of RLS.

Delete behavior:

| Deleting | Result |
|---|---|
| auth user (account) | `businesses` + full subtree via `owner_id ON DELETE CASCADE`; storage cleaned by admin fn first |
| business | cascade all children; storage objects cleaned by caller |
| transaction | cascade items, receipt row, extraction row |
| category (in use) | **RESTRICT** — blocked (safe for history) |
| default category | blocked (RLS DELETE `type='custom'`) |

This is correct. No orphan-risk beyond the documented app/admin-compensated storage cleanup.

---

## 7. RLS Review

RLS is enabled on all 6 tables and the storage bucket. Every policy is ownership-scoped via `current_business_id()`; `ato authenticated`-without-predicate style is **not** used anywhere. Per-table verification:

| Table | RLS | SELECT | INSERT (WITH CHECK) | UPDATE (USING/WITH CHECK) | DELETE | Ownership |
|---|---|---|---|---|---|---|
| `businesses` | ✅ | `owner=auth.uid()` | `owner=auth.uid()` | both = `owner=auth.uid()` | none | direct |
| `categories` | ✅ | biz | biz + `type='custom'` | both = biz | biz + `type='custom'` | direct |
| `transactions` | ✅ | biz | biz | both = biz | biz | direct |
| `transaction_items` | ✅ | biz | biz | both = biz | biz | direct |
| `receipts` | ✅ | biz | biz | **none** (immutable) | biz | direct |
| `ai_extractions` | ✅ | biz | biz | **none** (immutable) | **none** (cascade) | direct |

`anon`: zero grants, zero policies → zero access. `service_role`: only the admin Edge Function (account deletion), never exposed to clients.

**Every policy is sound.** `USING` + `WITH CHECK` are both specified for UPDATE on mutable tables, preventing ownership reassignment. The only RLS-adjacent defect is the **seeder EXECUTE exposure** (HIGH-02), which is a function-grant issue rather than a policy-predicate issue.

---

## 8. Storage Review

- **Private** bucket `receipts`; public URLs impossible; `anon` has zero policies.
- Object path `{business_id}/{transaction_id}/receipt.ext`; **segment 1 = ownership predicate**.
- Policies: SELECT/INSERT (WITH CHECK)/DELETE keyed on `(storage.foldername(name))[1] = current_business_id()::text`; **no UPDATE** (immutable images).
- Row-first upload ordering with rollback; **no pre-confirmation upload** (confirm-then-store holds by construction).
- Metadata stays in `receipts` (Postgres); binary content stays in Storage. Clean separation.

Sound. Defense-in-depth gap noted (storage policy can't validate MIME/size — enforced app + DB only), see MEDIUM-03; upload policy cannot be bypassed to another tenant's prefix.

---

## 9. Index Review

18 index structures (8 unique constraints + 10 standalone). Assessment:

| Index | Required / Useful / Redundant / Missing |
|---|---|
| U1 `businesses(owner_id)` | **Required** — hot path for `current_business_id()` |
| U2 `businesses(web_email)` partial | **Required** — unique portal identity |
| U3 `categories(business_id,name_key)` | **Required** — uniqueness + name lookup |
| U4 `categories(id,business_id)` | **Required** — FK target |
| U5 `transactions(id,business_id)` | **Required** — FK target |
| U6 `receipts(transaction_id)` | **Required** — 1:1 + lookup |
| U7 `receipts(storage_path)` | **Useful** — reconciliation/dedupe |
| U8 `ai_extractions(transaction_id)` | **Required** — 1:1 |
| I1 `(business_id,date DESC,created_at DESC)` | **Required** — main list + sort |
| I2 `(business_id,type,date DESC)` | **Useful** — type tab |
| I3 `(business_id,category_id,date DESC)` | **Useful** — category filter |
| I4 `(business_id,amount)` | **Useful** — amount range |
| I5 `(category_id,business_id)` | **Useful** — FK RESTRICT support (overlaps I3 lead; accepted) |
| I6 GIN `lower(party_name)` | **Required** — Arabic contains-search |
| I7 `items(transaction_id)` | **Useful** — FK/join |
| I8 `items(business_id)` | **Useful** — RLS/delete |
| I9 `receipts(business_id)` | **Useful** — RLS |
| I10 `ai_extractions(business_id)` | **Useful** — RLS |

No excessive index on every column; composite indexes align with RLS predicate + sort; correct decision **not** to index `extracted_fields` JSONB (read-only provenance). Missing: none blocking MVP. LOW-04 (party_name bound) touches the trgm index sizing.

---

## 10. Query Pattern Review

| Query (mobile/web) | Filters | Joins | Order | Index used | RLS impact |
|---|---|---|---|---|---|
| List transactions / today | date | categories | date DESC, created DESC | I1 | biz scoped |
| Type tab | type | categories | date DESC | I2 | biz scoped |
| Category tab | category | categories | date DESC | I3 | biz scoped |
| Search by name | `lower(party_name) ILIKE` | — | date DESC | I6 | biz scoped |
| Summary tiles | period | — | — | I1/I2 | biz scoped |
| Category breakdown | period | categories | spend DESC | I3 | biz scoped |
| Detail | id | categories, receipts | — | PK, U6 | biz scoped |
| Export | period + filters | categories | date | I1…I4 | biz scoped |
| Usage count (web categories) | — | count per category | — | I3 | biz scoped |

All major query patterns are covered by a leading-`business_id` index, and RLS injects the same tenant predicate on every path. No materialized views are required for MVP volumes (thousands of rows/year). Sound.

---

## 11. Data Integrity Review

- **Money**: `numeric(14,2)` everywhere; no float; `amount > 0` CHECK; `currency_code='EGP'` pinned. ✅
- **IDs**: `uuid` PK + `gen_random_uuid()`. ✅
- **Dates**: `transaction_date DATE` (business date, no tz); audit stamps `TIMESTAMPTZ`. ✅ Correct distinction.
- **Enums**: `TEXT + CHECK` (not Postgres ENUMs) — removable ALTER friction, keeps client SDKs simple. ✅
- **Status/booleans**: `is_hidden` boolean. ✅
- **Constraints**: named; composite same-tenant FKs; `mime_type LIKE 'image/%'`, `size_bytes` bounds. ✅

Gaps: `entry_source='ai'` → `ai_extractions` pairing is **not** DB-enforced (MEDIUM-01); `party_name` length unbounded (LOW-04). Both documented.

---

## 12. Concurrency Review

- Last Write Wins is the approved MVP rule (Q-006) — correctly **no** optimistic-lock/versioning machinery.
- `created_at` + `updated_at` on every mutable table provide enough metadata for future optimistic concurrency and Phase 2 synchronization/offline reconciliation.
- `updated_at` is maintained by a `set_updated_at()` trigger on the 4 mutable tables; immutable tables omit it. Sufficient.

No over-engineering. ✅

---

## 13. Deletion Review

- **Transaction** → cascade items, receipt row, extraction row; storage object removed by app (owner-scoped). ✅
- **Receipt detach** → owner storage DELETE + row DELETE (both owner-policy-gated). ✅
- **Category** → RESTRICT when in use; default blocked (RLS + trigger); unused custom deletable. ✅ No orphan rows.
- **Account** → admin Edge Function (service_role) deletes storage objects under `receipts/{biz}/…`, then deletes the auth user; `owner_id ON DELETE CASCADE` removes the subtree. ✅
- **AI provenance** → cascade-only; immutable. ✅
- No soft delete / no trash — respects MVP (BR-TRANS-004, ADR-DB-005). ✅

Correct. Requirement: unlinking web access must also clear `web_email` so the global unique is released and re-linking is possible (MEDIUM-02).

---

## 14. Supabase Security Review

- RLS on all 6 tables + storage; `anon` zero access. ✅
- `TO authenticated` always combined with an ownership predicate. ✅
- UPDATE has both `USING` and `WITH CHECK` on every mutable table (blocks ownership reassignment). ✅
- Composite FKs prevent cross-tenant reference independent of RLS. ✅
- Private storage, owner-prefixed paths, no public URLs. ✅
- `service_role` never client-exposed; admin function minimal. ✅
- Web access is a server-side gate, not an RLS relaxation. ✅

Findings:
- **HIGH-02**: `seed_default_categories_for_business()` is `SECURITY DEFINER`, owned by `postgres`, in `public`, and no `REVOKE EXECUTE` is stated. By default Postgres grants EXECUTE to PUBLIC, so `authenticated` could invoke it via the RPC endpoint with an arbitrary `business_id` and seed default categories into a $other tenant's business | tables. Correction: `REVOKE EXECUTE … FROM public, anon, authenticated` so the trigger-only invocation path is the sole entry.

---

## 15. MVP Scope Review

Correctly **not** over-modeled: double-entry accounting, payroll, multi-currency, government tax submission, offline capture/sync, duplicate-receipt hashing, web transaction creation — none are modeled, matching the finalized scope. The schema is a deliberately minimal "income / expense / receipt / category / reporting" model.

---

## 16. Future Extensibility Review

| Future capability | Fit | Blocker? |
|---|---|---|
| Phase 2 e-invoice/e-receipt | additive export mapping; no core change | no |
| Phase 2 multi-user | `auth.uid()→business` generalizes to membership; RLS concept extends | no (clean seam) |
| Phase 2 recurring transactions | new template table; additive | no |
| Phase 2 low-stock | additive inventory tables | no |
| Phase 2 notifications | cron Edge Functions over RLS data | no |
| Phase 2 offline sync | `updated_at` present for reconciliation | no |
| Phase 3 WhatsApp / multi-branch / credit / AI summary | additive ingestion/providers | no |
| Multi-currency (future) | `currency_code` CHECK already has a loosening migration path | no (seam noted) |

No future blocker introduced. ✅

---

## 17. Findings

### Critical
None.

### High

**HIGH-01 — Category guard trigger blocks renaming custom categories**
- **Issue**: `categories_guard_default_immutable()` is specified as rejecting `name`/`name_key`/`type`/`business_id` changes on **any** category row. This makes *custom* categories un-renameable, contradicting **FR-CATEGORY-004 / BR-CATEGORY-005** ("custom categories can be added, edited, and deleted").
- **Why it matters**: the primary category-management feature (edit/rename a custom category) would not work.
- **Affected**: `categories`, guard trigger, ADR-DB-003.
- **Affected requirements**: FR-CATEGORY-004, BR-CATEGORY-005, FR-WEB-CATEGORY-002.
- **Recommended correction**: scope the trigger so that:
  - `business_id` and `type` changes are rejected for **all** categories (prevents cross-tenant move and custom→default / default→custom conversion);
  - `name` / `name_key` changes are rejected **only for `type='default'`** categories (custom rename allowed via RLS-scoped UPDATE).
- **Impact**: restores custom-category editing while keeping default identity immutable.

**HIGH-02 — `SECURITY DEFINER` seeder is publicly executable**
- **Issue**: `seed_default_categories_for_business()` is `SECURITY DEFINER`, owned by `postgres`, lives in `public`, and the design does not revoke EXECUTE. Postgres grants EXECUTE to PUBLIC by default, so any `authenticated` caller could invoke it via the Data API with the `business_id` of a $different tenant and insert default categories into their `categories` table (a cross-tenant write that bypasses RLS).
- **Why it matters**: a privilege-escalation / cross-tenant integrity path.
- **Affected**: seeder function, migration 009.
- **Affected requirements**: NFR-SEC-001, BR-SEC-001.
- **Recommended correction**: `REVOKE EXECUTE ON FUNCTION seed_default_categories_for_business() FROM public, anon, authenticated;` — the function is then reachable **only** by the AFTER INSERT trigger (which runs as the owner/`postgres`, passing the newly created business id). Optionally also add an internal precondition that the provided `business_id` corresponds to a just-created business; the revoke is the primary control.
- **Impact**: removes the only client-reachable surface of the seeder.

### Medium

**MEDIUM-01 — `entry_source='ai'` ↔ `ai_extractions` pairing is not DB-enforced**
- **Issue**: schema.md states an `entry_source='ai'` transaction must be accompanied by an `ai_extractions` row **in the same client call**, but no DB constraint/trigger enforces it. A buggy client could tag a manual transaction `'ai'` without provenance, or drop the extraction row.
- **Why it matters**: provenance completeness (NFR-DATA-001 auditsability) is app-coordinated only.
- **Affected**: `transactions`, `ai_extractions`.
- **Affected requirements**: NFR-DATA-001, FR-AI-*, BR-AI-001.
- **Recommended correction**: add a `BEFORE INSERT OR UPDATE` trigger `transactions_ai_provenance_guard` that rejects `entry_source='ai'` for a row without an existing/inserted `ai_extractions` record (or, as a lighter decision, document it as an accepted app-level contract for MVP and add the trigger as a hardening item). Recommend `trigger` in the implementation plan; accept app-coordination if a minimal trigger is deferred.
- **Impact**: deterministic provenance; removes silent-save drift risk.

**MEDIUM-02 — Web-access unlink lifecycle / `web_email` uniqueness not specified**
- **Issue**: the design pins `web_email` with a global partial UNIQUE and gates web access on `web_access_enabled`, but does not state that unlinking must clear `web_email`. If unlink only toggles the flag, the email stays globally reserved (the same email could never be re-linked, and another business could not claim it).
- **Why it matters**: breaks re-link / rebind flows (BR-WEB-002, Q-015).
- **Affected**: `businesses`.
- **Affected requirements**: BR-WEB-002, BR-WEB-006, FR-WEB-SETTINGS-002.
- **Recommended correction**: document that unlink operation sets `web_access_enabled = false` **and** `web_email = NULL` (releasing the global unique). A single-owner re-link then needs no schema change.
- **Impact**: correct birth/life/revocation lifecycle for web access.

**MEDIUM-03 — Storage policy cannot enforce MIME/size; relies on app + DB CHECK**
- **Issue**: Storage RLS validates only the owner path prefix; it cannot validate file MIME type or size. Enforcement of "images only, ≤ 20 MB" depends on the app and on `receipts.mime_type`/`size_bytes` CHECK constraints. If a client writes a `receipts` row for an arbitrary object, the object itself could be a non-image/oversized blob under the owner's own prefix.
- **Why it matters**: defense-in-depth against invalid/abusive objects; not a cross-tenant risk (owner-scoped), but a data-quality/size risk.
- **Affected**: Storage policies, `receipts`.
- **Affected requirements**: NFR (storage private), storage-design.md §1/§9.
- **Recommended correction**: keep the bucket private and owner-scoped; document that MIME/size are enforced at the app (capture-side downscale + rejection) **and** by `receipts` CHECKs; add a verification asserting no object can be created for a `receipts` row outside those bounds. Revisit server-side thumbnails/validation at Phase 2.
- **Impact**: explicit, verified defense-in-depth; no silent reliance on Storage RLS for arbitrary content.

### Low

**LOW-01 — Web transaction-create is enforced only at the application layer**
- The DB cannot distinguish a "mobile session" from a "web session" (same `auth.uid()`), so `transactions` INSERT remains open to the single owner under RLS. This matches ADR-006 / Q-005/Q-017 (app-level guard), and carries no security-boundary risk (it is the same owner). Ensure the web app does not offer create UI and no separate guard is claimed.
- **Correction**: document as an accepted application-layer control in the implementation plan.

**LOW-02 — Duplicate category-index lead column (I5 overlaps I3)**
- `idx_transactions_category_business` (I5: `categories.category_id, business_id`) shares its lead with `idx_transactions_business_category_date` (I3: `business_id, category_id, transaction_date DESC`). For FK `RESTRICT` delete-time checks a `WHERE category_id = ?` lookup is served by either. Keeping both is acceptable (delete-time correctness over write cost), but the overlap is intentionally retained only because delete-time lookups matter; the redundant double-write is documented.
- **Correction**: retain I5 for FK-support/delete-time correctness; revisit dropping I3's redundancy with real `pg_stat_user_indexes` data post-MVP.

**LOW-03 — `party_name` has no length bound**
- `party_name` is unbounded `TEXT`, feeding the trigram index. Bound it (e.g., ≤ 255) to limit index size and abuse.
- **Correction**: add `CHECK (party_name IS NULL OR length(trim(party_name)) BETWEEN 1 AND 255)`. Low impact.

---

## 18. Corrections Made

Documentation under `docs/database/` was updated to resolve the findings (no SQL, no schema execution):

| Original | Issue | Correction | Reason |
|---|---|---|---|
| `categories_guard_default_immutable()` rejects identity changes on all rows (database-design.md §11, schema.md §2, ADR-DB-003 §4) | Custom rename blocked (HIGH-01) | Reject `business_id`/`type` on all; reject `name`/`name_key` **only on `type='default'`** | Restore FR-CATEGORY-004 edit while keeping defaults immutable |
| Seeder `SECURITY DEFINER` without EXECUTE revoke (migration 009, ADR-DB-003) | Cross-tenant callable via Data API (HIGH-02) | Add `REVOKE EXECUTE … FROM public, anon, authenticated` | Restrict seeder to trigger-only invocation |
| `entry_source='ai'` pairing app-only (schema.md §3, database-design.md §12) | Provenance can drift (MEDIUM-01) | Document + recommend `transactions_ai_provenance_guard` trigger | Deterministic provenance |
| `web_email` unlink lifecycle unspecified (database-design.md §10, ADR-DB-001) | Email stays reserved after unlink (MEDIUM-02) | Document unlink clears `web_access_enabled` and `web_email` | Release global unique on unlink |
| Storage MIME/size app+CHECK only (storage-design.md §1/§9) | No silent reliance on Storage RLS for content (MEDIUM-03) | Note app+DB CHECK enforcement + verification of no invalid object | Confirm defense-in-depth |
| Duplicate category-index lead (indexes.md I5 vs I3) | Redundant index (LOW-02) | Retain I5 for FK RESTRICT delete-time correctness; revisit post-MVP | Delete-time correctness over write cost |
| `party_name` unbounded (schema.md §3) | Trigram index sizing (LOW-03) | Recommend length bound (≤ 255) | Bound index + input |

No ADR was superseded; ADR-DB-003 was updated to reflect the refined trigger semantics and seeder EXECUTE revocation. See `docs/database/decisions/ADR-DB-003-category-model.md`.

---

## 19. Remaining Risks

| Risk | Severity | Mitigation / status |
|---|---|---|
| Seeder privilege escalation if EXECUTE revocation is missed at implementation | HIGH | Encode `REVOKE EXECUTE` in migration 009 and verify via security checks (DoD item) |
| Guard trigger semantics implemented incorrectly (blocks custom rename) | HIGH | Verification test: rename a custom category succeeds; rename a default fails |
| AI provenance pairing drift | MEDIUM | Add `transactions_ai_provenance_guard` trigger + test |
| Web-access email lifecycle bug | MEDIUM | Unlink clears `web_email`; test re-link |
| Storage MIME/size enforcement relies on app + CHECK | MEDIUM | Security verification confirms no invalid objects |
| Redundant category index overlap | LOW | Retain I5; drop-redundancy revisited post-MVP with real stats |
| Last-write-wins silent overwrite (cross-device) | MEDIUM (accepted, Q-006) | Documented; Phase 2 realtime |
| Cross-business leak via RLS misconfig | (guard) | Policy tests mandatory (DoD) |

---

## 20. Approval Status

**APPROVED WITH CONDITIONS**

The design is sound and secure; no unresolved CRITICAL or HIGH issue remains after the conditions below are implemented. Conditions:

1. Apply the two HIGH corrections (custom-category rename + seeder EXECUTE revocation) exactly as specified in §18 and `database-implementation-plan.md`.
2. Implement the MEDIUM refinements (AI-provenance guard trigger, web-email unlink lifecycle) unless the plan's documented risk-acceptance is explicitly approved.
3. Implement per-table RLS policy tests and the storage/security verification defined in the DoD before declaring the Database Implementation phase complete.

If any condition cannot be met, re-review before proceeding.

---

## 21. Migration count planned

12 migrations (extensions → businesses → categories → transactions → transaction_items → receipts → ai_extractions → updated_at → seed → indexes → rls → storage). See `database-implementation-plan.md`.
