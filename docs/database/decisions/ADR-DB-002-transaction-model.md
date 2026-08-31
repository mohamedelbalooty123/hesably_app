# ADR-DB-002 — Transaction Model

**Status:** Accepted · **Date:** 2026-08-31 · **Scope:** database layer

## Context

The MVP must record income and expense events (AI-confirmed and manual), support optional line items, and give the dashboard its summaries. We must fix the money/date/type representation and decide how far the "accounting" concept goes without over-building.

## Decision

1. **A transaction is a single-currency ledger event row** in `transactions`:
   - `type TEXT CHECK IN ('income','expense')`
   - `amount numeric(14,2) NOT NULL CHECK (amount > 0)`
   - `transaction_date DATE` (business-local date; no time-of-day, no tz)
   - `category_id NOT NULL` → composite same-tenant FK to `categories` `ON DELETE RESTRICT`
   - `party_name TEXT NULL` (free text supplier/customer name; trigram-indexed)
   - `entry_source TEXT CHECK IN ('manual','ai')`
   - `created_at`/`updated_at TIMESTAMPTZ`
2. **Money is always `numeric(14,2)`**; `currency_code` is pinned to `'EGP'` via `CHECK (currency_code = 'EGP')` for MVP.
3. **No double-entry** (no debit/credit pairs, no linked transfers, no ledgers) — a single signed-direction field + positive amount keeps queries trivial and matches the product vocabulary (income/expense).
4. **Optional line items** in `transaction_items` (`description NOT NULL`, `amount NULL CHECK > 0`). There is **no DB invariant** that `SUM(items) = amount` — shipping/discounts/rounding make the transaction amount authoritative (documented assumption).
5. **No inventory/quantity fields, no soft-delete, no audit columns** in MVP.

## Consequences

- Reports (income vs expense, by category/month) are simple indexed `GROUP BY` queries (`data-access-patterns.md` §2).
- AI entries are unambiguously tagged (`entry_source='ai'`) and always paired with an `ai_extractions` provenance row after confirmation (`ai-architecture.md`, NFR-DATA-001).
- Pinning `EGP` via CHECK, not a table/seq, gives a cheap later migration path to real multi-currency.
- `numeric` avoids float drift when summing ledger amounts — critical for a bookkeeping product.
- The "sum of items ≠ total" allowance must be confirmed by product (assumption A2).

## Alternatives considered

- **Decimal vs float:** float rejected (summation drift, bookkeeping).
- **`TIMESTAMPTZ` for transaction date:** rejected — day-boundary ambiguity and dashboard tz churn for a daily book; kept `DATE`.
- **Double-entry journal now:** rejected — MVP product language is income/expense; migration to journals later is additive.
- **PG enum types:** rejected — `TEXT + CHECK` keeps alters cheap and client SDKs simple (AGENTS.md conventions).