# ADR-005 — Storage

**Status:** Accepted
**Date:** 2026-08-31
**Applies to:** Backend, Storage, Mobile, Dashboard

## Context

Receipt images are sensitive business records (party names, phone numbers, financial data). The requirements fix that they live in a **private, non-public** bucket (NFR-SEC-002, BR-SEC-002, BR-REC-004) and are linked to their transaction for later reference (FR-REVIEW-006). Read/write must be restricted to the owning business (NFR-SEC-001, BR-REC-004). Deleting a transaction removes the record and its image (FR-TRANS-013).

## Decision

Store receipt images in a **private Supabase Storage bucket** with four properties:

```text
Private receipt storage
  + Authenticated access only
  + Owner-scoped object keys (<business-id>/<transaction-id>/receipt.ext)
  + Business-ownership policies (mirror of RLS on the owning business)
```

Rules:

1. **Never public.** The bucket is never public; images are never referenced by unauthenticated public URLs. Both clients render images via authenticated access only (mobile §16, dashboard §15).
2. **Owner-scoped.** Object keys encode the owning business; Storage access policies permit an authenticated user to read/write/delete only objects under their own business path (NFR-SEC-002).
3. **Confirm-then-store.** An image is uploaded **only** as part of a confirmed transaction (BR-CONFIRM-001, NFR-DATA-001). The AI boundary never stores the image (ADR-004). Manual transactions have no image (BR-REC-002).
4. **Image lifecycle bound to the record.** Delete removes both the transaction row and its image; failure is surfaced, not silently half-deleted (FR-TRANS-013).

## Why (rationale)

- **Privacy/regulatory posture:** Egyptian retail receipts frequently contain customer PII; a private bucket plus ownership policies is the minimum acceptable posture and is explicitly required (NFR-SEC-002).
- **No public leak path:** a public bucket would expose every owner's receipts to the internet — catastrophic and unrecoverable if it ever shipped (security risk `system-architecture.md` §16).
- **Owner isolation:** Storage policies mirror RLS, so object access is governed by the same ownership chain as row access (user → business → data).
- **Data trust:** storing images only on confirmation keeps the "no silent save" guarantee literal and avoids orphaned, unconfirmed objects needing cleanup.

## Consequences

- **Positive:** receipts are never publicly reachable; uniform ownership enforcement across rows and objects; deletion semantics are complete (record + image).
- **Negative:** authenticated reads during list/detail require a small signing/retrieval step (acceptable; thumbnails minimize cost, mobile §17); a misconfigured policy that made the bucket public would be severe, so the security phase mandates policy tests and CI checks (backend §19).
- **Traceability:** NFR-SEC-001/002, BR-SEC-001/002, BR-REC-003/004, FR-REVIEW-006, FR-TRANS-013, BR-CONFIRM-001.