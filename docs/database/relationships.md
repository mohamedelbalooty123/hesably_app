# Relationships — Smart Invoice Assistant

Complete foreign-key and integrity map for the MVP schema. Design-stage reference (no SQL produced).

---

## 1. Relationship inventory

### 1.1 Single-column FKs

| # | Constraint | Child (column) | Parent (column) | ON DELETE | Purpose |
|---|---|---|---|---|---|
| 1 | `businesses_owner_id_fkey` | `businesses.owner_id` | `auth.users(id)` | CASCADE | 1:1 owner (tenant root). Cascade removes the whole tenant when the account is deleted (ADR-DB-005). |
| 2 | `categories_business_id_fkey` | `categories.business_id` | `businesses(id)` | CASCADE | tenant scoping |
| 3 | `transactions_business_id_fkey` | `transactions.business_id` | `businesses(id)` | CASCADE | tenant scoping |
| 4 | `transaction_items_business_id_fkey` | `transaction_items.business_id` | `businesses(id)` | CASCADE | tenant scoping (denormalized) |
| 5 | `receipts_business_id_fkey` | `receipts.business_id` | `businesses(id)` | CASCADE | tenant scoping (denormalized) |
| 6 | `ai_extractions_business_id_fkey` | `ai_extractions.business_id` | `businesses(id)` | CASCADE | tenant scoping (denormalized) |

### 1.2 Composite same-tenant FKs (the isolation guarantee)

| # | Constraint | Child (columns) | Parent (columns) | ON DELETE | Purpose |
|---|---|---|---|---|---|
| 7 | `transactions_category_business_fkey` | `transactions(category_id, business_id)` | `categories(id, business_id)` | **RESTRICT** | category must belong to the same business; cannot delete an in-use category |
| 8 | `transaction_items_txn_business_fkey` | `transaction_items(transaction_id, business_id)` | `transactions(id, business_id)` | CASCADE | line items die with their transaction, same tenant |
| 9 | `receipts_txn_business_fkey` | `receipts(transaction_id, business_id)` | `transactions(id, business_id)` | CASCADE | receipt dies with its transaction, same tenant |
| 10 | `ai_extractions_txn_business_fkey` | `ai_extractions(transaction_id, business_id)` | `transactions(id, business_id)` | CASCADE | provenance dies with its transaction, same tenant |

**Why composite:** a child write carries both `business_id` and the parent's id; the FK validates *both* match a parent row with that same tenant. Cross-tenant references become impossible to construct — even through a bug or a compromised session — because no `(id, business_id)` pair exists outside the tenant.

## 2. Parent unique targets

Each composite FK references a UNIQUE key on the parent:

| Parent | Unique target |
|---|---|
| `businesses` | `id` (PK) |
| `categories` | `(id, business_id)` |
| `transactions` | `(id, business_id)` |

`transactions` exposes `UNIQUE(id, business_id)` purely so three children can point at it same-tenant.

## 3. Delete behavior summary

| Deleting… | Result |
|---|---|
| Auth user (account) | `businesses` row + all children via cascade chain |
| Business | cascade deletes categories/transactions/items/receipts/extractions; storage objects are **not** removed by the DB (the app / admin function cleans them; RLS storage DELETE is owner-scoped) |
| Transaction | cascade deletes line items, receipt row, extraction row |
| Category | **RESTRICT** if referenced by any transaction (even a hidden one); else allowed for custom; defaults blocked by RLS+trigger |

## 4. Integrity rules beyond FKs

- **CHECKs:** enum domains (`type`, `entry_source`, `currency_code`), `amount > 0`, `mime_type LIKE 'image/%'`, `size_bytes` between 1 and 20 MB, length bounds on names.
- **UNIQUEs:** `owner_id` (1:1), `(business_id, name_key)`, `transaction_id` on receipts & extractions (1:1), `storage_path`.
- **Triggers:** `set_updated_at()` on the 4 mutable tables; `categories_guard_default_immutable()` (rejects identity edits to categories).
- **RLS** is enabled on all six tables — see `rls-matrix.md`; it is the access wall, while FKs guarantee structural correctness.

## 5. Referential integrity matrix (child → parent)

| Child table | Parent `businesses` | Parent `categories` | Parent `transactions` |
|---|---|---|---|
| `categories` | ✅ business_id CASCADE | — | — |
| `transactions` | ✅ business_id CASCADE | ✅ (category_id, business_id) RESTRICT | — |
| `transaction_items` | ✅ business_id CASCADE | — | ✅ (transaction_id, business_id) CASCADE |
| `receipts` | ✅ business_id CASCADE | — | ✅ (transaction_id, business_id) CASCADE |
| `ai_extractions` | ✅ business_id CASCADE | — | ✅ (transaction_id, business_id) CASCADE |

## 6. Dependency graph

```
auth.users
   └── businesses ──────┬── categories (1:N)
        (1:1 owner)      ├── transactions (1:N) ──┬── transaction_items (0:N)
                         │                         ├── receipts (0..1, UNIQUE txn)
                         │                         └── ai_extractions (0..1, UNIQUE txn)
                         └── (denormalized business_id on every child)
```

## 7. Design notes / decisions

- **Denormalized `business_id`** on items/receipts/extractions is intentional: it powers RLS with a single cheap predicate (`business_id = current_business_id()`) in every policy, and it is *required* to express composite same-tenant FKs. Risk (redundancy) is contained because the composite FKs force it to always match the parent's tenant.
- **`RESTRICT` on category→transaction** implements the business rule "a category in use cannot be deleted". The app surfaces the constraint as a friendly error (assumption A1, `database-design.md` Appendix).
- **No cross-tenant join is expressible**: the only association tables are the six business tables, all tenant-keyed.
- No un-pinned `SECURITY DEFINER` functions participate in relationships; the one exception (seeding) is documented and scoped (migration 009).