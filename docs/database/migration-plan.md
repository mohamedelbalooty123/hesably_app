# Migration Plan — Smart Invoice Assistant

Ordered, additive, idempotent migrations for the MVP datastore. **Design-stage only — SQL is deliberately not produced here**; each row describes what the migration will contain and why it sits where it does.

Sequencing principles:
1. Extensions → tables → triggers/functions → indexes → **RLS last**.
2. RLS is enabled only after every table/grant exists, so enabling it is the final hardening step (no window where a table is exposed).
3. Each migration is independent and reversible-in-practice (additive DDL), keeping rollback to "drop objects added by this version".

---

| # | Migration name | Contents | Rationale / notes |
|---|---|---|---|
| 001 | `extensions` | `CREATE EXTENSION IF NOT EXISTS pg_trgm` | needed by `idx_transactions_party_name_trgm` (I6) |
| 002 | `businesses` | table, PK, `owner_id` UNIQUE FK → `auth.users(id)` ON DELETE CASCADE, `currency_code`/`name` CHECKs, partial UNIQUE `web_email` | tenant root first; nothing depends on the rest yet |
| 003 | `categories` | table, `UNIQUE(business_id, name_key)`, `UNIQUE(id, business_id)`, `type` CHECK, guard trigger **`categories_guard_default_immutable()`** | guard logic ships with the table so identity edits are impossible from day one. **Reject `business_id`/`type` changes on ALL rows; reject `name`/`name_key` changes ONLY on `type='default'`** (custom rename must work — HIGH-01) |
| 004 | `transactions` | table, UNIQUE(id,business_id), CHECKs (**incl. `party_name` bound ≤ 255**, `amount>0`, `type`, `entry_source`), **composite FK `(category_id,business_id) → categories(id,business_id) ON DELETE RESTRICT`** | core ledger event; category dependency enforced now. `party_name` bounded per LOW-03 |
| 005 | `transaction_items` | table, composite FK → transactions CASCADE, denormalized `business_id` FK | optional line items |
| 006 | `receipts` | table, UNIQUE `transaction_id` + `storage_path`, composite FK → transactions CASCADE, mime/size CHECKs, no `updated_at` | immutable image record |
| 007 | `ai_extractions` | table, UNIQUE `transaction_id`, composite FK → transactions CASCADE, confidence CHECK, no `updated_at` | immutable provenance snapshot |
| 008 | `updated_at_timestamps` | `set_updated_at()` trigger fn + triggers on `businesses`, `categories`, `transactions`, `transaction_items` | uniform mutation stamping; omitted from immutable tables |
| 009 | `seed_default_categories` | `seed_default_categories_for_business()` (`SECURITY DEFINER`, owned by `postgres`, `search_path` pinned) + AFTER INSERT trigger on `businesses`; **`REVOKE EXECUTE ON FUNCTION … FROM public, anon, authenticated`** (HIGH-02) + `transactions_ai_provenance_guard()` trigger (MEDIUM-01) | defaults appear the moment a business exists; narrow scope, no generic permissions; seeder reachable only via trigger; AI provenance enforced |
| 010 | `indexes` | all 10 standalone indexes (incl. GIN trgm, composite business+date, FK-support) | created after tables exist; before RLS so planning is clean |
| 011 | `rls` | `current_business_id()` helper (INVOKER/STABLE) → enable RLS on all 6 tables → grants (authenticated/anon) → per-table policies (incl. `type='custom'` INSERT/delete guards; no UPDATE on immutable tables; no DELETE on `businesses`/`ai_extractions`) | final hardening layer; helper first so policies resolve |
| 012 | `storage` | bucket `receipts` (private), object policies (owner path SELECT/INSERT/DELETE; none for anon), size/file-type guidance | storage isolated per tenant; mirrors table RLS |

---

## Rollback / drift notes

- Additive migrations: rollback = `DROP TABLE … ` in reverse order, or revert migration history; no data loss is expected pre-`001` because nothing exists yet.
- `009` seeder is idempotent with the UNIQUE `(business_id, name_key)` — never double-seeds.
- If a migration prefix collides with a future local migration, renumber locally before first apply (nothing applied to any environment yet).
- **Gate:** model review (this deliverable set) must sign off before `001` is authored/run.
- Apply order is linear; no branching or data backfills in MVP.

## Verification steps (post-apply, once SQL exists)

1. `SELECT` as `anon` → zero rows everywhere.
2. Authenticated owner: full CRUD on own data, none on a second test tenant's data.
3. Delete a category in use → RESTRICT error surfaces gracefully.
4. Delete a transaction → items/receipt/extraction cascade; storage object removed by app/admin.
5. Create a second business → default categories seeded once.