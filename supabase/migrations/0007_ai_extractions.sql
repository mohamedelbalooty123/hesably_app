-- Migration 007: ai_extractions — immutable AI provenance snapshot (0..1 per transaction)
-- Written only after user confirmation (NFR-DATA-001). No updated_at.

CREATE TABLE ai_extractions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id uuid NOT NULL UNIQUE,
    business_id uuid NOT NULL,
    model text NOT NULL,
    overall_confidence numeric(3,2) NOT NULL CHECK (overall_confidence BETWEEN 0 AND 1),
    extracted_fields jsonb NOT NULL,
    field_confidences jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- FK to businesses: cascade deletes extraction rows when business is removed
ALTER TABLE ai_extractions
    ADD CONSTRAINT ai_extractions_business_id_fkey
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE;

-- Composite same-tenant FK to transactions: provenance dies with its transaction
ALTER TABLE ai_extractions
    ADD CONSTRAINT ai_extractions_txn_business_fkey
    FOREIGN KEY (transaction_id, business_id) REFERENCES transactions(id, business_id) ON DELETE CASCADE;
