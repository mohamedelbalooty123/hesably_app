# RLS Matrix — Smart Invoice Assistant

Row Level Security is **mandatory** (AGENTS.md) and enabled on every business table and the private storage bucket. This matrix is the complete access-control spec.

---

## 1. Security model (three layers)

| Layer | Concern | Enforced by |
|---|---|---|
| **Auth** | *Who* is making the request (phone OTP / magic link) | Supabase Auth → JWT (`auth.uid()`) |
| **Authorization** | *What* the authenticated user may do | RLS policies per table per operation |
| **Ownership** | That records always resolve to *this* user's business | `current_business_id()` predicate used by every policy |

> **Web-access gating (Q-015 / ADR-006) is intentionally NOT an RLS layer.** `web_access_enabled`/`web_email` are *metadata*; the per-request server-side gate (Edge Function / API middleware) rejects requests based on it before they reach the DB. RLS trusts the authenticated caller as the sole owner.

## 2. Roles

| Role | When used | Effective access |
|---|---|---|
| `anon` | unauthenticated / public | **zero** access to tables, functions, storage bucket |
| `authenticated` | app + dashboard sessions (owner JWT) | RLS-scoped table access + private bucket access |
| `service_role` | admin Edge Functions only (e.g. account deletion) | bypasses RLS (BYPASSRLS) — **never** exposed client-side; functions are minimal and scoped |

## 3. Helper: `current_business_id()`

```sql
-- SECURITY INVOKER, STABLE
SELECT b.id FROM businesses b WHERE b.owner_id = auth.uid();
```

- Empty result → caller has no business → all RLS predicates false → zero data returned.
- `EXECUTE` granted to `authenticated` only (`PUBLIC` revoked) to avoid leaking existence info to `anon`.

## 4. Table policy matrix

Notation: **USING** is the row filter for the operation; **WITH CHECK** validates rows written. Legende for "grant": grant table privileges to `authenticated`.

### `businesses`
| Operation | Policy expression | Notes |
|---|---|---|
| SELECT | `owner_id = auth.uid()` | only own tenant root |
| INSERT | CHECK `owner_id = auth.uid()` | owner can create their own business (first run). Only business row the app ever creates. |
| UPDATE | USING `owner_id = auth.uid()`; CHECK `owner_id = auth.uid()` | owner edits name / web-access flag; cannot hand the business to another user |
| DELETE | **no policy** | blocked; account removal is admin-Edge-Function scoped (ADR-DB-005) |

### `categories`
| Operation | Policy |
|---|---|
| SELECT | `business_id = current_business_id()` |
| INSERT | CHECK `business_id = current_business_id() AND type = 'custom'` |
| UPDATE | USING `business_id = current_business_id()`; CHECK `business_id = current_business_id()` |
| DELETE | USING `business_id = current_business_id() AND type = 'custom'` |

Notes: INSERT restricted to `custom` so clients can never create `default` rows (seeding is server-side). DEFAULT identity is further hardened by `categories_guard_default_immutable()`. `is_hidden` toggling is allowed by UPDATE for both types.

### `transactions`
| Operation | Policy |
|---|---|
| SELECT | `business_id = current_business_id()` |
| INSERT | CHECK `business_id = current_business_id()` |
| UPDATE | USING `business_id = current_business_id()`; CHECK `business_id = current_business_id()` |
| DELETE | USING `business_id = current_business_id()` |

### `transaction_items`
Identical shape to `transactions` (all four ops, `business_id = current_business_id()`).

### `receipts` (immutable)
| Operation | Policy |
|---|---|
| SELECT | `business_id = current_business_id()` |
| INSERT | CHECK `business_id = current_business_id()` |
| UPDATE | **no policy** — immutable record |
| DELETE | USING `business_id = current_business_id()` (owner may detach an image; transaction record unaffected) |

### `ai_extractions` (immutable, after-confirmation only)
| Operation | Policy |
|---|---|
| SELECT | `business_id = current_business_id()` |
| INSERT | CHECK `business_id = current_business_id()` (app inserts **only after user confirmation**, NFR-DATA-001) |
| UPDATE | **no policy** — immutable provenance |
| DELETE | **no policy** — removal only via transaction cascade |

## 5. Storage (`storage.objects`) — bucket `receipts`, private

All policies reference `bucket_id = 'receipts'`. Ownership = first path segment.

| Operation | Policy expression |
|---|---|
| SELECT | `(storage.foldername(name))[1] = current_business_id()::text` |
| INSERT | CHECK `(storage.foldername(name))[1] = current_business_id()::text` |
| UPDATE | **no policy** |
| DELETE | `(storage.foldername(name))[1] = current_business_id()::text` |

- Bucket is `private`; public URLs are impossible.
- Objects may only live under `{business_id}/…` (download/upload path enforced + app path convention).
- `anon`: no policies → 403/404 for everything.

## 6. Grants summary

Grants (goal state; the policies in §4 are the authority for what each operation may touch):

- `REVOKE ALL ON <all 6 tables> FROM anon, public;`
- To `authenticated`:

  | Table               | SELECT | INSERT | UPDATE | DELETE |
  |---------------------|--------|--------|--------|--------|
  | `businesses`        | ✅     | ✅     | ✅     | —      |
  | `categories`        | ✅     | ✅     | ✅     | ✅     |
  | `transactions`      | ✅     | ✅     | ✅     | ✅     |
  | `transaction_items` | ✅     | ✅     | ✅     | ✅     |
  | `receipts`          | ✅     | ✅     | —      | ✅     |
  | `ai_extractions`    | ✅     | ✅     | —      | —      |

  (A grant authorizes the operation class; RLS policies make it owner-scoped. `businesses` and `ai_extractions` intentionally have no DELETE grant, matching their policy set.)

- `GRANT EXECUTE ON FUNCTION current_business_id() TO authenticated;`
- `REVOKE EXECUTE ON FUNCTION current_business_id() FROM public;`

## 7. Edge Function access

| Function | Role | DB access |
|---|---|---|
| `extract-receipt` | owner key | receives image **bytes** (multipart, owner session); never touches storage and never writes `ai_extractions`/`transactions` (client confirms first) |
| account-deletion (admin) | `service_role` | deletes auth user → cascade removes tenant; cleans storage objects |

Principle: the client never holds `service_role`. Elevated code paths are tiny, reviewed, and cannot read/delete other tenants' rows beyond their explicit purpose (ADR-DB-005).

## 8. Defence-in-depth checklist

- [ ] RLS enabled on all 6 tables + storage bucket.
- [ ] `anon` has zero grants and zero policies.
- [ ] Every query the clients run resolves through `current_business_id()`.
- [ ] Composite FKs prevent cross-tenant references independent of RLS (belt *and* braces).
- [ ] Immutable tables have no UPDATE policy; provenance has no DELETE policy.
- [ ] `service_role` never exposed to clients; admin functions minimal.
- [ ] Web access is a server-side gate, never an RLS relaxation.
- [ ] Object paths are tenant-prefixed; storage policies mirror table policies.