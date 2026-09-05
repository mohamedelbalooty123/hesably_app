# ADR-001 — Architecture Style

**Status:** Accepted
**Date:** 2026-08-31
**Applies to:** Mobile, Dashboard, Backend, AI

## Context

The Smart Invoice Assistant is an MVP for solo Egyptian shop owners: a Flutter mobile app as the primary experience, a Next.js web dashboard as a companion, Supabase as the shared backend, and Gemini for receipt extraction. The requirements demand security, data trust (no silent AI saves), cross-platform consistency, Arabic-first RTL, low-spec Android support, and explicit MVP scope. The architecture must be simple enough to ship, maintainable and testable, and leave seams for documented Phase 2/3 features — without speculative enterprise complexity (no microservices, event buses, queues, or caching layers unless justified).

## Decision

Adopt a **simple, pragmatic layered architecture per component** — not a single grand style:

1. **Mobile (Flutter):** Layered Clean Architecture (Presentation → Domain → Data) organized **feature-first**, with repository interfaces owned by the Domain. State management uses **Bloc/Cubit** (`flutter_bloc`) — lightweight per-feature Cubits/Blocs exposed through `BlocProvider`; widgets never hold business logic. Navigation uses **go_router**; localization uses **easy_localization**. Domain is pure Dart and unit-testable without Flutter/Supabase. (See `mobile-architecture.md`.)

2. **Dashboard (Next.js):** App Router with **React Server Components for initial data + Client Components for interactivity**, and Supabase SSR for authentication/session. No heavy client state library in MVP; filters/periods live in the URL. (See `dashboard-architecture.md`.)

3. **Backend (Supabase):** Backend-as-a-service — **Postgres + RLS as the authorization authority**, private object Storage, Auth for both clients, and one server-side Edge Function as the AI boundary. There is deliberately no custom application server for business data (ASM-007). (See `backend-architecture.md`.)

4. **AI (Edge Function → Gemini):** a **single server-side extraction boundary** isolating Gemini behind a stable HTTP contract, with a confidence model and a strict no-persistence rule. (See `ai-architecture.md`.)

## Why (rationale)

- **Separation of concerns / testability:** Domain logic (validation, reviewer gating, EGP semantics, period/export scope, category normalization) is framework-free, so the most bug-prone logic is unit-testable (mobile §18).
- **MVP simplicity:** each component uses the minimum machinery that still gives clean boundaries. RLS replaces a custom authz layer; the Edge Function replaces a bespoke AI service; client-side export replaces an export service.
- **Consistency between platforms:** both clients share one schema, one ownership model, one period set, one category model, and one currency format (Q-011, Q-012, Q-021), reinforced by a common responsibility matrix (`backend-architecture.md` §3).
- **Extensibility:** layer/repository seams localize Phase 2 items (extended offline sync, multi-user, server export) without redesign; the same seams host the MVP offline pending queue (ADR-007).

## Consequences

- **Positive:** fast to build; business logic is testable; platform/scalability details stay in the data layer; RLS + private storage + server-side AI key deliver the mandatory security posture.
- **Negative:** RLS becomes the single most important security control — it must be designed and tested with rigor in the Database Design phase. Client-side export must be re-assessed for very large datasets (Phase 2 seam). Some shared logic (normalization, search predicate) must be mirrored consistently across the two clients.
- **Traceability:** MVP scope boundaries BR-MVP-001…006; NFR-SEC-001/002; NFR-DATA-001; NFR-LANG-001; NFR-LOWDEV-001; ASM-001/002/007/008; Q-006, Q-011, Q-012, Q-021.