# Database Implementation Plan — Smart Invoice Assistant

Bridge from the reviewed database design to an executable Supabase (PostgreSQL) implementation. This document is **planning only** — no SQL is executed, no migrations are created, and no Supabase project is modified by this deliverable.

Derived from: `database-review.md` (status: **APPROVED WITH CONDITIONS**), `database-design.md`, `schema.md`, `relationships.md`, `rls-matrix.md`, `indexes.md`, `storage-design.md`, `data-access-patterns.md`, `migration-plan.md`, `decisions/ADR-DB-001…005`.

---

## 1. Purpose

Define the complete, ordered, and review-approved path to implement the Smart Invoice Assistant MVP datastore on Supabase: six business tables, composite same-tenant foreign keys, Row Level Security on every table and the private storage bucket, the category seeder, and the AI-provenance model — exactly as reviewed, satisfying all review conditions (HIGH-01, HIGH-02 and the MEDIUM/LOW refinements).

The document is the contract the **Database Implementation** phase will execute and verify against. It resolves dependencies, migration order, grants, policies, seed behavior, and the Definition of Done.

---

## 2. Implementation Prerequisites

- **Supabase project** dedicated to this development task (fresh/empty `public` schema, Postgres 15+, RLS-capable). The reviewed design targets Postgres 17 (Supabase). *Target environment identified and confirmed before any write.*
- **Auth configured** so `auth.uid()` and `auth.users` exist (Supabase Auth on by default). The schema references `auth.users` for the `businesses.owner_id` FK.
- **Service role available server-side only** (never in clients) for the admin account-deletion function.
- **Client SDK** (`supabase-js`) for migrations/verification in later phases; database objects created by the DB implementation phase, not the app.
- **Skills**: `supabase`, `supabase-postgres-best-practices` loaded.
- **Review gate passed**: `database-review.md` = `APPROVED WITH CONDITIONS`; conditions listed in §24 (Definition of Done) must close before declaring the phase complete.

---

## 3. Supabase Project Preparation

Before writing migrations:

1. Confirm the target project is empty of conflicting `public` objects (`list_tables` → only `public.*` tables if any, and none named `businesses`/`categories`/`transactions`/`transaction_items`/`receipts`/`ai_extractions`).
2. Verify no prior `.sql` migrations exist for these objects; **do not overwrite existing migrations**.
3. Enable the required extension only once, at the top of the sequence (§6).
4. Use the project's supported migration workflow (imperative migrations via the Supabase CLI/MCP `apply_migration`; create migration files with `supabase migration new`; apply with `supabase db push`). Honor the project's `supabase/config.toml`.
5. Never expose `service_role`/secret keys; use publishable keys in clients.
6. Storage bucket `receipts` does not exist yet — created in migration `012`, not before.

---

## 4. Schema Implementation Order

Dependency-based order (mirrors `migration-plan.md`):

1. Extensions (so GIN/trigram types are available to indexes later).
2. `businesses` (tenant root; nothing depends on it yet).
3. `categories` (depends on `businesses`; guard trigger ships here).
4. `transactions` (depends on `businesses` + `categories`; composite FK to categories).
5. `transaction_items` (depends on `transactions` + `businesses`).
6. `receipts` (depends on `transactions` + `businesses`).
7. `ai_extractions` (depends on `transactions` + `businesses`).
8. `updated_at` trigger function + triggers on the four mutable tables.
9. Category seeder (`SECURITY DEFINER`) + AFTER INSERT trigger on `businesses` + AI-provenance guard trigger.
10. Indexes (standalone + GIN trgm; after tables exist).
11. RLS: helper `current_business_id()` → enable RLS → grants → policies (hardening last).
12. Storage: private bucket + object policies.

Ordering principle: tables/constraints before indexes; RLS last so a table is never exposed without a policy.

---

## 5. Migration Sequence

12 ordered, additive, independent migrations. Each is reversible-in-practice (rollback = drop objects added by that version; see §21).

| # | Name | Purpose | Dependencies | Objects created | Objects modified | Security considerations | Rollback considerations | Verification |
|---|---|---|---|---|---|---|---|---|
| 001 | `extensions` | enable `pg_trgm` for Arabic party-name search (I6) | none | `pg_trgm` extension | — | only required extension; no unnecessary privilege | `DROP EXTENSION` (only if nothing uses it) | `SELECT * FROM pg_extension WHERE extname='pg_trgm'` |
| 002 | `businesses` | tenant root, 1:1 with owner | `auth.users` exists | `businesses` (+ U1, U2-partial, CHECK `name`, `currency_code`) | — | no FK to privileged schema; `owner_id` UNIQUE enforces 1:1 | `DROP TABLE businesses` | table + constraints exist; partial unique present |
| 003 | `categories` | category model + immutability guard | 002 | `categories`, U3, U4, `type` CHECK, `categories_guard_default_immutable()` trigger | — | guard scoped per HIGH-01 (custom rename allowed; default immutable); no cross-tenant move | `DROP TRIGGER` + `DROP TABLE categories` | guard behavior: default rename fails, custom rename succeeds |
| 004 | `transactions` | ledger event | 002, 003 | `transactions`, U5, CHECKs (`type`,`amount>0`,`entry_source`,`party_name` bound), composite FK → categories RESTRICT | — | composite same-tenant FK (category must belong to same business) | `DROP TABLE transactions` | composite FK rejects cross-business category |
| 005 | `transaction_items` | optional line items | 002, 004 | `transaction_items`, composite FK → transactions CASCADE, `business_id` FK | — | DB-level child-to-parent same-tenant FK | `DROP TABLE transaction_items` | delete transaction cascades items |
| 006 | `receipts` | immutable image record | 002, 004 | `receipts`, U6, U7, composite FK → transactions CASCADE, mime/size CHECKs | — | no `updated_at`; immutable | `DROP TABLE receipts` | 1:1 relation; path unique |
| 007 | `ai_extractions` | immutable AI provenance snapshot | 002, 004 | `ai_extractions`, U8, composite FK → transactions CASCADE, confidence CHECK | — | written only post-confirm; immutable (no UPDATE/DELETE policy later) | `DROP TABLE ai_extractions` | 1:1 relation |
| 008 | `updated_at_timestamps` | mutation stamping | 002–007 | `set_updated_at()` fn + triggers on `businesses`,`categories`,`transactions`,`transaction_items` | — | INVOKER only; omitted on immutable tables | `DROP TRIGGER …` arrays + `DROP FUNCTION` | UPDATE changes `updated_at` |
| 009 | `seed_default_categories` | auto-seed defaults + AI provenance guard | 003, 008 | `seed_default_categories_for_business()` (SECURITY DEFINER, `search_path` pinned, owned by `postgres`) + AFTER INSERT trigger on `businesses`; **`REVOKE EXECUTE … FROM public, anon, authenticated`**; `transactions_ai_provenance_guard()` trigger | — | **HIGH-02**: seeder not client-callable; trigger-only path | `DROP TRIGGER` + `DROP FUNCTION` | new business → 10 defaults; `has_function_privilege` EXECUTE false for anon/authenticated |
| 010 | `indexes` | I1–I10 incl. GIN trgm | 002–007 | 10 standalone indexes (I1–I10) | — | none beyond standard | `DROP INDEX` | `EXPLAIN` uses business-lead indexes; trgm GIN present |
| 011 | `rls` | helper + enable RLS + grants + policies | 002–010 | `current_business_id()` (INVOKER/STABLE); RLS on 6 tables; grants; per-table policies | 6 tables (RLS on) | **final hardening**: anon zero access; ownership predicates everywhere; UPDATE USING+WITH CHECK | re-run `DISABLE RLS`/drop policies | see §19 (security verification) |
| 012 | `storage` | private receipt bucket + policies | 011 | bucket `receipts` (private); storage SELECT/INSERT/DELETE policies on `storage.objects` | — | private (no public URL); owner-prefix ownership; no UPDATE | `DROP POLICY`; `DELETE bucket` (storage.migrations unaffected) | see §19 storage verification |

---

## 6. Extensions

- **`pg_trgm`** — required by index I6 (`lower(party_name) gin_trgm_ops`) for substring/`ILIKE` search on Arabic vendor/customer names. Enabled in migration `001`. This is the **only** extension the reviewed design requires.
- Not enabled: `unaccent` (normalization is handled at write time into `name_key` and at query time; `unaccent` may optionally wrap the trgm expression in a later phase if Arabic normalization demands it — designed-out for MVP).
- Every enabled extension is documented in migration `001` with its purpose. Do not enable speculative extensions.

---

## 7. Base Tables

Six tables, exactly per `schema.md` / `database-design.md`. Key shapes:

| Table | Primary identity | Ownership column | Mutability |
|---|---|---|---|
| `businesses` | `id uuid` | `owner_id` (UNIQUE) | mutable |
| `categories` | `id uuid` | `business_id` | mutable (defaults guarded) |
| `transactions` | `id uuid` | `business_id` | mutable |
| `transaction_items` | `id uuid` | `business_id` (denormalized) | mutable |
| `receipts` | `id uuid` | `business_id` (denormalized) | immutable |
| `ai_extractions` | `id uuid` | `business_id` (denormalized) | immutable |

- **`businesses`**: `owner_id` UNIQUE FK→`auth.users(id)` CASCADE; `name` CHECK 1..100; `currency_code` CHECK `= 'EGP'`; `web_access_enabled boolean DEFAULT false`; `web_email text` nullable with **partial UNIQUE WHERE web_email IS NOT NULL**; `created_at`/`updated_at` TIMESTAMPTZ. **Unlink clears `web_email`** (MEDIUM-02).
- **`categories`**: `name` CHECK 1..100; `name_key` normalized (trim+lower+NFC); `type` CHECK `('default','custom')` DEFAULT `'custom'`; `is_hidden boolean DEFAULT false`; `UNIQUE(business_id,name_key)`; `UNIQUE(id,business_id)`; guard trigger.
- **`transactions`**: `category_id` NOT NULL composite FK `(category_id,business_id)`→`categories(id,business_id)` RESTRICT; `type` CHECK `('income','expense')`; `amount numeric(14,2) CHECK >0`; `transaction_date DATE`; `party_name text` nullable CHECK exists≤255 (LOW-03); `entry_source` CHECK `('manual','ai')`; `UNIQUE(id,business_id)`.
- **`transaction_items`**: `description` CHECK 1..255; `amount numeric(14,2)` nullable CHECK >0; composite FK→`transactions(id,business_id)` CASCADE; `business_id` FK→businesses CASCADE.
- **`receipts`**: `transaction_id` UNIQUE + composite FK→transactions CASCADE; `storage_path` UNIQUE; `original_filename`; `mime_type` CHECK `LIKE 'image/%'`; `size_bytes bigint` CHECK `>0 AND <=20971520`; no `updated_at`.
- **`ai_extractions`**: `transaction_id` UNIQUE + composite FK→transactions CASCADE; `model`; `overall_confidence numeric(3,2)` CHECK `BETWEEN 0 AND 1`; `extracted_fields jsonb`; `field_confidences jsonb`; no `updated_at`.

Do not add Phase 2/3 columns.

---

## 8. Relationships and Foreign Keys

**10 foreign keys** (from `relationships.md` / `database-design.md` §16):

| FK | From → To | On delete |
|---|---|---|
| `businesses.owner_id` | businesses → auth.users | CASCADE |
| `categories.business_id` | categories → businesses | CASCADE |
| `transactions.business_id` | transactions → businesses | CASCADE |
| `transaction_items.business_id` | transaction_items → businesses | CASCADE |
| `receipts.business_id` | receipts → businesses | CASCADE |
| `ai_extractions.business_id` | ai_extractions → businesses | CASCADE |
| `transactions.(category_id,business_id)` | transactions → categories(id,business_id) | RESTRICT |
| `transaction_items.(transaction_id,business_id)` | transaction_items → transactions(id,business_id) | CASCADE |
| `receipts.(transaction_id,business_id)` | receipts → transactions(id,business_id) | CASCADE |
| `ai_extractions.(transaction_id,business_id)` | ai_extractions → transactions(id,business_id) | CASCADE |

Each composite same-tenant FK requires the parent to expose `UNIQUE(id, business_id)` (U4/U5). This guarantees a child can never reference a row from a different business, independent of RLS — the primary isolation guarantee.

---

## 9. Constraints

Named constraints on all six tables, per §7 and `schema.md`. Full list to implement:

- **Check**: `businesses.name` 1..100; `businesses.currency_code = 'EGP'`; `categories.name` 1..100; `categories.type IN ('default','custom')`; `transactions.type IN ('income','expense')`; `transactions.amount > 0`; `transactions.entry_source IN ('manual','ai')`; `transactions.party_name IS NULL OR length(trim(...)) BETWEEN 1 AND 255`; `transaction_items.description` 1..255; `transaction_items.amount IS NULL OR amount>0`; `receipts.mime_type LIKE 'image/%'`; `receipts.size_bytes >0 AND <=20971520`; `ai_extractions.overall_confidence BETWEEN 0 AND 1`.
- **Unique**: `businesses.owner_id` (U1); `businesses.web_email` partial (U2); `categories(business_id,name_key)` (U3); `categories(id,business_id)` (U4); `transactions(id,business_id)` (U5); `receipts.transaction_id` (U6); `receipts.storage_path` (U7); `ai_extractions.transaction_id` (U8).
- **Foreign keys**: §8.
- **Not null** on every required column.
- Do **not** rely on Flutter validation for DB integrity — constraints are authoritative.

---

## 10. Indexes

**8 unique constraints (U1–U8, §9)** + **10 standalone indexes (I1–I10)** per `indexes.md`:

| # | Table (columns) | Type | Serves |
|---|---|---|---|
| I1 | `transactions(business_id, transaction_date DESC, created_at DESC)` | btree | default list + month ranges |
| I2 | `transactions(business_id, type, transaction_date DESC)` | btree | type tab |
| I3 | `transactions(business_id, category_id, transaction_date DESC)` | btree | category filter/totals |
| I4 | `transactions(business_id, amount)` | btree | amount range |
| I5 | `transactions(category_id, business_id)` | btree | FK RESTRICT delete-time support |
| I6 | `transactions lower(party_name) gin_trgm_ops` | **GIN trgm** | Arabic contains-search |
| I7 | `transaction_items(transaction_id)` | btree | line-item fetch |
| I8 | `transaction_items(business_id)` | btree | RLS predicate |
| I9 | `receipts(business_id)` | btree | RLS predicate |
| I10 | `ai_extractions(business_id)` | btree | RLS predicate |

Create indexes **after** tables exist (migration `010`), before RLS. Do not over-index (no JSONB-path indexes, no per-month partial indexes, no materialized views). Validate against the query patterns in §18.

---

## 11. RLS Enablement

Enable RLS **after** every table and grant exists (migration `011`), so enabling it is the final hardening step — no window where a table is exposed.

- `ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;` for all 6 tables.
- `ALTER TABLE <table> FORCE ROW LEVEL SECURITY;` (defense-in-depth for table owners, where the project supports it — optional but recommended so the table owner is also subject to policies).

Roles:
- `anon`: **zero** grants, **zero** policies.
- `authenticated`: owner-scoped grants + policies (below).
- `service_role`: bypasses RLS; used only by the admin account-deletion function; never client-exposed.

---

## 12. RLS Policies

Per-table policy plan (convertible directly to SQL). All policies scope by `current_business_id()`.

**Helper (migration 011, before policies):**
- `current_business_id()` — SECURITY INVOKER, STABLE: `SELECT id FROM businesses WHERE owner_id = auth.uid();`
- `GRANT EXECUTE ON FUNCTION current_business_id() TO authenticated;` and `REVOKE EXECUTE … FROM public;`

**Grants to `authenticated`** (authorizes the operation class; policies make them owner-scoped):

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `businesses` | ✅ | ✅ | ✅ | — |
| `categories` | ✅ | ✅ | ✅ | ✅ |
| `transactions` | ✅ | ✅ | ✅ | ✅ |
| `transaction_items` | ✅ | ✅ | ✅ | ✅ |
| `receipts` | ✅ | ✅ | — | ✅ |
| `ai_extractions` | ✅ | ✅ | — | — |

`REVOKE ALL ON <6 tables> FROM anon, public;`

**Policies** (operation → USING / WITH CHECK):

| Table | SELECT (USING) | INSERT (WITH CHECK) | UPDATE (USING / WITH CHECK) | DELETE (USING) |
|---|---|---|---|---|
| `businesses` | `owner_id = auth.uid()` | `owner_id = auth.uid()` | `owner_id=auth.uid()` / `owner_id=auth.uid()` | **none** (admin-scoped) |
| `categories` | `business_id = current_business_id()` | `business_id = current_business_id() AND type='custom'` | `business_id=current_business_id()` / `business_id=current_business_id()` | `business_id=current_business_id() AND type='custom'` |
| `transactions` | `business_id = current_business_id()` | `business_id = current_business_id()` | `business_id=current_business_id()` / `business_id=current_business_id()` | `business_id=current_business_id()` |
| `transaction_items` | `business_id = current_business_id()` | `business_id = current_business_id()` | `business_id=current_business_id()` / `business_id=current_business_id()` | `business_id=current_business_id()` |
| `receipts` | `business_id = current_business_id()` | `business_id = current_business_id()` | **none** (immutable) | `business_id=current_business_id()` |
| `ai_extractions` | `business_id = current_business_id()` | `business_id = current_business_id()` | **none** (immutable) | **none** (cascade only) |

Rules enforced:
- `TO authenticated` is **never** the complete authorization rule — every policy adds a business-ownership predicate.
- UPDATE policies always specify both `USING` and `WITH CHECK` (prevents ownership reassignment).
- No UPDATE policy on immutable tables; no DELETE on `businesses`/`ai_extractions`.
- Web-access gating is **not** an RLS concern (Q-015/ADR-006) — see §16.

**Verification tests** per table described in §19.

---

## 13. Storage Bucket

- **Name:** `receipts`
- **Visibility:** **private** (never public; no public URL ever generated).
- **Path convention:** `receipts/{business_id}/{transaction_id}/receipt.ext`
  - Segment 1 = owning business (authorization backbone).
  - Segment 2 = owning transaction (provenance + uniqueness + cleanup).
- Created in migration `012` via `storage.create_bucket('receipts', { public: false })` (or SQL `storage.buckets` insert).

---

## 14. Storage Policies

Policies on `storage.objects` (bucket `receipts`), owner-scoped by first path segment:

| Operation | Policy expression |
|---|---|
| SELECT | `bucket_id = 'receipts' AND (storage.foldername(name))[1] = current_business_id()::text` |
| INSERT | `WITH CHECK` same ownership expression |
| UPDATE | **none** (no overwrite) |
| DELETE | same ownership expression |

- `anon`: no policies → 403/404 for everything.
- **Defense-in-depth (MEDIUM-03):** storage policies validate only ownership path; MIME type and file size are enforced at the app **and** in `receipts.mime_type`/`size_bytes` CHECKs. Verification must prove a client cannot create a non-image/oversized object for a `receipts` row (see §19).
- Do not add public access; do not expose service-role credentials.

---

## 15. Seed Data

**Default categories** (authoritative 10 from `business-rules.md` / ADR-DB-003):

| EN | AR | name_key (normalized) |
|---|---|---|
| Sales | مبيعات | مبيعات |
| Purchases / Stock | مشتريات | مشتريات |
| Rent | إيجار | إيجار |
| Salaries | مرتبات | مرتبات |
| Utilities | فواتير | فواتير |
| Transport | نقل | نقل |
| Marketing | تسويق | تسويق |
| Maintenance | صيانة | صيانة |
| Taxes / Fees | ضرائب ورسوم | ضرائب ورسوم |
| Other | أخرى | أخرى |

- **Mechanism:** `seed_default_categories_for_business(NEW.id)` fired by AFTER INSERT trigger on `businesses` (migration `009`). SECURITY DEFINER, owned by `postgres`, `search_path` pinned.
- **Stable identity:** each row `type='default'`; uniqueness via `UNIQUE(business_id, name_key)` guarantees no duplicates and makes seeding **idempotent** (a re-run never double-seeds).
- **Default/custom distinction:** `type='default'` vs `'custom'`.
- **Ordering:** none required; clients render in a defined order (or by `name_key`); no `sort_order` column in MVP.
- **Hidden default behavior:** `is_hidden` editable on both types; hidden defaults remain valid for historical transactions.
- **Secrets/privileges:** seeder EXECUTE revoked from `public`/`anon`/`authenticated` — trigger-only path (HIGH-02).
- Seeding is **not** executed in this plan; the trigger does it at business creation.

---

## 16. Database Functions

- `current_business_id()` — SECURITY INVOKER, STABLE (RLS helper). Migration `011`.
- `set_updated_at()` — SECURITY INVOKER trigger function; stamps `updated_at = now()`. Migration `008`.
- `categories_guard_default_immutable()` — SECURITY INVOKER BEFORE UPDATE trigger; HIGH-01 semantics. Migration `003`.
- `transactions_ai_provenance_guard()` — SECURITY INVOKER BEFORE INSERT/UPDATE trigger; MEDIUM-01. Migration `009`.
- `seed_default_categories_for_business()` — SECURITY DEFINER (owned by `postgres`, `search_path` pinned); EXECUTE revoked from public roles; HIGH-02. Migration `009`.
- Admin account deletion (service_role Edge Function, ADR-DB-005) — deletes storage objects under `{business_id}/…` **before** deleting the auth user; then `owner_id ON DELETE CASCADE` removes the subtree. Planned with the backend phase; its DB relationships are implemented here.

**Web access (MEDIUM-02, LOW-01, ADR-006):**
- `web_access_enabled` / `web_email` are **metadata + server-side gate**, not DB authorization.
- **Unlink** must set BOTH `web_access_enabled=false` AND `web_email=NULL` (releases the global partial-UNIQUE; the email can be re-linked).
- **Web transaction creation** is blocked at the **application layer** (the DB cannot distinguish mobile vs web — same `auth.uid()`); no fake DB distinction is added. The dashboard must not expose create in MVP.

---

## 17. Triggers

| Trigger | Table(s) | Timing | Function |
|---|---|---|---|
| `trg_set_updated_at` | businesses, categories, transactions, transaction_items | BEFORE UPDATE | `set_updated_at()` |
| `trg_categories_guard_default_immutable` | categories | BEFORE UPDATE | `categories_guard_default_immutable()` |
| `trg_transactions_ai_provenance_guard` | transactions | BEFORE INSERT OR UPDATE | `transactions_ai_provenance_guard()` |
| `trg_seed_default_categories` | businesses | AFTER INSERT | `seed_default_categories_for_business()` |

Immutable tables (`receipts`, `ai_extractions`) have **no** `updated_at` trigger and **no** UPDATE trigger.

---

## 18. Validation Queries

The implementation phase will validate against real query patterns:

- **Transactions list / month range:** `WHERE business_id=… AND transaction_date BETWEEN … ORDER BY transaction_date DESC, created_at DESC` → I1.
- **Type tab:** `WHERE business_id=… AND type='expense' ORDER BY transaction_date DESC` → I2.
- **Category tab / totals:** `WHERE business_id=… AND category_id=… ORDER BY transaction_date DESC` → I3.
- **Amount range:** `WHERE business_id=… AND amount BETWEEN …` → I4.
- **Party search:** `WHERE business_id=… AND lower(party_name) ILIKE '%فطير%'` → I6 (GIN trgm).
- **Detail:** `WHERE id=… AND business_id=…` → PK/U5.
- **Line items:** `WHERE transaction_id=… AND business_id=…` → I7/U5.
- **Receipt lookup:** `WHERE transaction_id=…` → U6.
- **AI extraction lookup:** `WHERE transaction_id=…` → U8.
- **Category lookup:** `WHERE business_id=… AND name_key=…` → U3.
- **Web access:** by `owner_id` (U1) / `web_email` (U2) — low volume.

**Reports** (no persistent tables): derived from `transactions` with `business_id` + date/type/category/amount filters and `SUM`, supporting This Week / This Month / Last Month / Year-to-Date / Custom Range, Total Income / Expenses / Net, Category Breakdown, Period Comparison.

**Export** (no export-history tables): RLS-scoped reads over the same period + active-filter set; CSV flat (transactions), Excel (summary/transactions/categories), PDF (period/totals/breakdown/list).

---

## 19. Security Verification

The implementation phase MUST run these checks (per `database-review.md` §20 conditions, §33 of the review workflow):

**Schema:** tables/columns/types/constraints/FKs/indexes/functions/triggers all present and correct.

**RLS / cross-business isolation (User A/B):**
- Owner A reads/writes/updates/deletes own data; owner B cannot read/write/update/delete A's data, cannot reassign A's rows to B, and vice versa.
- Unauthorized cross-business operations fail: changing `business_id`, category ownership, transaction ownership, receipt ownership, AI-extraction ownership.
- UPDATE requires SELECT (silently returns 0 rows without a SELECT policy) — confirm UPDATE policies exist.

**Escalation:** none — `anon` zero access; composite FKs block cross-tenant references independent of RLS.

**Seeder (HIGH-02):** `has_function_privilege('anon','seed_default_categories_for_business(...)','EXECUTE')` is false; `authenticated` likewise; new business still seeds 10 defaults via trigger.

**Storage:** A can read B cannot; anon cannot read/upload; unauthorized cannot delete another business's receipts; private bucket; invalid-object attempts blocked per LOW-02.

**Advisors:** run Supabase security + performance advisors after implementation; fix findings that violate the design; document intentional accepts.

---

## 20. Performance Verification

- `EXPLAIN` the §18 queries; confirm index usage (leading `business_id`).
- Confirm `pg_trgm` GIN on `lower(party_name)` is used for the search pattern.
- Confirm RLS predicates are index-aligned (I1–I10).
- Confirm no sequential scan on hot paths at MVP scale; revisit with real data (Phase 1 post-MVP).

---

## 21. Rollback Strategy

Migrations are additive and independent; rollback = drop the objects added by the offending version, in reverse order:

- `012` storage: drop policies + bucket (leave `storage.migrations` metadata review).
- `011` RLS: drop policies, revoke grants, `DISABLE RLS`, drop helper (or re-run a fixed `011`).
- `010` indexes: `DROP INDEX`.
- `009/008/003` triggers+functions: `DROP TRIGGER` then `DROP FUNCTION`.
- `007–002` tables: `DROP TABLE` reverse (children before parents).
- `001` extension: `DROP EXTENSION pg_trgm` only if nothing else uses it.
- Never silently drop an object that predates this plan; verify ownership before any destructive step.

---

## 22. Deployment Strategy

- Apply migrations through the project's supported Supabase workflow (imperative migrations: `supabase migration new` → author SQL → `supabase db push`/`supabase db reset`; or MCP `apply_migration`).
- Order strictly per §5; do not squash unrelated changes.
- After apply: run §19/§20 verification, then Supabase advisors.
- Do **not** push destructive changes to a remote environment without evidence it is the intended dev target (per the review/plan constraints). This plan targets the designated fresh dev project.
- Produce `docs/database/database-implementation-report.md` in the implementation phase with evidence.

---

## 23. Post-Implementation Verification

- Confirm migration history: listed + applied, consistent with `supabase/migrations/`.
- Confirm schema matches §7–§10 exactly.
- Confirm RLS/grants/policies per §11–§12.
- Confirm storage bucket per §13–§14.
- Confirm seed per §15.
- Run functional verification scenario (User A/B, categories CRUD rules, transactions+items, receipt relation, AI extraction relation, web access lifecycle, account deletion relationships).
- Confirm advisors pass; document accepted findings.
- Confirm `anon` reaches nothing (tables, functions, storage).

---

## 24. Definition of Done

The Database Implementation phase is complete only when **all** of these hold (checklist carried into that phase):

```
[ ] Reviewed database design implemented
[ ] All approved HIGH corrections implemented (HIGH-01 custom rename; HIGH-02 seeder revoke)
[ ] AI provenance guard implemented (MEDIUM-01)
[ ] Web email unlink lifecycle implemented (MEDIUM-02)
[ ] party_name bounded (LOW-03)
[ ] All six tables created
[ ] All relationships (composite same-tenant FKs) created and verified
[ ] Constraints verified
[ ] Indexes created (U1–U8, I1–I10)
[ ] RLS enabled on all 6 tables
[ ] RLS policies implemented (owner-scoped; UPDATE USING+WITH CHECK verified)
[ ] Cross-business isolation tests pass (User A vs User B)
[ ] Category seeding works (10 defaults on business create)
[ ] Custom category rename works
[ ] Default category rename fails
[ ] Default category delete fails
[ ] Custom category delete works (unless in use → RESTRICT)
[ ] Duplicate normalized category rejected
[ ] Private storage bucket created (receipts)
[ ] Storage policies verified (owner SELECT/INSERT/DELETE; no UPDATE; anon none)
[ ] Storage cross-business isolation verified
[ ] Seeder EXECUTE revoked from public/anon/authenticated
[ ] Report query support verified
[ ] Search (party_name trgm) support verified
[ ] Web access lifecycle verified (enable → link → unlink clears web_email)
[ ] Web transaction create is application-blocked (documented; no fake DB distinction)
[ ] Account deletion relationships verified (owner_id CASCADE + admin storage cleanup)
[ ] Supabase security advisors reviewed
[ ] No unintended public access
[ ] Database implementation report created (docs/database/database-implementation-report.md)
```

Final gate: this plan is executable only after the review status is satisfied. The next phase (Database Implementation) converts §5–§17 directly into SQL.
