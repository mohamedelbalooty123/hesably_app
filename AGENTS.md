# AGENTS.md

## Project
**Smart Invoice Assistant** — AI-powered receipt/invoice capture and bookkeeping app for small Egyptian shop owners. Flutter (mobile), Supabase (auth/db/storage), Gemini Vision API (AI extraction).

## Repo state (important)
This is a **greenfield scaffold — no application code exists yet**. `apps/mobile/`, `apps/mobile/dashboard/`, `supabase/migrations/`, `supabase/functions/`, and every `docs/` subdir (api, architecture, database, implementation, security) are **empty directories**. `supabase/config.toml` and `supabase/seed.sql` are empty placeholder files. There is no `pubspec.yaml`, `package.json` (except the `.opencode/` plugin helper), no build/test/lint tooling, and no CI. Do not assume any framework/tooling is "set up" — it isn't.

The only real source of truth for what to build is `docs/requirements/`:

| File | Content |
|------|---------|
| `feature-list.md` | Full product spec + phases (MVP → Phase 2/3), NFRs |
| `user-flow-mobile.md` | Flutter app screens/flows |
| `user-flow-dashboard.md` | Next.js web dashboard flows |

Read these before proposing or building features.

## Planned architecture (from requirements docs — not yet implemented)
- Two clients share **one Supabase schema**: Flutter mobile app (`apps/mobile/`) + Next.js web dashboard (`apps/dashboard/` — future home of the web app).
- Backend: Supabase (Auth/Postgres/Storage) + Gemini Vision API via a Supabase Edge Function (`supabase/functions/`).
- Auth: **phone + OTP only** for mobile MVP (no email/password). Dashboard uses email magic links, gated on an email identity linked from the mobile app.
- Web dashboard is only a companion view for MVP; camera capture + AI extraction stays mobile-only.

## Conventions that differ from defaults (from NFRs — honor them)
- **Primary UI language is Arabic, RTL** throughout (English secondary). Plan RTL support from the start.
- **Row Level Security in Supabase is mandatory** — each business owner can only read/write their own data.
- Receipt images go in a **private (not public) storage bucket**.
- **AI-extracted data is NEVER saved without user confirmation** — always route through a review/confirmation step first.
- Target runs on **low/mid-spec Android** — keep the app lightweight, avoid heavy animations.

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
