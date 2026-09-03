-- Migration 013: Fix advisor findings
-- 1. Pin search_path on all functions (security: function_search_path_mutable)
-- 2. Add composite indexes for composite FKs (performance: unindexed_foreign_keys)
-- 3. Optimize RLS policies with (select auth.uid()) (performance: auth_rls_initplan)

-- 1. Fix function search_path
CREATE OR REPLACE FUNCTION categories_guard_default_immutable()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.business_id IS DISTINCT FROM OLD.business_id THEN
        RAISE EXCEPTION 'Cannot change business_id on categories';
    END IF;
    IF NEW.type IS DISTINCT FROM OLD.type THEN
        RAISE EXCEPTION 'Cannot change type on categories';
    END IF;
    IF OLD.type = 'default' THEN
        IF NEW.name IS DISTINCT FROM OLD.name OR NEW.name_key IS DISTINCT FROM OLD.name_key THEN
            RAISE EXCEPTION 'Cannot rename default categories';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE OR REPLACE FUNCTION trigger_seed_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM seed_default_categories_for_business(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE OR REPLACE FUNCTION current_business_id()
RETURNS uuid AS $$
    SELECT id FROM businesses WHERE owner_id = (select auth.uid());
$$ LANGUAGE sql STABLE SECURITY INVOKER SET search_path = public;

CREATE OR REPLACE FUNCTION transactions_ai_provenance_guard()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.entry_source = 'ai' THEN
        IF NOT EXISTS (
            SELECT 1 FROM ai_extractions
            WHERE transaction_id = NEW.id AND business_id = NEW.business_id
        ) THEN
            RAISE EXCEPTION 'AI-originated transactions must have a matching ai_extractions record';
        END IF;
    END IF;
    IF NEW.entry_source = 'ai' AND (OLD.entry_source IS DISTINCT FROM 'ai') THEN
        IF NOT EXISTS (
            SELECT 1 FROM ai_extractions
            WHERE transaction_id = NEW.id AND business_id = NEW.business_id
        ) THEN
            RAISE EXCEPTION 'AI-originated transactions must have a matching ai_extractions record';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- 2. Add composite indexes for composite FKs (performance)
CREATE INDEX IF NOT EXISTS idx_receipts_txn_business
    ON receipts (transaction_id, business_id);

CREATE INDEX IF NOT EXISTS idx_transaction_items_txn_business
    ON transaction_items (transaction_id, business_id);

CREATE INDEX IF NOT EXISTS idx_ai_extractions_txn_business
    ON ai_extractions (transaction_id, business_id);

-- 3. Optimize RLS policies: replace auth.uid() with (select auth.uid())
DROP POLICY IF EXISTS businesses_select_owner ON businesses;
DROP POLICY IF EXISTS businesses_insert_owner ON businesses;
DROP POLICY IF EXISTS businesses_update_owner ON businesses;

CREATE POLICY "businesses_select_owner" ON businesses
    FOR SELECT TO authenticated
    USING (owner_id = (select auth.uid()));

CREATE POLICY "businesses_insert_owner" ON businesses
    FOR INSERT TO authenticated
    WITH CHECK (owner_id = (select auth.uid()));

CREATE POLICY "businesses_update_owner" ON businesses
    FOR UPDATE TO authenticated
    USING (owner_id = (select auth.uid()))
    WITH CHECK (owner_id = (select auth.uid()));
