# Web Access Contract — Smart Invoice Assistant

Contracts for the web dashboard's access model: how the mobile app enables web access, how the dashboard authenticates, and how access is revoked.

---

## 1. Web Access Model

```text
Mobile: "Enable Web Access" → link email to existing user → Supabase Auth identity
Web: Email → Magic Link → Same auth.uid() → Same business → Same RLS
```

- Web access is **optional** — not required to use the mobile app (FR-SETTINGS-003).
- The linked email maps to the **same Supabase user** created on mobile (Q-016).
- No independent web account; no self-signup (BR-WEB-001).

### 1.1 Normalized state model

The web-access lifecycle is exactly **four canonical states**. UI and both clients use these names for state, CTA labels, and messaging:

| State | Meaning | Seen when | Canonical action | Next state |
|---|---|---|---|---|
| `WEB_ACCESS_DISABLED` | No email linked; mobile-only | Settings shows "Enable Web Access" | Mobile: Enable Web Access (email link) | `WEB_EMAIL_PENDING` (or back to `WEB_ACCESS_DISABLED` on failure) |
| `WEB_EMAIL_PENDING` | Email link requested but not yet first-used | After enabling, before first successful dashboard login | Dashboard: send/use magic link (FR-WEB-AUTH-004 expired-link recoverable) | `WEB_ACCESS_ENABLED` |
| `WEB_ACCESS_ENABLED` | Email linked + web sessions working | Dashboard home / authenticated routes | Use dashboard; or Unlink (`UNLINK_CONFIRMATION`) | `UNLINK_CONFIRMATION` |
| `UNLINK_CONFIRMATION` | Unlink confirm dialog/step; `web_email` cleared → back to disabled | Settings → "Unlink Web Access" | Confirm unlink (mobile) / next web request rejected → redirect to disabled state (Q-015) | `WEB_ACCESS_DISABLED` |

- **Error path** (all states): network failure → retryable error state, state unchanged.
- **No new feature** — this normalizes the states the flow already produces (enable → pending → enabled → unlink), giving both clients one shared vocabulary.

---

## 2. Enable Web Access (from Mobile)

| Field | Value |
|---|---|
| **Client** | Flutter Mobile |
| **Trigger** | Settings → "Enable Web Access" |
| **Input** | Email address |
| **Steps** | 1. Validate email format. 2. Link email identity to existing Supabase user (Auth). 3. Update `businesses`: `web_access_enabled=true`, `web_email=lower(email)`. |
| **Output** | Updated `businesses` row |
| **Constraint** | `web_email` partial UNIQUE — one email per project universe |
| **Error: email taken** | Email already linked to another business → show error |
| **Error: network** | Retry prompt |
| **Auth** | Authenticated session; RLS-scoped UPDATE |
| **Requirements** | FR-SETTINGS-003, BR-WEB-002, Q-016 |

---

## 3. Web Login (Magic Link)

| Field | Value |
|---|---|
| **Client** | Next.js Dashboard |
| **Trigger** | Login page → enter email → "Send Magic Link" |
| **Input** | Email address |
| **Steps** | 1. Call `signInWithOtp(email)`. 2. Supabase sends magic link. 3. User clicks link. 4. Callback route exchanges code for session. 5. Session cookie set. 6. Redirect to Dashboard Home. |
| **Pre-check** | Email must be linked to an existing Supabase user (checked via `businesses.web_email`) |
| **Output** | Authenticated session (cookie-based) |
| **Error: unlinked email** | "This email isn't linked to a business account. Enable web access from the mobile app first." (FR-WEB-AUTH-002, BR-WEB-001/003) |
| **Error: expired link** | "Link expired" + "Send new link" button (FR-WEB-AUTH-004) |
| **Requirements** | FR-WEB-AUTH-001..004, BR-WEB-001..004, Q-004, Q-016 |

---

## 4. Web Session Management

| Field | Value |
|---|---|
| **Cookie** | HttpOnly, SameSite, managed by `@supabase/ssr` |
| **Refresh** | Automatic via Supabase SSR helpers on each request |
| **Persistence** | Until explicit logout (FR-WEB-AUTH-003) |
| **Middleware** | Route protection: no session → redirect to login |
| **Identity** | Same `auth.uid()` as mobile; same business, same RLS |

---

## 5. Per-Request Web Access Re-Check

| Field | Value |
|---|---|
| **Mechanism** | Dashboard server routes re-validate `businesses.web_access_enabled` on every request |
| **Trigger** | Even with a valid session cookie, each request checks if web access is still enabled |
| **If disabled** | Next request rejected → user returned to access-disabled state |
| **Message** | "Web access has been disabled. Re-enable from the mobile app." |
| **No real-time disconnect** | MVP uses per-request check, not session revocation (Q-015) |
| **Requirements** | Q-015, BR-WEB-006 |

---

## 6. Disable Web Access (Unlink)

| Field | Value |
|---|---|
| **Client** | Flutter Mobile or Next.js Dashboard |
| **Trigger** | Settings → "Unlink Web Access" / "Disable Web Access" |
| **Steps** | 1. Update `businesses`: `web_access_enabled=false`, `web_email=NULL`. 2. (Mobile) confirm. 3. (Web) session invalidated on next request. |
| **Output** | Updated `businesses` row |
| **Effect** | Existing web sessions rejected on next authenticated request (Q-015) |
| **Email release** | `web_email=NULL` releases the partial UNIQUE reservation (MEDIUM-02) |
| **Mobile unaffected** | Unlinking does not affect the mobile session |
| **Requirements** | FR-WEB-SETTINGS-002, Q-015, BR-WEB-006 |

---

## 7. Web Dashboard Capabilities

| Operation | Mobile | Web | Notes |
|---|---|---|---|
| Read transactions | ✅ | ✅ | Same RLS-scoped data |
| Create transactions | ✅ | ❌ | Mobile-only in MVP (Q-005, Q-017) |
| Edit transactions | ✅ | ✅ | Same Supabase record (BR-TRANS-005) |
| Delete transactions | ✅ | ✅ | Same RLS + confirmation |
| Receipt capture + AI | ✅ | ❌ | Mobile-only (BR-WEB-005) |
| View receipt images | ✅ | ✅ | Authenticated Storage reads |
| Reports | ✅ | ✅ | Same data model, same periods |
| Export | ✅ | ✅ | Client-side generation |
| Categories | ✅ | ✅ | Shared table (Q-021) |
| Settings | ✅ | ✅ | Shared business profile |
| Enable/disable web access | ✅ | ✅ (disable only) | Mobile is source of truth |

---

## 8. Web-Only Features

| Feature | Behavior |
|---|---|
| Sortable/paginated data table | Web uses PostgREST Range header for pagination |
| Category usage count | Web shows count of transactions per category |
| URL-based filter state | Filters/period stored in URL search params |
| Direct download (no share sheet) | Export downloads directly to browser |

---

## 9. Error States

| Scenario | Behavior |
|---|---|
| No session | Redirect to login page |
| Unlinked email at login | Blocked with explanatory message |
| Expired magic link | "Link expired" + "Send new link" |
| Access disabled mid-session | Next request rejected → access-disabled state |
| RLS denial | Generic error message + retry |
| Network failure | Error state + retry |

---

## 10. Security

| Control | Implementation |
|---|---|
| No self-signup | Unlinked email blocked at login |
| Same identity model | Web user = mobile user (same `auth.uid()`) |
| Per-request access check | `web_access_enabled` verified server-side |
| RLS enforcement | Same policies as mobile; no elevated access |
| No service role | Dashboard never uses `service_role` |
| Private storage | Receipt images authenticated-only |
| No secrets in browser | No Gemini key, no Twilio key, no service role |

---

## 11. Traceability

| Web Access element | Requirement / Decision IDs |
|---|---|
| Enable from mobile, email linking | FR-SETTINGS-003, BR-WEB-002, Q-016 |
| Magic link login, no self-signup | FR-WEB-AUTH-001..004, BR-WEB-001..003, Q-004 |
| Session persistence | FR-WEB-AUTH-003, BR-WEB-004 |
| Per-request access re-check | Q-015, BR-WEB-006 |
| Unlink / disable | FR-WEB-SETTINGS-002, Q-015, BR-WEB-006 |
| No web create | Q-005, Q-017, BR-WEB-005 |
| Shared data model | BR-WEB-002/003/006, Q-017 |
| Dashboard features | FR-WEB-DASH-001..006, FR-WEB-TRANS-001..006, FR-WEB-REPORT-001..003, FR-WEB-CATEGORY-001..003, FR-WEB-SETTINGS-001..003 |
