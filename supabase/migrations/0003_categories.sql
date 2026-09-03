-- Migration 003: categories — budget classification + immutability guard
-- HIGH-01 CORRECTION: custom categories CAN be renamed (name/name_key editable)
--                      default categories CANNOT be renamed (name/name_key immutable)
--                      ALL categories: business_id and type are immutable (no cross-business move, no type conversion)

CREATE TABLE categories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL,
    name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 100),
    name_key text NOT NULL,
    type text NOT NULL DEFAULT 'custom' CHECK (type IN ('default', 'custom')),
    is_hidden boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- FK to businesses: cascade deletes categories when business is removed
ALTER TABLE categories
    ADD CONSTRAINT categories_business_id_fkey
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE;

-- No duplicate category names per tenant
ALTER TABLE categories
    ADD CONSTRAINT categories_business_name_key
    UNIQUE (business_id, name_key);

-- Unique target for composite FK from transactions
ALTER TABLE categories
    ADD CONSTRAINT categories_id_business_key
    UNIQUE (id, business_id);

-- Guard trigger: HIGH-01 corrected semantics
CREATE OR REPLACE FUNCTION categories_guard_default_immutable()
RETURNS TRIGGER AS $$
BEGIN
    -- Block business_id changes on ALL categories (no cross-business move)
    IF NEW.business_id IS DISTINCT FROM OLD.business_id THEN
        RAISE EXCEPTION 'Cannot change business_id on categories';
    END IF;

    -- Block type changes on ALL categories (no default/custom conversion)
    IF NEW.type IS DISTINCT FROM OLD.type THEN
        RAISE EXCEPTION 'Cannot change type on categories';
    END IF;

    -- Block name/name_key changes ONLY on default categories (custom rename allowed)
    IF OLD.type = 'default' THEN
        IF NEW.name IS DISTINCT FROM OLD.name OR NEW.name_key IS DISTINCT FROM OLD.name_key THEN
            RAISE EXCEPTION 'Cannot rename default categories';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trg_categories_guard_default_immutable
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION categories_guard_default_immutable();
