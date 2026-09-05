# Architecture Decision Records

This directory records the significant architectural decisions for the **Smart Invoice Assistant** project.

## Status

| ADR | Decision | Status |
|---|---|---|
| [ADR-001](./ADR-001-architecture-style.md) | Architecture style for Mobile, Dashboard, Backend, and AI | Accepted |
| [ADR-002](./ADR-002-client-backend-boundary.md) | Client / backend boundary with Supabase as the shared application backend | Accepted |
| [ADR-003](./ADR-003-authentication.md) | Authentication: phone + OTP (mobile) and email magic link (web) | Accepted |
| [ADR-004](./ADR-004-ai-processing.md) | Server-side AI processing boundary (extraction is never persistence) | Accepted |
| [ADR-005](./ADR-005-storage.md) | Private receipt storage with owner-scoped authenticated access | Accepted |
| [ADR-006](./ADR-006-web-access.md) | Web access via email linking + magic link; no independent web signup | Accepted |
| [ADR-007](./ADR-007-offline-capture.md) | Offline receipt capture + deferred sync (client-side pending queue; no schema change) | Accepted |

## How to use

- Each ADR records **context → decision → consequences**, and references the finalized requirements/decisions (FR / BR / NFR / Q-XXX) it implements.
- ADRs are the contract for the later design phases (Database, API, Implementation). If a later phase finds a reason to change an ADR, write a new ADR superseding it rather than editing silently.
- An ADR may be marked **Blocked** only if it requires a product decision that the finalized requirements do not resolve. There are none at this phase.