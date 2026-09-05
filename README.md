# Smart Invoice Assistant

AI-powered receipt/invoice capture and bookkeeping for small Egyptian shop owners. Take a photo of a receipt, let Gemini extract the details, confirm, and your books stay up to date — all from your phone.

## Overview

Small shop owners in Egypt run on paper receipts and mental arithmetic. This app turns that into clean, searchable bookkeeping:

- **Capture a receipt** with the camera or from the gallery — even with no internet (waits in a local queue and syncs later).
- **AI extraction** reads vendor, date, items, total, tax, and suggests a category — with a confidence score per field.
- **You confirm before anything is saved.** Extracted data is never persisted silently; low-confidence fields are flagged for review.
- **Understand your business** with monthly income/expense summaries, category breakdowns, and exports.

The mobile app is the primary product; a web dashboard provides a companion view for reading reports.

## MVP features

- **Authentication** — phone + OTP only (no passwords), short onboarding, session persistence.
- **Receipt capture** — camera/gallery, basic image-quality check, sales vs purchase type.
- **AI extraction** — Gemini 3.1 Flash-Lite (server-side Edge Function; API key never reaches the client), confidence thresholds (<80% flagged, <50% failure), 15s timeout with manual-entry fallback.
- **Review & edit** — extracted fields pre-filled in an editable form; save happens only after user confirmation. Manually enter receipts that have no paper trail.
- **Categories** — seeded defaults for Egyptian retail/service businesses, AI-suggested, overridable, custom categories supported.
- **Transactions** — chronological list with receipt thumbnails, filters (date/category/type/amount), name search, edit/delete, detail view with the original image.
- **Dashboard & reports** — current-month totals, category breakdown, month-over-month comparison.
- **Export** — PDF/Excel/CSV scoped to the selected report period *and* the currently applied filters.

See `docs/requirements/feature-list.md` and `docs/requirements/requirements.md` for the full specification.

## Tech stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Arabic-first, RTL, low/mid-spec Android target) |
| Dashboard | Next.js (companion web view) |
| Backend | Supabase — Auth, Postgres with Row Level Security, private Storage, Edge Functions |
| AI | Gemini Vision API (Gemini 3.1 Flash-Lite) via a server-side Edge Function |

## Architecture

Two clients share **one Supabase schema** — Flutter mobile and the Next.js dashboard. All data is scoped to the business owner via Row Level Security; receipt images live in a private storage bucket at `{business_id}/{transaction_id}/receipt.ext`; AI extraction runs server-side only. Full detail in `docs/architecture/system-architecture.md`.

## Repository layout

```
apps/
  mobile/        Flutter app            (not yet scaffolded)
  dashboard/     Next.js web dashboard  (not yet scaffolded)
supabase/
  config.toml    (placeholder)
  seed.sql       (placeholder)
  migrations/    Database schema, 0001–0013 (implemented)
  functions/     Edge Functions         (not yet scaffolded)
docs/
  requirements/  Product spec, business rules, acceptance criteria, decisions
  architecture/  System/mobile/backend/dashboard/AI design + ADR-001–007
  database/      Schema, RLS, indexes, storage, migration plan + DB ADRs
  api/           Data-access & API contracts + API ADRs
  mobile-design/ UX strategy, information architecture, user journeys
  change-management/  Scope-change analyses and impact matrices
  implementation/     (empty)
  security/            (empty)
```

## Project status

- **Done** — full requirements, architecture, database, API, and UX design packages; external review pass; the Supabase database schema is **implemented** in `supabase/migrations/0001–0013` (extensions → tables → triggers → seed → indexes → RLS → storage).
- **In progress** — no application code yet. `apps/`, and the AI Edge Function under `supabase/functions/`, are unbuilt.

## Getting started

Development tooling is not set up yet (no `pubspec.yaml`, no `package.json`, no CI). For the database side, follow the migration plan in `docs/database/migration-plan.md`.

## Documentation

The design documentation is extensive and complete — read it before building anything:

- Product spec & decisions: `docs/requirements/`
- Architecture & ADRs: `docs/architecture/`
- Database design & migration plan: `docs/database/`
- API & data-access contracts: `docs/api/`
- Mobile UX design: `docs/mobile-design/`

## Contributing

See the Git Workflow Contract (branching, commit format, PR rules) in `AGENTS.md`.