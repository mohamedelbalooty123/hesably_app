-- Migration 009: Category seeder + AI provenance guard + REVOKE EXECUTE (HIGH-02)
-- 1. seed_default_categories_for_business() — SECURITY DEFINER, owned by postgres, search_path pinned
-- 2. AFTER INSERT trigger on businesses to auto-seed defaults
-- 3. REVOKE EXECUTE from public/anon/authenticated (HIGH-02 — trigger-only path)
-- 4. transactions_ai_provenance_guard() — MEDIUM-01

-- 1. Seeder function
CREATE OR REPLACE FUNCTION seed_default_categories_for_business(p_business_id uuid)
RETURNS void AS $$
BEGIN
    INSERT INTO categories (business_id, name, name_key, type) VALUES
        (p_business_id, 'مبيعات', 'مبيعات', 'default'),
        (p_business_id, 'مشتريات', 'مشتريات', 'default'),
        (p_business_id, 'إيجار', 'إيجار', 'default'),
        (p_business_id, 'مرتبات', 'مرتبات', 'default'),
        (p_business_id, 'فواتير', 'فواتير', 'default'),
        (p_business_id, 'نقل', 'نقل', 'default'),
        (p_business_id, 'تسويق', 'تسويق', 'default'),
        (p_business_id, 'صيانة', 'صيانة', 'default'),
        (p_business_id, 'ضرائب ورسوم', 'ضرائب ورسوم', 'default'),
        (p_business_id, 'أخرى', 'أخرى', 'default')
    ON CONFLICT (business_id, name_key) DO NOTHING;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- 2. AFTER INSERT trigger on businesses
CREATE OR REPLACE FUNCTION trigger_seed_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM seed_default_categories_for_business(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trg_seed_default_categories
    AFTER INSERT ON businesses
    FOR EACH ROW
    EXECUTE FUNCTION trigger_seed_default_categories();

-- 3. HIGH-02: REVOKE EXECUTE from all client roles (trigger-only path)
REVOKE EXECUTE ON FUNCTION seed_default_categories_for_business(uuid) FROM public;
REVOKE EXECUTE ON FUNCTION seed_default_categories_for_business(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION seed_default_categories_for_business(uuid) FROM authenticated;

-- 4. MEDIUM-01: AI provenance guard trigger
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

CREATE TRIGGER trg_transactions_ai_provenance_guard
    BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION transactions_ai_provenance_guard();
