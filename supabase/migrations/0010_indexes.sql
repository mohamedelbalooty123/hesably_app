-- Migration 010: Standalone indexes (I1-I10)
-- Created after all tables exist, before RLS

-- I1: Default transaction list — newest first, month ranges
CREATE INDEX idx_transactions_business_date
    ON transactions (business_id, transaction_date DESC, created_at DESC);

-- I2: Type filter tab (income/expense) + date sort
CREATE INDEX idx_transactions_business_type_date
    ON transactions (business_id, type, transaction_date DESC);

-- I3: Category filter + per-category totals
CREATE INDEX idx_transactions_business_category_date
    ON transactions (business_id, category_id, transaction_date DESC);

-- I4: Amount range lookups (dashboard largest transactions)
CREATE INDEX idx_transactions_business_amount
    ON transactions (business_id, amount);

-- I5: FK RESTRICT support — delete-time category-in-use check
CREATE INDEX idx_transactions_category_business
    ON transactions (category_id, business_id);

-- I6: GIN trigram — Arabic supplier/customer name contains-search
CREATE INDEX idx_transactions_party_name_trgm
    ON transactions USING gin (lower(party_name) gin_trgm_ops);

-- I7: Line-item fetch by transaction
CREATE INDEX idx_transaction_items_transaction
    ON transaction_items (transaction_id);

-- I8: RLS predicate on items; business-scoped deletes
CREATE INDEX idx_transaction_items_business
    ON transaction_items (business_id);

-- I9: RLS predicate + storage reconciliation
CREATE INDEX idx_receipts_business
    ON receipts (business_id);

-- I10: RLS predicate + provenance queries
CREATE INDEX idx_ai_extractions_business
    ON ai_extractions (business_id);
