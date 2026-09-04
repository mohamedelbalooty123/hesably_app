# ADR-API-002: Edge Function AI Boundary

**Status:** Accepted  
**Date:** 2026-09-03  
**Deciders:** Engineering  
**Supersedes:** None  
**Related:** `docs/architecture/ai-architecture.md`, `docs/api/ai-edge-function-contract.md`

---

## Context

The application uses Gemini 3.1 Flash-Lite to extract structured data from receipt images. The Gemini API key is a secret that must never be exposed to client code. The team needs to decide where the AI call happens and how the result is handled.

### Options Considered

| Option | Description |
|--------|-------------|
| A. Edge Function as AI boundary | Single Supabase Edge Function mediates all Gemini calls; returns result to client; never persists data |
| B. Edge Function with persistence | Edge Function calls Gemini AND writes extraction results to the database |
| C. Client-side with obfuscation | Flutter/Next.js call Gemini directly; API key obfuscated or proxied through a lightweight proxy |
| D. Dedicated AI microservice | Separate service (Cloud Run, Lambda, etc.) handles AI extraction |
| E. Supabase Database Function | PL/pgSQL function calls Gemini via HTTP extension |

---

## Decision

**We chose Option A: Edge Function as AI boundary.**

A single Supabase Edge Function (`extract-receipt`) mediates all access to Gemini. The function:
- Receives receipt image bytes + transaction type + category list
- Calls Gemini with the image and a structured output schema
- Returns an `ExtractionResult` to the client
- **Never writes to the database or Storage**

The client holds the extraction result in memory, presents it on a Review & Edit screen, and only persists data after user confirmation.

---

## Rationale

### Why Edge Function (Not Client-Side)

1. **API key isolation.** The Gemini API key is stored in the Edge Function's environment variables. It never appears in Flutter/Next.js code, bundles, or network requests from clients. This is a hard security requirement (BR-AI-005, Q-007).

2. **Server-side processing.** Image preprocessing, quality checks, and structured output parsing happen on the server. This keeps client code lean and ensures consistent extraction quality.

3. **Cost control.** The Edge Function validates business ownership before making AI calls. This prevents unauthorized or abusive requests that would incur Gemini costs.

4. **Model versioning.** The model is pinned in the function config (`gemini-3.1-flash-lite`). Upgrades happen via function redeployment, not client releases.

### Why Not Edge Function with Persistence (Option B)

- **Separation of concerns.** The AI layer should not own business data persistence. If the extraction logic changes, it shouldn't affect the data model.
- **User confirmation boundary.** AI extraction is ephemeral. The user reviews and confirms before anything is saved. If the Edge Function persisted data, it would bypass the confirmation step.
- **Retry flexibility.** If the client-side confirmation step fails (network, crash), the user can retry without worrying about partial writes in the database.
- **Provenance, not ownership.** The `ai_extractions` row stores the raw extraction snapshot for provenance, but it's inserted by the client after confirmation — not by the AI layer.

### Why Not Dedicated Microservice (Option D)

- **Overkill for MVP.** A single Edge Function is sufficient for the extraction use case.
- **Supabase-native.** Edge Functions run in the same ecosystem as Auth, Postgres, and Storage. No separate infrastructure to manage.
- **Cost.** Edge Functions are billed per invocation; a dedicated service would have a fixed monthly cost.
- **Simplicity.** One fewer service to deploy, monitor, and scale.

### Why Not Database Function (Option E)

- **Deno runtime is better suited.** Edge Functions run Deno, which has native fetch, JSON parsing, and TypeScript support. PL/pgSQL is not designed for HTTP calls to external APIs.
- **Error handling.** Edge Functions can catch and structure errors cleanly. Database functions have limited error handling for external HTTP calls.
- **Maintainability.** TypeScript is easier to maintain and debug than PL/pgSQL for this use case.

---

## Consequences

### Positive

- **Clean security boundary.** Gemini key is server-side only. Clients never see it.
- **Ephemeral extraction.** AI results are returned to the client but never persisted by the AI layer. User confirmation is the only path to persistence.
- **Simple deployment.** One Edge Function to deploy and monitor. Function redeployment handles model upgrades.
- **Consistent extraction.** Server-side processing ensures all clients get the same extraction quality and output format.
- **Cost control.** Business ownership check happens before AI calls, preventing abuse.

### Negative

- **Single point of failure.** If the Edge Function is down, AI extraction is unavailable. Mitigation: client falls back to manual entry (no dead ends).
- **No real-time streaming.** Edge Functions don't support streaming responses. The client waits for the full extraction result. Mitigation: Gemini Flash-Lite is fast; 15-second client timeout covers worst cases.
- **Cold start latency.** Edge Functions may have cold start delays. Mitigation: Supabase keeps functions warm for active projects; 15-second client timeout covers this.
- **Limited compute.** Edge Functions have execution time limits (typically 60 seconds). Mitigation: Gemini extraction should complete in <10 seconds; 15-second client timeout covers this.

### Risks

| Risk | Mitigation |
|------|-----------|
| Edge Function downtime | Client falls back to manual entry; no dead ends |
| Gemini API changes | Prompt/schema versioned with function deploys; no client change required |
| Cost spike from abuse | Business ownership check before AI calls; rate limiting if needed |
| Cold start delays | Supabase warm execution; 15-second client timeout |

---

## Follow-Up Items

1. **Monitoring.** Set up Edge Function metrics: request count, outcome distribution, latency, error rate.
2. **Prompt versioning.** Establish a process for prompt/schema changes that includes testing against sample receipts.
3. **Fallback testing.** Test the manual entry fallback path to ensure no dead ends in the extraction lifecycle.
4. **Cost monitoring.** Track Gemini API costs per business to detect anomalies.

---

## References

- AI Edge Function Contract: `docs/api/ai-edge-function-contract.md`
- AI Architecture: `docs/architecture/ai-architecture.md`
- Confidence Model: `docs/requirements/acceptance-criteria.md` (FR-AI-001..009)
- Model Selection: `docs/requirements/open-questions.md` (Q-007, Q-008, Q-009)
