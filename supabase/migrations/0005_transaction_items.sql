-- Migration 005: transaction_items — optional line items
-- Composite FK to transactions (CASCADE), denormalized business_id FK to businesses

CREATE TABLE transaction_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id uuid NOT NULL,
    business_id uuid NOT NULL,
    description text NOT NULL CHECK (length(trim(description)) BETWEEN 1 AND 255),
    amount numeric(14,2) CHECK (amount IS NULL OR amount > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- FK to businesses: cascade deletes items when business is removed
ALTER TABLE transaction_items
    ADD CONSTRAINT transaction_items_business_id_fkey
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE;

-- Composite same-tenant FK to transactions: line items die with their transaction
ALTER TABLE transaction_items
    ADD CONSTRAINT transaction_items_txn_business_fkey
    FOREIGN KEY (transaction_id, business_id) REFERENCES transactions(id, business_id) ON DELETE CASCADE;
