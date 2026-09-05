# Assumptions

This document records assumptions required to understand the source documents. Each assumption is implied by the source documents but not fully specified there. Assumptions are **not** confirmed requirements and must not be treated as such. Any assumption that needs a product-owner decision is also cross-referenced in `open-questions.md` where appropriate.

---

## 1. Product Assumptions

### ASM-001 — Mobile App Is the Primary Product Experience
**Assumption:**
The mobile app is the primary product experience, and the web dashboard is a companion view for the MVP.

**Why this assumption exists:**
The source documents repeatedly describe the mobile app as the primary capture/entry tool and the dashboard as a "companion view", "mainly for reviewing data on a bigger screen, running reports, and light management." This assumption distinguishes the two platforms' roles.

**Source evidence:**
- feature-list.md — Target user ("manages the business mostly from their phone")
- user-flow-dashboard.md — Section "Assumption (please confirm before development)"

---

## 2. User Assumptions

### ASM-002 — Single Owner Per Business in MVP
**Assumption:**
In the MVP, a business is managed by a single (solo) owner; there is no multi-user access.

**Why this assumption exists:**
The product targets a "solo shop owner / small business owner with no dedicated accountant." Multi-user access is listed as a Phase 2 feature, implying the MVP is single-user.

**Source evidence:**
- feature-list.md — Target user; Phase 2 (Multi-user access per business)

### ASM-003 — Owner Is Responsible for Their Data
**Assumption:**
Each user corresponds to exactly one owned business profile whose data is exclusively theirs.

**Why this assumption exists:**
RLS "so each business owner can only ever query their own data" implies a 1:1 relationship between a user and their own data, with no multi-owner sharing in MVP.

**Source evidence:**
- feature-list.md — Non-Functional (Security)

---

## 3. MVP Assumptions

### ASM-004 — Receipt Type Selection Occurs Before/After Capture
**Assumption:**
The user picks the transaction type (sale/purchase) either before or after capture; the exact ordering is flexible.

**Why this assumption exists:**
feature-list.md says "user picks a type before/after capture", and user-flow-mobile.md shows the Type Selector preceding the Capture screen. The documents do not pin down a single mandatory order.

**Source evidence:**
- feature-list.md — Receipt Capture
- user-flow-mobile.md — Section 2, steps 2–3

### ASM-005 — Web "Add Transaction" Deferred
**Assumption:**
There is no manual "Add Transaction" capability on the web dashboard in the MVP; it is only described as optional/deferred.

**Why this assumption exists:**
The dashboard document explicitly marks "Add Transaction" as "(Optional, not required for MVP)" deferrable to Phase 2.

**Source evidence:**
- user-flow-dashboard.md — Section 3, step 6

### ASM-006 — Dashboard Serves an Accountant Audience in Time
**Assumption:**
The web Reports screen is the one most likely to be used by an accountant the business owner shares access with in the future (Phase 2 multi-user).

**Why this assumption exists:**
The document states this explicitly as context for why reports matter, though multi-user is a Phase 2 concern.

**Source evidence:**
- user-flow-dashboard.md — Section 4, step 5

---

## 4. Platform Assumptions

### ASM-007 — Same Supabase Backend, No Separate Backend
**Assumption:**
The web dashboard reads/writes the same Supabase tables as the mobile app; no separate backend is needed.

**Why this assumption exists:**
The dashboard document states "The dashboard reads/writes the same Supabase tables as the mobile app, so no separate backend is needed."

**Source evidence:**
- user-flow-dashboard.md — Section "Assumption (please confirm before development)"

### ASM-008 — Low/Mid-Spec Android Target
**Assumption:**
The primary mobile target platform is low/mid-spec Android devices.

**Why this assumption exists:**
The non-functional requirements explicitly target mid/low-spec Android devices and require a lightweight app.

**Source evidence:**
- feature-list.md — Non-Functional (Low-end device friendly)

---

## 5. Data Assumptions

### ASM-009 — Currency Is EGP-Only in MVP
**Assumption:**
All monetary values are in EGP in the MVP (the default currency), and multi-currency is not supported.

**Why this assumption exists:**
The default currency is EGP, and multi-currency support is explicitly out of scope for the MVP.

**Source evidence:**
- feature-list.md — Authentication (default currency EGP); Explicitly out of scope (Multi-currency)

---

## 6. AI Assumptions

### ASM-010 — AI May Return Partial/Empty Results
**Assumption:**
The AI extraction may return incomplete, empty, or non-receipt results, and the MVP must handle these gracefully.

**Why this assumption exists:**
The documents explicitly require graceful handling of low confidence, extraction failure, and non-receipt images.

**Source evidence:**
- feature-list.md — AI Data Extraction
- user-flow-mobile.md — Section 2, step 4; Edge Cases

### ASM-011 — AI Runs Only After Capture
**Assumption:**
AI extraction is triggered on a captured/selected image and does not run for manual entry (which bypasses AI entirely).

**Why this assumption exists:**
The manual entry path is described as bypassing AI entirely, and the AI processing state follows photo capture.

**Source evidence:**
- user-flow-mobile.md — Section 2, steps 3–4

---

## 7. Web Dashboard Assumptions

### ASM-012 — Web Access Is Opt-In from Mobile
**Assumption:**
Web access requires the owner to explicitly enable it from the mobile app, linking an email to their account.

**Why this assumption exists:**
This is stated as the proposed approach for the web login method, flagged as an open design decision pending confirmation.

**Source evidence:**
- user-flow-mobile.md — Section 5, step 2
- user-flow-dashboard.md — Section "Open design decision — Web login method"

### ASM-013 — Web Magic Link Is the Supabase Email Authentication Mechanism
**Assumption:**
The web login uses Supabase's email magic-link authentication, linking an email identity to the user's Supabase account.

**Why this assumption exists:**
The flows describe email magic-link login authenticated "via Supabase", and web access "links an email identity to their existing Supabase user." The exact linking mechanism is not fully specified.

**Source evidence:**
- user-flow-dashboard.md — Section 1; Section "Open design decision — Web login method"

---

## 8. Requirement Interpretation Notes

### ASM-014 — "Default currency (EGP)" Applies to Bookkeeping Values
**Assumption:**
The default currency EGP applies to how transactional amounts are recorded and displayed for the business.

**Why this assumption exists:**
feature-list.md lists "default currency (EGP)" as part of onboarding but does not elaborate on its usage (display, storage, formatting).

**Source evidence:**
- feature-list.md — Authentication

### ASM-015 — Language Toggle Is the Only Localization Mechanism Described
**Assumption:**
The MVP provides Arabic (default, RTL) as the primary UI language with an optional English secondary via a language toggle; no other locales are specified.

**Why this assumption exists:**
feature-list.md and user-flow-mobile.md describe an Arabic/English language toggle but do not define additional locales or full translation scope.

**Source evidence:**
- feature-list.md — Non-Functional (Primary language); Settings
- user-flow-mobile.md — Section 5, step 2

### ASM-016 — No Undo/Trash in MVP (Confirmation Only)
**Assumption:**
Deleting a record removes it permanently; the only safeguard in the MVP is the confirmation dialog (no undo/trash).

**Why this assumption exists:**
The mobile document states the confirmation dialog is the only safeguard in the MVP (no undo/trash in Phase 1).

**Source evidence:**
- user-flow-mobile.md — Edge Cases & Error States

### ASM-017 — Offline Pending Captures Are Device-Local Only
**Assumption:**
Offline pending captures are stored and managed **client-side on the device**; there is no server copy before sync, they do not survive reinstall (no server backup), and the already-deployed Supabase schema requires no change for this capability.

**Why this assumption exists:**
Offline capture + deferred sync (Q-018, flipped to MVP) is implemented as a local queue with idempotent sync (ADR-007). Because the database is already implemented, the pending-capture state is a mobile-only concept rather than a new server table/state.

**Source evidence:**
- ADR-007 — Offline Receipt Capture
- open-questions.md — Q-018 (decision revised IN MVP)
- database-review.md — pending capture is client-side; schema unchanged
