-- Migration 006: receipts — immutable image record (0..1 per transaction)
-- No updated_at (immutable)

CREATE TABLE receipts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id uuid NOT NULL UNIQUE,
    business_id uuid NOT NULL,
    storage_path text NOT NULL UNIQUE,
    original_filename text NOT NULL,
    mime_type text NOT NULL CHECK (mime_type LIKE 'image/%'),
    size_bytes bigint NOT NULL CHECK (size_bytes > 0 AND size_bytes <= 20971520),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- FK to businesses: cascade deletes receipt rows when business is removed
ALTER TABLE receipts
    ADD CONSTRAINT receipts_business_id_fkey
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE;

-- Composite same-tenant FK to transactions: receipt dies with its transaction
ALTER TABLE receipts
    ADD CONSTRAINT receipts_txn_business_fkey
    FOREIGN KEY (transaction_id, business_id) REFERENCES transactions(id, business_id) ON DELETE CASCADE;
