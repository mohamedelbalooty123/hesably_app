# Authentication Contracts — Smart Invoice Assistant

Contracts for identity, session management, and authentication boundaries between the two clients and Supabase Auth.

---

## 1. Authentication Model

Two independent authentication paths sharing one identity model:

```text
Mobile:  Phone + OTP  → Supabase Auth (Twilio SMS) → JWT session
Web:     Email + Magic Link  → Supabase Auth (Email) → Cookie session
```

Both paths resolve to the **same `auth.uid()`** and the same `businesses` row. The mobile app is the source of truth for account creation (BR-WEB-001).

---

## 2. Mobile Authentication

### 2.1 Phone OTP Sign-up / Login

| Field | Value |
|---|---|
| **Endpoint** | Supabase Auth SDK: `signInWithOtp(phone)` / `verifyOTP(phone, token)` |
| **Client** | Flutter Mobile |
| **Auth required** | No (this IS the auth flow) |
| **Input** | Phone number (E.164 format), then 6-digit OTP code |
| **Output** | `Session { access_token, refresh_token, user }` |
| **Session storage** | Secure persistent storage via Supabase Flutter client |
| **Behavior** | First-time phone creates a new Supabase user; returning phone logs in |
| **Cooldown** | Resend OTP after 60-second cooldown (Q-001) |
| **Error: wrong OTP** | Inline error message, allow retry |
| **Error: OTP not received** | Resend after cooldown + "Having trouble?" support link |
| **Error: network** | Retry prompt |
| **Requirements** | FR-AUTH-001..007, BR-AUTH-001..004, Q-001, Q-002 |

### 2.2 Session Persistence

| Field | Value |
|---|---|
| **Behavior** | Persistent session until explicit logout (Q-003) |
| **No inactivity timeout** | Session does not expire on inactivity |
| **Token refresh** | Handled automatically by Supabase Flutter client |
| **Splash routing** | On app launch: check session → has session? Home : Phone Entry (FR-AUTH-007) |
| **Expiry handling** | On token expiry: Supabase client refreshes; if refresh fails, routes to Phone Entry |

### 2.3 Onboarding Gate

| Field | Value |
|---|---|
| **Trigger** | First successful login |
| **Gate** | If no `businesses` row for `auth.uid()` → force Business Setup screen |
| **Input** | Business name, business type |
| **Output** | Created `businesses` row + seeded default categories → route to Home |
| **Returning users** | Skip onboarding (business row exists) |
| **Requirements** | FR-ONBOARD-001..005, BR-BUS-001..003 |

---

## 3. Web Authentication

### 3.1 Email Magic Link Login

| Field | Value |
|---|---|
| **Endpoint** | Supabase Auth SDK: `signInWithOtp(email)` (magic link mode) |
| **Client** | Next.js Dashboard |
| **Auth required** | No (this IS the auth flow) |
| **Input** | Email address (must be linked from mobile) |
| **Output** | Redirect via magic link callback → `Session { access_token, refresh_token, user }` → HttpOnly cookie |
| **Pre-check** | Email must be linked to an existing Supabase user (via `businesses.web_email`) |
| **Error: unlinked email** | "This email isn't linked to a business account. Enable web access from the mobile app first." (FR-WEB-AUTH-002, BR-WEB-001/003) |
| **Error: expired link** | "Link expired" + "Send new link" button (FR-WEB-AUTH-004) |
| **Error: used link** | Same as expired |
| **Requirements** | FR-WEB-AUTH-001..004, BR-WEB-001..004, Q-004, Q-016 |

### 3.2 Web Session Management

| Field | Value |
|---|---|
| **Cookie type** | HttpOnly, SameSite, managed by `@supabase/ssr` |
| **Refresh** | Automatic via Supabase SSR helpers on each request |
| **Persistence** | Until explicit logout (FR-WEB-AUTH-003) |
| **Middleware** | Route protection: no session → redirect to login |
| **Per-request re-check** | Dashboard server routes re-validate `web_access_enabled` on every request; if unlinked, reject and show disabled state (Q-015, BR-WEB-006) |

### 3.3 Web Access Enable / Disable

**Enable (from mobile):**

| Field | Value |
|---|---|
| **Trigger** | Settings → "Enable Web Access" → enter email → verify |
| **Mechanism** | Update `businesses` row: `web_access_enabled=true`, `web_email=lower(email)` |
| **Constraint** | `web_email` partial UNIQUE (one email per project universe) |
| **Auth identity** | Email identity linked to existing Supabase user (no second account, Q-016) |

**Disable (from mobile or web):**

| Field | Value |
|---|---|
| **Trigger** | Settings → "Unlink Web Access" |
| **Mechanism** | Update `businesses` row: `web_access_enabled=false`, `web_email=NULL` |
| **Effect** | Existing web sessions rejected on next authenticated request (Q-015) |
| **No real-time disconnect** | MVP uses per-request check, not session revocation |

---

## 4. Logout

| Field | Value |
|---|---|
| **Mobile** | `supabase.auth.signOut()` → clear local session → route to Phone Entry |
| **Web** | `supabase.auth.signOut()` → clear session cookie → redirect to login page |
| **Behavior** | Session terminated; no data cached client-side in MVP |

---

## 5. Delete Account

| Field | Value |
|---|---|
| **Client** | Flutter Mobile (request) |
| **Backend** | Admin Edge Function (service_role) |
| **Mechanism** | Confirmation dialog → Edge Function deletes storage objects → deletes `auth.users` row → cascade deletes business + all data |
| **Session** | Client clears local session after successful deletion |
| **Security** | `service_role` bypasses RLS but validates `auth.uid()` ownership; function is minimal and scoped |
| **Requirements** | FR-SETTINGS-006, ADR-DB-005 |

---

## 6. Security Boundaries

| Boundary | Enforcement |
|---|---|
| Identity issuance | Supabase Auth only; no client-side JWT minting |
| Session validity | JWT verified by Supabase on every request; RLS uses `auth.uid()` |
| Web access gate | `businesses.web_access_enabled` checked server-side per request (not RLS) |
| Cross-identity isolation | One user = one business; web email maps to same `auth.uid()` (Q-016) |
| Token exposure | Never logged; never embedded in URLs; secure storage on mobile |
| Service role | Never used client-side; only in admin Edge Functions |

---

## 7. Error States

| Scenario | Mobile | Web |
|---|---|---|
| Wrong OTP | Inline error, 60s cooldown resend | N/A |
| OTP not received | Resend after 60s + support link | N/A |
| Unlinked email | N/A | Blocked with explanatory message |
| Expired magic link | N/A | "Link expired" + "Send new link" |
| Session expired | Route to Phone Entry | Redirect to login |
| Web access unlinked | No effect on mobile | Next request rejected → disabled state |
| Network failure | Retry prompt | Retry prompt |

---

## 8. Traceability

| Auth element | Requirement / Decision IDs |
|---|---|
| Phone + OTP, 60s cooldown, Twilio | FR-AUTH-001..005, BR-AUTH-001..003, Q-001, Q-002 |
| Session persistence, splash routing | FR-AUTH-006/007, BR-AUTH-004, Q-003 |
| Onboarding gate | FR-ONBOARD-001..005, BR-BUS-001..003 |
| Magic link, no self-signup | FR-WEB-AUTH-001..004, BR-WEB-001..004, Q-004, Q-016 |
| Web access enable/disable | FR-SETTINGS-003, FR-WEB-SETTINGS-002, Q-015, Q-016 |
| Delete account | FR-SETTINGS-006, ADR-DB-005 |
| Logout | FR-SETTINGS-005, FR-WEB-SETTINGS-003 |
