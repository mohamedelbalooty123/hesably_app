-- Migration 002: businesses — tenant root, 1:1 with auth user
CREATE TABLE businesses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id uuid NOT NULL UNIQUE,
    name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 100),
    currency_code text NOT NULL DEFAULT 'EGP' CHECK (currency_code = 'EGP'),
    web_access_enabled boolean NOT NULL DEFAULT false,
    web_email text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- FK to auth.users: cascade deletes the whole tenant on account deletion
ALTER TABLE businesses
    ADD CONSTRAINT businesses_owner_id_fkey
    FOREIGN KEY (owner_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Partial unique index on web_email: one linked email per project universe
CREATE UNIQUE INDEX businesses_web_email_key
    ON businesses (web_email)
    WHERE web_email IS NOT NULL;
