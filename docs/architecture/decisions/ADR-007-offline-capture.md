# ADR-007 — Offline Receipt Capture

**Status:** Accepted
**Date:** 2026-09-05
**Applies to:** Mobile, Backend, Storage, AI

## Context

MVP usage happens on Egyptian shop floors. A shop owner captures a receipt at the counter precisely when a customer has just paid — often in a stall or market with intermittent connectivity. The requirement set originally fixed offline capture as a Phase 2 / post-MVP capability (Q-018: "Offline capture (queue + sync) is out of MVP", BR-MVP-004), which made capture an online-only activity and created an unacceptable failure mode: the moment the connection drops, the core capture flow stops working (system-architecture §14; mobile-architecture line 13).

Product decision **Q-018 is flipped to IN MVP** (see open-questions Q-018 decision record). Offline **capture + deferred sync** becomes an MVP capability. The AI trust invariant (ADR-004: extraction is never persistence; AI output is never saved without user confirmation) and the account-isolation/RLS invariants remain unchanged and now also govern the offline pending queue.

The database is already implemented on Supabase and requires **no schema change**: the pending capture is a client-side device concept, not a server row.

## Decision

Offline mode covers exactly the **capture + deferred sync** boundary; everything that requires connectivity is **NOT** part of offline mode.

```text
[Offline]  Camera/gallery → image + type + optional note → local pending capture
           → Pending list (SCR-16) with status: pending → syncing → failed
[Online]   Sync now (manual) or auto-retry when connectivity returns
           → upload image to private storage
           → create DB rows (row-first: transaction → items → receipt → ai_extraction)
           → AI Edge Function → structured JSON + confidence
           → REVIEW flow (never auto-save)  ← ADR-004 invariant
           → user confirms → SYNCED
[Any time, before sync] delete the pending capture locally
```

Capability boundary (unchanged vs the original MVP split except capture + deferred sync):

| Capability | Offline MVP? |
|---|---|
| Capture image + metadata; view/manage pending list | **YES** |
| Local storage of pending capture; manual + auto retry sync | **YES** |
| AI extraction, storage upload, server persistence, cross-device sync | **NO** — connectivity required |
| Reports / analytics reflecting unsynced data | **NO** — reports are online server-side |
| Conflict-resolution UI | **NO** — last-write-wins; sync is a queue, not concurrent editing |

Rules:

1. **Capture is local-first.** Capturing a receipt never depends on connectivity; the image and selected metadata are stored on-device as a pending capture (new FR-OFFLINE-001/002/003).
2. **Deferred, idempotent sync.** Sync uploads the pending capture and marks it SYNCED. Each pending capture carries a **client-generated UUID**; re-sync of an already-synced UUID is a no-op (idempotency + duplicate prevention, FR-OFFLINE-005).
3. **AI trust invariant holds.** Offline never bypasses review. AI extraction runs only online via the Edge Function, and its output always routes through the review/confirm step before persistence (FR-OFFLINE-008).
4. **Account isolation is absolute.** Pending captures are bound to the current owner identity. On logout, account deletion, token expiry, or device switch, pending captures must never be visible to or syncable under a different account (FR-OFFLINE-006).
5. **No offline inventiveness.** "Read-only local cache of previously loaded data" is allowed in Home (never implying cloud sync, never implying the cache is current); offline never fabricates capabilities like offline analytics, offline export, or offline cross-device access (correction #1).
6. **Sync retry ≠ conflict resolution.** "Sync failed / retry" and "data changed meanwhile" are distinct. Server data uses last-write-wins; no merge UI in MVP.
7. **Database unchanged.** The pending queue lives client-side only; the already-deployed schema is untouched. This document and the DB docs describe the offline state as client-side (database-review, database-implementation-report addendum).

## Why (rationale)

- **The core flow must survive the shop floor.** Capture is the highest-frequency action; making it online-only makes the app fail at its reason for existence exactly when connectivity is poor (ADR-001: architecture style favors simplicity, but availability of the capture path is a hard product requirement).
- **Minimal capability gliding, maximum value.** "Capture now, process later" needs no server feature — only a local queue and an idempotent sync path — so MVP cost is small relative to the failure mode it removes.
- **Invariants preserved, not weakened.** The offline queue is deliberately prevented from becoming an end-run around AI confirmation (rule 3) or around tenant isolation (rule 4).
- **LWW + idempotency keeps MVP simple.** `system-architecture.md` post-MVP already listed conflict handling as out-of-scope; keeping sync as an ordered queue with no merge UI preserves that simplification (Q-018 context: single-device usage; cross-device sync remains post-MVP).
- **No schema churn on a deployed database.** The DB is live on Supabase; a client-side queue adds zero DDL risk while meeting the product need.

## Consequences

- **Positive:** capture works with no connectivity; pending captures are visible and retryable; sync is duplicate-safe and tenant-isolated; no schema/migration is required; AI trust and storage-privacy invariants (ADR-004, ADR-005) are untouched.
- **Negative:** device-local storage introduces a new local state surface (encryption-at-rest guidance documented, mobile-architecture); pending captures do not survive reinstall (no server copy) and must be surfaced honestly in UX; offline never includes AI results or server reports, so users with poor connectivity may accumulate pendings before they can be processed.
- **Implementation notes:** local store (device keystore / SQLCipher) for pending captures; the sync path reuses the existing AI Edge Function; the Edge Function already enforces that the caller is an authenticated owner (JWT); idempotency is enforced by a unique constraint on client UUID for the upload path. Logout/delete must purge or cryptographically bind the local queue (FR-OFFLINE-006).
- **Supersedes / links:** extends the boundary in ADR-002 (client/backend boundary now includes a client-side pending queue); honors ADR-004 (AI is never persistence) and ADR-005 (images never public) unchanged. Decision record: Q-018 (flipped IN MVP). BR-MVP-004 revised to match.
- **Traceability:** FR-OFFLINE-001…008, BR-OFFLINE-001…00n, AC-OFFLINE-001…; Q-018; BR-MVP-004, BR-MVP-006.