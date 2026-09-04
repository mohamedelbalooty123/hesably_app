# Data Access Contracts — Smart Invoice Assistant

Implementation-ready contracts for every major backend operation. No traditional REST API layer — both clients integrate directly with Supabase via its client SDKs. The only server-side boundary is the AI Edge Function.

---

## 1. Access Model Overview

```text
Flutter Mobile ──→ Supabase Client SDK ──→ Supabase Auth / Postgres (RLS) / Storage
Next.js Dashboard ──→ Supabase SSR Client ──→ Supabase Auth / Postgres (RLS) / Storage
Flutter Mobile ──→ Edge Function (extract-receipt) ──→ Gemini (server-side)
```

- **No application server** for normal CRUD. Clients issue PostgREST requests through the Supabase client SDKs with the user's authenticated session.
- **RLS is the authorization layer.** Every table is RLS-scoped to `current_business_id()`. Clients never pass `business_id` manually; RLS injects it.
- **The Edge Function** is the only custom server-side code. It handles AI extraction and never persists business data.

---

## 2. Operation Registry

Every operation below follows a standard contract shape. Each entry specifies the exact access path.

---

### 2.1 Authentication

| Field | Value |
|---|---|
| **Operation** | Phone OTP Sign-up / Login |
| **Client** | Flutter Mobile |
| **Data source** | Supabase Auth (Phone + OTP via Twilio) |
| **Access path** | Direct Supabase Auth SDK |
| **Auth required** | No (unauthenticated flow) |
| **RLS** | N/A |
| **Input** | Phone number → OTP code |
| **Output** | JWT session (access_token, refresh_token) |
| **Error cases** | Wrong OTP (inline error, 60s cooldown), OTP not received (resend + support link), network failure |
| **Validation** | Supabase Auth validates OTP server-side |
| **Security** | No credentials stored client-side beyond session; session persisted securely via Supabase client |
| **Requirements** | FR-AUTH-001..007, BR-AUTH-001..004, Q-001, Q-002, Q-003 |

---

| Field | Value |
|---|---|
| **Operation** | Email Magic Link (Web Login) |
| **Client** | Next.js Dashboard |
| **Data source** | Supabase Auth (Email magic link) |
| **Access path** | Direct Supabase Auth SDK (SSR) |
| **Auth required** | No (unauthenticated flow, but email must be linked) |
| **RLS** | N/A (pre-check: email linked?) |
| **Input** | Linked email address |
| **Output** | JWT session (cookie-based via `@supabase/ssr`) |
| **Error cases** | Unlinked email (blocked with message), expired link ("Send new link"), network failure |
| **Validation** | Supabase Auth validates magic link exchange |
| **Security** | Session cookie HttpOnly, SameSite; no self-signup |
| **Requirements** | FR-WEB-AUTH-001..004, BR-WEB-001..003, Q-004, Q-016 |

---

### 2.2 Business Profile

| Field | Value |
|---|---|
| **Operation** | Create Business Profile (Onboarding) |
| **Client** | Flutter Mobile |
| **Data source** | Supabase Postgres (`businesses` table) |
| **Access path** | Direct Supabase (INSERT) |
| **Auth required** | Yes (authenticated session) |
| **RLS** | `businesses` INSERT policy: `CHECK (owner_id = auth.uid())` |
| **Input** | `name` (text, 1-100 chars), business type (from fixed enum, stored on user metadata) |
| **Output** | Created `businesses` row + auto-seeded default categories (trigger) |
| **Error cases** | Validation failure (name length), duplicate creation (unique constraint), network failure |
| **Validation** | Client validates name length; DB CHECK constraint enforces `length(trim(name)) BETWEEN 1 AND 100` |
| **Security** | RLS ensures only the authenticated user can create their own business; trigger seeds categories |
| **Requirements** | FR-ONBOARD-001..005, BR-BUS-001..003, Q-012 |

---

| Field | Value |
|---|---|
| **Operation** | Read Business Profile |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`businesses` table) |
| **Access path** | Direct Supabase (SELECT) |
| **Auth required** | Yes |
| **RLS** | `businesses` SELECT policy: `owner_id = auth.uid()` |
| **Input** | None (derived from session) |
| **Output** | `businesses` row (id, name, currency_code, web_access_enabled, web_email, created_at, updated_at) |
| **Error cases** | No business found (user hasn't completed onboarding), network failure |
| **Validation** | None (read-only) |
| **Security** | Only own business visible |
| **Requirements** | FR-ONBOARD-001, FR-WEB-DASH-001 |

---

| Field | Value |
|---|---|
| **Operation** | Update Business Profile |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`businesses` table) |
| **Access path** | Direct Supabase (UPDATE) |
| **Auth required** | Yes |
| **RLS** | `businesses` UPDATE policy: `USING (owner_id = auth.uid()), CHECK (owner_id = auth.uid())` |
| **Input** | `name` (text, 1-100 chars), business type |
| **Output** | Updated row |
| **Error cases** | Validation failure, network failure |
| **Validation** | Client validates; DB CHECK on name |
| **Security** | Cannot reassign business to another user |
| **Requirements** | FR-SETTINGS-001, FR-WEB-SETTINGS-001, BR-BUS-004 |

---

### 2.3 Categories

| Field | Value |
|---|---|
| **Operation** | List Categories |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`categories` table) |
| **Access path** | Direct Supabase (SELECT) |
| **Auth required** | Yes |
| **RLS** | `categories` SELECT policy: `business_id = current_business_id()` |
| **Input** | Optional filter: `is_hidden` |
| **Output** | Array of `{id, name, type, is_hidden, created_at, updated_at}` |
| **Error cases** | Network failure |
| **Validation** | None (read-only) |
| **Security** | Only own business categories visible |
| **Requirements** | FR-CATEGORY-001..005, BR-CATEGORY-001..008 |

---

| Field | Value |
|---|---|
| **Operation** | Create Custom Category |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`categories` table) |
| **Access path** | Direct Supabase (INSERT) |
| **Auth required** | Yes |
| **RLS** | `categories` INSERT policy: `CHECK (business_id = current_business_id() AND type = 'custom')` |
| **Input** | `name` (text, 1-100 chars) |
| **Output** | Created category row |
| **Error cases** | Duplicate name after normalization (UNIQUE on `business_id, name_key`), validation failure, network failure |
| **Validation** | Client normalizes (trim + lower + NFC); DB unique constraint on `(business_id, name_key)` |
| **Security** | Only custom types allowed; default creation blocked by RLS + guard trigger |
| **Requirements** | FR-CATEGORY-003, FR-WEB-CATEGORY-002, BR-CATEGORY-003, BR-CATEGORY-008, Q-021 |

---

| Field | Value |
|---|---|
| **Operation** | Update Category (Hide / Rename Custom) |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`categories` table) |
| **Access path** | Direct Supabase (UPDATE) |
| **Auth required** | Yes |
| **RLS** | `categories` UPDATE policy: `USING (business_id = current_business_id()), CHECK (business_id = current_business_id())` |
| **Input** | `id`, `is_hidden` (boolean), or `name` (custom only) |
| **Output** | Updated row |
| **Error cases** | Attempt to rename default category (guard trigger rejects), duplicate name, network failure |
| **Validation** | Guard trigger blocks `name`/`name_key` changes on `type='default'` categories |
| **Security** | Cannot move category to another business |
| **Requirements** | FR-CATEGORY-004/005, FR-WEB-CATEGORY-002/003, BR-CATEGORY-004/005 |

---

| Field | Value |
|---|---|
| **Operation** | Delete Custom Category |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`categories` table) |
| **Access path** | Direct Supabase (DELETE) |
| **Auth required** | Yes |
| **RLS** | `categories` DELETE policy: `USING (business_id = current_business_id() AND type = 'custom')` |
| **Input** | `id` |
| **Output** | Confirmation |
| **Error cases** | Category in use (FK RESTRICT from `transactions.category_id`), default category (blocked by RLS + no DELETE policy), network failure |
| **Validation** | DB FK RESTRICT prevents deletion of in-use categories |
| **Security** | Default categories cannot be deleted (no DELETE policy on defaults) |
| **Requirements** | FR-CATEGORY-004/005, BR-CATEGORY-004/005 |

---

### 2.4 Transactions

| Field | Value |
|---|---|
| **Operation** | Create Transaction (after confirmation) |
| **Client** | Flutter Mobile (only) |
| **Data source** | Supabase Postgres (`transactions`, `transaction_items`, `receipts`, `ai_extractions` tables) + Supabase Storage |
| **Access path** | Direct Supabase (INSERT × multiple tables) |
| **Auth required** | Yes |
| **RLS** | All INSERT policies: `CHECK (business_id = current_business_id())` |
| **Input** | `type` (income/expense), `amount` (numeric > 0), `transaction_date` (date), `party_name` (optional), `category_id`, `entry_source` (manual/ai), optional `transaction_items[]`, optional receipt image, optional `ai_extractions` row |
| **Output** | Created transaction row + receipt row + optional AI extraction row + storage object |
| **Error cases** | Validation failure (amount, type, category), category not found (FK), image upload failure, network failure; all partial writes must be cleaned up |
| **Validation** | Client validates all fields; DB CHECK constraints enforce type, amount, category FK; `transactions_ai_provenance_guard` trigger ensures `entry_source='ai'` has matching `ai_extractions` row |
| **Security** | Row-first ordering: INSERT transaction → INSERT ai_extractions → upload image → INSERT receipt; all within the confirmation commit (the `transactions_ai_provenance_guard` trigger requires an `entry_source='ai'` transaction to be accompanied by its matching `ai_extractions` row, so both inserts share the same client call/transaction — see `data-access-patterns.md` §1.4); on failure: compensate by deleting partial rows, clean orphan image best-effort |
| **Requirements** | FR-REVIEW-002, BR-CONFIRM-001, NFR-DATA-001, FR-TRANS-011, data-access-patterns §1.4/1.5 |

---

| Field | Value |
|---|---|
| **Operation** | List Transactions (with filters) |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`transactions` table, joined with `categories`) |
| **Access path** | Direct Supabase (SELECT) |
| **Auth required** | Yes |
| **RLS** | `transactions` SELECT policy: `business_id = current_business_id()` |
| **Input** | Filters: `date_range` (start, end), `category_id`, `type` (income/expense), `amount_min`, `amount_max`, `search` (party_name substring), `page`, `page_size` |
| **Output** | Array of `{id, type, amount, transaction_date, party_name, category_id, category_name, entry_source, created_at, updated_at, receipt_thumbnail_url}` + total count |
| **Error cases** | Network failure, invalid filter params |
| **Validation** | Client validates filter params; RLS scopes all results |
| **Security** | Only own business transactions visible; search uses trigram GIN index on `lower(party_name)` |
| **Requirements** | FR-TRANS-001..008, FR-WEB-TRANS-001..003, BR-TRANS-001, BR-TRANS-007, Q-022 |

---

| Field | Value |
|---|---|
| **Operation** | Read Transaction Detail |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`transactions`, `transaction_items`, `receipts`, `ai_extractions` tables) |
| **Access path** | Direct Supabase (SELECT × multiple tables) |
| **Auth required** | Yes |
| **RLS** | All SELECT policies: `business_id = current_business_id()` |
| **Input** | `transaction_id` |
| **Output** | Transaction row + items[] + receipt metadata (storage_path, mime_type) + optional ai_extractions row |
| **Error cases** | Transaction not found (RLS scoping), network failure |
| **Validation** | None (read-only) |
| **Security** | Only own business transaction visible |
| **Requirements** | FR-TRANS-009/010, FR-WEB-TRANS-004 |

---

| Field | Value |
|---|---|
| **Operation** | Update Transaction |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`transactions`, `transaction_items` tables) |
| **Access path** | Direct Supabase (UPDATE) |
| **Auth required** | Yes |
| **RLS** | `transactions` UPDATE policy: `USING (business_id = current_business_id()), CHECK (business_id = current_business_id())` |
| **Input** | `transaction_id`, updated fields (type, amount, transaction_date, party_name, category_id, items[]) |
| **Output** | Updated row |
| **Error cases** | Validation failure, category not found (FK), network failure |
| **Validation** | Client validates; DB constraints enforce |
| **Security** | Cannot move transaction to another business; `updated_at` set by trigger |
| **Requirements** | FR-TRANS-011, FR-WEB-TRANS-005, BR-TRANS-002/005, Q-006 |

---

| Field | Value |
|---|---|
| **Operation** | Delete Transaction |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`transactions` table) + Supabase Storage |
| **Access path** | Direct Supabase (DELETE) + Storage DELETE |
| **Auth required** | Yes |
| **RLS** | `transactions` DELETE policy: `USING (business_id = current_business_id())` |
| **Input** | `transaction_id` |
| **Output** | Confirmation; cascade deletes line items, receipt row, extraction row; storage object deleted by app |
| **Error cases** | Network failure; partial deletion (record deleted but image not); confirmation required before deletion |
| **Validation** | Confirmation dialog required client-side |
| **Security** | Only own business transaction deletable; cascade handles DB cleanup; app handles storage cleanup |
| **Requirements** | FR-TRANS-012/013, BR-TRANS-003/004, FR-WEB-TRANS-006 |

---

### 2.5 Reports

| Field | Value |
|---|---|
| **Operation** | Load Report Summary |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (aggregate query over `transactions`) |
| **Access path** | Direct Supabase (SELECT with aggregates) |
| **Auth required** | Yes |
| **RLS** | `transactions` SELECT policy: `business_id = current_business_id()` |
| **Input** | `period` (this_week / this_month / last_month / ytd / custom), optional `date_start`, `date_end`, optional filters (category_id, type, amount range) |
| **Output** | `{total_income: numeric, total_expense: numeric, net: numeric, transaction_count: integer}` |
| **Error cases** | Network failure, invalid period params |
| **Validation** | Client computes date range from period; DB aggregates over scoped rows |
| **Security** | Only own business data aggregated |
| **Requirements** | FR-DASH-001..004, FR-WEB-REPORT-001/002, FR-WEB-DASH-002, BR-REPORT-001..003, Q-011 |

---

| Field | Value |
|---|---|
| **Operation** | Load Category Breakdown |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (GROUP BY over `transactions` + `categories`) |
| **Access path** | Direct Supabase (SELECT with GROUP BY) |
| **Auth required** | Yes |
| **RLS** | `transactions` SELECT policy: `business_id = current_business_id()` |
| **Input** | Same period + filters as summary |
| **Output** | Array of `{category_id, category_name, total_amount, percentage}` sorted by `total_amount DESC` |
| **Error cases** | Network failure |
| **Validation** | Client sorts by spend; DB groups and sums |
| **Security** | Only own business data |
| **Requirements** | FR-DASH-002/006, FR-WEB-DASH-003, FR-WEB-REPORT-002, BR-REPORT-001 |

---

| Field | Value |
|---|---|
| **Operation** | Load Period Comparison |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (two aggregate queries: current period + previous period) |
| **Access path** | Direct Supabase (SELECT × 2) |
| **Auth required** | Yes |
| **RLS** | `transactions` SELECT policy: `business_id = current_business_id()` |
| **Input** | Current period + previous period date ranges |
| **Output** | `{current_income, current_expense, previous_income, previous_expense, income_change_pct, expense_change_pct}` |
| **Error cases** | Network failure, division by zero (previous period has zero expenses) |
| **Validation** | Client handles zero-division gracefully |
| **Security** | Only own business data |
| **Requirements** | FR-DASH-003/007, FR-WEB-DASH-005, BR-REPORT-003 |

---

### 2.6 Export

| Field | Value |
|---|---|
| **Operation** | Generate Export Data (Client-side) |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Data already fetched from Supabase (RLS-scoped transactions + reports) |
| **Access path** | Client-side (no server call) |
| **Auth required** | Yes (data was fetched under authenticated session) |
| **RLS** | Data already scoped from prior RLS-scoped queries |
| **Input** | `format` (pdf / excel / csv), `period`, active filters |
| **Output** | Generated file (PDF, Excel, CSV) |
| **Error cases** | Generation failure (client-side), empty data set |
| **Validation** | Client generates from already-validated data |
| **Security** | No additional server access; export scope matches RLS-scoped data |
| **Requirements** | FR-EXPORT-001..004, BR-EXPORT-001..003, Q-013, Q-014 |

---

### 2.7 Settings

| Field | Value |
|---|---|
| **Operation** | Enable Web Access (Link Email) |
| **Client** | Flutter Mobile |
| **Data source** | Supabase Postgres (`businesses` table) + Supabase Auth (email identity) |
| **Access path** | Direct Supabase (UPDATE businesses + Auth identity link) |
| **Auth required** | Yes |
| **RLS** | `businesses` UPDATE policy: `owner_id = auth.uid()` |
| **Input** | Email address (to link) |
| **Output** | Updated `businesses` row (`web_access_enabled=true`, `web_email=email`) |
| **Error cases** | Email already used by another business (partial unique on `web_email`), invalid email format, network failure |
| **Validation** | Client validates email format; DB partial UNIQUE on `web_email` enforces uniqueness |
| **Security** | Only the owner can enable web access for their business |
| **Requirements** | FR-SETTINGS-003, BR-WEB-002, Q-016 |

---

| Field | Value |
|---|---|
| **Operation** | Disable Web Access (Unlink Email) |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Postgres (`businesses` table) |
| **Access path** | Direct Supabase (UPDATE businesses) |
| **Auth required** | Yes |
| **RLS** | `businesses` UPDATE policy: `owner_id = auth.uid()` |
| **Input** | None (derived from session) |
| **Output** | Updated row: `web_access_enabled=false`, `web_email=NULL` |
| **Error cases** | Network failure |
| **Validation** | None |
| **Security** | Owner can unlink from either client; existing web sessions rejected on next request (Q-015) |
| **Requirements** | FR-WEB-SETTINGS-002, Q-015, BR-WEB-006 |

---

### 2.8 AI Extraction

| Field | Value |
|---|---|
| **Operation** | Extract Receipt Data |
| **Client** | Flutter Mobile (only) |
| **Data source** | Edge Function (`extract-receipt`) → Gemini 3.1 Flash-Lite |
| **Access path** | Edge Function (HTTPS, verified JWT) |
| **Auth required** | Yes (verified JWT + business ownership validation) |
| **RLS** | N/A (Edge Function performs its own ownership check) |
| **Input** | Receipt image bytes (multipart), `transaction_type` (income/expense), business context (category list) |
| **Output** | `ExtractionResult`: `{transaction_date, total_amount, party_name, line_items[], suggested_category, per_field_confidence{}, overall_confidence, extraction_status}` |
| **Error cases** | Authentication failure (401), ownership failure (403), image validation failure, Gemini timeout, extraction failure (required fields missing OR overall confidence < 50%), network failure |
| **Validation** | Server validates image (size, MIME); validates Gemini response schema; computes confidence thresholds |
| **Security** | `verify_jwt=true`; business ownership checked before Gemini call; Gemini API key server-side only; image bytes in-memory only, never persisted by AI layer |
| **Requirements** | FR-AI-001..009, BR-AI-001..005, Q-007, Q-008, Q-009, ADR-API-002 |

---

### 2.9 Account Management

| Field | Value |
|---|---|
| **Operation** | Delete Account |
| **Client** | Flutter Mobile |
| **Data source** | Admin Edge Function (service_role) |
| **Access path** | Edge Function (service_role, not client-accessible directly) |
| **Auth required** | Yes (authenticated user requests deletion; admin function executes with service_role) |
| **RLS** | Bypassed (service_role); function validates auth.uid() ownership |
| **Input** | Authenticated user's JWT |
| **Output** | Account deleted; cascade removes business + all data; storage objects cleaned |
| **Error cases** | Storage cleanup partial failure, network failure |
| **Validation** | Confirmation dialog required client-side |
| **Security** | `service_role` used only in this minimal admin function; validates auth.uid() before deletion |
| **Requirements** | FR-SETTINGS-006, ADR-DB-005 |

---

| Field | Value |
|---|---|
| **Operation** | Logout |
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Data source** | Supabase Auth |
| **Access path** | Direct Supabase Auth SDK |
| **Auth required** | Yes (active session) |
| **RLS** | N/A |
| **Input** | None |
| **Output** | Session terminated |
| **Error cases** | Network failure (client clears local session regardless) |
| **Validation** | None |
| **Security** | Session cookie cleared (web); session cleared locally (mobile) |
| **Requirements** | FR-SETTINGS-005, FR-WEB-SETTINGS-003 |

---

## 3. Cross-Cutting Concerns

### 3.1 Error Response Shape

All Supabase client errors follow a consistent pattern:

```json
{
  "message": "Error message",
  "code": "error_code",
  "details": "Additional context (non-sensitive)"
}
```

- **RLS denial** → returns empty result set or 403 (no data leak)
- **Constraint violation** → returns 400 with PG error code
- **Auth failure** → returns 401; client routes to login
- **Network failure** → client shows retryable error state

### 3.2 Pagination

- **Mobile**: cursor-based or offset pagination for transaction lists; client manages page state
- **Web**: offset-based pagination for the data table; server-side via PostgREST `Range` header

### 3.3 Real-Time

- Not in MVP scope (Q-006). Both clients use Last Write Wins.
- Extension point: Supabase Realtime subscriptions on RLS-scoped tables (Phase 2).

### 3.4 Offline

- Not in MVP scope (Q-018). Network required for all operations.
- Extension point: local-first queue in TransactionRepository (Phase 2).

---

## 4. Traceability

| Contract area | Requirement / Decision IDs |
|---|---|
| Auth (phone/OTP, magic link) | FR-AUTH-001..007, FR-WEB-AUTH-001..004, BR-AUTH-001..004, BR-WEB-001..006, Q-001..004, Q-015, Q-016 |
| Business profile CRUD | FR-ONBOARD-001..005, FR-SETTINGS-001, FR-WEB-SETTINGS-001, BR-BUS-001..004, Q-012 |
| Category CRUD | FR-CATEGORY-001..005, FR-WEB-CATEGORY-001..003, BR-CATEGORY-001..008, Q-010, Q-021 |
| Transaction CRUD | FR-TRANS-001..013, FR-WEB-TRANS-001..006, BR-TRANS-001..007, Q-005, Q-006, Q-017, Q-022 |
| Reports | FR-DASH-001..007, FR-WEB-DASH-001..006, FR-WEB-REPORT-001..003, BR-REPORT-001..004, Q-011, Q-012 |
| Export | FR-EXPORT-001..004, FR-WEB-REPORT-003, BR-EXPORT-001..003, Q-013, Q-014 |
| AI extraction | FR-AI-001..009, BR-AI-001..005, Q-007, Q-008, Q-009, ADR-API-002 |
| Settings / web access | FR-SETTINGS-001..006, FR-WEB-SETTINGS-001..003, Q-015, Q-016 |
| Security / RLS | NFR-SEC-001, NFR-SEC-002, NFR-DATA-001, BR-SEC-001/002 |
