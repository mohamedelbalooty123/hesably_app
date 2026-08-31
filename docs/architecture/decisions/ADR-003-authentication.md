# ADR-003 — Authentication

**Status:** Accepted
**Date:** 2026-08-31
**Applies to:** Mobile, Dashboard, Supabase Auth

## Context

The product is mobile-first for non-tech-savvy Egyptian shop owners. Requirements fix: phone + OTP with no email/password in the MVP (FR-AUTH-002, BR-AUTH-001), session persistence (FR-AUTH-006), and a web dashboard that must not allow independent self-signup (BR-WEB-001). The finalized decisions fix SMS via Twilio (Q-002), a 60-second resend cooldown (Q-001), persistent mobile sessions until logout (Q-003), magic-link web login (Q-004), and email-identity linking to the existing user (Q-016).

## Decision

**Mobile:**

```text
Phone number
   ↓
6-digit OTP (Supabase Phone Auth + Twilio SMS)
   ↓
Supabase Auth session (persistent until explicit logout)
   ↓
App access (splash routes by session: FR-AUTH-007)
```

- No email/password option in the app at all (FR-AUTH-002, BR-MVP-002).
- Resend gated by a 60-second cooldown with visible countdown; wrong code → inline error (FR-AUTH-004/005, BR-AUTH-003, Q-001).
- Session persists between app opens; no inactivity timeout (FR-AUTH-006, Q-003); logout is explicit (FR-SETTINGS-005).

**Web:**

```text
Enable Web Access (mobile Settings)
   ↓
Email verification / linking onto the existing Supabase user
   ↓
Email magic link (Supabase)
   ↓
Dashboard (same user → same business → same RLS)
```

- No independent web registration (BR-WEB-001, Q-004). An unlinked email is blocked with explanatory messaging (FR-WEB-AUTH-002).
- Magic-link expiry is handled ("Link expired" + "Send new link") (FR-WEB-AUTH-004).
- Web session persists until logout; unlink invalidates access on the next request (FR-WEB-AUTH-003, Q-015).

## Why (rationale)

- **Phone + OTP** minimizes login friction for the target user and matches the product's mobile-first, phone-owned identity (FR-AUTH-001, target-user profile).
- **One identity model** — the linked email maps onto the **same** Supabase user as the phone (Q-016) — preserves a single account/business ownership chain and RLS isolation; there is never a second, disconnected account with its own dataset.
- **Persistent sessions** (Q-003) reflect the "stays logged in" requirement and suit frequent daily use.
- **Magic link** (Q-004) is the low-friction, standard web alternative to phone OTP while keeping account creation mobile-side.

## Consequences

- **Positive:** consistent ownership/RLS across platforms; minimal friction; no password storage problem; web access is opt-in from the device that owns the account.
- **Negative:** web access disappears if the phone is lost (user must re-enable from mobile after account recovery); SMS delivery cost/reliability in Egypt is a live risk with a defined support/resend path (Q-001, Q-002). Magic links and OTP both rely on Supabase's delivery mechanisms.
- **Implementation notes for later phases:** onboarding gate after first login (business profile required, FR-ONBOARD-001); splash session routing (FR-AUTH-007); the web-access re-check on each request (Q-015) is a data-access authorization gate, not a JWT-revocation mechanism.
- **Traceability:** FR-AUTH-001…007, FR-SETTINGS-003/005, FR-WEB-AUTH-001…004, BR-AUTH-001…004, BR-WEB-001…006, BR-MVP-002; Q-001…Q-004, Q-015, Q-016.