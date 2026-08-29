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
- Two clients share **one Supabase schema**: Flutter mobile app (`apps/mobile/`) + Next.js web dashboard (`apps/mobile/dashboard/` — future home of the web app).
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
