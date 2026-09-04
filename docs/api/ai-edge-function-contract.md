# AI Edge Function Contract — Smart Invoice Assistant

Contract for the `extract-receipt` Edge Function: the server-side AI boundary that mediates all access to Gemini. This function never persists business data.

---

## 1. Function Specification

| Property | Value |
|---|---|
| Name | `extract-receipt` |
| Runtime | Supabase Edge Function (Deno) |
| Authentication | `verify_jwt = true` — requires valid Supabase JWT |
| Secrets | Gemini API key stored in function environment; never exposed to clients (Q-007, BR-AI-005) |
| State | Stateless; horizontally scalable |
| Writes | **None** — never writes to database or Storage |
| Client | Flutter Mobile only (no AI on web, BR-WEB-005) |

---

## 2. Request Contract

### 2.1 HTTP Request

| Field | Value |
|---|---|
| Method | POST |
| URL | `https://{project-ref}.supabase.co/functions/v1/extract-receipt` |
| Headers | `Authorization: Bearer {access_token}` (verified JWT) |
| Content-Type | `multipart/form-data` |

### 2.2 Request Body (Multipart)

| Part | Type | Required | Description |
|---|---|---|---|
| `image` | binary | Yes | Receipt image bytes (JPEG/PNG/WebP/HEIC); client compresses/downscales before send (NFR-PERF-001); max 20 MB |
| `transaction_type` | string | Yes | `'income'` or `'expense'` — biases category suggestion |
| `category_list` | string (JSON) | Yes | Array of `{id, name}` for the business's categories — used by Gemini for category suggestion matching |

### 2.3 JWT Claims Used

| Claim | Usage |
|---|---|
| `sub` | `auth.uid()` — used to look up the business via `current_business_id()` |
| `role` | Must be `authenticated` |

---

## 3. Processing Pipeline

```text
1. Validate JWT → extract auth.uid()
2. Look up business_id via current_business_id() or direct query
3. Validate image payload (present, sane size, valid MIME)
4. Call Gemini 3.1 Flash-Lite with:
   - Receipt image (inline bytes)
   - Structured output schema
   - Transaction type context
   - Business category list
5. Parse Gemini response (strict schema validation)
6. Compute per-field confidence (0-1 scale)
7. Compute overall confidence
8. Classify outcome (success or failure)
9. Return ExtractionResult to client
```

### 3.1 Validation Steps

| Step | Check | Failure |
|---|---|---|
| JWT validation | Token valid, not expired, role = authenticated | 401 Unauthorized |
| Business ownership | `auth.uid()` → business exists | 403 Forbidden |
| Image present | `image` part exists in multipart | 400 Bad Request |
| Image size | ≤ 20 MB | 413 Payload Too Large |
| Image MIME | `image/*` | 415 Unsupported Media Type |
| Gemini call | Successful response within internal timeout | Structured failure response |
| Response schema | Gemini output matches expected JSON schema | Structured failure response |

---

## 4. Gemini Integration

| Field | Value |
|---|---|
| Model | Gemini 3.1 Flash-Lite (Q-007) |
| API | `generateContent` with structured JSON output |
| Input | Receipt image (inline), system prompt with extraction instructions |
| Output | Structured JSON with fields, confidences |
| Timeout | Internal timeout (distinct from client's 15s ceiling) |
| Retry | No retry loops in MVP (single call per receipt) |

### 4.1 Prompt Contract

The Edge Function sends Gemini:
1. The receipt image as inline bytes
2. A system prompt specifying:
   - Extract: `transaction_date`, `total_amount`, `party_name` (optional), `line_items[]` (optional), `suggested_category`
   - Return per-field confidence (0-1)
   - Match `suggested_category` against the provided category list
   - Output strict JSON matching the defined schema

### 4.2 Structured Output Schema

```json
{
  "transaction_date": "string (YYYY-MM-DD)",
  "total_amount": "number (> 0)",
  "party_name": "string | null",
  "line_items": [
    {
      "description": "string",
      "amount": "number | null"
    }
  ],
  "suggested_category": "string (category name from list)",
  "field_confidences": {
    "transaction_date": "number (0-1)",
    "total_amount": "number (0-1)",
    "party_name": "number (0-1)",
    "suggested_category": "number (0-1)"
  }
}
```

---

## 5. Response Contract

### 5.1 Success Response

| Field | Value |
|---|---|
| Status | 200 OK |
| Content-Type | `application/json` |

```json
{
  "status": "success",
  "data": {
    "transaction_date": "2026-03-15",
    "total_amount": 1250.50,
    "party_name": "محل فطير الشام",
    "line_items": [
      { "description": "فطير بالجبنة", "amount": 25.00 },
      { "description": "عصير برتقال", "amount": 15.00 }
    ],
    "suggested_category": "مبيعات",
    "field_confidences": {
      "transaction_date": 0.92,
      "total_amount": 0.98,
      "party_name": 0.75,
      "suggested_category": 0.85
    },
    "overall_confidence": 0.92
  }
}
```

### 5.2 Extraction Failure Response

| Field | Value |
|---|---|
| Status | 200 OK (not an HTTP error — structured failure) |
| Condition | Required fields missing OR overall confidence < 50% (Q-008) |

```json
{
  "status": "failure",
  "reason": "missing_required_fields",
  "message": "Required fields (date, amount) could not be extracted",
  "overall_confidence": 0.32
}
```

### 5.3 Non-Receipt Response

```json
{
  "status": "failure",
  "reason": "non_receipt",
  "message": "Image does not appear to be a receipt",
  "overall_confidence": 0.0
}
```

### 5.4 Error Response (Server-Side)

| Status | Condition |
|---|---|
| 401 | Invalid/missing JWT |
| 403 | Business ownership validation failed |
| 400 | Invalid payload (missing image, invalid MIME) |
| 413 | Image too large (> 20 MB) |
| 500 | Internal error (Gemini call failed, parsing error) |

---

## 6. Confidence Model

### 6.1 Per-Field Confidence

| Range | Behavior |
|---|---|
| ≥ 80% | Field considered high-confidence; no flag |
| < 80% | Field flagged for user review on Review & Edit screen (FR-AI-004, Q-008) |
| 0-1 scale | Normalized by Edge Function from Gemini's raw confidence |

### 6.2 Overall Confidence

| Condition | Outcome |
|---|---|
| Required fields present AND overall ≥ 50% | **Success** — return extracted data for review |
| Required fields missing OR overall < 50% | **Failure** — client routes to manual entry (FR-AI-006, Q-008) |

Required fields: `transaction_date`, `total_amount` (FR-AI-002).

### 6.3 Overall Confidence Derivation

The MVP applies a simple, consistent derivation:
- `overall_confidence` = minimum of the required fields' confidences (for the success/failure gate)
- An aggregate (e.g., average of all field confidences) is included for display

No second confidence algorithm is invented (per phase instruction).

---

## 7. Timeout Handling

| Layer | Timeout | Behavior |
|---|---|---|
| Client-visible | 15 seconds (Q-009, FR-AI-008) | If no usable result within 15s → timeout message + "Enter manually instead" |
| Server internal | Distinct from client timeout | Function has its own internal timeout/error handling; returns structured failure |
| Gemini call | Provider-dependent | Function handles provider timeout internally |

The client owns the 15-second countdown. The server request may continue asynchronously, but the UI is never trapped in a loading state.

---

## 8. Manual Entry Fallback

Every extraction failure or timeout routes to manual entry:

| Trigger | Client behavior |
|---|---|
| Extraction failure (status=failure) | "Enter manually instead" button (FR-AI-005/006) |
| Client timeout (>15s) | Timeout message + "Enter manually instead" (FR-AI-008) |
| Non-receipt image | "Couldn't read this as a receipt, try again or enter manually" (FR-AI-009) |
| Network failure | Clear message + retry or manual entry |
| User preference | "Skip — enter manually" at Capture screen bypasses AI entirely (FR-CAPTURE-007) |

There is **no dead end** at any point in the extraction lifecycle.

---

## 9. AI Persistence Boundary

```text
Gemini result (structured JSON)
      ↓
Edge Function returns ExtractionResult to client
      ↓ (ephemeral — nothing persisted by AI layer)
Flutter client receives result
      ↓
Review & Edit screen: pre-filled form, <80% fields flagged
      ↓
User edits fields as needed
      ↓
User confirms Save ← CONFIRMATION BOUNDARY
      ↓
Client persists: INSERT transactions + INSERT ai_extractions + upload image + INSERT receipts
      ↓
Database + Storage (only now is data persisted)
```

**Critical rule**: The Edge Function never writes to business tables or Storage. The `ai_extractions` row is inserted by the client after confirmation, not by the Edge Function.

---

## 10. Security

| Control | Implementation |
|---|---|
| JWT verification | `verify_jwt = true` on the function |
| Business ownership | Function validates `auth.uid()` → business before spending AI calls |
| Gemini key isolation | Key stored in function environment; never in clients or responses |
| Image handling | Bytes in-memory only; not logged; not stored by AI layer |
| No secrets in responses | Error bodies contain no keys, paths, or business data |
| Cost control | Ownership check prevents cross-tenant abuse; quality gate reduces junk calls |

---

## 11. Performance

| Metric | Target |
|---|---|
| End-to-end latency | "A few seconds" (NFR-PERF-001) |
| Client-visible ceiling | 15 seconds (Q-009) |
| Image size | Client downscales to ≤ 2-4 MB before send |
| Model | Gemini 3.1 Flash-Lite (low latency, low cost) |
| Stateless | Function scales horizontally without design change |

---

## 12. Observability

- Function-level metrics: request count, outcome (success/failure/low-confidence), latency, error class, bytes processed
- No receipt contents, field values, or business names in logs
- Client-side trace: extraction duration vs 15-second budget; flag-ratio per field

---

## 13. Model Versioning

- Model pinned in function config: `gemini-3.1-flash-lite` (Q-007)
- Prompt/schema versioned with deploys
- API contract versioned for client independence (ADR-API-002)
- Model upgrades ship via function redeployment; no client change required

---

## 14. Traceability

| AI Edge Function element | Requirement / Decision IDs |
|---|---|
| Server-side boundary, model selection | FR-AI-001, BR-AI-005, Q-007, ADR-API-002 |
| Structured extraction fields | FR-AI-002 |
| Per-field confidence / flagging | FR-AI-003, FR-AI-004, BR-AI-002, Q-008 |
| Extraction failure rules | FR-AI-005, FR-AI-006, BR-AI-003, Q-008 |
| Loading state | FR-AI-007, NFR-PERF-001 |
| 15-second timeout / manual fallback | FR-AI-008, Q-009 |
| Non-receipt detection | FR-AI-009 |
| No persistence without confirmation | FR-REVIEW-001/002, BR-AI-001, BR-CONFIRM-001, NFR-DATA-001 |
| Category suggestion | FR-CATEGORY-002 |
| Gemini key server-side only | Q-007, BR-AI-005 |
