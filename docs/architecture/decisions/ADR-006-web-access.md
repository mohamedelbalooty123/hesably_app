# ADR-006 — Web Access

**Status:** Accepted
**Date:** 2026-08-31
**Applies to:** Mobile, Dashboard, Supabase Auth

## Context

The web dashboard must be a companion view with no independent signup (BR-WEB-001, FR-WEB-AUTH-002) while still letting the owner access it from a browser. The final decisions fix the approved model (Q-004, Q-015, Q-016):

- Log in via **email magic link**; the email is **linked to the existing Supabase user** created on mobile (no second account) (Q-016).
- Web access is enabled from the mobile app (Settings → "Enable Web Access") (FR-SETTINGS-003).
- Web **cannot create** transactions in MVP; it can read/edit/delete (Q-005, Q-017).
- Unlinking invalidates web access on the **next request**; the user returns to the login/access-disabled state (Q-015, BR-WEB-006).

## Decision

```text
Mobile App (authenticated, phone + OTP)
   ↓ Settings → Enable Web Access
   ↓ Enter + verify email
   ↓ Email identity attached to the existing Supabase user (auth.user)
Web Login
   ↓ Enter email → magic link
   ↓ Link → session → Dashboard
   ↓ Same auth.uid() → same business → same RLS
```

Rules:

1. **Enablement is opt-in and mobile-driven.** Web access exists only after the owner links an email from the app (FR-SETTINGS-003, Q-016).
2. **No independent web registration.** The mobile app remains the source of account creation (BR-WEB-001). An unlinked email is blocked with explanatory copy (FR-WEB-AUTH-002).
3. **One user, one business, one dataset.** The linked email resolves to the same `auth.uid()` as the phone identity, so RLS and ownership are identical on both platforms — there is exactly one dataset and one set of ownership relationships (Q-016).
4. **Unlink behavior.** Unlinking (from mobile or web) revokes web access: the **next authenticated request** is rejected, the user is returned to the login/disabled state, and is told to re-enable from the mobile app. No real-time disconnect mechanism is required (Q-015, BR-WEB-006).
5. **Capability split enforced.** Web is read/edit/delete only; transaction creation is not offered in the UI and is not part of the web data path in MVP (Q-005, Q-017).
6. **Session persists until logout** (FR-WEB-AUTH-003); magic-link expiry is handled with "Send new link" (FR-WEB-AUTH-004).

## Why (rationale)

- **Ownership integrity:** linking the email onto the existing user (rather than creating a separate email account) preserves the single account/business model and RLS isolation (Q-016) — this is what makes web and mobile literally the same tenant.
- **Friction and opt-in:** magic links are low-friction; keeping enablement mobile-side means only someone holding the authenticated phone account can grant web access.
- **Minimal revocation machinery:** re-checking access on the next request (Q-015) avoids building real-time revocation while still honoring "access becomes invalid" — acceptable for MVP.
- **Clear platform role:** web's management/reconciliation role (no create) keeps the mobile capture path authoritative and simple (Q-005, Q-017).

## Consequences

- **Positive:** one identity/ownership model; RLS protects both platforms uniformly; no password/registration handling on web; unlink semantics are simple and testable.
- **Negative:** web access depends on a previously linked email — first-time web users must complete the mobile enablement step; if an email is unlinked mid-session, the next request is rejected (by design). These are surfaced with clear UX (Q-015, Q-019).
- **Implementation notes:** the email-linking mechanics use Supabase identity linking (single user, multiple identities); the per-request web-access re-check is an authorization gate in the data-access path (`backend-architecture.md` §5/§12), not JWT revocation.
- **Traceability:** FR-SETTINGS-003, FR-WEB-AUTH-001…004, FR-WEB-SETTINGS-002, BR-WEB-001…006, BR-MVP-002; Q-004, Q-005, Q-015, Q-016, Q-017.