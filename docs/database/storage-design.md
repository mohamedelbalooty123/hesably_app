# Storage Design — Smart Invoice Assistant

Receipt images, bucket layout, policies, upload ordering, lifecycle. **Design-stage reference; no policies executed.**

---

## 1. Bucket

| Property | Value |
|---|---|
| Name | `receipts` |
| Visibility | **private** (never public; no public URL ever generated) |
| File-restriction | jpeg/png/webp/heic↓ (re-encoded to jpeg) — reject others at app + edge |
| Max size per object | **20 MB** (matches `receipts.size_bytes` CHECK `<= 20971520`) |
| Default bucket policies | none for `anon`; owner policies per §4 |

## 2. Path convention

```
receipts/{business_id}/{transaction_id}/receipt.ext
```

- **Segment 1** = owning business (authorization backbone).
- **Segment 2** = owning transaction (provenance + uniqueness + cleanup).
- Filename constant `receipt` + extension — deterministic, avoids collisions, makes the full path derivable from the DB (`receipts.storage_path`).

## 3. Object↔DB consistency

- Every object → one `receipts` row (`storage_path` unique, transaction unique).
- `receipts.storage_path` is authoritative: clients build the path the same way; policies validate segment 1; extraneous objects are cleaned by the app/admin function.

## 4. Policies (`storage.objects`)

| Operation | Expression |
|---|---|
| SELECT | `bucket_id = 'receipts' AND (storage.foldername(name))[1] = current_business_id()::text` |
| INSERT | `WITH CHECK` same ownership expression |
| UPDATE | none (no overwrite) |
| DELETE | same ownership expression |

**anon:** no policies → all storage requests 403/404. **service_role** (Edge Functions) may read objects on behalf of the owner path or perform admin cleanup.

## 5. Upload ordering (row-first, atomic on failure)

The owner flow must guarantee a receipt is never orphaned:

```
1. INSERT transactions (confirmed values)        -- owner token; RLS-scoped
2. uploadImage(receipt path)                     -- owner token; storage INSERT policy
3. INSERT receipts (storage_path, metadata)      -- owner token
   ON upload/receipt-row failure: compensate by deleting the partial transaction row
   (app-level rollback, not a DB transaction across client calls);
   orphan object (if step 2 succeeded) is cleaned up best-effort by the app.
```

Reasoning:
- DB record last → an object without a row can exist briefly and be cleaned; a row without an object is a dangling pointer we never persist.
- `receipts.storage_path` UNIQUE protects double-insert; storage path determinism allows idempotent re-retry.
- **No pre-confirmation upload**: the captured image stays in the app temp area and is uploaded only inside the confirmed commit (`mobile-architecture.md`; BR-CONFIRM-001, NFR-DATA-001). Confirm-then-store therefore holds by construction — nothing exists server-side until the user confirms.

## 6. Read / delivery path

- Mobile: signed URL (owner authorized) → `Image.file` render; short expiry (60..300 s), private bucket never proxied publicly.
- Dashboard: same signed-URL flow through the app server (owner session).
- Edge `extract-receipt`: receives the image **bytes** (multipart, owner session) and passes them to Gemini — it neither reads nor writes storage on the extract path (`ai-architecture.md`); the image never passes through a public URL.

## 7. Recompression / size policy (MVP)

- Client downscales on capture (low/mid-spec Android focus) to ≤ ~2–4 MB before upload; server accepts ≤ 20 MB.
- No server-side thumbnails in MVP (perf budget); revisit at Phase 2.

## 8. Lifecycle & cleanup

| Event | Action |
|---|---|
| Transaction deleted (owner) | app deletes the object (storage DELETE policy) + row (cascade) |
| Receipt detached | owner storage DELETE + row DELETE (both owner-policy-gated) |
| Account deletion | admin Edge Function enumerates `{business_id}` folder and removes objects *before* deleting the auth user (cascade handles DB) |
| Orphan objects (crash) | reconciled by owner's list query comparing `receipts` rows vs `storage.list` on the business folder (post-MVP tooling) |

## 9. Security notes

- Path-prefix ownership means users never see another tenant's `{business_id}/…` prefix (UUID unguessable in practice, ownership predicate unguarded by guesswork).
- No UPDATE on objects → immutable images (audit-friendly).
- Bucket-level and per-object size/file-type rejection are both enforced; object key length limited to DB text capacity (`storage_path`).
- All access logs visible in Supabase Storage audit; align with `docs/architecture/backend-architecture.md` auth model.