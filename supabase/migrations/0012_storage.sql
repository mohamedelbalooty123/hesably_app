-- Migration 012: Private storage bucket 'receipts' + object policies
-- Path convention: {business_id}/{transaction_id}/receipt.ext
-- Segment 1 = owning business (authorization backbone)

-- 1. Create private bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('receipts', 'receipts', false)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage policies on storage.objects

-- SELECT: owner can read their own business's receipts
CREATE POLICY "receipts_select_owner" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'receipts'
        AND (storage.foldername(name))[1] = current_business_id()::text
    );

-- INSERT: owner can upload to their own business's folder
CREATE POLICY "receipts_insert_owner" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'receipts'
        AND (storage.foldername(name))[1] = current_business_id()::text
    );

-- DELETE: owner can delete their own business's receipts
CREATE POLICY "receipts_delete_owner" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'receipts'
        AND (storage.foldername(name))[1] = current_business_id()::text
    );

-- No UPDATE policy — immutable images (no overwrite)
