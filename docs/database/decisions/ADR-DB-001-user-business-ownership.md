# ADR-DB-001 — User↔Business Ownership Model

**Status:** Accepted · **Date:** 2026-08-31 · **Scope:** database layer

## Context

The MVP serves solo Egyptian shop owners: one person, one shop, one ledger. Requirements and architecture define phone-OTP auth for mobile and a magic-link dashboard that reads/edits the same data without creating a second tenant. We must decide how the database models "who owns what", how the dashboard fits, and how RLS (mandatory) derives the tenant. Prior work: ADR-006 (web-access identity), `docs/architecture/system-architecture.md`.

## Decision

1. **One Supabase Auth user owns exactly one `businesses` row.** `businesses.owner_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE`. No `profiles`, `membership`, `staff`, or `roles` tables in MVP.
2. **The tenant is the business.** Every child table carries denormalized `business_id` and is bound to its parent with composite same-tenant FKs (`relationships.md` §1.2).
3. **Web dashboard access is NOT a second tenant.** It is an opt-in flag on the business (`web_access_enabled`, `web_email` with partial UNIQUE) gated **server-side** per request (Q-015, ADR-006). It grants no DB role and appears in no RLS policy.
4. **RLS** derives the tenant with `current_business_id() = SELECT id FROM businesses WHERE owner_id = auth.uid()`; every table policy uses it (`rls-matrix.md`).

## Consequences

- The simplest correct isolation model: one predicate per request resolves a single tenant.
- No notion of shared/staff access (a Phase 2 feature — explicitly out of MVP). Adding staff later means new tables + policy changes but **no** change to existing owner semantics.
- `owner_id` UNIQUE hard-enforces "one business per user" in the DB regardless of client bugs.
- Account deletion = deleting the auth user cascades the whole tenant (ADR-DB-005).
- Dashboard identity must be linked to the same auth user via email identity; if the dashboard ever becomes a true second role this ADR is revisited.

## Alternatives considered

- **`profiles` = user profile + `businesses.owner_id` reference (dashboard via same email):** rejected — introduces a join hop into every policy for zero MVP benefit.
- **Membership/workspace table now (even empty):** YAGNI; defers a clean 1:1 → 1:N migration later.
- **Web access as `team`/`role`:** over-engineering; conflicts with Q-015's "metadata + gate" decision.