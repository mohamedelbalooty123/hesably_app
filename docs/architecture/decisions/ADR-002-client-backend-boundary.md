# ADR-002 — Client / Backend Boundary

**Status:** Accepted
**Date:** 2026-08-31
**Applies to:** System boundary, Mobile, Dashboard, Backend

## Context

Two clients (Flutter mobile, Next.js dashboard) must share one business dataset with strict owner isolation. Requirements prohibit inventing backend technology and require a simple, secure, testable MVP. The source documents and finalized decisions fix the stack: Flutter + Next.js + Supabase + Gemini (system context). The dashboard reads/writes the same tables as mobile; no separate backend (ASM-007).

## Decision

Use **Supabase as the single shared application backend** for both clients, and define the boundary as follows:

```text
Flutter Mobile ─┐
                ├──▶ Supabase (Auth + Postgres/RLS + Storage) ── business data
Next.js Dashboard
Flutter Mobile ──▶ Edge Function `extract-receipt` ──▶ Gemini   (AI only)
```

- Both clients talk to Supabase through their own session with **Supabase client/SSR SDKs**. RLS is the authoritative authorization layer for all business data (NFR-SEC-001).
- The **only custom server-side component** is the AI Edge Function (verified JWT + ownership check + Gemini call). It is a separate, narrow boundary — not a general backend.
- Exports and reports are generated client-side from RLS-scoped data in MVP; there is no export/report server.
- Clients are **untrusted** (ADR-001): every query/mutation carries the caller's identity; the database re-validates ownership on every operation. Hiding a button is never a security control.

## Why (rationale)

- **Single source of truth:** one tenant-scoped schema; no sync/duplication problem; consistent behavior across platforms by construction (BR-CATEGORY-006, ASM-007).
- **Security:** owner isolation is enforced at the data layer (RLS + Storage policies) (NFR-SEC-001/002), uniformly for mobile and web (Q-017).
- **Simplicity:** no custom REST/GraphQL server, no DTO layer, no deployment burden; the shared backend is hosted (Supabase). Matches the "no unnecessary infrastructure" objective.
- **AI isolation:** the only server code is the AI boundary that holds the Gemini secret (Q-007, BR-AI-005), so the secret never reaches a client.

## Consequences

- **Positive:** fastest path to a secure MVP; one schema to design and migrate; auth/RLS/storage semantics identical for both apps; AI can only be reached through the verified boundary.
- **Negative:** SQL quality (indexes, RLS) directly drives performance and security — the Database Design phase must include policy tests. Cross-client shared logic must be kept consistent intentionally (mirrored normalization, search, formatting).
- **Acceptable boundary behaviors:** when an operation requires elevated or non-user rights (e.g., admin, cron, ETA submission in Phase 2), the extension point is a server-side Edge Function with explicit scope — never a client with service-role credentials.
- **Traceability:** NFR-SEC-001/002; BR-SEC-001/002; BR-AI-005; Q-007, Q-017; ASM-007.