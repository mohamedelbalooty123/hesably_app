# Storage Contracts — Smart Invoice Assistant

Contracts for receipt image storage: upload, read, delete, path convention, and authorization policies. All access is through the private `receipts` bucket with owner-scoped policies.

---

## 1. Bucket Specification

| Property | Value |
|---|---|
| Name | `receipts` |
| Visibility | **Private** — no public URL ever generated (NFR-SEC-002) |
| Max object size | 20 MB (`CHECK (size_bytes <= 20971520)` on `receipts` table) |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp`, `image/heic` (re-encoded to JPEG at upload) |
| Anon access | Zero (no policies for `anon` role) |

---

## 2. Path Convention

```
receipts/{business_id}/{transaction_id}/receipt.ext
```

| Segment | Value | Purpose |
|---|---|---|
| 1 | `business_id` (uuid) | Authorization backbone — ownership predicate |
| 2 | `transaction_id` (uuid) | Provenance, uniqueness, cleanup target |
| 3 | `receipt.ext` | Deterministic filename; avoids collisions; derivable from `receipts.storage_path` |

- The path is deterministic: the client constructs it the same way as the DB stores it.
- `receipts.storage_path` UNIQUE constraint prevents duplicate entries.

---

## 3. Upload Receipt

| Field | Value |
|---|---|
| **Client** | Flutter Mobile (only — no web create in MVP) |
| **Trigger** | User confirms Save on Review & Edit screen |
| **Pre-condition** | Transaction row already inserted (row-first ordering) |
| **Path** | `receipts/{business_id}/{transaction_id}/receipt.ext` |
| **Auth** | Authenticated session (owner JWT) |
| **Storage policy** | INSERT: `WITH CHECK (bucket_id = 'receipts' AND (storage.foldername(name))[1] = current_business_id()::text)` |
| **Content** | Image bytes (compressed/downscaled by client before upload) |
| **Expected response** | 200 OK with object metadata |
| **Error cases** | Policy denial (403), file too large (413), invalid MIME type, network failure |
| **Relation to transaction** | Must be uploaded AFTER the transaction row is created; `receipts` row links `storage_path` to `transaction_id` |
| **No pre-confirmation upload** | Image stays in app temp area until user confirms (BR-CONFIRM-001, NFR-DATA-001) |
| **Requirements** | FR-REVIEW-006, BR-REC-003/004, NFR-SEC-002, BR-CONFIRM-001 |

### Upload Ordering (Row-First)

```text
Step 1: INSERT transactions (confirmed values)       ← RLS-scoped
Step 2: uploadImage(path)                             ← Storage INSERT policy
Step 3: INSERT receipts (storage_path, metadata)      ← RLS-scoped
  On failure at step 2 or 3: delete the partial transaction row (compensate)
  Orphan object (step 2 succeeded, step 3 failed): cleaned up best-effort by app
```

---

## 4. Read Receipt

### 4.1 Mobile Read

| Field | Value |
|---|---|
| **Client** | Flutter Mobile |
| **Path** | Supabase Storage → authenticated download |
| **Auth** | Authenticated session (owner JWT) |
| **Storage policy** | SELECT: `bucket_id = 'receipts' AND (storage.foldername(name))[1] = current_business_id()::text` |
| **Mechanism** | Create signed URL (short expiry: 60-300s) → render via `Image.file` |
| **Output** | Image bytes or signed URL |
| **Use cases** | Review & Edit thumbnail, Transaction detail full-size view |
| **No public URLs** | Private bucket; all reads are authenticated |
| **Requirements** | FR-REVIEW-005, FR-TRANS-009 |

### 4.2 Web Read

| Field | Value |
|---|---|
| **Client** | Next.js Dashboard |
| **Path** | Supabase Storage → authenticated download (via SSR or client SDK) |
| **Auth** | Authenticated session (owner JWT via cookie) |
| **Storage policy** | Same as mobile: owner-scoped SELECT |
| **Mechanism** | Create signed URL → render in `<img>` or viewer component |
| **Output** | Signed URL (short expiry) |
| **Use cases** | Transaction detail panel receipt viewer |
| **Requirements** | FR-WEB-TRANS-004 |

### 4.3 Edge Function Read

| Field | Value |
|---|---|
| **Client** | Edge Function (`extract-receipt`) |
| **Path** | Image bytes received as multipart in the request body |
| **Auth** | Verified JWT; business ownership validated |
| **Storage policy** | N/A — image bytes are sent directly in the request, not fetched from Storage |
| **Note** | The Edge Function does NOT read from Storage; it receives bytes from the mobile client |
| **Requirements** | FR-AI-001, ai-architecture §4 |

---

## 5. Delete Receipt

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Trigger** | Transaction deletion (cascading) or explicit receipt detach |
| **Auth** | Authenticated session (owner JWT) |
| **Storage policy** | DELETE: `bucket_id = 'receipts' AND (storage.foldername(name))[1] = current_business_id()::text` |
| **Mechanism** | App deletes storage object via Storage SDK DELETE; DB `receipts` row deleted via transaction CASCADE |
| **Ordering** | App deletes storage object AND/OR relies on DB cascade for `receipts` row; orphan cleanup is best-effort |
| **Error cases** | Network failure (object may remain; reconcilable) |
| **No update** | Storage objects are immutable (no UPDATE policy) |
| **Requirements** | FR-TRANS-013, BR-TRANS-003 |

---

## 6. Storage Policies Summary

| Operation | Policy Expression |
|---|---|
| SELECT | `bucket_id = 'receipts' AND (storage.foldername(name))[1] = current_business_id()::text` |
| INSERT | `WITH CHECK` same ownership expression |
| UPDATE | **No policy** — objects are immutable |
| DELETE | Same ownership expression |

- `anon`: no policies → all requests 403/404
- `service_role`: may read objects for admin cleanup (account deletion enumerates `{business_id}/` folder)

---

## 7. Object Lifecycle

| Event | Action |
|---|---|
| Transaction created (with receipt) | Object uploaded under `{business_id}/{transaction_id}/receipt.ext` |
| Transaction viewed | Signed URL generated for authenticated read |
| Transaction deleted | App deletes storage object + DB row (cascade) |
| Receipt detached | Owner Storage DELETE + row DELETE |
| Account deletion | Admin Edge Function enumerates `{business_id}/` folder, removes objects, then deletes auth user (cascade handles DB) |
| Orphan (partial failure) | Reconciled by app or post-MVP tooling comparing `receipts` rows vs `storage.list` |

---

## 8. Security

- Path-prefix ownership means users never see another tenant's prefix
- UUID paths are unguessable in practice
- No signed public URLs; all access is authenticated
- Bucket-level and per-object size/file-type rejection enforced
- Storage audit logs visible in Supabase dashboard

---

## 9. Traceability

| Storage element | Requirement / Decision IDs |
|---|---|
| Private bucket | NFR-SEC-002, BR-SEC-002, BR-REC-004, ADR-API-003 |
| Upload on confirm only | BR-CONFIRM-001, NFR-DATA-001 |
| Owner-scoped access | NFR-SEC-001, BR-SEC-001 |
| Delete with transaction | FR-TRANS-013, BR-TRANS-003 |
| No public URLs | NFR-SEC-002, ADR-API-003 |
| Authenticated reads | FR-REVIEW-005, FR-TRANS-009, FR-WEB-TRANS-004 |
