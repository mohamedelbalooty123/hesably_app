# ADR-004 — AI Processing

**Status:** Accepted
**Date:** 2026-08-31
**Applies to:** Mobile, Backend, AI

## Context

Receipts must be turned into structured, confidence-flagged fields that the user reviews before anything is recorded. Requirements are explicit: extraction never saves silently (NFR-DATA-001, BR-AI-001); Gemini runs through a **server-side** boundary with the key never in the client (Q-007, BR-AI-005); field confidence < 80% is flagged; missing required info or overall confidence < 50% is extraction failure (Q-008); 15-second client-visible timeout (Q-009); manual entry is always available (FR-AI-005/008); the model is Gemini 3.1 Flash-Lite (Q-007).

## Decision

Route all extraction through a **server-side AI boundary**: the `extract-receipt` Supabase Edge Function.

```text
Flutter Mobile
   ↓ capture + advisory quality check (advisory, on-device)
   ↓ image bytes + type + business context (verified JWT)
extract-receipt Edge Function   ← Gemini API key lives here only
   ↓ validates caller JWT + business ownership
   ↓ call Gemini 3.1 Flash-Lite (structured output schema)
   ↓ parse/validate → field confidences + overall confidence → classify
   ↓ structured ExtractionResult (ephemeral)
Flutter → Review & Edit (flag <80%) → user confirms → persistence
```

Key rules:

1. **Extraction is not persistence.** The boundary has no DB/Storage write capability; results exist only in the client's transient state and the transient response. Even the receipt image is not stored before confirmation — the bytes are processed in memory.
2. **The user confirmation step is mandatory and in-between** (FR-REVIEW-002, BR-CONFIRM-001).
3. **The confidence model uses only the approved thresholds** (Q-008): field < 80% → flag; overall < 50% or missing required data → extraction failure → manual entry. No second confidence algorithm is invented.
4. **Failure/timeout never dead-ends** (Q-009): manual entry is always offered.
5. **The AI boundary is the only holder of the Gemini secret** (Q-007, BR-AI-005).

## Why (rationale)

- **Data trust:** the *only* way to guarantee "AI data is never saved without confirmation" is to keep the AI path structurally incapable of writing. Persisting the image or a draft server-side would create orphans and an implicit pre-save.
- **Security/cost:** verifying the JWT and ownership inside the boundary prevents unauthenticated/cross-owner use of the paid model.
- **Stability / swapability:** isolating Gemini behind one stable HTTP contract lets the model/prompt/schema evolve (or a fallback be added post-MVP) without touching either client.
- **Latency control:** the client owns the 15-second ceiling so the user is never trapped regardless of provider behavior (Q-009).

## Consequences

- **Positive:** literal compliance with the data-trust NFR; no orphaned pre-confirmation objects; a single place to enforce AI security and observability.
- **Negative:** the image crosses the network twice in the happy path (once to the boundary for extraction, once to Storage on confirm). Accepted for MVP for cleanliness; the mobile architecture uses a single on-device image reference and client-side compression to keep it cheap (mobile §12, §17).
- **Non-functional expectations:** extraction target "a few seconds" (NFR-PERF-001); quality gate filters obviously unusable images before any AI cost (Q-020).
- **Traceability:** FR-AI-001…009, FR-REVIEW-002, FR-CAPTURE-007, BR-AI-001…005, BR-CONFIRM-001, NFR-DATA-001, NFR-PERF-001; Q-007, Q-008, Q-009.