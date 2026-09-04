# Transaction Contracts — Smart Invoice Assistant

Contracts for the full transaction lifecycle: creation (manual and AI-assisted), reading, filtering, searching, editing, and deletion. Distinguishes the confirmation boundary for AI-assisted transactions.

---

## 1. Transaction Types

| Type value | Label (Arabic) | Label (English) |
|---|---|---|
| `income` | مبيعات / إيرادات | Sale / Income |
| `expense` | مشتريات / مصروفات | Purchase / Expense |

Defined by `CHECK (type IN ('income','expense'))` on `transactions.type`.

---

## 2. Create Transaction — Manual Entry

| Field | Value |
|---|---|
| **Client** | Flutter Mobile (only — no web create in MVP, Q-005/Q-017) |
| **Path** | Direct Supabase → INSERT `transactions` + optional `transaction_items` |
| **Entry source** | `entry_source = 'manual'` |
| **Auth** | Authenticated session; RLS-scoped |
| **Input** | `type`, `amount` (> 0, numeric(14,2)), `transaction_date` (date), `party_name` (optional, 1-255 chars), `category_id`, optional `transaction_items[]` |
| **Output** | Created transaction row (id, all fields, timestamps) |
| **Image** | None (manual entry has no receipt) |
| **Validation** | Client validates required fields, amount > 0, category exists; DB CHECK constraints enforce |
| **RLS** | INSERT: `CHECK (business_id = current_business_id())` |
| **Error cases** | Category not found (FK RESTRICT), invalid amount, network failure |
| **Requirements** | FR-CAPTURE-007, BR-REC-002, BR-CONFIRM-001 |

---

## 3. Create Transaction — AI-Assisted (Confirmation Boundary)

This is the critical path. The AI extraction result is **never** persisted without user confirmation.

### 3.1 Pre-Confirmation Flow

```text
1. Capture image → held in app temp area (NOT uploaded)
2. POST /functions/extract-receipt (multipart image bytes, verified JWT)
3. Edge Function → Gemini → ExtractionResult (ephemeral, nothing persisted)
4. Review & Edit screen: pre-filled form, <80% fields flagged
5. User edits fields as needed
6. User confirms Save ← THIS IS THE CONFIRMATION BOUNDARY
```

### 3.2 Post-Confirmation Persistence (Row-First)

| Step | Operation | Table | Notes |
|---|---|---|---|
| 1 | INSERT transaction | `transactions` | `entry_source='ai'`; RLS-scoped |
| 2 | INSERT ai_extractions | `ai_extractions` | Provenance snapshot; required for `entry_source='ai'` (guard trigger) |
| 3 | Upload image | Storage | Path: `{business_id}/{transaction_id}/receipt.ext` |
| 4 | INSERT receipt | `receipts` | Links storage_path to transaction; 1:1 |

**Failure handling:**
- If step 3 or 4 fails: delete the partial transaction + extraction rows (compensate)
- Orphan image (step 3 succeeded, step 4 failed): cleaned up best-effort by app
- Client surfaces error to user; no partial success presented as saved

### 3.3 AI Extraction Contract

See `ai-edge-function-contract.md` for the full Edge Function contract. Key boundaries:

- Edge Function returns `ExtractionResult` — ephemeral, never persisted by AI layer
- Client holds result in memory; shows on Review & Edit screen
- User may edit any field; user's values are persisted, not raw AI values
- `ai_extractions` row stores the raw extraction snapshot for provenance only

---

## 4. Read Transaction List

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT on `transactions` JOIN `categories` |
| **Auth** | Authenticated session; RLS-scoped |
| **Ordering** | `transaction_date DESC, created_at DESC` (most recent first, grouped by date) |
| **Default view** | All transactions for the business, current month |
| **Output shape** | `{id, type, amount, transaction_date, party_name, category_id, category_name, entry_source, created_at, updated_at, receipt_thumbnail_url}` |
| **RLS** | SELECT: `business_id = current_business_id()` |
| **Index** | `idx_transactions_business_date` (I1) covers default list |
| **Pagination** | Mobile: client-managed; Web: PostgREST Range header |
| **Requirements** | FR-TRANS-001..003, FR-WEB-TRANS-001 |

---

## 5. Filter Transactions

| Filter | Field | DB column | Index |
|---|---|---|---|
| Date range | `date_start`, `date_end` | `transaction_date` | I1 (business_id, transaction_date) |
| Category | `category_id` | `category_id` | I3 (business_id, category_id, transaction_date) |
| Type | `type` | `type` | I2 (business_id, type, transaction_date) |
| Amount range | `amount_min`, `amount_max` | `amount` | I4 (business_id, amount) |

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT with WHERE clauses |
| **Combination** | Filters compose with AND; all filters are optional |
| **RLS** | All queries scoped by `current_business_id()` |
| **Requirements** | FR-TRANS-004..007, FR-WEB-TRANS-002 |

---

## 6. Search Transactions

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT with trigram search |
| **Search scope** | `party_name` only (Q-022) — vendor/customer name |
| **Query** | `lower(party_name) ILIKE '%' \|\| lower(query) \|\| '%'` |
| **Index** | `idx_transactions_party_name_trgm` (I6) — GIN trigram on `lower(party_name)` |
| **RLS** | SELECT: `business_id = current_business_id()` |
| **Debounce** | Client-side debouncing recommended for keystroke search |
| **Output** | Same shape as list, filtered by search match |
| **Requirements** | FR-TRANS-008, FR-WEB-TRANS-003, BR-TRANS-007, Q-022 |

---

## 7. Read Transaction Detail

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT on `transactions` + `transaction_items` + `receipts` + `ai_extractions` |
| **Auth** | Authenticated session; RLS-scoped |
| **Input** | `transaction_id` |
| **Output** | Full transaction + line items + receipt metadata (storage_path, mime_type, size_bytes, original_filename) + optional AI extraction snapshot |
| **Image access** | `storage_path` → authenticated download from private Storage bucket |
| **RLS** | All SELECT policies: `business_id = current_business_id()` |
| **Requirements** | FR-TRANS-009/010, FR-WEB-TRANS-004 |

---

## 8. Update Transaction

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → UPDATE `transactions` + optional batch DELETE/INSERT `transaction_items` |
| **Auth** | Authenticated session; RLS-scoped |
| **Input** | `transaction_id`, any subset of: `type`, `amount`, `transaction_date`, `party_name`, `category_id`, `items[]` |
| **Output** | Updated row (`updated_at` set by trigger) |
| **Concurrency** | Last Write Wins (Q-006) — no optimistic locking in MVP |
| **RLS** | UPDATE: `USING (business_id = current_business_id()), CHECK (business_id = current_business_id())` |
| **Validation** | Client validates; DB CHECK constraints + FK enforced |
| **Error cases** | Category not found, invalid amount, network failure |
| **Requirements** | FR-TRANS-011, FR-WEB-TRANS-005, BR-TRANS-002/005, Q-006, Q-017 |

---

## 9. Delete Transaction

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → DELETE `transactions` + app-level Storage DELETE |
| **Auth** | Authenticated session; RLS-scoped |
| **Input** | `transaction_id` |
| **Pre-condition** | Confirmation dialog required (BR-TRANS-003/004) |
| **Cascade** | DB: `transaction_items` (CASCADE), `receipts` (CASCADE), `ai_extractions` (CASCADE) |
| **Storage cleanup** | App deletes storage object via Storage DELETE policy (before or after DB delete) |
| **RLS** | DELETE: `USING (business_id = current_business_id())` |
| **Error cases** | Network failure (record retained); partial failure (record deleted but image not — best-effort cleanup) |
| **No undo** | Confirmation dialog is the only safeguard in MVP (BR-TRANS-004) |
| **Requirements** | FR-TRANS-012/013, BR-TRANS-003/004, FR-WEB-TRANS-006 |

---

## 10. Transaction Data Shape

### Transaction Row

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `business_id` | uuid | FK → businesses; RLS scope |
| `category_id` | uuid | FK → categories (same business) |
| `type` | text | 'income' or 'expense' |
| `amount` | numeric(14,2) | > 0 |
| `transaction_date` | date | Business date (no timezone) |
| `party_name` | text | Nullable; vendor/customer name |
| `entry_source` | text | 'manual' or 'ai' |
| `created_at` | timestamptz | Auto-set |
| `updated_at` | timestamptz | Trigger-set on update |

### Transaction Item Row

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `transaction_id` | uuid | FK → transactions (same business) |
| `business_id` | uuid | FK → businesses; denormalized for RLS |
| `description` | text | 1-255 chars |
| `amount` | numeric(14,2) | Nullable; > 0 if present |
| `created_at` | timestamptz | Auto-set |
| `updated_at` | timestamptz | Trigger-set |

### Receipt Row

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `transaction_id` | uuid | UNIQUE; FK → transactions (same business) |
| `business_id` | uuid | FK → businesses; denormalized for RLS |
| `storage_path` | text | UNIQUE; path `{business_id}/{transaction_id}/receipt.ext` |
| `original_filename` | text | Display name |
| `mime_type` | text | `CHECK (mime_type LIKE 'image/%')` |
| `size_bytes` | bigint | `CHECK (size_bytes > 0 AND size_bytes <= 20971520)` |
| `created_at` | timestamptz | Auto-set |

### AI Extraction Row

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `transaction_id` | uuid | UNIQUE; FK → transactions (same business) |
| `business_id` | uuid | FK → businesses; denormalized for RLS |
| `model` | text | e.g., `gemini-3.1-flash-lite` (provenance label) |
| `overall_confidence` | numeric(3,2) | `CHECK (overall_confidence BETWEEN 0 AND 1)` |
| `extracted_fields` | jsonb | Immutable snapshot of AI-returned fields |
| `field_confidences` | jsonb | Nullable; per-field confidence snapshot |
| `created_at` | timestamptz | Auto-set |

---

## 11. Traceability

| Transaction element | Requirement / Decision IDs |
|---|---|
| Create (manual) | FR-CAPTURE-007, BR-REC-002, BR-CONFIRM-001 |
| Create (AI-assisted, confirmation boundary) | FR-REVIEW-001..007, FR-AI-001..009, BR-CONFIRM-001, BR-AI-001, NFR-DATA-001 |
| List / filter / search | FR-TRANS-001..008, FR-WEB-TRANS-001..003, BR-TRANS-001/007, Q-022 |
| Detail view | FR-TRANS-009/010, FR-WEB-TRANS-004 |
| Update | FR-TRANS-011, FR-WEB-TRANS-005, BR-TRANS-002/005, Q-006, Q-017 |
| Delete | FR-TRANS-012/013, BR-TRANS-003/004, FR-WEB-TRANS-006 |
| Web create disabled | Q-005, Q-017, BR-WEB-005 |
