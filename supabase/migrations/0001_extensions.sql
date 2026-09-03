-- Migration 001: Enable pg_trgm extension for Arabic party-name trigram search
-- Required by idx_transactions_party_name_trgm (I6)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
