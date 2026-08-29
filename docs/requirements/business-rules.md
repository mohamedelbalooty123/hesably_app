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
A resend of the OTP is allowed only after a cooldown timer (e.g., 30s).

- Source: user-flow-mobile.md — Section 1, step 3; Edge Cases
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

---

## 5. AI Extraction Rules

### BR-AI-001 — AI Suggestion Requires Confirmation
AI-extracted data is never saved to the database without user confirmation; there is no silent auto-save of unverified AI data.

- Source: feature-list.md — Review & Edit; Non-Functional (Data trust)
- Related: FR-REVIEW-002, NFR-DATA-001

### BR-AI-002 — Confidence Flagging
Extraction returns a confidence indicator per field; low-confidence fields are visually flagged for user review.

- Source: feature-list.md — AI Data Extraction; user-flow-mobile.md — Section 2, step 5
- Related: FR-AI-003, FR-AI-004

### BR-AI-003 — Extraction Failure Falls Back to Manual Entry
If extraction fails (blurry, non-receipt, handwritten) or returns low/no confidence overall, the system routes to manual entry rather than presenting a hard error or forcing garbage data to be fixed.

- Source: feature-list.md — AI Data Extraction; user-flow-mobile.md — Section 2, step 4; Edge Cases
- Related: FR-AI-005, FR-AI-006, FR-AI-008, FR-AI-009

### BR-AI-004 — Manual Path to Bypass AI
The user can choose to bypass AI and enter the transaction manually ("Skip — enter manually").

- Source: user-flow-mobile.md — Section 2, step 3 (Option C)
- Related: FR-CAPTURE-007, FR-REVIEW-007

---

## 6. Data Confirmation Rules

### BR-CONFIRM-001 — Confirmation Before Persistence
A transaction is written to the database only after the user confirms/saves it from the Review & Edit screen.

- Source: feature-list.md — Review & Edit; user-flow-mobile.md — Section 2, step 6
- Related: FR-REVIEW-002

---

## 7. Category Rules

### BR-CATEGORY-001 — Default Categories Exist
Predefined default categories are provided, relevant to small Egyptian retail/service businesses (e.g., Purchases/Stock, Rent, Salaries, Utilities, Transport, Sales, Other).

- Source: feature-list.md — Categories
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

- Source: user-flow-mobile.md — Section 5, step 2; user-flow-dashboard.md — Section 5, step 4
- Related: FR-CATEGORY-005, FR-WEB-CATEGORY-003

### BR-CATEGORY-005 — Custom Categories Editable/Deletable
Custom categories can be added, edited, and deleted (in both mobile Settings and web Categories view).

- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2; user-flow-dashboard.md — Section 5, step 3
- Related: FR-CATEGORY-004, FR-WEB-CATEGORY-002

### BR-CATEGORY-006 — Shared Category Table
Web and mobile categories are managed against the same underlying table and rules (mirror behavior).

- Source: user-flow-dashboard.md — Section 5, step 3
- Related: FR-WEB-CATEGORY-002

### BR-CATEGORY-007 — Category Usage Count (Web)
The web Categories view shows a usage count (how many transactions use each category).

- Source: user-flow-dashboard.md — Section 5, step 2
- Related: FR-WEB-CATEGORY-001

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

---

## 9. Export Rules

### BR-EXPORT-001 — Export Default Period
The export period defaults to the period currently selected on the Reports screen.

- Source: user-flow-mobile.md — Section 4, step 3
- Related: FR-EXPORT-001

### BR-EXPORT-002 — Export Formats
Exports are available as PDF (shareable with an accountant) and Excel/CSV (raw data).

- Source: feature-list.md — Export
- Related: FR-EXPORT-002, FR-EXPORT-003

---

## 10. Web Access Rules

### BR-WEB-001 — No Web Self-Signup in MVP
Web access does not provide self-signup in MVP; the mobile app is the source of truth for account creation.

- Source: user-flow-dashboard.md — Section 1, step 3; Section 5 assumptions
- Related: FR-WEB-AUTH-002

### BR-WEB-002 — Web Access Requires Email Linking from Mobile
To use the web dashboard, the business owner must enable web access from the mobile app (Settings → "Enable Web Access"), which links an email identity to the existing Supabase user.

- Source: user-flow-mobile.md — Section 5, step 2; user-flow-dashboard.md — Section 5 assumption
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
If web access is unlinked while the user is logged in elsewhere, the session is invalidated on the next request (handled by Supabase via RLS + auth checks).

- Source: user-flow-dashboard.md — Edge Cases & Error States

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

### BR-MVP-004 — Online/Offline Capture Decision Pending
Unified-queue offline capture during the capture flow is a decision between Phase 1 and Phase 2 scope; the MVP may simply block capture offline with a clear message.

- Source: user-flow-mobile.md — Edge Cases & Error States
- See open questions

### BR-MVP-005 — Web Manual "Add Transaction" Not Required in MVP
A web "Add Transaction" button for manual desktop entry is optional and not required for MVP; it can be deferred to Phase 2.

- Source: user-flow-dashboard.md — Section 3, step 6
- Classification: POST-MVP

### BR-MVP-006 — Phase 2 / Phase 3 Not MVP
Phase 2 and Phase 3 features (per feature-list.md) are not treated as MVP requirements.

- Source: feature-list.md — Phase 2 / Phase 3 headings
