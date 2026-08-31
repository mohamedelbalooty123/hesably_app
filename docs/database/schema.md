# Schema — Smart Invoice Assistant

Design-stage reference. **No SQL is generated in this deliverable; tables below are the agreed DDL surface.**

- Rules: `TEXT`+`CHECK` enums, `numeric(14,2)` money, `DATE` business dates, `TIMESTAMPTZ` audit timestamps, `uuid` PKs.
- All six tables have RLS enabled (see `rls-matrix.md`).
- Column set is **complete for MVP** — do not add Phase 2/3 fields (inventory, multi-currency, soft-delete, audit).

---

## 1. `businesses` — tenant root (1:1 with an auth user)

| Column | Type | Nullable | Default | Constraints |
|---|---|---|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `owner_id` | `uuid` | no | — | **UNIQUE**; FK → `auth.users(id)` ON DELETE CASCADE |
| `name` | `text` | no | — | `CHECK (length(trim(name)) BETWEEN 1 AND 100)` |
| `currency_code` | `text` | no | `'EGP'` | `CHECK (currency_code = 'EGP')` |
| `web_access_enabled` | `boolean` | no | `false` | — |
| `web_email` | `text` | yes | — | **partial UNIQUE** `WHERE web_email IS NOT NULL` |
| `created_at` | `timestamptz` | no | `now()` | — |
| `updated_at` | `timestamptz` | no | `now()` | set by trigger |

Notes:
- Exactly one business per owner (UNIQUE `owner_id`). Owner deletion cascades the whole tenant (ADR-DB-005).
- `web_email` is a portal gate only (Q-015). It participates in **no** RLS checks and grants no DB authorization.

---

## 2. `categories`

| Column | Type | Nullable | Default | Constraints |
|---|---|---|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | no | — | FK → `businesses(id)` ON DELETE CASCADE |
| `name` | `text` | no | — | `CHECK (length(trim(name)) BETWEEN 1 AND 100)` |
| `name_key` | `text` | no | — | normalized (trim + lower + NFC) |
| `type` | `text` | no | `'custom'` | `CHECK (type IN ('default','custom'))` |
| `is_hidden` | `boolean` | no | `false` | — |
| `created_at` | `timestamptz` | no | `now()` | — |
| `updated_at` | `timestamptz` | no | `now()` | set by trigger |

Table-level:
- `UNIQUE (business_id, name_key)` — no duplicate names per tenant.
- `UNIQUE (id, business_id)` — target for the composite FK from `transactions`.

Behavior notes:
- Seeded per business (AFTER INSERT on `businesses`) by `seed_default_categories_for_business()` — migration `009`.
- Clients may INSERT only `type='custom'` (RLS `WITH CHECK`).
- Defaults: cannot be renamed (guard trigger), cannot be deleted (RLS DELETE policy). Custom: deletable if unused (FK `RESTRICT` blocks in-use).
- `is_hidden` is editable on both types.

---

## 3. `transactions`

| Column | Type | Nullable | Default | Constraints |
|---|---|---|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | no | — | FK → `businesses(id)` ON DELETE CASCADE |
| `category_id` | `uuid` | no | — | composite FK `(category_id, business_id)` → `categories(id, business_id)` ON DELETE RESTRICT |
| `type` | `text` | no | — | `CHECK (type IN ('income','expense'))` |
| `amount` | `numeric(14,2)` | no | — | `CHECK (amount > 0)` |
| `transaction_date` | `date` | no | — | business-local date (no tz) |
| `party_name` | `text` | yes | — | free text (supplier/customer) |
| `entry_source` | `text` | no | — | `CHECK (entry_source IN ('manual','ai'))` |
| `created_at` | `timestamptz` | no | `now()` | — |
| `updated_at` | `timestamptz` | no | `now()` | set by trigger |

Table-level:
- `UNIQUE (id, business_id)` — target for composite FKs from `transaction_items`, `receipts`, `ai_extractions`.

Notes:
- `category_id` is required, so deleting an in-use category is impossible (RESTRICT).
- AI entries are written only after user confirmation; `entry_source='ai'` must be accompanied (in the same client call) by an `ai_extractions` row.
- `party_name` search uses a trigram index on `lower(party_name)`.

---

## 4. `transaction_items` — optional line items

| Column | Type | Nullable | Default | Constraints |
|---|---|---|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `transaction_id` | `uuid` | no | — | composite FK `(transaction_id, business_id)` → `transactions(id, business_id)` ON DELETE CASCADE |
| `business_id` | `uuid` | no | — | FK → `businesses(id)` ON DELETE CASCADE (denormalized) |
| `description` | `text` | no | — | `CHECK (length(trim(description)) BETWEEN 1 AND 255)` |
| `amount` | `numeric(14,2)` | yes | — | `CHECK (amount > 0)` (null = unit price unknown/aggregated) |
| `created_at` | `timestamptz` | no | `now()` | — |
| `updated_at` | `timestamptz` | no | `now()` | set by trigger |

Notes:
- No quantity/stock fields (MVP). No DB invariant tying `SUM(amount)` to `transactions.amount` (assumption; authoritative value is the transaction amount).

---

## 5. `receipts` — immutable image record

| Column | Type | Nullable | Default | Constraints |
|---|---|---|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `transaction_id` | `uuid` | no | — | **UNIQUE**; composite FK `(transaction_id, business_id)` → `transactions(id, business_id)` ON DELETE CASCADE |
| `business_id` | `uuid` | no | — | FK → `businesses(id)` ON DELETE CASCADE (denormalized) |
| `storage_path` | `text` | no | — | **UNIQUE** — path `{business_id}/{transaction_id}/receipt.ext` |
| `original_filename` | `text` | no | — | display name |
| `mime_type` | `text` | no | — | `CHECK (mime_type LIKE 'image/%')` |
| `size_bytes` | `bigint` | no | — | `CHECK (size_bytes > 0 AND size_bytes <= 20971520)` |
| `created_at` | `timestamptz` | no | `now()` | — |

Behavior notes:
- **Immutable**: no `updated_at`, no UPDATE policy, no DELETE-friendly flow beyond removing the whole transaction or deleting the record via an explicit owner DELETE (policy allows owner DELETE).
- 1:1 per transaction (`UNIQUE transaction_id`).
- Path embeds the tenant and transaction — storage policies + object lifecycle rely on it.

---

## 6. `ai_extractions` — immutable AI provenance snapshot

| Column | Type | Nullable | Default | Constraints |
|---|---|---|---|---|
| `id` | `uuid` | no | `gen_random_uuid()` | PK |
| `transaction_id` | `uuid` | no | — | **UNIQUE**; composite FK `(transaction_id, business_id)` → `transactions(id, business_id)` ON DELETE CASCADE |
| `business_id` | `uuid` | no | — | FK → `businesses(id)` ON DELETE CASCADE (denormalized) |
| `model` | `text` | no | — | practice: `gemini-3.1-flash-lite` (Q-007); provenance label only |
| `overall_confidence` | `numeric(3,2)` | no | — | `CHECK (overall_confidence BETWEEN 0 AND 1)` |
| `extracted_fields` | `jsonb` | no | — | immutable snapshot of AI-returned fields; shape per `ai-architecture.md` prompt contract |
| `field_confidences` | `jsonb` | yes | — | per-field confidence snapshot |
| `created_at` | `timestamptz` | no | `now()` | — |

Behavior notes:
- Written **only after user confirmation** (NFR-DATA-001). Never written directly by the extract function.
- Values here never drive access control; they are auditability and retraining inputs.
- **Immutable**: no UPDATE/DELETE policies; removal happens only via transaction cascade.

---

## 7. Helper functions

| Function | Type | Security | Purpose |
|---|---|---|---|
| `current_business_id()` | `TABLE/returns uuid` | SECURITY INVOKER, STABLE | `SELECT id FROM businesses WHERE owner_id = auth.uid()`; backbones all RLS policies |
| `set_updated_at()` | trigger | SECURITY INVOKER | sets `updated_at = now()` on `businesses`, `categories`, `transactions`, `transaction_items` |
| `categories_guard_default_immutable()` | trigger | SECURITY INVOKER | rejects identity changes (`name`,`name_key`,`type`,`business_id`) on any category row |
| `seed_default_categories_for_business()` | function | **SECURITY DEFINER** (owned by `postgres`, `search_path` pinned) | inserts default categories for a newly created business; fired by AFTER INSERT trigger |

---

## 8. Type glossary

| Type | Where | Why |
|---|---|---|
| `numeric(14,2)` | `amount`, money fields | exact decimal arithmetic; range up to ¥/LE trillion — ample for MVPs |
| `date` | `transaction_date` | business date; time-of-day irrelevant and avoids tz ambiguity |
| `timestamptz` | `created_at`/`updated_at` | machine truth at instant; stored in UTC by Postgres |
| `jsonb` | `extracted_fields`, `field_confidences` | vendor-neutral AI payload; validated in app; immutable snapshots |
| `text` | everything labelled `text` | enums are `TEXT`+`CHECK`; Arabic-safe (no special collation) |
| `bigint` | `size_bytes` | file sizes can exceed int4 range safely |