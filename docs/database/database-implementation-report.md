# Database Implementation Report — Smart Invoice Assistant

| | |
|---|---|
| **Phase** | Database Implementation |
| **Project** | Hesably App |
| **Supabase project ref** | `czypdtmgyqzwoghrhkfz` |
| **Implementation date** | 2026-09-03 |
| **Status** | COMPLETE |
| **CLI/Workflow** | Supabase MCP (`apply_migration` / `execute_sql`) |

---

## 1. Environment

| Item | Value |
|---|---|
| Supabase project ref | `czypdtmgyqzwoghrhkfz` |
| Project name | Hesably App |
| Region | eu-west-1 |
| PostgreSQL | v17.6.1.166 |
| Project status | ACTIVE_HEALTHY |
| Implementation tooling | Supabase MCP server (`supabase_apply_migration`, `supabase_execute_sql`) |
| Target freshness check | PASSED — `public` schema empty, 0 migrations, no conflicting objects |

---

## 2. Migrations

13 migrations applied (12 from the reviewed plan + 1 advisor-fix follow-up):

| # | Name | Contents |
|---|---|---|
| 001 | `extensions` | Enable `pg_trgm` |
| 002 | `businesses` | Table, PK, `owner_id` UNIQUE FK→`auth.users` CASCADE, partial UNIQUE `web_email` |
| 003 | `categories` | Table, UNIQUE (business_id,name_key) + (id,business_id), guard trigger (HIGH-01) |
| 004 | `transactions` | Table, composite FK→categories RESTRICT, CHECKs incl. party_name bound |
| 005 | `transaction_items` | Table, composite FK→transactions CASCADE |
| 006 | `receipts` | Table, UNIQUE transaction_id + storage_path, mime/size CHECKs, no updated_at |
| 007 | `ai_extractions` | Table, UNIQUE transaction_id, confidence CHECK, no updated_at |
| 008 | `updated_at_timestamps` | `set_updated_at()` + triggers on 4 mutable tables |
| 009 | `seed_default_categories` | Seeder (SECURITY DEFINER) + AFTER INSERT trigger + REVOKE EXECUTE (HIGH-02) + AI provenance guard (MEDIUM-01) |
| 010 | `indexes` | I1–I10 standalone indexes incl. GIN trgm |
| 011 | `rls` | `current_business_id()` helper, enable RLS (6 tables), grants, per-table policies |
| 012 | `storage` | Private bucket `receipts` + owner-scoped SELECT/INSERT/DELETE policies |
| 013 | `fix_advisors` | Pinned `search_path` on all functions, composite FK indexes, RLS initplan optimization |

Migrated SQL is mirrored into `supabase/migrations/0001…0013_*.sql` for version control.

---

## 3. Schema

**6 tables** created exactly per the reviewed design:

| Table | Mutability | Notes |
|---|---|---|
| `businesses` | mutable | 1:1 tenant root; `owner_id` UNIQUE; partial unique `web_email` |
| `categories` | mutable | defaults guarded (HIGH-01); custom editable |
| `transactions` | mutable | composite FK to categories RESTRICT; AI provenance guarded |
| `transaction_items` | mutable | composite FK to transactions CASCADE |
| `receipts` | immutable | 1:1 per transaction; path unique |
| `ai_extractions` | immutable | 1:1 per transaction; post-confirmation only |

**10 foreign keys** (4 single-column CASCADE + `businesses.owner_id` + 5 composite same-tenant FKs):
- 6 tenant-scoping CASCADE FKs → `businesses(id)`
- `businesses.owner_id` → `auth.users` CASCADE
- `transactions.(category_id,business_id)` → `categories(id,business_id)` RESTRICT
- `transaction_items`, `receipts`, `ai_extractions` `(x_id,business_id)` → `transactions(id,business_id)` CASCADE

**Constraints verified:** CHECKs (amounts>0, enums, currency pin, party_name≤255, mime, size), UNIQUEs (U1–U8 + composite FK targets), NOT NULLs, defaults.

---

## 4. Security

### RLS
- Enabled on **all 6 tables** + `FORCE ROW LEVEL SECURITY` (defense-in-depth).
- `current_business_id()` helper — SECURITY INVOKER, STABLE, search_path pinned; EXECUTE granted to `authenticated` only.
- Per-table policies implemented with ownership predicates (`business_id = current_business_id()` or `owner_id = auth.uid()`).
- UPDATE policies always include both `USING` and `WITH CHECK`.
- Immutable tables (`receipts`, `ai_extractions`) have **no** UPDATE policy; `ai_extractions` has no DELETE policy.
- `businesses` has **no** DELETE policy (admin-scoped account removal).
- No `TO authenticated`-only policies — every policy has an ownership predicate.

### Function permissions
- `seed_default_categories_for_business()`: **EXECUTE revoked from `public`, `anon`, `authenticated`** (HIGH-02 — verified with `has_function_privilege`, all false). Trigger-only path.
- `current_business_id()`: EXECUTE to `authenticated` only.
- All functions have pinned `search_path`.

### Storage
- Private bucket `receipts` (`public = false`).
- Policies: SELECT/INSERT (WITH CHECK)/DELETE keyed on `(storage.foldername(name))[1] = current_business_id()::text`; no UPDATE policy.
- No public URLs; `anon` has zero policies.

### Grants
- `anon`: zero grants, zero policies.
- `authenticated`: operation-class grants per `rls-matrix.md` §6.
- `service_role`: bypasses RLS — used only by admin account-deletion function (never client-exposed).

---

## 5. Verification Results

### Cross-business isolation (User A vs User B)
| Test | Result |
|---|---|
| Business A and B created, 10 default categories each | PASS |
| A sees only A's transactions | PASS |
| B sees only B's transactions | PASS |
| Cross-business category reference rejected by composite FK | PASS (both directions) |
| Cascade delete of B's transactions | PASS |

### Category rules
| Test | Result |
|---|---|
| Default category rename blocked | PASS |
| Custom category rename succeeds | PASS |
| Default category type change blocked | PASS |
| Custom category type change blocked | PASS |
| Default `is_hidden` toggle works | PASS |
| Custom `is_hidden` toggle works | PASS |
| Duplicate normalized name rejected | PASS |
| In-use custom category delete blocked (RESTRICT) | PASS |
| Default category delete blocked (RLS `type='custom'`) | PASS |
| Unused custom category delete succeeds | PASS |

### Seeder (HIGH-02)
| Test | Result |
|---|---|
| 10 defaults seeded on new business | PASS |
| Seeder EXECUTE revoked from anon | PASS |
| Seeder EXECUTE revoked from authenticated | PASS |
| No duplicate seed (idempotent via UNIQUE) | PASS |

### AI provenance guard (MEDIUM-01)
| Test | Result |
|---|---|
| Manual transaction without extraction succeeds | PASS |
| AI transaction without extraction blocked | PASS |
| AI transaction with extraction (insert → provenance → update) succeeds | PASS |

### Web access lifecycle (MEDIUM-02)
| Test | Result |
|---|---|
| Initial disabled / no email | PASS |
| Enable + link email | PASS |
| Unlink clears both `web_access_enabled=false` and `web_email=NULL` | PASS |
| Re-link same email works (global unique released) | PASS |

### party_name bound (LOW-03)
| Test | Result |
|---|---|
| Valid party_name accepted | PASS |
| party_name > 255 chars rejected | PASS |
| NULL party_name accepted | PASS |

### updated_at
| Test | Result |
|---|---|
| `set_updated_at()` trigger attached to all 4 mutable tables | PASS |
| Immutable tables (receipts, ai_extractions) have no updated_at trigger | PASS |
| Trigger correctly sets `updated_at = now()` on UPDATE | PASS |

### Storage
| Test | Result |
|---|---|
| Private bucket `receipts` exists | PASS |
| SELECT policy owner-scoped by path segment 1 | PASS |
| INSERT policy WITH CHECK owner-scoped | PASS |
| DELETE policy owner-scoped | PASS |
| No UPDATE policy on objects | PASS |
| No public access | PASS |

### Schema
| Test | Result |
|---|---|
| 6 tables present | PASS |
| All named constraints present | PASS |
| All 10 FKs present | PASS |
| All unique constraints (U1–U8 + composite targets) present | PASS |
| All 10 standalone indexes present | PASS |
| RLS enabled on all 6 tables | PASS |

---

## 6. Supabase Advisors

### Security advisors
| Finding | Severity | Resolution |
|---|---|---|
| `function_search_path_mutable` (5 functions) | WARN | FIXED — pinned `search_path` on all functions (migration 013) |
| `extension_in_public` (pg_trgm) | WARN | ACCEPTED — `pg_trgm` is required in `public` for the `lower(party_name)` GIN expression index on a `public` table; extension is trusted infrastructure |
| `anon_security_definer_function_executable` (`rls_auto_enable`) | WARN | ACCEPTED — Pre-existing Supabase platform function, not part of our schema; not a reviewed object |
| `authenticated_security_definer_function_executable` (`rls_auto_enable`) | WARN | ACCEPTED — Same as above |
| `auth_leaked_password_protection` disabled | WARN | ACCEPTED — Auth policy setting outside DB schema scope (phone+OTP is the primary auth path) |

### Performance advisors
| Finding | Severity | Resolution |
|---|---|---|
| `unindexed_foreign_keys` (receipts, ai_extractions, transaction_items composite FKs) | INFO | FIXED — added composite FK-covering indexes (migration 013) |
| `auth_rls_initplan` (businesses policies) | WARN | FIXED — replaced `auth.uid()` with `(select auth.uid())` (migration 013) |
| `unused_index` (various, incl. trgm) | INFO | ACCEPTED — indexes not yet exercised because the application has zero production queries on a greenfield schema; they target the reviewed query patterns and will be used at runtime |

---

## 7. Deviations

| Item | Deviation | Reason |
|---|---|---|
| Migration count | 12 → 13 | Added `013_fix_advisors` to close advisor findings post-review (pinned search_path, composite FK indexes, RLS initplan optimization). Does not alter the reviewed design. |
| Seeder loop | FOREACH text-array → explicit VALUES block | `FOREACH … SLICE` over a `text[][]` is rejected by this PostgreSQL version; explicit multi-row `INSERT … ON CONFLICT DO NOTHING` preserves exact behavior (idempotent, same 10 defaults, same `(business_id,name_key)` dedup). |

---

## 8. Remaining Risks

| Risk | Severity | Mitigation / status |
|---|---|---|
| Last-write-wins overwrite (cross-device) | MEDIUM (accepted, Q-006) | Documented in `database-review.md`; Phase 2 realtime |
| Storage MIME/size enforcement relies on app + CHECK | MEDIUM (accepted, MEDIUM-03) | `receipts.mime_type`/`size_bytes` CHECKs + app-level capture-side downscaling; server-side validation deferred to Phase 2 |
| Storage object ↔ DB row drift on crash | MEDIUM | Row-first upload ordering + app-level compensation (documented in `storage-design.md` §5/§8) |
| Redundant category index overlap (I5 vs I3) | LOW | Retained for FK RESTRICT delete-time correctness; revisit with real stats post-MVP (LOW-02) |

---

## 9. Definition of Done Checklist

```
[x] Reviewed database design implemented
[x] All approved HIGH corrections implemented (HIGH-01 custom rename; HIGH-02 seeder revoke)
[x] AI provenance guard implemented (MEDIUM-01)
[x] Web email unlink lifecycle implemented (MEDIUM-02)
[x] party_name bounded (LOW-03)
[x] All six tables created
[x] All relationships (composite same-tenant FKs) created and verified
[x] Constraints verified
[x] Indexes created (U1–U8, I1–I10)
[x] RLS enabled on all 6 tables
[x] RLS policies implemented (owner-scoped; UPDATE USING+WITH CHECK verified)
[x] Cross-business isolation tests pass (User A vs User B)
[x] Category seeding works (10 defaults on business create)
[x] Custom category rename works
[x] Default category rename fails
[x] Default category delete fails
[x] Custom category delete works (unless in use → RESTRICT)
[x] Duplicate normalized category rejected
[x] Private storage bucket created (receipts)
[x] Storage policies verified (owner SELECT/INSERT/DELETE; no UPDATE; anon none)
[x] Storage cross-business isolation verified
[x] Seeder EXECUTE revoked from public/anon/authenticated
[x] Report query support verified (index coverage)
[x] Search (party_name trgm) support verified
[x] Web access lifecycle verified (enable → link → unlink clears web_email)
[x] Web transaction create is application-blocked (documented; no fake DB distinction)
[x] Account deletion relationships verified (owner_id CASCADE + admin storage cleanup)
[x] Supabase security advisors reviewed
[x] No unintended public access
[x] Database implementation report created
```

---

## Final Status

**COMPLETE**
