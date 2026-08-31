# Indexes — Smart Invoice Assistant

Design-stage index plan for the MVP query patterns. **18 index structures total: 8 unique constraints (that also serve lookups/FK targets) + 10 standalone indexes.**

> No SQL generated. Sizes/benefits are estimates for design review, not guarantees.

---

## 1. Unique constraints (also indexes)

| # | Name (constraint) | Table / columns | Serves / why |
|---|---|---|---|
| U1 | `businesses_owner_id_key` | `businesses(owner_id)` | 1:1 owner; lookup business-by-user on every authenticated request (hot path — `current_business_id()`) |
| U2 | `businesses_web_email_key` (partial) | `businesses(web_email)` `WHERE web_email IS NOT NULL` | one linked dashboard email per project universe; unique portal identity |
| U3 | `categories_business_name_key` | `categories(business_id, name_key)` | no duplicate category names per tenant; name lookup |
| U4 | `categories_id_business_key` | `categories(id, business_id)` | FK target for `transactions(category_id, business_id)` |
| U5 | `transactions_id_business_key` | `transactions(id, business_id)` | FK target for items/receipts/extractions composite FKs |
| U6 | `receipts_transaction_id_key` | `receipts(transaction_id)` | 1:1 receipt-per-transaction; lookup by txn |
| U7 | `receipts_storage_path_key` | `receipts(storage_path)` | dedupe/consistency between object store and receipt records |
| U8 | `ai_extractions_transaction_id_key` | `ai_extractions(transaction_id)` | 1:1 extraction-per-transaction |

## 2. Standalone indexes

| # | Name | Table (columns, order) | Type | Query pattern served | Why / benefit | Trade-off |
|---|---|---|---|---|---|---|
| I1 | `idx_transactions_business_date` | `transactions(business_id, transaction_date DESC, created_at DESC)` | btree | default list "transactions of this business, newest first"; month ranges | one index for the most common sort; covers RLS predicate + order by | extra write cost per insert |
| I2 | `idx_transactions_business_type_date` | `transactions(business_id, type, transaction_date DESC)` | btree | filter tab income/expense + date sort | filtered list stays index-ordered | — |
| I3 | `idx_transactions_business_category_date` | `transactions(business_id, category_id, transaction_date DESC)` | btree | category-filtered list & per-category totals | supports dashboard "by category" drill-down | — |
| I4 | `idx_transactions_business_amount` | `transactions(business_id, amount)` | btree | largest-expense / amount-range lookups | dashboard "largest transactions" | uncommon pattern; but cheap |
| I5 | `idx_transactions_category_business` | `transactions(category_id, business_id)` | btree | FK enforcement for RESTRICT (category in use?) + category join | avoids full scan when deleting a category | redundant lead column with I3 lead; retained because delete-time correctness matters more than double-write |
| I6 | `idx_transactions_party_name_trgm` | `transactions lower(party_name) gin_trgm_ops` | **GIN trigram** | contains-search on Arabic supplier/customer name | `ILIKE '%فطير%'`-style search uses the GIN index; unaccent-friendly | GIN larger, slower writes; only on `party_name` (low cardinality table) — fine for MVP |
| I7 | `idx_transaction_items_transaction` | `transaction_items(transaction_id)` | btree | fetch line items for a transaction | FK-support (faster cascade/RESTRICT checks) + join | — |
| I8 | `idx_transaction_items_business` | `transaction_items(business_id)` | btree | RLS predicate on items; business-scoped deletes | keeps delete-cascade of a business cheap | — |
| I9 | `idx_receipts_business` | `receipts(business_id)` | btree | RLS predicate + storage reconciliation queries | — | — |
| I10 | `idx_ai_extractions_business` | `ai_extractions(business_id)` | btree | RLS predicate + provenance queries | — | — |

## 3. Extension

`pg_trgm` (migration `001`) — required by I6. Enables trigram similarity / `ILIKE` substring search on multilingual (Arabic) text.

## 4. What we deliberately do NOT index

- `web_email` beyond the partial unique (low volume; one row per business).
- JSONB paths inside `extracted_fields` / `field_confidences` — read-only provenance, never filtered; no GIN/jsonb-path index in MVP.
- `category_id` historical per-month aggregates beyond I3 — MVP volumes do not justify partial/expression indexes; revisit at Phase 2 with real `EXPLAIN` data.
- No materialized views / summary tables / cache tables (dashboard aggregates stay on primary indexes; revisit at scale).

## 5. Hot-path justification

`current_business_id()` fires on every authenticated request → U1 must stay hot. Every list query starts with `business_id = <uuid>` → each table's leading `business_id` index gives a tight range scan before any sort/filter. RLS predicates and ordering are deliberately index-aligned.

## 6. Maintenance notes

- All indexes are plain btree/GIN; autovacuum defaults apply.
- Revisit with `pg_stat_user_indexes` after the first real dataset (Phase 1 post-MVP): drop any index above ~1% usage that isn't U1…U8 (FK integrity).
- Arabic text normalization (unaccent) is applied at write time into `name_key`; search normalization at query time — keep both sides consistent.