# ADR-API-003: Client-Side Security Boundary

**Status:** Accepted  
**Date:** 2026-09-03  
**Deciders:** Engineering  
**Supersedes:** None  
**Related:** `docs/database/rls-matrix.md`, `docs/api/auth-contracts.md`, `docs/api/data-access-contracts.md`

---

## Context

The Smart Invoice Assistant uses Supabase's client SDKs for direct database access. The team needs to decide how to handle security: what goes in clients, what stays server-side, and how to enforce tenant isolation.

### Key Security Questions

1. **What secrets can live in clients?** API keys, JWTs, service role keys?
2. **How is tenant isolation enforced?** RLS? Application logic? Both?
3. **What operations require server-side mediation?** AI extraction? Account deletion? Batch operations?

---

## Decision

**We chose a three-layer security model:**

1. **Supabase anon key in clients.** Both Flutter and Next.js include the Supabase anon/publishable key. This is safe because RLS policies enforce tenant isolation at the database level.

2. **RLS as the authorization layer.** Every table has per-business-owner policies. The `current_business_id()` function maps `auth.uid()` to `businesses.id`. Clients never pass `business_id` manually — it's derived from the JWT.

3. **Service role stays server-side.** The `service_role` key is never included in client code. It's used only in Edge Functions (e.g., account deletion) and server-side operations.

---

## Rationale

### Why Anon Key in Clients

1. **Supabase's design model.** Supabase client SDKs are designed to include the anon/publishable key. The key identifies the project, not a user. Authentication is handled by JWTs.

2. **RLS provides the security.** The anon key grants access to the PostgREST endpoint, but RLS policies restrict what data can be read or written. Without a valid JWT (or with a JWT that doesn't match RLS policies), queries return empty results.

3. **No security benefit to hiding the key.** The anon key is not a secret — it's a project identifier. Hiding it adds complexity without improving security.

4. **Client SDKs expect it.** Both Supabase Flutter and JS SDKs require the anon key for initialization. Removing it would break the SDK contract.

### Why RLS (Not Application Logic)

1. **Defense in depth.** RLS is enforced at the database level, regardless of which client makes the query. A bug in client code can't accidentally expose cross-tenant data.

2. **Single source of truth.** Authorization logic lives in one place (database policies), not scattered across Flutter, Next.js, and Edge Functions.

3. **Auditability.** RLS policies are declarative SQL. They're easy to review, test, and audit. Application-level authorization logic is harder to verify.

4. **Consistency.** Both Mobile and Web clients enforce the same authorization rules because they share the same RLS policies.

### Why Service Role Stays Server-Side

1. **Elevated privileges.** The `service_role` key bypasses RLS. It can read/write any data, regardless of policies. Exposing it to clients would defeat the entire RLS security model.

2. **Limited use cases.** Only two operations need `service_role`:
   - Account deletion (enumerate + delete all business data)
   - Admin operations (future: billing, support)
   
   Both happen in Edge Functions, not client code.

3. **Risk of exposure.** Client code is distributed to users' devices. It can be decompiled, inspected, or modified. Any secrets in client code are effectively public.

---

## Security Model

### Layer 1: Authentication (Supabase Auth)

| Client | Auth Method | Session Type |
|--------|-------------|--------------|
| Flutter Mobile | Phone + OTP | JWT in memory |
| Next.js Dashboard | Email magic link | JWT in HttpOnly cookie |

- JWT contains `sub` (auth.uid) and `role` (authenticated)
- JWT is verified on every Supabase request
- Expired/invalid JWT → 401 Unauthorized

### Layer 2: Authorization (RLS Policies)

| Table | Policy | Predicate |
|-------|--------|-----------|
| `businesses` | SELECT/INSERT/UPDATE | `owner_id = auth.uid()` (USING/WITH CHECK); **no DELETE** — account removal is admin Edge Function via `service_role` (ADR-DB-005) |
| `categories` | SELECT/INSERT/UPDATE/DELETE | `business_id = current_business_id()` |
| `transactions` | SELECT/INSERT/UPDATE/DELETE | `business_id = current_business_id()` |
| `transaction_items` | SELECT/INSERT/UPDATE/DELETE | `business_id = current_business_id()` |
| `receipts` | SELECT/INSERT/DELETE | `business_id = current_business_id()` (immutable — **no UPDATE** policy) |
| `ai_extractions` | SELECT/INSERT | `business_id = current_business_id()` (immutable provenance — no UPDATE/DELETE) |

> Access classes must match `docs/database/rls-matrix.md` §4/§6 exactly: `businesses` has no DELETE; `receipts` (immutable) has no UPDATE; `ai_extractions` (immutable provenance) has no UPDATE or DELETE. All bundled immutable/deletion constraints are belt-and-braces alongside composite same-tenant FKs.

- `current_business_id()` maps `auth.uid()` → `businesses.id`
- Every query is automatically scoped to the user's business
- Cross-tenant queries return empty results (not errors)

### Layer 3: Server-Side Mediation

| Operation | Mediation | Reason |
|-----------|-----------|--------|
| AI extraction | Edge Function | Gemini API key isolation; never persists business data |
| Account deletion | Edge Function | `service_role` needed to enumerate + delete storage objects and cascade `auth.users` row; bypasses RLS |

- Edge Functions verify JWT before processing
- Edge Functions validate business ownership
- Edge Functions never persist business data (extraction is ephemeral)
- **Email linking is NOT an Edge Function.** It is a direct client operation: the authenticated mobile session uses Supabase Auth identity linking to associate the email with the existing `auth.uid()`, then performs an RLS-scoped UPDATE on `businesses` (`web_access_enabled=true`, `web_email=lower(email)`). See `auth-contracts.md` §3.3, `web-access-contract.md` §2, and `ADR-006`.

---

## What Clients Can and Cannot Do

### Can Do (Direct Supabase Access)

- Read/write own business data (RLS-scoped)
- Upload/download receipt images (private bucket, authenticated)
- Manage categories, transactions, settings
- Generate reports, export data
- Authenticate (phone OTP, magic link)

### Cannot Do

- Access other businesses' data (RLS blocks)
- Use `service_role` key (not in client code)
- Call Gemini directly (key server-side only)
- Bypass RLS (database enforces)
- Access public storage (bucket is private)

### Must Do via Edge Function

- AI extraction (Gemini key isolation)
- Account deletion (full cascade with `service_role`)
- Any future operation requiring secrets or elevated privileges

---

## Consequences

### Positive

- **Strong tenant isolation.** RLS ensures no cross-tenant data access, regardless of client bugs.
- **Simple client code.** Clients don't need to implement authorization logic — RLS handles it.
- **Consistent security.** Both Mobile and Web enforce the same rules via shared RLS policies.
- **Auditability.** Security policies are declarative SQL, easy to review and test.
- **Low maintenance.** No custom authorization middleware to maintain.

### Negative

- **Anon key visible in clients.** This is by design — it's not a secret. But it may confuse developers unfamiliar with Supabase's security model.
- **RLS complexity.** Policies must be carefully designed and tested. A policy bug can expose cross-tenant data.
- **Limited server-side validation.** PostgREST validates against CHECK constraints, but there's no application-level validation middleware. This is acceptable at MVP scale.
- **Schema migrations require care.** Changes to tables with RLS policies must be tested against existing policies to avoid security regressions.

### Risks

| Risk | Mitigation |
|------|-----------|
| RLS policy bugs | Automated RLS tests; security advisors; code review |
| Anon key misuse | Document that anon key is not a secret; RLS provides security |
| Schema migration breaks RLS | Test migrations against RLS policies before deploying |
| Client code inspection | No secrets in clients; RLS enforces at database level |

---

## Follow-Up Items

1. **RLS testing.** Write automated tests for all RLS policies. Test cross-tenant access attempts.
2. **Security advisors.** Run Supabase security advisors regularly to catch policy gaps.
3. **Documentation.** Clearly document the security model for new developers (this ADR is the starting point).
4. **Monitoring.** Track RLS policy denials to detect potential attack attempts.

---

## References

- RLS Matrix: `docs/database/rls-matrix.md`
- Auth Contracts: `docs/api/auth-contracts.md`
- Data Access Contracts: `docs/api/data-access-contracts.md`
- Storage Contracts: `docs/api/storage-contracts.md`
- Backend Architecture: `docs/architecture/backend-architecture.md`
