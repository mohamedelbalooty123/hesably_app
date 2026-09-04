# API & Security Decisions — Smart Invoice Assistant

Architecture Decision Records (ADRs) documenting key architectural choices for the data access layer, server-side boundaries, and client security model.

---

## What This Directory Contains

These ADRs capture the architectural decisions that shape how the application accesses data, enforces security, and interacts with external services. They are the "why" behind the contracts defined in the parent `docs/api/` directory.

---

## Decision Records

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| [ADR-API-001](ADR-API-001-direct-supabase-access.md) | Direct Supabase Client Access | Accepted | Clients talk directly to Supabase; no custom REST/GraphQL API |
| [ADR-API-002](ADR-API-002-edge-function-boundary.md) | Edge Function AI Boundary | Accepted | Single Edge Function mediates Gemini; never persists data |
| [ADR-API-003](ADR-API-003-client-security-boundary.md) | Client-Side Security Boundary | Accepted | RLS as authorization; keys in clients; no service role in clients |

---

## Relationship to Other Documentation

| Document | Relationship |
|----------|-------------|
| `docs/api/data-access-contracts.md` | Operations registry; implementation of these decisions |
| `docs/api/auth-contracts.md` | Auth flows; how the security boundary is enforced |
| `docs/api/*-contracts.md` | Domain-specific contracts; all follow these architectural decisions |
| `docs/database/rls-matrix.md` | Database-level enforcement of the security boundary |
| `docs/architecture/system-architecture.md` | System-level context for these decisions |

---

## Decision Principles

1. **Ship working software, then refine** — prefer simple, proven patterns over theoretical purity
2. **RLS is the authorization layer** — all security flows through database policies
3. **Server-side only for secrets** — API keys never touch client code
4. **No dead ends** — every error state has a recovery path
5. **Single source of truth** — one table shared across platforms (categories, transactions)

---

## How to Read These ADRs

Each ADR follows the standard format:
- **Title**: Short descriptive name
- **Status**: Accepted / Superseded / Deprecated
- **Context**: The situation or problem being addressed
- **Decision**: What was decided
- **Consequences**: Trade-offs, risks, and follow-up items

---

*Last updated: 2026-09-03*
