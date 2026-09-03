-- Migration 004: transactions — income/expense ledger events
-- Composite same-tenant FK to categories (RESTRICT prevents deleting in-use categories)
-- party_name bounded ≤ 255 (LOW-03)

CREATE TABLE transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL,
    category_id uuid NOT NULL,
    type text NOT NULL CHECK (type IN ('income', 'expense')),
    amount numeric(14,2) NOT NULL CHECK (amount > 0),
    transaction_date date NOT NULL,
    party_name text CHECK (party_name IS NULL OR length(trim(party_name)) BETWEEN 1 AND 255),
    entry_source text NOT NULL CHECK (entry_source IN ('manual', 'ai')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- FK to businesses: cascade deletes transactions when business is removed
ALTER TABLE transactions
    ADD CONSTRAINT transactions_business_id_fkey
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE;

-- Composite same-tenant FK to categories: category must belong to same business
-- RESTRICT prevents deleting a category that is in use
ALTER TABLE transactions
    ADD CONSTRAINT transactions_category_business_fkey
    FOREIGN KEY (category_id, business_id) REFERENCES categories(id, business_id) ON DELETE RESTRICT;

-- Unique target for composite FKs from transaction_items, receipts, ai_extractions
ALTER TABLE transactions
    ADD CONSTRAINT transactions_id_business_key
    UNIQUE (id, business_id);
