-- Migration 011: RLS — helper function, enable RLS, grants, per-table policies
-- Final hardening step: tables are never exposed without a policy

-- ============================================================
-- 1. Helper: current_business_id()
-- ============================================================
CREATE OR REPLACE FUNCTION current_business_id()
RETURNS uuid AS $$
    SELECT id FROM businesses WHERE owner_id = (select auth.uid());
$$ LANGUAGE sql STABLE SECURITY INVOKER SET search_path = public;

-- Grant EXECUTE only to authenticated; revoke from public (avoid leaking existence info to anon)
GRANT EXECUTE ON FUNCTION current_business_id() TO authenticated;
REVOKE EXECUTE ON FUNCTION current_business_id() FROM public;

-- ============================================================
-- 2. Revoke all from anon/public, then grant to authenticated
-- ============================================================
REVOKE ALL ON businesses FROM anon, public;
REVOKE ALL ON categories FROM anon, public;
REVOKE ALL ON transactions FROM anon, public;
REVOKE ALL ON transaction_items FROM anon, public;
REVOKE ALL ON receipts FROM anon, public;
REVOKE ALL ON ai_extractions FROM anon, public;

-- Grant to authenticated (authorizes the operation class; RLS makes it owner-scoped)
GRANT SELECT, INSERT, UPDATE ON businesses TO authenticated;
-- No DELETE on businesses (admin-scoped)

GRANT SELECT, INSERT, UPDATE, DELETE ON categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON transactions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON transaction_items TO authenticated;

GRANT SELECT, INSERT, DELETE ON receipts TO authenticated;
-- No UPDATE on receipts (immutable)

GRANT SELECT, INSERT ON ai_extractions TO authenticated;
-- No UPDATE/DELETE on ai_extractions (immutable; removal via cascade only)

-- ============================================================
-- 3. Enable RLS on all 6 tables
-- ============================================================
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_extractions ENABLE ROW LEVEL SECURITY;

-- Force RLS for table owners too (defense-in-depth)
ALTER TABLE businesses FORCE ROW LEVEL SECURITY;
ALTER TABLE categories FORCE ROW LEVEL SECURITY;
ALTER TABLE transactions FORCE ROW LEVEL SECURITY;
ALTER TABLE transaction_items FORCE ROW LEVEL SECURITY;
ALTER TABLE receipts FORCE ROW LEVEL SECURITY;
ALTER TABLE ai_extractions FORCE ROW LEVEL SECURITY;

-- ============================================================
-- 4. Policies
-- ============================================================

-- === businesses ===
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

-- No DELETE policy — account removal is admin Edge Function scoped

-- === categories ===
CREATE POLICY "categories_select_owner" ON categories
    FOR SELECT TO authenticated
    USING (business_id = current_business_id());

CREATE POLICY "categories_insert_custom" ON categories
    FOR INSERT TO authenticated
    WITH CHECK (business_id = current_business_id() AND type = 'custom');

CREATE POLICY "categories_update_owner" ON categories
    FOR UPDATE TO authenticated
    USING (business_id = current_business_id())
    WITH CHECK (business_id = current_business_id());

CREATE POLICY "categories_delete_custom" ON categories
    FOR DELETE TO authenticated
    USING (business_id = current_business_id() AND type = 'custom');

-- === transactions ===
CREATE POLICY "transactions_select_owner" ON transactions
    FOR SELECT TO authenticated
    USING (business_id = current_business_id());

CREATE POLICY "transactions_insert_owner" ON transactions
    FOR INSERT TO authenticated
    WITH CHECK (business_id = current_business_id());

CREATE POLICY "transactions_update_owner" ON transactions
    FOR UPDATE TO authenticated
    USING (business_id = current_business_id())
    WITH CHECK (business_id = current_business_id());

CREATE POLICY "transactions_delete_owner" ON transactions
    FOR DELETE TO authenticated
    USING (business_id = current_business_id());

-- === transaction_items ===
CREATE POLICY "transaction_items_select_owner" ON transaction_items
    FOR SELECT TO authenticated
    USING (business_id = current_business_id());

CREATE POLICY "transaction_items_insert_owner" ON transaction_items
    FOR INSERT TO authenticated
    WITH CHECK (business_id = current_business_id());

CREATE POLICY "transaction_items_update_owner" ON transaction_items
    FOR UPDATE TO authenticated
    USING (business_id = current_business_id())
    WITH CHECK (business_id = current_business_id());

CREATE POLICY "transaction_items_delete_owner" ON transaction_items
    FOR DELETE TO authenticated
    USING (business_id = current_business_id());

-- === receipts (immutable — no UPDATE policy) ===
CREATE POLICY "receipts_select_owner" ON receipts
    FOR SELECT TO authenticated
    USING (business_id = current_business_id());

CREATE POLICY "receipts_insert_owner" ON receipts
    FOR INSERT TO authenticated
    WITH CHECK (business_id = current_business_id());

CREATE POLICY "receipts_delete_owner" ON receipts
    FOR DELETE TO authenticated
    USING (business_id = current_business_id());

-- No UPDATE policy — immutable record

-- === ai_extractions (immutable — no UPDATE/DELETE policy) ===
CREATE POLICY "ai_extractions_select_owner" ON ai_extractions
    FOR SELECT TO authenticated
    USING (business_id = current_business_id());

CREATE POLICY "ai_extractions_insert_owner" ON ai_extractions
    FOR INSERT TO authenticated
    WITH CHECK (business_id = current_business_id());

-- No UPDATE policy — immutable provenance
-- No DELETE policy — removal only via transaction cascade
