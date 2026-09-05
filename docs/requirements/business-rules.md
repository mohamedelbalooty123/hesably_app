# Business Rules

This document formalizes the business rules supported by the three source documents (`feature-list.md`, `user-flow-mobile.md`, `user-flow-dashboard.md`). No rule is inferred beyond what the source documents support. Each rule is linked to the requirements it governs where applicable.

---

## 1. Account and Authentication Rules

### BR-AUTH-001 — Phone-Only Authentication in MVP
Users shall sign up and log in using a phone number with OTP verification only. There is no email/password option in the MVP.

- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1
- Related: FR-AUTH-001, FR-AUTH-002

### BR-AUTH-002 — OTP Verification Required
Account access requires verification via a 6-digit OTP code sent to the user's phone number.

- Source: user-flow-mobile.md — Section 1, step 3
- Related: FR-AUTH-003

### BR-AUTH-003 — OTP Resend Cooldown
A resend of the OTP is allowed only after a cooldown timer of **60 seconds**. The resend button is disabled (with a visible countdown) during the cooldown and becomes available afterwards.

- Source: user-flow-mobile.md — Section 1, step 3; Edge Cases
- Decision: Q-001 (open-questions.md)
- Related: FR-AUTH-004, FR-AUTH-005

### BR-AUTH-004 — Session Persistence
A logged-in user remains logged in between app opens (session persists until explicit logout or session expiry).

- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1, step 1
- Related: FR-AUTH-006

---

## 2. Business Profile Rules

### BR-BUS-001 — Mandatory Business Setup on First Login
A business profile record is created via the one-time Business Setup screen shown after the first successful login.

- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1, step 4
- Related: FR-ONBOARD-001, FR-ONBOARD-005

### BR-BUS-002 — Business Type Allowed Values
The business type is selected from a fixed dropdown: Retail / Restaurant / Pharmacy / Service / Other.

- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1, step 4
- Related: FR-ONBOARD-003

### BR-BUS-003 — Default Currency EGP
The default currency for a business is EGP.

- Source: feature-list.md — Authentication
- Related: FR-ONBOARD-004

### BR-BUS-004 — Business Profile Editable
The business profile (name, type) is editable by the owner after onboarding, and syncs between mobile and web.

- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2; user-flow-dashboard.md — Section 6, step 2
- Related: FR-SETTINGS-001, FR-WEB-SETTINGS-001

---

## 3. Transaction Rules

### BR-TRANS-001 — Transaction Type
Every recorded transaction has a type: "Sale / Income" or "Purchase / Expense".

- Source: feature-list.md — Receipt Capture; user-flow-mobile.md — Section 2, step 2
- Related: FR-CAPTURE-002

### BR-TRANS-002 — Transaction Edit
Any past entry can be edited.

- Source: feature-list.md — Transaction List & Management; user-flow-mobile.md — Section 3, step 3
- Related: FR-TRANS-011

### BR-TRANS-003 — Transaction Delete with Confirmation
Any past entry can be deleted, but only after a confirmation dialog. Deleting removes the record and its associated image.

- Source: user-flow-mobile.md — Section 3, step 3; Edge Cases
- Related: FR-TRANS-012, FR-TRANS-013

### BR-TRANS-004 — No Undo/Trash in MVP
The confirmation dialog is the only safeguard against accidental deletion in the MVP (no undo/trash in Phase 1).

- Source: user-flow-mobile.md — Edge Cases & Error States
- Related: FR-TRANS-013

### BR-TRANS-005 — Web Edits Update Shared Record
An edit made on the web updates the same Supabase record the mobile app reads.

- Source: user-flow-dashboard.md — Section 3, step 5
- Related: FR-WEB-TRANS-005

### BR-TRANS-006 — Last Write Wins (MVP)
Concurrent edits on web and mobile for the same record are not specially handled in the MVP; last write wins. Real-time sync is a Phase 2 consideration.

- Source: user-flow-dashboard.md — Edge Cases & Error States
- Classification: POST-MVP (for the sync behavior); MVP behavior is last-write-wins

### BR-TRANS-007 — Search Scope (Vendor/Customer Name Only)
MVP transaction search matches only the vendor/customer name. It does not include notes, categories, other transaction fields, full-text search, or OCR text.

- Source: feature-list.md — Transaction List & Management; user-flow-mobile.md — Section 3, step 2; user-flow-dashboard.md — Section 3, step 4
- Decision: Q-022 (open-questions.md)
- Related: FR-TRANS-008, FR-WEB-TRANS-003

---

## 4. Receipt Rules

### BR-REC-001 — Receipt Image Capture Channels
A receipt is captured via the in-app camera (primary) or imported from the gallery.

- Source: feature-list.md — Receipt Capture; user-flow-mobile.md — Section 2, step 3
- Related: FR-CAPTURE-003, FR-CAPTURE-004

### BR-REC-002 — Manual Entry Without Receipt
A transaction can be recorded without a receipt, using a quick manual-entry path (e.g., cash sale with no printed receipt); this bypasses AI entirely.

- Source: feature-list.md — Review & Edit; user-flow-mobile.md — Section 2, step 3
- Related: FR-CAPTURE-007, FR-REVIEW-007

### BR-REC-003 — Original Photo Kept Linked to Record
When a photo is captured, it is attached/kept linked to the record for later reference.

- Source: feature-list.md — Review & Edit; user-flow-mobile.md — Section 2, step 6
- Related: FR-REVIEW-006

### BR-REC-004 — Receipt Image Stored in Private Bucket
Receipt images are stored in a private (non-public) storage bucket.

- Source: feature-list.md — Non-Functional (Security)
- Related: NFR-SEC-002

### BR-REC-005 — Image Quality Check Outcomes
The pre-upload image quality check is advisory, with three outcomes:

- **PASS** — image appears usable; processing proceeds.
- **WARNING** — borderline quality (darkness, blur, framing); the user may continue.
- **REJECT** — clearly unusable (extremely dark, blank, no meaningful receipt content); the user is prompted to retake.

The check is not a strict guarantee and must not reject potentially readable receipts.

- Source: feature-list.md — Receipt Capture
- Decision: Q-020 (open-questions.md)
- Related: FR-CAPTURE-005

---

## 5. AI Extraction Rules

### BR-AI-001 — AI Suggestion Requires Confirmation
AI-extracted data is never saved to the database without user confirmation; there is no silent auto-save of unverified AI data.

- Source: feature-list.md — Review & Edit; Non-Functional (Data trust)
- Related: FR-REVIEW-002, NFR-DATA-001

### BR-AI-002 — Confidence Flagging
Extraction returns a confidence indicator per field; low-confidence fields are visually flagged for user review. A field with confidence **below 80%** is flagged for review. A field with incorrect or missing data can still be edited by the user.

- Source: feature-list.md — AI Data Extraction; user-flow-mobile.md — Section 2, step 5
- Decision: Q-008 (open-questions.md)
- Related: FR-AI-003, FR-AI-004

### BR-AI-003 — Extraction Failure Falls Back to Manual Entry
If extraction fails (blurry, non-receipt, handwritten) or returns low/no confidence overall, the system routes to manual entry rather than presenting a hard error or forcing garbage data to be fixed. Extraction is treated as **unsuccessful** when required information is missing **or** the overall extraction confidence is below **50%**. If extraction has not produced a usable result within **15 seconds**, the timeout path is shown with manual-entry offered.

- Source: feature-list.md — AI Data Extraction; user-flow-mobile.md — Section 2, step 4; Edge Cases
- Decision: Q-008, Q-009 (open-questions.md)
- Related: FR-AI-005, FR-AI-006, FR-AI-008, FR-AI-009

### BR-AI-004 — Manual Path to Bypass AI
The user can choose to bypass AI and enter the transaction manually ("Skip — enter manually").

- Source: user-flow-mobile.md — Section 2, step 3 (Option C)
- Related: FR-CAPTURE-007, FR-REVIEW-007

### BR-AI-005 — Gemini Model and Server-Side Access
Receipt/invoice extraction uses the Gemini Vision API (initial production model: **Gemini 3.1 Flash-Lite**). The Gemini API key is accessed only through a server-side AI processing boundary and is never embedded in the Flutter app or otherwise exposed client-side.

- Source: feature-list.md — AI Data Extraction
- Decision: Q-007 (open-questions.md)
- Related: FR-AI-001

---

## 6. Data Confirmation Rules

### BR-CONFIRM-001 — Confirmation Before Persistence
A transaction is written to the database only after the user confirms/saves it from the Review & Edit screen.

- Source: feature-list.md — Review & Edit; user-flow-mobile.md — Section 2, step 6
- Related: FR-REVIEW-002

---

## 7. Category Rules

### BR-CATEGORY-001 — Default Categories Exist
Predefined default categories are provided, relevant to small Egyptian retail/service businesses. The authoritative default list is: Sales, Purchases/Stock, Rent, Salaries, Utilities, Transport, Marketing, Maintenance, Taxes/Fees, Other.

- Source: feature-list.md — Categories
- Decision: Q-010 (open-questions.md)
- Related: FR-CATEGORY-001

### BR-CATEGORY-002 — AI Category Suggestion
The AI suggests a category automatically; the user can override it via the picker.

- Source: feature-list.md — Categories; user-flow-mobile.md — Section 2, step 5
- Related: FR-CATEGORY-002, FR-REVIEW-004

### BR-CATEGORY-003 — Custom Categories Addable
Users can add custom categories.

- Source: feature-list.md — Categories; user-flow-mobile.md — Section 5, step 2
- Related: FR-CATEGORY-003

### BR-CATEGORY-004 — Default Categories Cannot Be Deleted
Default categories cannot be deleted; they can only be hidden.

Hidden default categories:
- remain valid for existing historical transactions;
- stay available when displaying historical transactions;
- remain represented in reports and filters where historical data uses them;
- do not appear in normal category selection lists.

- Source: user-flow-mobile.md — Section 5, step 2; user-flow-dashboard.md — Section 5, step 4
- Decision: Q-010 (open-questions.md)
- Related: FR-CATEGORY-005, FR-WEB-CATEGORY-003

### BR-CATEGORY-005 — Custom Categories Editable/Deletable
Custom categories can be added, edited, and deleted (in both mobile Settings and web Categories view).

- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2; user-flow-dashboard.md — Section 5, step 3
- Related: FR-CATEGORY-004, FR-WEB-CATEGORY-002

### BR-CATEGORY-006 — Shared Category Table
Web and mobile categories are managed against the same underlying table and rules (mirror behavior). Categories are shared across platforms, and default categories are identifiable separately from custom categories. Category behavior is consistent between Mobile and Web.

- Source: user-flow-dashboard.md — Section 5, step 3
- Decision: Q-021 (open-questions.md)
- Related: FR-WEB-CATEGORY-002

### BR-CATEGORY-007 — Category Usage Count (Web)
The web Categories view shows a usage count (how many transactions use each category).

- Source: user-flow-dashboard.md — Section 5, step 2
- Related: FR-WEB-CATEGORY-001

### BR-CATEGORY-008 — No Duplicate Custom Category
A custom category cannot duplicate an existing default or custom category after normalization.

- Source: Q-021 (open-questions.md)
- Decision: Q-021 (open-questions.md)
- Related: FR-CATEGORY-003, FR-WEB-CATEGORY-002

---

## 8. Reporting Rules

### BR-REPORT-001 — Category Breakdown Sorted by Spend
The mobile reports category breakdown is sorted by highest spend.

- Source: user-flow-mobile.md — Section 4, step 2
- Related: FR-DASH-006

### BR-REPORT-002 — Shared Data Model Across Platforms
The web reports use the same data model as mobile (summary cards + category breakdown).

- Source: user-flow-dashboard.md — Section 4, step 3
- Related: FR-WEB-REPORT-002

### BR-REPORT-003 — Unified Report Periods
The same report-period options apply on Mobile and Web: This Week, This Month, Last Month, Year-to-Date, and Custom Range.

- Source: Q-011 (open-questions.md)
- Decision: Q-011 (open-questions.md)
- Related: FR-DASH-004, FR-WEB-REPORT-001

### BR-REPORT-004 — EGP Display Format
Displayed monetary values use human-readable EGP formatting (thousands separators, decimal precision where applicable, and a currency label/symbol appropriate for the Arabic UI, e.g., `1,250.50 ج.م`). Financial calculations use numeric values, not formatted strings, and display formatting is consistent across Mobile and Web.

- Source: Q-012 (open-questions.md)
- Decision: Q-012 (open-questions.md)
- Related: FR-DASH-001, FR-WEB-DASH-002

---

## 9. Export Rules

### BR-EXPORT-001 — Export Scope (Period + Filters)
The export period defaults to the period currently selected on the Reports screen, and the export respects the currently applied filters (category, type, amount range) as well. A filtered subset exports exactly that subset.

- Source: user-flow-mobile.md — Section 4, step 3
- Decision: Q-014 (open-questions.md)
- Related: FR-EXPORT-001

### BR-EXPORT-002 — Export Formats
Exports are available as PDF (shareable with an accountant) and Excel/CSV (raw data).

- PDF contains: report period, total income, total expenses, net, category breakdown, and transaction list for the selected scope.
- Excel contains three sheets: Summary (period, income, expenses, net, category summary), Transactions (detailed records), and Categories (category totals).
- CSV contains transaction-level data in a flat tabular structure.

- Source: feature-list.md — Export
- Decision: Q-013 (open-questions.md)
- Related: FR-EXPORT-002, FR-EXPORT-003

### BR-EXPORT-003 — Currency Formatting in Exports
Monetary values in exports are formatted as EGP (e.g., `1,250.50 ج.م`); exported numeric data remains machine-readable where appropriate.

- Source: Q-012 (open-questions.md)
- Decision: Q-012 (open-questions.md)
- Related: FR-EXPORT-002, FR-EXPORT-003

---

## 10. Web Access Rules

### BR-WEB-001 — No Web Self-Signup in MVP
Web access does not provide self-signup in MVP; the mobile app is the source of truth for account creation.

- Source: user-flow-dashboard.md — Section 1, step 3; Section 5 assumptions
- Related: FR-WEB-AUTH-002

### BR-WEB-002 — Web Access Requires Email Linking from Mobile
To use the web dashboard, the business owner must enable web access from the mobile app (Settings → "Enable Web Access"), which links an email identity to the **existing Supabase user**. No second independent account is created for the email; the web identity maps back to the same business/account ownership.

- Source: user-flow-mobile.md — Section 5, step 2; user-flow-dashboard.md — Section 5 assumption
- Decision: Q-016 (open-questions.md)
- Related: FR-SETTINGS-003, FR-WEB-AUTH-002

### BR-WEB-003 — Unlinked Email Blocks Web Login
If an email isn't linked to any business account, web login is blocked with a clear message (no account creation path).

- Source: user-flow-dashboard.md — Section 1, step 3; Edge Cases
- Related: FR-WEB-AUTH-002

### BR-WEB-004 — Web Session Persists Until Logout
The web session persists (stay logged in) until explicit logout.

- Source: user-flow-dashboard.md — Section 1, step 5
- Related: FR-WEB-AUTH-003

### BR-WEB-005 — Receipt Capture Stays Mobile-Only in MVP
Receipt capture (camera + AI extraction) remains mobile-only for the MVP; the dashboard is a companion view.

- Source: user-flow-dashboard.md — Section 5 assumption
- Related: FR-CAPTURE-003 (mobile-only binding)

### BR-WEB-006 — Web Access Unlink Invalidates Session
If web access is unlinked while the user is logged in elsewhere, existing web access becomes invalid. On the next authenticated request, dashboard access is rejected, the user is returned to the login/access-disabled state, and is informed that Web Access must be re-enabled from the Mobile App. No real-time disconnect mechanism is required in MVP.

- Source: user-flow-dashboard.md — Edge Cases & Error States
- Decision: Q-015 (open-questions.md)

---

## 11. Security and Data Access Rules

### BR-SEC-001 — Data Isolation by Business Owner
Each business owner can only ever query (read/write) their own data, enforced via Row Level Security in Supabase.

- Source: feature-list.md — Non-Functional (Security)
- Related: NFR-SEC-001

### BR-SEC-002 — Private Receipt Storage
Receipt images are stored in a private (non-public) storage bucket.

- Source: feature-list.md — Non-Functional (Security)
- Related: NFR-SEC-002, BR-REC-004

---

## 12. MVP Scope Rules

### BR-MVP-001 — MVP Build Order
MVP features are built in the order defined in feature-list.md Phase 1 (Authentication → Receipt Capture → AI Data Extraction → Review & Edit → Categories → Transaction List → Dashboard & Reports → Export → Settings & Profile).

- Source: feature-list.md — Phase 1 heading and ordering

### BR-MVP-002 — No Email/Password in MVP
Email/password login is out of scope for the MVP; phone-only authentication applies.

- Source: feature-list.md — Authentication
- Related: BR-AUTH-001

### BR-MVP-003 — Duplicate Receipt Detection Not in MVP
Duplicate receipt detection (hash check on image) is not required for MVP; it is a Phase 2 nice-to-have.

- Source: user-flow-mobile.md — Edge Cases & Error States
- Classification: POST-MVP

### BR-MVP-004 — Offline Capture In MVP
Offline receipt capture (queue + deferred sync) **is in the MVP** (Q-018 flipped to IN MVP). With no network connection, the MVP captures the receipt and stores it locally as a pending capture; AI processing and sync run when connectivity returns. A clear "waiting for connection" status is shown and retry is available. The offline boundary covers **capture + deferred sync only** — AI extraction, storage upload, server persistence, cross-device sync, and reports reflecting unsynced data are online-only (FR-OFFLINE-007).

- Source: user-flow-mobile.md — Edge Cases & Error States
- Decision: Q-018 (open-questions.md) — flipped IN MVP; ADR-007
- Related: BR-OFFLINE-001..008, BR-MVP-006, NFR-DATA-001
- Classification: MVP

### BR-MVP-005 — Web Manual "Add Transaction" Not Required in MVP
A web "Add Transaction" button for manual desktop entry is optional and not required for MVP; it can be deferred to Phase 2.

- Source: user-flow-dashboard.md — Section 3, step 6
- Classification: POST-MVP

### BR-MVP-006 — Phase 2 / Phase 3 Not MVP
Phase 2 and Phase 3 features (per feature-list.md) are not treated as MVP requirements.

- Source: feature-list.md — Phase 2 / Phase 3 headings
- Note: Offline capture was moved from Phase 2 into Phase 1 MVP (Q-018 flipped) — see BR-MVP-004 and BR-OFFLINE-001.

---

## 13. Offline Capture Rules

### BR-OFFLINE-001 — Capture Is Local-First
Capturing a receipt (camera or gallery) never requires connectivity; the image and chosen metadata are stored on-device as a pending capture.

- Source: ADR-007
- Related: FR-OFFLINE-001, FR-OFFLINE-002

### BR-OFFLINE-002 — Deferred Idempotent Sync
Pendings sync when connectivity is available (manual "Sync now" and/or automatically when the connection returns). Sync is idempotent: each pending capture carries a client-generated UUID, and re-syncing an already-synced UUID is a no-op (no duplicates).

- Source: ADR-007
- Related: FR-OFFLINE-004, FR-OFFLINE-005

### BR-OFFLINE-003 — Pending Status Is Visible
Unsynced captures appear in a Pending list with an explicit status (pending / syncing / failed) and may be retried or deleted locally before syncing.

- Source: ADR-007
- Related: FR-OFFLINE-003

### BR-OFFLINE-004 — No Offline Bypass of AI Confirmation
Offline flow never bypasses the AI trust invariant (BR-CONFIRM-001, NFR-DATA-001): AI extraction runs only online and its output always routes through the review/confirm step before persistence.

- Source: ADR-007
- Related: FR-OFFLINE-008, BR-CONFIRM-001, BR-AI-001

### BR-OFFLINE-005 — Online-Only Capabilities
AI extraction, storage upload, server-side persistence, cross-device sync, and reports over unsynced data require connectivity; offline mode never fabricates these.

- Source: ADR-007
- Related: FR-OFFLINE-007

### BR-OFFLINE-006 — Pending Capture Account Isolation
Pending captures are bound to the current owner identity. Logout, account deletion, token expiry, reinstall, or device switch must never expose a pending capture to a different account (RLS invariant extended to the local queue).

- Source: ADR-007
- Related: FR-OFFLINE-006, BR-SEC-001, BR-SEC-002

### BR-OFFLINE-007 — Sync Retry Is Not Conflict Resolution
"Sync failed / retry" and "data changed meanwhile" are distinct concerns. Server data uses last-write-wins (BR-TRANS-006); no conflict-resolution/merge UI in MVP.

- Source: ADR-007
- Related: BR-TRANS-006

### BR-OFFLINE-008 — No Offline Inventiveness
Offline mode is capture + deferred sync only. A read-only cache of previously loaded data may be shown in Home but must never imply cloud sync or current status; offline windows never offer export, analytics, or cross-device access.

- Source: ADR-007
- Related: FR-OFFLINE-007, BR-EXPORT-001
