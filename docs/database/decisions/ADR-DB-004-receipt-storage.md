# ADR-DB-004 — Receipt Storage & Upload Order

**Status:** Accepted · **Date:** 2026-08-31 · **Scope:** database layer + storage

## Context

The MVP is "capture a receipt, AI extracts it, owner confirms". The image is sensitive (business data) so it must be private. Requirements also demand AI-extracted data is never saved without confirmation (NFR-DATA-001). We must decide the bucket model, object layout, and the ordering that guarantees we never persist a dangling pointer or leak an image.

## Decision

1. **Private bucket `receipts`**; never public; anon has zero policies (`rls-matrix.md` §5).
2. **Deterministic path** `{business_id}/{transaction_id}/receipt.ext` — segment 1 is the ownership predicate for all storage policies; full path is derivable from the DB row.
3. **0..1 per transaction**: `receipts.transaction_id UNIQUE` (1:1), composite same-tenant FK to `transactions` `ON DELETE CASCADE`.
4. **Immutable record**: `storage_path UNIQUE`, no `updated_at`, no UPDATE policy. Metadata constraints: `mime_type CHECK LIKE 'image/%'`, `size_bytes CHECK (0 < size_bytes <= 20971520)` (≤ 20 MB).
5. **Row-first upload ordering**:
   ```
   INSERT transactions → uploadImage(path) → INSERT receipts
   ```
   On any later step failing, the app compensates by deleting the partial transaction row; a stray object (if step 2 completed) is cleaned best-effort. A row-without-object is never persisted.
6. **All writes are confirm-gated.** The captured image is held in the app temp area until the user confirms; it is uploaded **only as part of the confirmed commit** (`mobile-architecture.md`; BR-CONFIRM-001, NFR-DATA-001). Nothing exists server-side (no object, no row) beforehand; transaction + `ai_extractions` + `receipts` are written together after confirmation.

## Consequences

- No public object is ever addressable; signed short-lived URLs are the only read path.
- Deletion semantics stay simple: owner DELETE on `receipts` (detach) or transaction cascade (remove); account deletion cleans objects first (ADR-DB-005).
- No pre-confirmation upload → abandoned captures leave no orphan objects; only the local temp file is cleaned up.
- The 1:1 + unique-path invariants make orphan detection (list vs rows) mechanical.
- Client must downscale on low-spec devices so most uploads stay well under 20 MB.

## Alternatives considered

- **Guid-suffixed random paths:** rejected — breaks deterministic reconciliation and path-based ownership policies.
- **Public bucket + signed URLs:** rejected — leaks by default (bucket ACL), violates the private-storage NFR.
- **Object-first ordering:** rejected — risks a persisted DB row pointing to a missing object (dangling reference in a bookkeeping product is unacceptable).
- **`updated_at` + re-upload policy on objects:** rejected — receipts are audit artifacts; immutability is the point.