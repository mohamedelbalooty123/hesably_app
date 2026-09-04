# ADR-API-001: Direct Supabase Client Access

**Status:** Accepted  
**Date:** 2026-09-03  
**Deciders:** Engineering  
**Supersedes:** None  
**Related:** `docs/architecture/system-architecture.md`, `docs/database/rls-matrix.md`

---

## Context

The Smart Invoice Assistant is a Flutter + Next.js application backed by Supabase (Auth/Postgres/Storage). The team needs to decide how clients access the database and business logic.

### Options Considered

| Option | Description |
|--------|-------------|
| A. Direct Supabase client access | Flutter and Next.js use Supabase client SDKs; communicate directly with PostgREST/Storage/Auth |
| B. Custom REST API layer | Next.js API routes or separate backend acts as middleware between clients and Supabase |
| C. GraphQL via PostgREST + pg_graphql | Expose a GraphQL endpoint; clients use GraphQL queries |
| D. Hybrid (read direct, write via API) | Reads go direct; writes go through a protective API layer |

---

## Decision

**We chose Option A: Direct Supabase client access.**

Both Flutter Mobile and Next.js Dashboard communicate directly with Supabase services (Auth, PostgREST, Storage) using their respective client SDKs. There is no custom API layer, no middleware, and no GraphQL endpoint.

The only exception is the `extract-receipt` Edge Function (see [ADR-API-002](ADR-API-002-edge-function-boundary.md)), which mediates access to Gemini for AI extraction.

---

## Rationale

### Why Direct Access

1. **Supabase is designed for this pattern.** PostgREST exposes a complete REST API automatically from the schema. Client SDKs handle auth, query building, and type safety. Adding a middleware layer duplicates what Supabase already provides.

2. **RLS is the authorization layer.** Row Level Security policies enforce tenant isolation at the database level. Every query is automatically scoped to `current_business_id()`. There is no need for a middleware layer to check permissions — the database does it.

3. **Solo-shop scale.** The application targets individual Egyptian shop owners. Transaction volumes are in the thousands per year, not millions. There is no need for a caching layer, query optimization middleware, or request batching beyond what PostgREST provides.

4. **Development velocity.** A greenfield project benefits from fewer moving parts. The team can ship features faster without maintaining a separate API server.

5. **Proven pattern.** Supabase's recommended architecture is direct client access with RLS. This is the pattern used by thousands of production applications.

### Why Not a Custom API Layer

- **Duplication:** A custom API would replicate PostgREST's filtering, pagination, and error handling.
- **Maintenance burden:** Another server to deploy, monitor, and scale.
- **No security benefit:** RLS already enforces tenant isolation. A custom API would need to implement the same checks or trust the database.
- **Overkill for MVP:** Solo-shop scale doesn't justify the infrastructure.

### Why Not GraphQL

- **PostgREST is sufficient.** The query patterns (filter, sort, paginate) are simple and well-supported by PostgREST's REST API.
- **Client SDKs are mature.** Supabase's Flutter and JS SDKs provide excellent type safety and query building without GraphQL.
- **GraphQL adds complexity.** Schema stitching, resolver logic, and client-side cache management are unnecessary overhead for this scale.

### Why Not Hybrid

- **Inconsistent mental model.** Developers need to remember which operations go through the API and which go direct. This increases cognitive load and bug risk.
- **No clear boundary.** If RLS handles authorization, what does the API layer protect? The hybrid approach lacks a clear value proposition.

---

## Consequences

### Positive

- **Simpler architecture.** No API server to deploy, monitor, or scale.
- **Faster development.** Direct access means fewer abstractions and faster iteration.
- **RLS as single source of security truth.** Authorization logic lives in one place (database policies), not scattered across API handlers.
- **Type safety.** Supabase client SDKs generate TypeScript/Dart types from the schema.
- **Real-time subscriptions.** Supabase Realtime works natively with direct access (future Phase 2+).

### Negative

- **Client-side complexity.** Query logic, filtering, and pagination live in client code rather than a centralized API. This is acceptable at MVP scale.
- **Gemini key exposure.** The Gemini API key cannot live in client code. This is handled by the Edge Function boundary (ADR-API-002).
- **No request validation layer.** PostgREST validates against the schema (CHECK constraints, FK constraints), but there's no application-level validation middleware. This is acceptable because RLS + DB constraints provide sufficient protection.
- **Schema changes affect clients directly.** There's no API versioning layer. Schema migrations must be backward-compatible or coordinated with client releases.

### Risks

| Risk | Mitigation |
|------|-----------|
| Schema migration breaks clients | Test migrations against client code before deploying; use backward-compatible changes |
| RLS policy bugs expose cross-tenant data | RLS matrix review (docs/database/rls-matrix.md); security advisors; automated tests |
| Client code contains sensitive logic | Keep business logic minimal in clients; complex logic moves to Edge Functions |
| No rate limiting at API layer | Supabase has built-in rate limiting; add custom limits if needed in Phase 2 |

---

## Follow-Up Items

1. **RLS testing:** Write automated tests for all RLS policies to catch policy bugs early.
2. **Schema migration coordination:** Establish a process for schema changes that ensures backward compatibility.
3. **Monitoring:** Set up Supabase database advisors to catch security/performance issues.
4. **Edge Function expansion:** If new server-side operations arise (e.g., batch processing), they follow the same Edge Function pattern as `extract-receipt`.

---

## References

- Supabase Architecture: `docs/architecture/system-architecture.md`
- RLS Matrix: `docs/database/rls-matrix.md`
- Data Access Contracts: `docs/api/data-access-contracts.md`
- Backend Architecture: `docs/architecture/backend-architecture.md`
