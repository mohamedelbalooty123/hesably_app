# AGENTS.md

## Project
**Smart Invoice Assistant** — AI-powered receipt/invoice capture and bookkeeping app for small Egyptian shop owners. Flutter (mobile), Supabase (auth/db/storage), Gemini Vision API (AI extraction).

## Repo state (important)
This is a **greenfield scaffold — no application code exists yet**. `apps/mobile/`, `apps/mobile/dashboard/`, `supabase/migrations/`, `supabase/functions/` are **empty directories**. `supabase/config.toml` and `supabase/seed.sql` are empty placeholder files. There is no `pubspec.yaml`, `package.json` (except the `.opencode/` plugin helper), no build/test/lint tooling, and no CI. Do not assume any framework/tooling is "set up" — it isn't.

**However, the design documentation is extensive and complete.** Three design phases are fully written; three remain empty. See the documentation inventory below.

## Documentation inventory

### Completed design phases (read these before building anything)

| Directory | Files | Content |
|-----------|-------|---------|
| `docs/requirements/` | 8 files | Full product spec, business rules, acceptance criteria, user flows, 22 resolved decisions, assumptions |
| `docs/architecture/` | 5 docs + 6 ADRs | System, mobile, backend, dashboard, and AI architecture; architecture decision records 001–006 |
| `docs/database/` | 8 docs + 5 ADRs | Schema design, RLS matrix, indexes, storage, migration plan, relationships, data access patterns; DB ADRs 001–005 |

### Empty (not yet written)

| Directory | Planned content |
|-----------|----------------|
| `docs/api/` | API reference docs |
| `docs/implementation/` | Implementation guides |
| `docs/security/` | Security documentation |

### Key requirements files

| File | Content |
|------|---------|
| `feature-list.md` | Full product spec + phases (MVP → Phase 2/3), NFRs |
| `requirements.md` | 101 MVP requirements (FR-AUTH-*, FR-CAPTURE-*, etc.) with traceability |
| `business-rules.md` | Formalized business rules (BR-AUTH-*, BR-TRANS-*, etc.) |
| `acceptance-criteria.md` | 84 testable Given/When/Then criteria mapped to requirements |
| `open-questions.md` | 22 resolved product decisions (Q-001 through Q-022) |
| `assumptions.md` | 16 recorded assumptions (ASM-001 through ASM-016) |
| `user-flow-mobile.md` | Flutter app screens/flows |
| `user-flow-dashboard.md` | Next.js web dashboard flows |

## Planned architecture (from design docs — not yet implemented)

- Two clients share **one Supabase schema**: Flutter mobile app (`apps/mobile/`) + Next.js web dashboard (`apps/mobile/dashboard/`).
- Backend: Supabase (Auth/Postgres/Storage) + Gemini Vision API via a Supabase Edge Function (`supabase/functions/`).
- Auth: **phone + OTP only** for mobile MVP (no email/password). Dashboard uses email magic links, gated on an email identity linked from the mobile app.
- Web dashboard is only a companion view for MVP; camera capture + AI extraction stays mobile-only.

## Database design summary (from `docs/database/` — fully designed, no SQL generated yet)

**Six tables** — `businesses`, `categories`, `transactions`, `transaction_items`, `receipts`, `ai_extractions`.

**Ownership model**: 1:1 user ↔ business (via `auth.uid()`). All data is business-scoped. Composite same-tenant foreign keys enforce isolation at the DB level.

**Key constraints**:
- `numeric(14,2)` for money, EGP only
- TEXT columns with CHECK constraints for enums (not Postgres enums)
- DATE type for dates (no timestamp)
- No soft delete — hard delete via admin Edge Function + `ON DELETE CASCADE`
- Categories: default categories seeded via `SECURITY DEFINER` trigger, undeletable/unrenameable

**RLS**: Every table has per-business-owner policies. Three roles: `anon`, `authenticated`, `service_role`. Helper function `current_business_id()` returns `auth.uid()` → `businesses.id`.

**Storage**: Private `receipts` bucket. Path: `{business_id}/{transaction_id}/receipt.ext`. Row-first upload ordering (DB row created before storage upload).

**Indexes**: 8 unique constraints + 10 standalone indexes (including GIN trigram on `party_name` for Arabic search via `pg_trgm`).

**Migration plan**: 12 ordered migrations designed (extensions → tables → triggers → seed → indexes → RLS → storage). None written yet.

## AI extraction design (from `docs/architecture/ai-architecture.md`)

- Runs server-side in a Supabase Edge Function (API key never exposed to clients).
- Model: Gemini 2.5 Flash-Lite via `generateContent` with structured JSON output.
- **Confidence thresholds**: <80% flagged for user review, <50% treated as extraction failure.
- **15-second timeout** — on timeout, user falls back to manual entry.
- **NEVER auto-saves** — extracted data always goes through user review/confirmation before persistence.
- Input: receipt image as base64. Output: structured JSON (vendor, date, items, total, tax, confidence scores).
- Image quality check: 3-outcome (pass / retry with guidance / reject).

## Conventions that differ from defaults (from NFRs — honor them)

- **Primary UI language is Arabic, RTL** throughout (English secondary). Plan RTL support from the start.
- **Row Level Security in Supabase is mandatory** — each business owner can only read/write their own data.
- Receipt images go in a **private (not public) storage bucket**.
- **AI-extracted data is NEVER saved without user confirmation** — always route through a review/confirmation step first.
- Target runs on **low/mid-spec Android** — keep the app lightweight, avoid heavy animations.
- Offline capture is **out of scope for MVP** (Q-018).
- Export content respects current filters (Q-014). Export includes: date range, summary totals, category breakdown, transaction list.

## Requirements doc gotcha
`docs/requirements/user-flow-mobile.md` has ~14 lines of unrelated AI-assistant promotional text at the top (junk that leaked into the commit); the actual spec starts at line 15 (`# User Flow — Mobile App`). Don't treat that junk as content.

## Git Workflow Contract (mandatory for all agents)

Every code/doc change MUST flow through disciplined version control. Follow these rules on **every task** — if the task was implemented successfully, you commit, push, and open a pull request automatically (no need to ask).

### Default branch
- `master` is the default branch and must always be deployable/stable.
- Work on short-lived branches only; never commit directly to `master`.

### Branch naming
- `feature/<short-description>` — new features, e.g. `feature/phone-otp-auth`
- `fix/<short-description>` — bug fixes, e.g. `fix/duplicate-receipts`
- `refactor/<short-description>` — refactors, e.g. `refactor/auth-module`
- `chore/<short-description>` — tooling/deps/config, e.g. `chore/update-deps`
- `docs/<short-description>` — documentation, e.g. `docs/git-workflow`
- Branch from `master`. Keep branches short-lived (merge within 1-3 days). Delete after merge.

### Commit message format
```
<type>: <short description>

<optional body explaining the WHY, not the what>
```

Types:
- `feat` — new feature
- `fix` — bug fix
- `refactor` — code change that neither fixes a bug nor adds a feature
- `test` — adding/updating tests
- `docs` — documentation only
- `chore` — tooling, dependencies, config

### Commit discipline
- **Commit early, commit often** — each successful increment gets its own commit. No giant commits.
- **Atomic commits** — each commit does ONE logical thing. Don't mix formatting with behavior, or refactors with features.
- Messages explain the *why*, not just the *what*.

### Pre-commit hygiene (before EVERY commit)
1. `git diff --staged` — check what you're about to commit.
2. Scan for secrets: no passwords/API keys/tokens in the diff.
3. Run tests, lint, and type-check if tooling exists for the affected code.
4. Ensure `.gitignore` covers generated/secret files.

### Pull requests
- After a successful implementation: push your branch, then open a PR against `master`.
- Title uses the same `<type>: <description>` convention.
- Keep PRs small (~100 lines target, split over ~1000 lines).
- Each PR = one logical change.

### After any change
Provide a structured summary:
```
CHANGES MADE:
- <file>: <what changed>

THINGS I DIDN'T TOUCH (intentionally):
- <file>: <why out of scope>

POTENTIAL CONCERNS:
- <anything reviewer should check>
```
