# Database Design — Smart Invoice Assistant

| | |
|---|---|
| **Status** | Draft — design stage (no SQL has been generated or executed) |
| **Date** | 2026-08-31 |
| **Owner** | Platform team |
| **Scope** | Supabase (PostgreSQL) schema for the MVP: `businesses`, `categories`, `transactions`, `transaction_items`, `receipts`, `ai_extractions` |
| **Related** | `docs/architecture/*.md`, `docs/architecture/decisions/ADR-001…006`, `docs/requirements/*.md` |

---

## 1. Purpose & Scope

This document is the single-source-of-truth design for the **database layer** of the Smart Invoice Assistant MVP. It covers:

- The entity model and table shapes (one business owner, fully tenant-isolated data).
- Constraints, data types, and integrity rules (including same-tenant composite foreign keys).
- Row Level Security (RLS) — the **mandatory** isolation model.
- Private storage for receipt images.
- Indexing strategy for the MVP query patterns.
- An ordered, non-destructive migration plan.

**Out of scope (this document):** authentication UX (mobile OTP / dashboard magic link — see `backend-architecture.md`), the Gemini integration (`ai-architecture.md`), Flutter / dashboard UI (`mobile-architecture.md`, `dashboard-architecture.md`), and any application code. No SQL is produced in this deliverable; design details only.

---

## 2. Status & Sign-off

| Item | Status |
|---|---|
| Requirements reviewed | ✅ `docs/requirements/*` (finalized, decisions resolved) |
| Architecture reviewed | ✅ `docs/architecture/*` + ADR-001…006 |
| Data model agreed | ⚠️ Draft — subject to model review |
| RLS matrix agreed | ⚠️ Draft |
| Storage design agreed | ⚠️ Draft |
| Migration plan agreed | ⚠️ Draft |
| Approval gate | ☐ Product + architecture sign-off before migration `001` |

---

## 3. Executive Summary

The MVP stores every piece of business data under a single tenant row, `businesses`, owned 1:1 by one Supabase Auth user. Every child table carries a denormalized `business_id` column, and cross-table references are enforced with **composite "same-tenant" foreign keys** so that no query, trigger, or bug can ever join data across two businesses.

Row Level Security is enabled on **every** table and storage bucket. The mobile app and the web dashboard connect with the end user's JWT; an anonymous client has **zero** access. Only the owner of a business can read, create, update, or hide records belonging to that business.

Receipt images live in a **private** storage bucket (`receipts`) whose path begins with the owning `business_id`; storage policies mirror the RLS ownership rule. AI-extracted data is stored as a provenance snapshot (`ai_extractions`) that is only written **after the user confirms** the extracted values (NFR-DATA-001); it is immutable by design.

Money is `numeric(14,2)` (no floating point), the currency is pinned to Egyptian pounds (`EGP`) for MVP, dates carry no timezone, and enums are implemented as `TEXT` + `CHECK` constraints rather than Postgres enum types.

---

## 4. Sources

| Document | Relevance |
|---|---|
| `docs/requirements/requirements.md` | Functional requirements |
| `docs/requirements/business-rules.md` | Business rules (source of truth for validation rules) |
| `docs/requirements/assumptions.md` | Assumptions |
| `docs/requirements/open-questions.md` | Decisions Q-001…Q-022 (all resolved) |
| `docs/requirements/acceptance-criteria.md` | Acceptance criteria |
| `docs/requirements/feature-list.md` | Product spec + phases (MVP / Phase 2 / Phase 3) |
| `docs/requirements/user-flow-mobile.md` | Mobile user flows |
| `docs/requirements/user-flow-dashboard.md` | Dashboard user flows |
| `docs/architecture/system-architecture.md` | System context, Supabase role, deployment model |
| `docs/architecture/backend-architecture.md` | Edge Functions, auth model, web-access gate |
| `docs/architecture/ai-architecture.md` | Gemini extraction, confidence model, prompt contract |
| `docs/architecture/mobile-architecture.md` | Flutter client, local-first, upload ordering |
| `docs/architecture/dashboard-architecture.md` | Next.js companion app |
| `docs/architecture/decisions/ADR-001…006` | Prior decisions (monorepo, Supabase, RLS, etc.) |
| `AGENTS.md` | Repo conventions (Arabic-first RTL, RLS mandatory, private storage, confirm-before-save) |

> **Note:** `user-flow-mobile.md` contains ~14 lines of unrelated promotional text at the top; the actual spec starts at `# User Flow — Mobile App` (per `AGENTS.md`).

---

## 5. Goals & Non-Goals

### Goals
- **Tenant isolation is ironclad.** Every row is scoped to exactly one business; RLS is enabled on every table; storage is private and ownership-scoped.
- **Minimal, boring schema.** Six business tables that map 1:1 to the MVP flows — nothing speculative, nothing from Phase 2/3.
- **Receipt provenance.** Store `where the image is`, `what the AI extracted`, and `how confident it was` — as immutable records.
- **Arabic-first compatibility.** Unicode-safe text columns (`text`), no case-insensitive collation tricks; normalization handled at the app/DB layer where needed.
- **Low-spec mobile friendly.** Simple queries with targeted indexes; no heavy aggregation, no materialized views in the hot path.

### Non-Goals (explicitly rejected for MVP)
- Multiple users / staff / membership tables per business (Phase: Phase 2 feature).
- Multi-currency (pinned to `EGP`).
- Double-entry accounting, ledgers, VAT logic, or inventory — out of MVP scope.
- Investment / savings / net-worth tracking.
- Export / reporting tables, cached dashboards, materialized views.
- Soft deletes / audit trails (deletion strategy covered by ADR-DB-005).

---

## 6. Requirements Summary (what this schema must satisfy)

| # | Capability | Backing |
|---|---|---|
| R1 | Owner creates a business on first sign-in (phone OTP); every subsequent request is scoped to that business | Q-001 … Q-022 (resolved), mobile flow |
| R2 | Owner captures a receipt image (camera/gallery) | Mobile flow, `backend-architecture.md` |
| R3 | AI extracts fields, shown for **user confirmation** before anything is persisted as a transaction | NFR-DATA-001, `ai-architecture.md` |
| R4 | Owner records transactions (income/expense) — by AI confirm or manual entry | Requirements, business rules |
| R5 | Transactions support line items (optional), a category (required), amount (required), date (required), optional party name | Business rules |
| R6 | Categories: a fixed set of seeded defaults + owner-created custom categories; defaults can be hidden but **not renamed or deleted** | Business rules |
| R7 | Receipt image attached 0..1 to a transaction; stored privately; never public | NFR (storage), ADR storage |
| R8 | Dashboard (web, magic-link) reads, edits, and deletes the same data — same schema, RLS-scoped | `dashboard-architecture.md` |
| R9 | Web access is an opt-in flag on the business, tied to a verified email identity | Q-015, ADR-006 |
| R10 | Account deletion removes the business and all associated data | Q (deletion), ADR-DB-005 |

---

## 7. Tenancy & Ownership Model

```
auth.users ──(1:1)── businesses ──1:N── categories / transactions ──0:N── transaction_items
                         │                 │ 0..1                       │ 0..1
                         │                 ├── receipts ────────────────┘
                         └──1:N── (denormalized business_id on every child table)
                                              │ 0..1
                                              └── ai_extractions
```

- **No** `profiles`, `membership`, or `roles` tables in MVP. A Supabase Auth user owns **exactly one** business (`businesses.owner_id` is UNIQUE).
- Every child table (`categories`, `transactions`, `transaction_items`, `receipts`, `ai_extractions`) carries `business_id NOT NULL` (denormalized) **and** is linked to its parent via a composite same-tenant FK (see §16).
- Web-dashboard access is **not** a second tenant: the dashboard user (if any) is the *same* owner, authenticated through a linked email identity. Gate = `businesses.web_access_enabled` + server-side email check (Q-015; ADR-006). The DB perceives one tenant: the business.
- RLS derives the tenant per request with `current_business_id()` → `businesses.id WHERE owner_id = auth.uid()`.

---

## 8. Conventions & Standards

- **Money:** `numeric(14,2)`. Checked positive where applicable. Never `float`/`double`.
- **Currency:** `currency_code` `TEXT NOT NULL DEFAULT 'EGP'` with `CHECK (currency_code = 'EGP')` — pins single-currency for MVP yet leaves a clean migration path.
- **Dates:** `transaction_date DATE` (business date, no timezone). Audit timestamps are `TIMESTAMPTZ`.
- **Enums:** `TEXT` + `CHECK` (e.g. `type IN ('income','expense')`), **not** Postgres `ENUM` types (removes ALTER-TYPE friction, keeps Supabase client types simple, per AGENTS.md low-friction rule).
- **IDs:** `uuid` PK, `DEFAULT gen_random_uuid()` (PG13+).
- **Timestamps:** `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` on every table; `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` (set by `set_updated_at()` trigger) on **mutable** tables only: `businesses`, `categories`, `transactions`, `transaction_items`. Immutable tables (`receipts`, `ai_extractions`) have `created_at` only.
- **Constraints:** named. Composite same-tenant FKs prefer `UNIQUE(id, business_id)` on the parent and `(fk_id, business_id)` on the child.
- **Integrity:** `ON DELETE CASCADE` along the business tree; `ON DELETE RESTRICT` for the category→transaction reference (blocks deleting an in-use category). Account-level deletion relies on `businesses.owner_id … ON DELETE CASCADE` invoked by an admin Edge Function (ADR-DB-005).
- **No soft delete, no audit tables, no `created_by`/`updated_by`** — MVP.
- **RLS:** enabled on all 6 tables (mandatory). Helpers are `SECURITY INVOKER` except the one narrowly-scoped seeding function (`seed_default_categories_for_business`, `SECURITY DEFINER`, documented).

---

## 9. Entities Overview

| Entity | Purpose | Owner-scoped | Cardinality to parent | Mutability |
|---|---|---|---|---|
| `businesses` | Tenant root; 1:1 with an auth user; owns all data | — | — | mutable |
| `categories` | Budget classification (`income`/`expense` buckets); seeded defaults + custom | yes | 1:N from business | mutable (defaults guarded) |
| `transactions` | A recorded income/expense event | yes | 1:N from business | mutable |
| `transaction_items` | Optional line items of a transaction | yes | 0..N from transaction | mutable |
| `receipts` | 0..1 stored image path per transaction | yes | 0..1 from transaction | immutable |
| `ai_extractions` | 0..1 immutable AI-provenance snapshot per transaction | yes | 0..1 from transaction | immutable |

---

## 10. Entity: `businesses`

The tenant root. Created once on first sign-in; exactly one per auth user.

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `owner_id` | `uuid` | NOT NULL, **UNIQUE**, FK → `auth.users(id) ON DELETE CASCADE` |
| `name` | `text` | NOT NULL, `CHECK (length(trim(name)) BETWEEN 1 AND 100)` |
| `currency_code` | `text` | NOT NULL, `DEFAULT 'EGP'`, `CHECK (currency_code = 'EGP')` |
| `web_access_enabled` | `boolean` | NOT NULL, `DEFAULT false` |
| `web_email` | `text` | NULL; **partial unique** index `WHERE web_email IS NOT NULL` |
| `created_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |
| `updated_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |

Notes:
- `owner_id UNIQUE` enforces the 1:1 invariant at the DB level.
- `web_email` is denormalized **only** as an opt-in portal identity gate (Q-015); it is not a second owner, and does not grant any DB role.
- No owner-level DELETE policy on `businesses`; account removal is admin-Edge-Function-scoped (ADR-DB-005).

Also see: `schema.md` §1 — full column table.

---

## 11. Entity: `categories`

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `business_id` | `uuid` | NOT NULL, FK → `businesses(id) ON DELETE CASCADE` |
| `name` | `text` | NOT NULL, `CHECK (length(trim(name)) BETWEEN 1 AND 100)` |
| `name_key` | `text` | NOT NULL (normalized: trimmed, lower-cased, NFC) |
| `type` | `text` | NOT NULL, `DEFAULT 'custom'`, `CHECK (type IN ('default','custom'))` |
| `is_hidden` | `boolean` | NOT NULL, `DEFAULT false` |
| `created_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |
| `updated_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |

Uniqueness: `UNIQUE (business_id, name_key)`; `UNIQUE (id, business_id)` (FK target).

Notes:
- Default categories are seeded per business by `seed_default_categories_for_business()` (AFTER INSERT trigger on `businesses`; `SECURITY DEFINER`, `search_path` pinned). Clients can only INSERT `type='custom'` (RLS `WITH CHECK`).
- Default categories are **immutable in identity**: a guard trigger rejects changes to `name`, `name_key`, `business_id`, and `type` for any category; `is_hidden` remains editable. Defaults are **undeletable** (RLS DELETE requires `type='custom'`).
- Deleting a custom category that is referenced by a transaction is blocked by the FK `RESTRICT`. This is documented as an assumption (see §Appendix — Risks & Assumptions).

Seed list (authoritative — `business-rules.md` BR): `مبيعات` (Sales), `مشتريات` (Purchases/Stock), `إيجار` (Rent), `مرتبات` (Salaries), `فواتير` (Utilities), `نقل` (Transport), `تسويق` (Marketing), `صيانة` (Maintenance), `ضرائب ورسوم` (Taxes/Fees), `أخرى` (Other).

---

## 12. Entity: `transactions`

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `business_id` | `uuid` | NOT NULL, FK → `businesses(id) ON DELETE CASCADE` |
| `category_id` | `uuid` | NOT NULL; composite FK `(category_id, business_id) → categories(id, business_id) ON DELETE RESTRICT` |
| `type` | `text` | NOT NULL, `CHECK (type IN ('income','expense'))` |
| `amount` | `numeric(14,2)` | NOT NULL, `CHECK (amount > 0)` |
| `transaction_date` | `date` | NOT NULL (business-local date) |
| `party_name` | `text` | NULL |
| `entry_source` | `text` | NOT NULL, `CHECK (entry_source IN ('manual','ai'))` |
| `created_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |
| `updated_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |

Uniqueness: `UNIQUE (id, business_id)` (FK target).

Notes:
- Represented as a ledger event (no double-entry, no linked transfer pairs).
- `party_name` free text (supplier/customer name); searched with `pg_trgm` (unaccent/trigram) — see `indexes.md`.
- Confidence/accepted-difference handling is **app-side** (Q-008); the DB stores the confirmed values. AI provenance is in `ai_extractions`.

---

## 13. Entity: `transaction_items`

Optional line items (e.g. an invoice with multiple goods).

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `transaction_id` | `uuid` | NOT NULL; composite FK `(transaction_id, business_id) → transactions(id, business_id) ON DELETE CASCADE` |
| `business_id` | `uuid` | NOT NULL, FK → `businesses(id) ON DELETE CASCADE` (denormalized) |
| `description` | `text` | NOT NULL, `CHECK (length(trim(description)) BETWEEN 1 AND 255)` |
| `amount` | `numeric(14,2)` | NULL, `CHECK (amount > 0)` |
| `created_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |
| `updated_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |

Notes: No inventory/quantity linkage in MVP. Sum of line-item amounts is **not** a DB invariant (receipt subtotals/shipping differ); the transaction `amount` is authoritative (documented assumption).

---

## 14. Entity: `receipts`

0..1 immutable image record per transaction.

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `transaction_id` | `uuid` | NOT NULL, **UNIQUE**; composite FK `(transaction_id, business_id) → transactions(id, business_id) ON DELETE CASCADE` |
| `business_id` | `uuid` | NOT NULL, FK → `businesses(id) ON DELETE CASCADE` (denormalized) |
| `storage_path` | `text` | NOT NULL, **UNIQUE** — `{business_id}/{transaction_id}/receipt.ext` |
| `original_filename` | `text` | NOT NULL |
| `mime_type` | `text` | NOT NULL, `CHECK (mime_type LIKE 'image/%')` |
| `size_bytes` | `bigint` | NOT NULL, `CHECK (size_bytes > 0 AND size_bytes <= 20971520)` (≤ 20 MB) |
| `created_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |

Notes: **Immutable** (no `updated_at`, no UPDATE policy). Upload ordering is *row-first* (insert transaction → upload object → insert `receipts` row), with app-level compensation (delete the partial row) on upload failure — see `storage-design.md`.

---

## 15. Entity: `ai_extractions`

0..1 immutable AI-provenance snapshot, written **only after user confirmation** (NFR-DATA-001).

| Column | Type | Rules |
|---|---|---|
| `id` | `uuid` | PK, `DEFAULT gen_random_uuid()` |
| `transaction_id` | `uuid` | NOT NULL, **UNIQUE**; composite FK `(transaction_id, business_id) → transactions(id, business_id) ON DELETE CASCADE` |
| `business_id` | `uuid` | NOT NULL, FK → `businesses(id) ON DELETE CASCADE` (denormalized) |
| `model` | `text` | NOT NULL (e.g. `gemini-3.1-flash-lite` — Q-007) |
| `overall_confidence` | `numeric(3,2)` | NOT NULL, `CHECK (overall_confidence BETWEEN 0 AND 1)` |
| `extracted_fields` | `jsonb` | NOT NULL — snapshot of the AI-returned field map; shape per the `ai-architecture.md` prompt contract |
| `field_confidences` | `jsonb` | NULL — per-field confidence snapshot |
| `created_at` | `timestamptz` | NOT NULL, `DEFAULT now()` |

Notes: Immutable. Threshold decisions (< 80% → flag, missing-required / < 50% → reject; Q-008) live in the app and Edge Function, *not* in the schema. `overall_confidence`/`field_confidences` never drive access control.

---

## 16. Relationships & Integrity

**10 foreign keys in total** (detailed truth table in `relationships.md`):

| FK | From | To | On delete |
|---|---|---|---|
| `businesses.owner_id` | businesses | auth.users | CASCADE |
| `categories.business_id` | categories | businesses | CASCADE |
| `transactions.business_id` | transactions | businesses | CASCADE |
| `transaction_items.business_id` | transaction_items | businesses | CASCADE |
| `receipts.business_id` | receipts | businesses | CASCADE |
| `ai_extractions.business_id` | ai_extractions | businesses | CASCADE |
| `transactions.(category_id, business_id)` | transactions | categories(id, business_id) | RESTRICT |
| `transaction_items.(transaction_id, business_id)` | transaction_items | transactions(id, business_id) | CASCADE |
| `receipts.(transaction_id, business_id)` | receipts | transactions(id, business_id) | CASCADE |
| `ai_extractions.(transaction_id, business_id)` | ai_extractions | transactions(id, business_id) | CASCADE |

Composite same-tenant FKs guarantee a child can never reference a row from another tenant, **even if a bug or malicious write slipped through RLS**.

Integrity rules also include CHECKs (amounts > 0, size caps, enum domains, currency pin) and triggers:
- `set_updated_at()` — on `businesses`, `categories`, `transactions`, `transaction_items`.
- `categories_guard_default_immutable()` — rejects identity changes to default categories.

---

## 17. Row Level Security

**Mandatory (AGENTS.md).** RLS is `ENABLE`d on all six tables; every access path from the mobile app and dashboard uses the owner's JWT (`authenticated` role). Summary (full matrix in `rls-matrix.md`):

| Entity | Can SELECT | Can INSERT | Can UPDATE | Can DELETE |
|---|---|---|---|---|
| `businesses` | owner | owner (WITH CHECK owner = auth.uid()) | owner | **no** (admin-scoped) |
| `categories` | owner | owner + `type='custom'` | owner (default identity guarded) | owner + `type='custom'` |
| `transactions` | owner | owner | owner | owner |
| `transaction_items` | owner | owner | owner | owner |
| `receipts` | owner | owner | — | owner |
| `ai_extractions` | owner | owner (**after confirmation**) | — | — (cascade only) |
| `storage.objects` (bucket `receipts`) | owner path | owner path | — | owner path |

`anon` role: zero access to tables, functions, and the storage bucket.

Helper: `current_business_id()` (SECURITY INVOKER, STABLE) → `SELECT id FROM businesses WHERE owner_id = auth.uid()`.

Edge Functions that require elevated rights (e.g. account deletion) use the **service_role** key and are carefully scoped (ADR-DB-005); the extract function operates on behalf of the owner in normal cases and never exposes cross-tenant data.

---

## 18. Storage Design

- Bucket: `receipts`, **private** (never `public`). Reject unknown file types; images only.
- Object path: `{business_id}/{transaction_id}/receipt.ext`.
- Policies mirror RLS via `(storage.foldername(name))[1] = current_business_id()::text` — SELECT/INSERT/DELETE for owners, nothing for anon.
- Size cap enforced at app level **and** via `receipts.size_bytes` CHECK (20 MB).
- Upload ordering: row-first, executed **only on confirmation** (see §14). The captured image lives in the app temp area until the user confirms (`mobile-architecture.md`); nothing is uploaded server-side beforehand, so confirm-then-store (NFR-DATA-001) holds by construction.
- No thumbnails/recompression in MVP (capture-side downscale on low-spec devices).

Full design: `storage-design.md`.

---

## 19. Indexes & Performance

18 index structures total (details in `indexes.md`):

- **8 unique constraints** (also serve as FK targets / 1:1 guards): `businesses(owner_id)`, `businesses(web_email) partial`, `categories(business_id,name_key)`, `categories(id,business_id)`, `transactions(id,business_id)`, `receipts(transaction_id)`, `receipts(storage_path)`, `ai_extractions(transaction_id)`.
- **10 standalone indexes**:
  - `transactions`: `(business_id, transaction_date DESC, created_at DESC)`, `(business_id, type, transaction_date DESC)`, `(business_id, category_id, transaction_date DESC)`, `(business_id, amount)`, `(category_id, business_id)` (FK support), GIN `lower(party_name) gin_trgm_ops`.
  - `transaction_items`: `(transaction_id)`, `(business_id)`.
  - `receipts`: `(business_id)`; `ai_extractions`: `(business_id)`.

Extends `pg_trgm` for Arabic party-name search (migration `001`). No materialized views or caches in MVP.

---

## 20. Data Access Patterns

High-level wiring (full pattern + sketches in `data-access-patterns.md`):

- **Mobile (owner JWT):** create business on first sign-in → seeded categories are available automatically; list transactions (today / this month / by type / by category); AI flow = capture (temp file) → `extract-receipt` (image bytes) → confirm → write `transactions` + `ai_extractions` + upload `receipts`; manual entry; edit; delete; hide category.
- **Dashboard (owner JWT via magic link):** same-RLS reads (income vs expense sums, lists, filters, party search), view/delete receipt, edit/delete transaction, toggle web access, link email.
- **Edge Function `extract-receipt`:** owner → sends image bytes (multipart) → function calls Gemini → returns normalized draft; writes nothing; persistence only after client confirmation.
- **Admin account deletion:** service_role function deletes auth user → `owner_id ON DELETE CASCADE` removes the business subtree; storage objects cleaned by the function.

---

## 21. Migration Plan & Deployment

Ordered, additive, idempotent migrations (SQL not produced here; see `migration-plan.md`):

| # | Migration | Contents |
|---|---|---|
| 001 | `extensions` | enable `pg_trgm` |
| 002 | `businesses` | table + constraints |
| 003 | `categories` | table + constraints + immutability guard trigger |
| 004 | `transactions` | table + constraints + FK to categories |
| 005 | `transaction_items` | table + constraints + FK |
| 006 | `receipts` | table + constraints + FK |
| 007 | `ai_extractions` | table + constraints + FK |
| 008 | `updated_at_timestamps` | `set_updated_at()` + triggers |
| 009 | `seed_default_categories` | `SECURITY DEFINER` seeder + AFTER INSERT trigger |
| 010 | `indexes` | composite business indexes, trgm GIN, partial unique web_email |
| 011 | `rls` | `current_business_id()` helper, enable RLS, grants, per-table policies |
| 012 | `storage` | bucket `receipts`, policies, path convention |

Order notes: indexes after tables (avoid stray access paths before RLS exists); RLS last so enabling it is the final hardening step.

---

## Appendix — Traceability, Decisions, Risks

### Traceability
- Every resolved decision Q-001…Q-022 from `docs/requirements/open-questions.md` is reflected (map below). Where a requirement's behaviour is enforced app-side rather than in-schema, that is stated explicitly.
- ADRs for the data model: `docs/database/decisions/ADR-DB-001…005`.

**Decision map (subset of the significant ones):**

| Decision | Impact on schema |
|---|---|
| Q: ownership model — one business per auth user | `businesses.owner_id` UNIQUE; no membership/profiles |
| Q: RLS mandatory | RLS on all 6 tables + private bucket (AGENTS.md) |
| Q-008 confidence/AC-difference handling | threshold logic app-side; schema stores confirmed values + provenance |
| Q-015 web access gating | `web_access_enabled` + `web_email`; per-request server-side gate, not RLS |
| Q: confirm-before-save (NFR-DATA-001) | `ai_extractions` written only post-confirmation |
| Q: deletion | admin Edge Function + `ON DELETE CASCADE`; no owner DELETE on businesses |

### Assumptions (to confirm with product)
1. A custom category that is in use (referenced by ≥1 transaction) cannot be deleted; the app must surface a friendly error. *(Schema enforces via RESTRICT.)*
2. Sum of line items ≠ transaction amount is allowed (shipping/discounts); `transactions.amount` is authoritative.
3. Default seed list is the authoritative 10 categories (`business-rules.md`; ADR-DB-003 §7). The Arabic labels are drafted as proposed UI copy — product may finalize labels without schema impact (`name_key` normalizes them); the set itself is fixed.

### Risks
| Risk | Mitigation |
|---|---|
| RLS on `storage.objects` misuse (path spoofing) | policies keyed off folder prefix AND ownership helper; objects bucket private; no UPDATE policy |
| SECURITY DEFINER seeder becomes a hole | function is tiny, owned by `postgres`, `search_path` pinned, only inserts `type='default'` categories for the passed `NEW.id` |
| Dashboard/web access expanding scope | web access is metadata only + server-side gate; RLS unchanged between clients |
| Numeric field overflow / float corruption | `numeric(14,2)` only; app never computes money in JS floats for totals served to DB |
| Trigger/RLS drift | single place for guard logic; triggers reviewed in model review |