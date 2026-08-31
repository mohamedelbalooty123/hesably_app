# Data Access Patterns — Smart Invoice Assistant

How the two clients and the Edge Functions touch the schema. These are the **query contracts** the RLS policies and indexes must support. Illustrative SQL sketches only — no DDL.

---

## 0. Common denominator

- Every query begins `… WHERE business_id = current_business_id()` (RLS injects it; client code does **not** need to pass `business_id` for reads).
- Pages/sorts align with indexes (see `indexes.md`).
- Clients never use `service_role`; `anon` has nothing.

---

## 1. Mobile (owner JWT)

### 1.1 First run — bootstrap
```
1. INSERT businesses (owner_id = auth.uid(), name, currency_code='EGP')   -- RLS INSERT
2. (AFTER INSERT trigger seeds default categories; no client action)
3. SELECT id FROM businesses WHERE owner_id = auth.uid()                    -- cache current_business_id()
```

### 1.2 Home / today
```sql
SELECT t.*,
       c.name AS category_name
FROM transactions t
JOIN categories c ON c.id = t.category_id AND c.business_id = t.business_id
WHERE t.business_id = <biz> AND t.transaction_date = CURRENT_DATE
ORDER BY t.created_at DESC;
```
→ I1 covers ordered business+date reads.

### 1.3 Filtered list (tabs / category)
```sql
-- type filter
SELECT ... WHERE business_id=<biz> AND type='expense' ORDER BY transaction_date DESC;   -- I2
-- category filter
SELECT ... WHERE business_id=<biz> AND category_id=<cat> ORDER BY transaction_date DESC; -- I3
```

### 1.4 AI capture & confirm (the core flow)
```
1. capture → image bytes held in the app temp area (NOT uploaded)  -- mobile-architecture.md
2. POST /functions/extract-receipt (multipart image bytes)         -- Edge: Gemini -> normalized draft
   (returns amount/date/party_name/type/category suggestion + confidences; writes nothing)
3. USER CONFIRMS in Review & Edit                                  -- NFR-DATA-001, BR-CONFIRM-001
4. confirmed commit (row-first; nothing server-side exists pre-confirm):
   INSERT transactions (entry_source='ai', confirmed values)
   INSERT ai_extractions (model, overall_confidence, extracted_fields, field_confidences)
   uploadImage("receipts/{biz}/{txn}/receipt.ext")
   INSERT receipts (storage_path, metadata)
   (on any failure: delete the partial transaction/extraction rows; image cleaned best-effort)
```
Edge writes **nothing**; only the confirmed client call persists (no pre-confirmation upload).

### 1.5 Manual entry
`INSERT transactions (entry_source='manual', …)` + optional `transaction_items` batch INSERT.

### 1.6 Edit / delete
```sql
UPDATE transactions SET party_name='<v>' WHERE id=<id>;    -- RLS-scoped; updated_at stamped by set_updated_at() trigger
DELETE transactions WHERE id=<id>;                        -- cascades items/receipt row/extraction
-- app also deletes the storage object for the receipt
```

### 1.7 Party-name search
```sql
SELECT ... FROM transactions
WHERE business_id=<biz> AND lower(party_name) ILIKE '%' || lower(<q>) || '%'
ORDER BY transaction_date DESC;                           -- I6 GIN trigram
```

### 1.8 Hide category
```sql
UPDATE categories SET is_hidden=true WHERE id=<id>;       -- defaults editable in flag only (guard trigger)
```

---

## 2. Dashboard (owner JWT via magic link)

Reads mirror mobile (same RLS). Distinct dashboard patterns:

### 2.1 Summary tiles
```sql
SELECT
  SUM(amount) FILTER (WHERE type='income')   AS income,
  SUM(amount) FILTER (WHERE type='expense')  AS expense,
  COUNT(*)                                   AS txn_count
FROM transactions
WHERE business_id=<biz>;
```
(No materialized view in MVP — `indexes.md` §5; revisit at scale.)

### 2.2 Web-access enable / email link
```sql
UPDATE businesses
SET web_access_enabled = true,
    web_email = lower(<email>)
WHERE id=<biz>;                                   -- partial unique web_email enforced
```
The per-request gate (Q-015) is enforced **before** this session reaches the DB (Edge/API middleware), not by RLS.

### 2.3 Manage categories / delete transaction / view receipt
Same forms as mobile (delete category blocked by RESTRICT surfaces a friendly error).

---

## 3. Edge Functions

### 3.1 `extract-receipt`
```
load image from receipts/{biz}/{txn}/receipt.ext   (owner-scoped read)
call Gemini vision (model + prompt per ai-architecture.md)
return { fields, confidences, overall_confidence }   -- NEVER persists
```

### 3.2 account-deletion (admin / service_role, ADR-DB-005)
```
1. enumerate + delete storage objects under receipts/{biz}/...
2. DELETE auth.users WHERE id=<uid>        -- cascades business subtree
```
No client-side equivalent exists.

---

## 4. Query-contract checklist (verify in model review)

- [ ] Every listing query is covered by a leading-`business_id` index (I1/I2/I3/I7–I10).
- [ ] `current_business_id()` is the only tenant predicate clients rely on.
- [ ] AI flow persists only after confirmation; the extract function is write-free.
- [ ] Receipt upload is row-first with rollback (storage-design §5).
- [ ] No query reads `ai_extractions` for authorization decisions.
- [ ] Dashboard gains nothing the mobile session lacks (same RLS identity).