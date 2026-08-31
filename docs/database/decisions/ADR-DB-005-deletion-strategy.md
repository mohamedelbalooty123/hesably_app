# ADR-DB-005 — Deletion Strategy

**Status:** Accepted · **Date:** 2026-08-31 · **Scope:** database layer + auth

## Context

Requirements cover "delete my account, wipe my data" and routine records deletion (a transaction, a receipt, a category). We must decide: soft vs hard delete, who may delete what (RLS vs admin), and how storage objects stay consistent.

## Decision

1. **No soft delete, no `deleted_at`, no tombstone/audit tables** in MVP. Deleted = gone.
2. **Record-level deletes are owner-scoped via RLS**:
   - `transactions`, `transaction_items`: owner DELETE (cascades children).
   - `categories`: owner DELETE **only for `type='custom'`**; in-use custom blocked by FK RESTRICT.
   - `receipts`: owner DELETE (detach image; storage object deleted by the app under the same ownership policy).
   - `ai_extractions`: **no DELETE policy** — provenance is immutable; it dies with its transaction via cascade.
3. **`businesses` has no owner DELETE policy.** The tenant root is removed **only** by a narrowly-scoped admin Edge Function using `service_role`:
   ```
   delete storage objects under receipts/{business_id}/… → DELETE auth.users WHERE id=<uid>
   ```
   `businesses.owner_id … ON DELETE CASCADE` then removes the whole subtree.
4. **Immutable tables have no UPDATE policy** (`receipts`, `ai_extractions`); effective delete paths are cascade-controlled.

## Consequences

- The boring default (hard delete) keeps schema, queries, and RLS trivial; nothing leaks through soft-delete filter bugs.
- Account deletion is deliberate and out-of-reach of clients — no self-destruct footgun from a leaked mobile session; it requires the admin function (ADR-002 scope: server-side responsibilities).
- Cascade covers transactional consistency: deleting a business/transaction removes all dependent rows atomically; storage objects are handled by the caller before the auth-user delete.
- GDPR-style erasure is satisfied by hard delete; if auditability is requested later it begins in the *new* system with an explicit export first.

## Alternatives considered

- **Soft delete on all tables:** rejected — every query then filters `deleted_at`, dashboards doublecount, storage orphans linger; MVP has no compliance need that merits it.
- **Owner DELETE on `businesses` (self-service reset):** rejected — storage cleanup + auth-user removal can't be done safely in a client RLS context; keeps the admin function as the single path.
- **DELETE on `ai_extractions` by owner:** rejected — defeats provenance; cascade-only is deliberate (NFR-DATA-001 spirit).