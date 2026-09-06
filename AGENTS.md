# AGENTS.md

## Project
**Smart Invoice Assistant** — AI-powered receipt/invoice capture and bookkeeping app for small Egyptian shop owners. Flutter (mobile), Supabase (auth/db/storage), Gemini Vision API (AI extraction).

## Repo state (important)
**The backend database schema is implemented; no application code exists yet.**

- `supabase/migrations/` contains **13 ordered migrations** (`0001_extensions.sql` → `0013_fix_advisors.sql`) implementing the full designed schema (extensions → tables → triggers → seed → indexes → RLS → storage). The design docs in `docs/database/` describe exactly what these migrations build — do not treat the schema as unimplemented.
- `apps/mobile/` and `apps/mobile/dashboard/` are **empty directories**. There is no `pubspec.yaml` or `package.json`, no build/test/lint tooling, and no CI. The Flutter app and Next.js dashboard are **not scaffolded** — do not assume any framework/tooling is "set up"; it isn't.
- `supabase/functions/` is empty (the AI extraction Edge Function is designed but not written).
- `supabase/config.toml` and `supabase/seed.sql` are empty placeholder files.
- The `.opencode/` directory contains plugin/skill helper config (e.g., `opencode.json`, agent skills) — not application code.

**The design documentation is extensive and complete.** See the documentation inventory below.

## Documentation inventory

### Completed design phases (read these before building anything)

| Directory | Files | Content |
|-----------|-------|---------|
| `docs/requirements/` | 8 files | Full product spec, business rules, acceptance criteria, user flows, 22 resolved decisions, assumptions |
| `docs/architecture/` | 5 docs + 7 ADRs | System, mobile, backend, dashboard, and AI architecture; architecture decision records 001–007 (incl. ADR-007 offline capture) |
| `docs/database/` | 8+ docs + 5 ADRs | Schema design, RLS matrix, indexes, storage, migration plan, relationships, data access patterns; DB ADRs 001–005 |
| `docs/api/` | 10+ contract docs + 3 ADRs | Auth, transaction, category, storage, report, export, AI edge function, web access, data access contracts; API ADRs 001–003 |
| `docs/mobile-design/` | 8+ files | UX strategy, information architecture, interaction model, navigation map, user journeys, screen inventory, UX states |
| `docs/change-management/` | 2 files | Offline-MVP change impact analysis + post-change consistency matrix |

### Empty (not yet written)

| Directory | Planned content |
|-----------|----------------|
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

## Database design summary (from `docs/database/` — implemented in `supabase/migrations/0001_…0013`)

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

**Migration plan**: 12 ordered migrations designed (extensions → tables → triggers → seed → indexes → RLS → storage). Implemented as 13 migrations in `supabase/migrations/0001–0013` (`0013_fix_advisors` addresses security-advisor findings).

## AI extraction design (from `docs/architecture/ai-architecture.md`)

- Runs server-side in a Supabase Edge Function (API key never exposed to clients).
- Model: Gemini 3.1 Flash-Lite via `generateContent` with structured JSON output.
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
- **Offline capture IS in MVP** (Q-018 flipped): camera/gallery capture works with no internet via a local pending-queue, syncing + AI-processing when back online (ADR-007). Offline covers **capture + deferred sync only** — offline AI, upload, reports, and cross-device sync remain online-only.
- Export content respects current filters (Q-014). Export includes: date range, summary totals, category breakdown, transaction list.

## Requirements doc gotcha
`docs/requirements/user-flow-mobile.md` has ~14 lines of unrelated AI-assistant promotional text at the top (junk that leaked into the commit); the actual spec starts at line 15 (`# User Flow — Mobile App`). Don't treat that junk as content.

## Stitch visual design workflow

Hesably UI mockups are designed in **Google Stitch**. The agent has Playwright browser MCP access to the Stitch project (user-granted, logged-in Chrome).

- **Stitch project id**: `projects/661013469764921318` (Hesably — Smart Invoice Assistant)
- **Design system**: `assets/7976229305596122358` ("Hesably Design System"). Theme: light, roundness ROUND_FOUR, primary custom color `#0A7A3D`; Cairo is proxied via Inter (Stitch has no Cairo). The `designMd` captures the full token set from `docs/mobile-design/design-system/`.
- Visual design work: `docs/mobile-design/design-system/stitch-handoff.md` is the source of truth for what/how to design. Generation/edit via Stitch MCP takes minutes and often returns `-32001` timeouts — those calls still run in background; verify by polling `get_screen` or re-checking `edit_screens` DOM operations.

### Mandatory visual QA step (before ANY Stitch design batch is marked done)
The model cannot view images through the normal toolchain, but it CAN via Playwright + Chrome (user-granted access to the Stitch project). So, after generating/editing screens in Stitch:

1. Open the Stitch project in Chrome via Playwright browser tools.
2. Navigate to each screen in the batch; screenshot it (mobile viewport ~393×852 and/or the Stitch canvas).
3. Verbally inspect the screenshots for consistency vs the design-system tokens, RTL layout, Arabic copy (no English placeholders), repeated elements (nav bars, buttons, app bars), and exact copy wording.
4. Correct any violations via Stitch MCP `edit_screens`, then re-screenshot to confirm.
5. Do NOT claim a batch is "visually confirmed" without this browser review.

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
