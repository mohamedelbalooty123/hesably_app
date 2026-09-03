# ADR-DB-003 — Category Model & Seeding

**Status:** Accepted · **Date:** 2026-08-31 · **Scope:** database layer

## Context

Categories classify income/expense transactions and are required on every transaction. Business rules require (a) a fixed set of defaults available immediately, (b) owner-created custom categories, (c) defaults can be hidden but not renamed/deleted, (d) an in-use category cannot be deleted. We must decide the seeding mechanism and how "default" is represented.

## Decision

1. **`categories` table**: `name`, `name_key` (normalized: trim + lower + NFC), `type TEXT CHECK IN ('default','custom') DEFAULT 'custom'`, `is_hidden boolean DEFAULT false`, `UNIQUE(business_id, name_key)`, `UNIQUE(id, business_id)` (FK target).
2. **Seeding is an AFTER INSERT trigger on `businesses`** → `seed_default_categories_for_business()`, a **narrow `SECURITY DEFINER`** function (owned by `postgres`, `search_path` pinned, parameterized with the new `business_id`, inserts only `type='default'` rows).
3. **Clients can only create `custom` rows**: RLS INSERT `WITH CHECK (business_id = current_business_id() AND type = 'custom')`.
4. **Default identity is immutable; custom identity is editable**: `categories_guard_default_immutable()` BEFORE UPDATE trigger rejects changing `business_id` and `type` for **all** rows (no cross-business move, no default/custom conversion), and rejects changing `name`/`name_key` **only for `type='default'`** rows. Custom categories **can** be renamed (`name`/`name_key`) per FR-CATEGORY-004 / BR-CATEGORY-005. `is_hidden` stays editable on both types. *(Amended 2026-08-31 — HIGH-01: the original guard blocked renaming custom categories, which would have broken the custom-category edit workflow.)*
5. **Defaults cannot be deleted**: RLS DELETE requires `business_id = current_business_id() AND type = 'custom'`.
6. **In-use custom categories cannot be deleted**: composite FK `transactions(category_id, business_id) → categories(id, business_id) ON DELETE RESTRICT`. The app surfaces a friendly error (assumption A1).
7. **Default seed list** is the authoritative 10 (`business-rules.md`): Sales, Purchases/Stock, Rent, Salaries, Utilities, Transport, Marketing, Maintenance, Taxes/Fees, Other — with drafted Arabic labels (مبيعات، مشتريات، إيجار، مرتبات، فواتير، نقل، تسويق، صيانة، ضرائب ورسوم، أخرى). The set is fixed by the rule; Arabic labels are UI copy only (assumption A3 closed).
8. **Seeder is trigger-only**: `seed_default_categories_for_business()` **`REVOKE EXECUTE` from `public`, `anon`, `authenticated`** — reachable only through the AFTER INSERT trigger path (runs as `postgres`). *(Amended 2026-08-31 — HIGH-02: Postgres grants EXECUTE to PUBLIC by default; without the revoke an `authenticated` client could invoke the SECURITY DEFINER seeder via the Data API and insert default categories into another tenant's business.)*

## Consequences

- Defaults exist the instant a business is created — no client-side provisioning race.
- `SECURITY DEFINER` surface area is minimal (single function, single purpose, owned by the DB superuser, `search_path` pinned) and **not client-callable** (EXECUTE revoked), so even a pathological Data API call cannot invoke the seeder; the RLS INSERT guard additionally prevents clients from creating `default` rows.
- Hiding defaults works. Renaming a default and type-converting/moving **any** category are refused by the trigger; renaming a **custom** category works (customs are otherwise deleted & recreated).
- Deleting a used category is impossible at the DB level — safe for historical transactions.

## Alternatives considered

- **Client-side seeding on first app open:** rejected — requires app changes to add a default later, races with first insert, forgets dashboards.
- **Generic `SECURITY DEFINER` RPC ("set any business fields")**: rejected — tall attack surface; we chose the 10-line seeder.
- **Seed via `INSERT ... SELECT` in an RPC with `grant execute to authenticated` only**: same intent but wider blast radius (client-invokable); trigger approach works even for service-role/backfill inserts.
- **`is_default boolean` instead of `type`:** rejected — block the accidental "two kinds of default" ambiguity; `type` leaves room for future kinds.