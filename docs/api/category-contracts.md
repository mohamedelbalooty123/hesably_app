# Category Contracts — Smart Invoice Assistant

Contracts for category management: defaults, custom categories, shared state across mobile and web, and the hidden-not-deleted pattern.

---

## 1. Category Model

| Property | Value |
|---|---|
| **Storage** | Supabase Postgres `categories` table |
| **Sharing** | Single table shared by Mobile and Web (Q-021, BR-CATEGORY-006) |
| **Scope** | Business-scoped (each business has its own set) |
| **Ownership** | `business_id = current_business_id()` via RLS |

### Category Types

| Type | Behavior |
|---|---|
| `default` | Seeded per business at onboarding; cannot be deleted, renamed, or re-typed; can be hidden |
| `custom` | Created by owner; can be renamed, hidden, or deleted (if not in use) |

---

## 2. Default Categories

The authoritative default list (10 categories, Q-010):

| # | Name (Arabic) | Name (English) |
|---|---|---|
| 1 | مبيعات | Sales |
| 2 | مشتريات | Purchases / Stock |
| 3 | إيجار | Rent |
| 4 | مرتبات | Salaries |
| 5 | فواتير | Utilities |
| 6 | نقل | Transport |
| 7 | تسويق | Marketing |
| 8 | صيانة | Maintenance |
| 9 | ضرائب ورسوم | Taxes / Fees |
| 10 | أخرى | Other |

> Arabic `name` values must match exactly what `seed_default_categories_for_business()` inserts (authoritative list in `docs/database/database-design.md` §Seed list, `ADR-DB-003`, and migration `009`). These are the stored `categories.name` values, so AI category suggestion matching and pickers reference the same strings. ADR-DB-003 notes Arabic labels are UI copy only (assumption A3 closed) — treat this table as the single source for display and for `suggested_category` matching.

### Seeding Mechanism

| Field | Value |
|---|---|
| **Trigger** | AFTER INSERT on `businesses` |
| **Function** | `seed_default_categories_for_business()` — SECURITY DEFINER (postgres-owned) |
| **Action** | Inserts 10 default category rows with `type='default'` for the new business |
| **Execution** | Automatic; no client action required |
| **Security** | Function `REVOKE EXECUTE` from `public`/`anon`/`authenticated` — reachable only through trigger path |

---

## 3. Read Categories

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT on `categories` |
| **Auth** | Authenticated session; RLS-scoped |
| **Input** | Optional: `is_hidden` filter |
| **Output** | Array of `{id, name, type, is_hidden, created_at, updated_at}` |
| **RLS** | SELECT: `business_id = current_business_id()` |
| **Ordering** | Defaults first (by name), then custom (by name) |
| **Hidden categories** | Included in results; clients may filter for selection lists |
| **Index** | `idx_categories_business_name` (U3 unique constraint) |
| **Requirements** | FR-CATEGORY-001..005, BR-CATEGORY-001..008 |

---

## 4. Create Custom Category

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → INSERT on `categories` |
| **Auth** | Authenticated session; RLS-scoped |
| **Input** | `name` (text, 1-100 chars) |
| **Output** | Created category row |
| **RLS** | INSERT: `CHECK (business_id = current_business_id() AND type = 'custom')` |
| **Normalization** | Client normalizes name: trim + lower + NFC → stored as `name_key` |
| **Uniqueness** | UNIQUE constraint on `(business_id, name_key)` — no duplicate names per tenant (Q-021) |
| **Guard trigger** | `categories_guard_default_immutable()` rejects `type` changes — clients can only create `type='custom'` |
| **Error cases** | Duplicate name after normalization (400/409), validation failure, network failure |
| **Requirements** | FR-CATEGORY-003, FR-WEB-CATEGORY-002, BR-CATEGORY-003, BR-CATEGORY-008, Q-021 |

---

## 5. Update Category

### 5.1 Hide / Unhide (Default or Custom)

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → UPDATE on `categories` |
| **Input** | `id`, `is_hidden` (boolean) |
| **Output** | Updated row |
| **RLS** | UPDATE: `USING (business_id = current_business_id()), CHECK (business_id = current_business_id())` |
| **Guard** | `is_hidden` is the only field editable on default categories (guard trigger blocks `name`/`name_key`/`type`/`business_id` changes) |
| **Hidden behavior** | Hidden categories remain valid for historical transactions, reports, and filters; hidden from new-transaction category picker |
| **Requirements** | FR-CATEGORY-005, FR-WEB-CATEGORY-003, BR-CATEGORY-004 |

### 5.2 Rename Custom Category

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → UPDATE on `categories` |
| **Input** | `id`, `name` (new name) |
| **Output** | Updated row (`name` + `name_key` updated) |
| **Normalization** | New name normalized; uniqueness checked against `(business_id, name_key)` |
| **Guard** | Guard trigger blocks rename on `type='default'` categories |
| **Error cases** | Duplicate name, rename of default category (rejected by trigger) |
| **Requirements** | FR-CATEGORY-004, BR-CATEGORY-005 |

---

## 6. Delete Custom Category

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → DELETE on `categories` |
| **Input** | `id` |
| **Output** | Confirmation |
| **RLS** | DELETE: `USING (business_id = current_business_id() AND type = 'custom')` |
| **FK constraint** | `transactions.category_id` → `categories(id, business_id)` with `ON DELETE RESTRICT` — blocks deletion if any transaction references this category |
| **Default categories** | No DELETE policy matches for default categories; deletion impossible through client path |
| **Error cases** | Category in use (FK RESTRICT → friendly error), default category (blocked by RLS + no policy match) |
| **Requirements** | FR-CATEGORY-004/005, BR-CATEGORY-004/005 |

---

## 7. Category Usage Count (Web)

| Field | Value |
|---|---|
| **Client** | Next.js Dashboard |
| **Path** | Direct Supabase → SELECT with COUNT on `transactions` GROUP BY `category_id` |
| **Input** | None (all categories for the business) |
| **Output** | Array of `{category_id, usage_count}` |
| **RLS** | Both `categories` and `transactions` SELECT policies apply |
| **Index** | I3 (business_id, category_id, transaction_date) supports the count |
| **Requirements** | FR-WEB-CATEGORY-001, BR-CATEGORY-007 |

---

## 8. Category Data Shape

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `business_id` | uuid | FK → businesses; RLS scope |
| `name` | text | Display name (1-100 chars) |
| `name_key` | text | Normalized (trim + lower + NFC) |
| `type` | text | 'default' or 'custom' |
| `is_hidden` | boolean | Default false |
| `created_at` | timestamptz | Auto-set |
| `updated_at` | timestamptz | Trigger-set |

---

## 9. Traceability

| Category element | Requirement / Decision IDs |
|---|---|
| Default list + seeding | FR-CATEGORY-001, BR-CATEGORY-001, Q-010 |
| AI category suggestion | FR-CATEGORY-002, BR-CATEGORY-002 |
| Custom create | FR-CATEGORY-003, FR-WEB-CATEGORY-002, BR-CATEGORY-003, BR-CATEGORY-008, Q-021 |
| Custom edit/delete | FR-CATEGORY-004/005, FR-WEB-CATEGORY-002, BR-CATEGORY-005 |
| Default hidden-not-deleted | FR-CATEGORY-005, FR-WEB-CATEGORY-003, BR-CATEGORY-004, Q-010 |
| Shared across platforms | BR-CATEGORY-006, Q-021 |
| Usage count | FR-WEB-CATEGORY-001, BR-CATEGORY-007 |
| No duplicates | BR-CATEGORY-008, Q-021 |
