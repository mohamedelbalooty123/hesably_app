# Requirements Specification

**Project**: Smart Invoice Assistant — AI-powered receipt/invoice capture and bookkeeping app for small shop owners in Egypt.

---

## 1. Document Purpose

This document is the functional requirements specification for the Smart Invoice Assistant product. It defines the product goals, target users, scope (MVP / Post-MVP / Future), functional requirements, user flows, edge cases, and non-functional requirements.

This specification is derived **only** from the three source documents:

- `feature-list.md` — Product spec, phases, and non-functional requirements
- `user-flow-mobile.md` — Flutter mobile app flows
- `user-flow-dashboard.md` — Next.js web dashboard flows

It is a companion to the business rules, assumptions, open questions, and acceptance criteria documents in this requirements package. Requirements that are missing, ambiguous, or conflicting are recorded in `assumptions.md` and `open-questions.md` rather than silently resolved.

---

## 2. Product Overview

The Smart Invoice Assistant is an AI-powered receipt and invoice capture and bookkeeping application for small shop/business owners in Egypt. The product captures receipts and invoices from a mobile camera, uses AI (Gemini Vision API) to extract data, and records transactions for later review, reporting, and export.

The mobile application is the primary product experience. The web dashboard is a companion view for the MVP, used for reviewing data on a bigger screen, running reports, and light management. Both clients share the same Supabase data.

**Product goals:**
- Provide small shop owners without a dedicated accountant an easy way to record and track income and expenses from their phone.
- Reduce manual data entry through AI-assisted receipt capture.
- Give business owners glanceable summaries of their income, expenses, and net position.
- Support reporting and export for sharing with an accountant.

---

## 3. Target Users

- **Primary user**: Solo shop owner / small business owner with no dedicated accountant.
- Mobile-first; manages the business mostly from their phone.
- Likely non-tech-savvy → phone + OTP authentication minimizes friction.
- Likely using low/mid-spec Android devices.
- Primary language is Arabic (RTL); English is secondary.
- Target market: Egypt.

---

## 4. Product Scope

### 4.1 MVP Scope

The MVP scope is defined in `feature-list.md` Phase 1 and consists of the following capability areas (to be built in this order):

1. Authentication (phone + OTP, business onboarding, session persistence)
2. Receipt Capture (camera / gallery / manual)
3. AI Data Extraction (Gemini Vision API with confidence flags and graceful failure)
4. Review & Edit Screen (confirmation before save, manual entry)
5. Categories (defaults, AI suggestion, custom categories)
6. Transaction List & Management (list, filters, search, edit/delete, detail view)
7. Dashboard & Reports (summary, breakdown, comparison, date range)
8. Export (PDF and Excel/CSV)
9. Settings & Profile (business profile, categories, language, logout/delete account)

The web dashboard is included in MVP as a **companion view** (login, home overview, transactions, reports, categories, settings), with no self-signup. Receipt capture and AI extraction stay mobile-only for MVP.

### 4.2 Post-MVP Scope

Post-MVP features are defined in `feature-list.md` Phase 2 and are **not** part of the MVP. These include:

- Egyptian e-invoice / e-receipt system integration (ETA).
- Multi-user access per business (e.g., owner + one employee, restricted permissions).
- Recurring transaction templates.
- Low-stock / reorder suggestions.
- Push notifications (reminders, report ready, unusual spending alerts).

See `open-questions.md` where these boundaries interact with MVP descriptions.

### 4.3 Future Vision

Future/Potential features are defined in `feature-list.md` Phase 3 and are **not** part of the MVP or Phase 2. These include:

- WhatsApp-based receipt submission.
- Multi-branch support.
- Simple loan/credit tracking.
- AI-generated plain-language monthly business summary.

### 4.4 Explicitly Out of Scope

The following are explicitly out of scope for the MVP (per `feature-list.md`):

- Full accounting / double-entry bookkeeping.
- Payroll management.
- Multi-currency support.
- Direct government tax filing/submission (Phase 2 at earliest, and only after legal/compliance review).

Additionally, the duplication detection feature (hash check) is identified in `user-flow-mobile.md` as not required for MVP. **Offline capture is in MVP** (per Q-018 flipped decision): capture works without connectivity and defers AI processing + sync until the device is back online (FR-OFFLINE-001..008).

---

## 5. Functional Requirements

Requirements are classified as `MVP`, `POST-MVP`, `FUTURE`, or `OUT-OF-SCOPE` (see Section 9 for classification). Sources are referenced as `feature-list.md`, `user-flow-mobile.md`, or `user-flow-dashboard.md`.

### 5.1 Authentication

#### FR-AUTH-001 — Phone Sign-up/Login
The system shall allow users to sign up and log in using their phone number with OTP verification.

- Classification: MVP
- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1

#### FR-AUTH-002 — No Email/Password in MVP
The system shall provide **no** email/password option in MVP; phone-only authentication.

- Classification: MVP
- Source: feature-list.md — Authentication

#### FR-AUTH-003 — OTP Verification
The system shall verify users via a 6-digit OTP code sent to their phone number.

- Classification: MVP
- Source: user-flow-mobile.md — Section 1, step 3

#### FR-AUTH-004 — OTP Error State
The system shall display an inline error for an incorrect OTP code and allow a resend after a cooldown.

- Classification: MVP
- Source: user-flow-mobile.md — Section 1, step 3; Edge Cases (OTP not received)

#### FR-AUTH-005 — OTP Resend / Support
The system shall provide a resend option after a cooldown timer of **60 seconds** and a "having trouble?" support link when the OTP is not received.

- Classification: MVP
- Source: user-flow-mobile.md — Edge Cases & Error States
- Decision: Q-001 (open-questions.md) — fixes the cooldown to 60 seconds

#### FR-AUTH-006 — Session Persistence
The system shall keep the user logged in between app opens (stay logged in until explicit logout / session expiry).

- Classification: MVP
- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1, step 1

#### FR-AUTH-007 — Splash Session Check
The system shall check for an active session on the splash screen and route to the Home Dashboard if a session exists, otherwise to Phone Entry.

- Classification: MVP
- Source: user-flow-mobile.md — Section 1, step 1

### 5.2 Business Onboarding

#### FR-ONBOARD-001 — First-Login Business Setup
The system shall present a one-time Business Setup screen after the first successful login, collecting business name and business type.

- Classification: MVP
- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1, step 4

#### FR-ONBOARD-002 — Business Name
The system shall allow the user to enter a business name (text input) during onboarding.

- Classification: MVP
- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1, step 4

#### FR-ONBOARD-003 — Business Type
The system shall allow the user to select a business type from a dropdown with the options: Retail / Restaurant / Pharmacy / Service / Other.

- Classification: MVP
- Source: feature-list.md — Authentication; user-flow-mobile.md — Section 1, step 4

#### FR-ONBOARD-004 — Default Currency
The system shall set the default currency to EGP during onboarding.

- Classification: MVP
- Source: feature-list.md — Authentication (default currency (EGP))
- Decision: Q-012 (open-questions.md) — MVP currency is EGP only; multi-currency is out of scope

#### FR-ONBOARD-005 — Business Profile Creation
Confirming the onboarding form shall create the business profile record and navigate to the Home Dashboard.

- Classification: MVP
- Source: user-flow-mobile.md — Section 1, step 4

### 5.3 Receipt Capture

#### FR-CAPTURE-001 — Add Transaction Entry Point
The system shall provide an "Add Transaction" ("+") button reachable in one tap from anywhere (floating action button on Home).

- Classification: MVP
- Source: user-flow-mobile.md — Section 2

#### FR-CAPTURE-002 — Transaction Type Selection
The system shall ask the user to pick a transaction type — "Sale / Income" or "Purchase / Expense".

- Classification: MVP
- Source: feature-list.md — Receipt Capture; user-flow-mobile.md — Section 2, step 2

#### FR-CAPTURE-003 — Camera Capture (primary)
The system shall allow the user to capture a receipt using the in-app camera.

- Classification: MVP
- Source: feature-list.md — Receipt Capture; user-flow-mobile.md — Section 2, step 3

#### FR-CAPTURE-004 — Gallery Import
The system shall allow the user to pick an existing photo from the gallery.

- Classification: MVP
- Source: feature-list.md — Receipt Capture; user-flow-mobile.md — Section 2, step 3

#### FR-CAPTURE-005 — Image Quality Check
The system shall perform a basic image quality check before upload (blurry/too-dark warning) and offer an optional retake prompt. The check is advisory with three outcomes:

- **PASS** — image appears usable; processing proceeds.
- **WARNING** — borderline darkness/blur/framing; the user may continue.
- **REJECT** — clearly unusable (extremely dark, blank, no meaningful receipt content); the user is prompted to retake.

Overly aggressive thresholds must not reject potentially readable receipts.

- Classification: MVP
- Source: feature-list.md — Receipt Capture
- Decision: Q-020 (open-questions.md) — three-outcome advisory model

#### FR-CAPTURE-006 — Sales vs Purchase Support
The system shall support capturing both sales receipts issued to customers and purchase invoices from suppliers (type selected before/after capture).

- Classification: MVP
- Source: feature-list.md — Receipt Capture

#### FR-CAPTURE-007 — Manual Entry Path (Skip AI)
The system shall allow the user to skip AI entirely and enter a transaction manually with an empty form ("Skip — enter manually").

- Classification: MVP
- Source: feature-list.md — Review & Edit; user-flow-mobile.md — Section 2, step 3 (Option C)

#### FR-OFFLINE-001 — Offline Capture
The system shall allow the user to capture a receipt (camera or gallery) with no internet connection; capture never requires connectivity.

- Classification: MVP
- Source: feature-list.md — Phase 1 §2 Receipt Capture; Q-018 (flipped to MVP); ADR-007

#### FR-OFFLINE-002 — Local Pending Storage
The system shall store the captured image and chosen metadata locally on-device as a pending capture until it can be synced.

- Classification: MVP
- Source: ADR-007; mobile-architecture.md — Offline
- Decision: pending captures are a client-side concept; no database schema change (database-review.md; ADR-007)

#### FR-OFFLINE-003 — Pending Capture List
The system shall show a "Pending" list of unsynced captures with a visible status (pending / syncing / failed) and allow the user to view or delete a pending capture before it syncs.

- Classification: MVP
- Source: ux/ux-states.md — Offline states; ux/screen-inventory.md — SCR-16

#### FR-OFFLINE-004 — Deferred Sync (Manual + Auto)
The system shall sync pending captures when connectivity is available — via explicit "Sync now" and/or automatically when the connection returns — and shall surface sync failures with a retry option.

- Classification: MVP
- Source: Q-018 (flipped to MVP); ADR-007

#### FR-OFFLINE-005 — Idempotent Sync (Duplicate Prevention)
Each pending capture shall carry a client-generated UUID; syncing an already-synced UUID shall be a no-op so retries never create duplicates.

- Classification: MVP
- Source: ADR-007; data-access-contracts.md — §3.4

#### FR-OFFLINE-006 — Pending Capture Account Isolation
Pending captures shall be bound to the current owner identity and shall never be visible to or syncable under a different account; logout, account deletion, token expiry, reinstall, or device switch shall never leak a pending capture across accounts.

- Classification: MVP
- Source: ADR-007; NFR-SEC-001 (RLS invariant extended to local pending state)

#### FR-OFFLINE-007 — Online-Only Processing Boundary
AI extraction, storage upload, and server-side persistence shall require connectivity; offline mode covers capture + deferred sync only, never offline AI, offline upload, offline reports, or offline cross-device sync.

- Classification: MVP
- Source: ADR-007; Q-018 (flipped to MVP)

#### FR-OFFLINE-008 — No Offline Bypass of AI Review
Offline flow shall never bypass the AI trust invariant: AI-extracted data is processed only online and is never saved without user confirmation (NFR-DATA-001).

- Classification: MVP
- Source: ADR-004; ADR-007; NFR-DATA-001

### 5.4 AI Data Extraction

#### FR-AI-001 — Send Image to Gemini
The system shall send the captured image to the Gemini Vision API for processing.

- Classification: MVP
- Source: feature-list.md — AI Data Extraction; user-flow-mobile.md — Section 2, step 4
- Decision: Q-007 (open-questions.md) — initial production model is **Gemini 3.1 Flash-Lite**; the Gemini API key stays server-side and is never exposed in Flutter

#### FR-AI-002 — Extract Structured Fields
The system shall extract structured fields from the receipt: date, total amount, vendor/customer name (if present), line items (if legible), suggested category.

- Classification: MVP
- Source: feature-list.md — AI Data Extraction

#### FR-AI-003 — Confidence Indicator
The system shall return a confidence indicator per field so that low-confidence fields can be visually flagged for review.

- Classification: MVP
- Source: feature-list.md — AI Data Extraction
- Decision: Q-008 (open-questions.md) — a field with confidence **below 80%** is treated as low-confidence and flagged for review

#### FR-AI-004 — Low-Confidence Flagging
The system shall visually flag low-confidence fields (<80% confidence) on the Review & Edit screen (e.g., subtle highlight) prompting the user to double-check.

- Classification: MVP
- Source: user-flow-mobile.md — Section 2, step 5
- Decision: Q-008 (open-questions.md)

#### FR-AI-005 — Extraction Failure Handling
The system shall handle extraction failure gracefully (blurry image, non-receipt, handwritten receipt) and fall back to a manual entry form rather than a hard error.

- Classification: MVP
- Source: feature-list.md — AI Data Extraction

#### FR-AI-006 — Low/No Confidence Result
If the AI returns low/no confidence on all fields, the system shall treat this as extraction failure and route to manual entry, not forcing the user to fix garbage data. Extraction is treated as **unsuccessful** when required information is missing **or** the overall extraction confidence is below **50%**.

- Classification: MVP
- Source: user-flow-mobile.md — Edge Cases & Error States; feature-list.md — AI Data Extraction
- Decision: Q-008 (open-questions.md)

#### FR-AI-007 — Processing Loading State
The system shall show a loading indicator while the image uploads and Gemini extracts data, and must never show a frozen screen.

- Classification: MVP
- Source: feature-list.md — Non-Functional (Performance); user-flow-mobile.md — Section 2, step 4

#### FR-AI-008 — Processing Timeout / Manual Fallback
If extraction fails or takes too long, the system shall show a message and a "Enter manually instead" button (never a dead end). If extraction has not produced a usable result within **15 seconds**, show the timeout message and offer manual entry.

- Classification: MVP
- Source: user-flow-mobile.md — Section 2, step 4
- Decision: Q-009 (open-questions.md) — fixes the client-visible extraction timeout to 15 seconds

#### FR-AI-009 — Non-Receipt Detection
If the user captures a non-receipt image, the system shall show "Couldn't read this as a receipt, try again or enter manually" instead of garbage data.

- Classification: MVP
- Source: user-flow-mobile.md — Edge Cases & Error States

### 5.5 Review and Edit

#### FR-REVIEW-001 — Pre-filled Editable Form
The system shall show extracted fields pre-filled in an editable form on the Review & Edit screen.

- Classification: MVP
- Source: feature-list.md — Review & Edit; user-flow-mobile.md — Section 2, step 5

#### FR-REVIEW-002 — User Confirmation Before Save
The system shall require the user to confirm/save before a transaction is written to the database; no silent auto-save of unverified AI data.

- Classification: MVP
- Source: feature-list.md — Review & Edit; Non-Functional (Data trust)

#### FR-REVIEW-003 — Edit Any Field
The user shall be able to edit any field on the Review & Edit screen.

- Classification: MVP
- Source: user-flow-mobile.md — Section 2, step 5

#### FR-REVIEW-004 — Category Override
The system shall allow the category to be changed via a picker, defaulting to the AI suggestion.

- Classification: MVP
- Source: feature-list.md — Categories; user-flow-mobile.md — Section 2, step 5

#### FR-REVIEW-005 — Original Photo View
The system shall show a thumbnail of the original photo on the Review & Edit screen, tappable to view full-size.

- Classification: MVP
- Source: user-flow-mobile.md — Section 2, step 5

#### FR-REVIEW-006 — Keep Original Photo Linked
The system shall attach/keep the original photo linked to the record for later reference.

- Classification: MVP
- Source: feature-list.md — Review & Edit

#### FR-REVIEW-007 — Manual Entry Path (No Receipt)
The system shall support a quick manual-entry path (skip AI entirely) for cases where a receipt isn't available (e.g., cash sale with no printed receipt).

- Classification: MVP
- Source: feature-list.md — Review & Edit

### 5.6 Categories

#### FR-CATEGORY-001 — Default Categories
The system shall provide predefined default categories relevant to small Egyptian retail/service businesses. The authoritative default category list is:

```text
1. Sales
2. Purchases / Stock
3. Rent
4. Salaries
5. Utilities
6. Transport
7. Marketing
8. Maintenance
9. Taxes / Fees
10. Other
```

- Classification: MVP
- Source: feature-list.md — Categories
- Decision: Q-010 (open-questions.md) — authoritative list; defaults are seeded for every business, cannot be permanently deleted, and may only be hidden

#### FR-CATEGORY-002 — AI Category Suggestion
The AI shall suggest a category automatically; the user may override it.

- Classification: MVP
- Source: feature-list.md — Categories; user-flow-mobile.md — Section 2, step 5

#### FR-CATEGORY-003 — Custom Categories
The system shall allow the user to add custom categories.

- Classification: MVP
- Source: feature-list.md — Categories; user-flow-mobile.md — Section 5, step 2
- Decision: Q-021 (open-questions.md) — a custom category cannot duplicate an existing default or custom category after normalization

#### FR-CATEGORY-004 — Manage Custom Categories
The user shall be able to add, edit, and delete custom categories in Settings.

- Classification: MVP
- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2

#### FR-CATEGORY-005 — Default Categories Cannot Be Deleted
Default categories cannot be deleted; they may only be hidden.

- Classification: MVP
- Source: user-flow-mobile.md — Section 5, step 2
- Decision: Q-010 (open-questions.md) — hidden categories remain valid for existing historical transactions, remain represented in reports and filters when historical data uses them, and do not appear in normal category selection lists

### 5.7 Transaction Management

#### FR-TRANS-001 — Transaction List
The system shall display a chronological list of all recorded transactions (income/expense), with a thumbnail of the receipt image.

- Classification: MVP
- Source: feature-list.md — Transaction List & Management

#### FR-TRANS-002 — List Ordering and Grouping
The transaction list shall be ordered most recent first, grouped by date.

- Classification: MVP
- Source: user-flow-mobile.md — Section 3, step 2

#### FR-TRANS-003 — List Row Content
Each transaction row shall show: thumbnail, vendor/customer name, category, amount (color-coded income/expense), and date.

- Classification: MVP
- Source: user-flow-mobile.md — Section 3, step 2

#### FR-TRANS-004 — Filter by Date Range
The system shall allow filtering transactions by date range.

- Classification: MVP
- Source: feature-list.md — Transaction List & Management

#### FR-TRANS-005 — Filter by Category
The system shall allow filtering transactions by category.

- Classification: MVP
- Source: feature-list.md — Transaction List & Management

#### FR-TRANS-006 — Filter by Type
The system shall allow filtering transactions by type (income/expense).

- Classification: MVP
- Source: feature-list.md — Transaction List & Management

#### FR-TRANS-007 — Filter by Amount Range
The system shall allow filtering transactions by amount range.

- Classification: MVP
- Source: feature-list.md — Transaction List & Management

#### FR-TRANS-008 — Search by Name
The system shall allow searching transactions by vendor/customer name.

- Classification: MVP
- Source: feature-list.md — Transaction List & Management
- Decision: Q-022 (open-questions.md) — MVP search matches only vendor/customer name; it does not include notes, categories, other fields, full-text, or OCR text

#### FR-TRANS-009 — Transaction Detail View
The system shall provide a detail view per transaction showing all fields plus the original image.

- Classification: MVP
- Source: feature-list.md — Transaction List & Management

#### FR-TRANS-010 — Detail Read-Only Default
The transaction detail view shall show all fields read-only by default.

- Classification: MVP
- Source: user-flow-mobile.md — Section 3, step 3

#### FR-TRANS-011 — Edit Past Entry
The system shall allow editing any past entry (reopens the Review & Edit form pre-filled with saved values).

- Classification: MVP
- Source: feature-list.md — Transaction List & Management; user-flow-mobile.md — Section 3, step 3

#### FR-TRANS-012 — Delete Past Entry
The system shall allow deleting any past entry.

- Classification: MVP
- Source: feature-list.md — Transaction List & Management

#### FR-TRANS-013 — Delete Confirmation
The system shall show a confirmation dialog before deleting a transaction, and shall remove the record and associated image on delete.

- Classification: MVP
- Source: user-flow-mobile.md — Section 3, step 3; Edge Cases

### 5.8 Dashboard and Reports

#### FR-DASH-001 — Home Summary
The Home screen shall show a summary of total income, total expenses, and net for the current month as large, glanceable numbers. Monetary values use the EGP display format (e.g., `1,250.50 ج.م`) with thousands separators, decimal precision where applicable, and a currency label appropriate for the Arabic UI. Display formatting is consistent across Mobile and Web; calculations always use numeric values, not formatted strings.

- Classification: MVP
- Source: feature-list.md — Dashboard & Reports
- Decision: Q-012 (open-questions.md)

#### FR-DASH-002 — Category Breakdown
The system shall show a breakdown by category (simple bar or list, not necessarily a fancy chart in MVP).

- Classification: MVP
- Source: feature-list.md — Dashboard & Reports

#### FR-DASH-003 — Month-over-Month Comparison
The system shall show a month-over-month comparison (e.g., "+15% expenses vs last month").

- Classification: MVP
- Source: feature-list.md — Dashboard & Reports

#### FR-DASH-004 — Reports Period Selector
The system shall provide a unified report-period selector used across Mobile and Web:

```text
This Week
This Month
Last Month
Year-to-Date
Custom Range
```

- Classification: MVP
- Source: feature-list.md — Dashboard & Reports; user-flow-mobile.md — Section 4, step 2
- Decision: Q-011 (open-questions.md) — the same period options apply on Mobile and Web

#### FR-DASH-005 — Reports Summary Cards
The Reports screen shall show summary cards for Total Income, Total Expenses, and Net.

- Classification: MVP
- Source: user-flow-mobile.md — Section 4, step 2

#### FR-DASH-006 — Category Breakdown Sorted by Spend
The Reports screen shall show a category breakdown (list or simple bar chart) sorted by highest spend.

- Classification: MVP
- Source: user-flow-mobile.md — Section 4, step 2

#### FR-DASH-007 — Comparison vs Previous Period
The Reports screen shall show a comparison line versus the previous period (e.g., "+15% vs last month").

- Classification: MVP
- Source: user-flow-mobile.md — Section 4, step 2

### 5.9 Export

#### FR-EXPORT-001 — Export Options Sheet
The system shall provide an Export Options sheet allowing the user to choose a format (PDF or Excel/CSV) and a period (defaulting to the currently selected period).

- Classification: MVP
- Source: user-flow-mobile.md — Section 4, step 3
- Decision: Q-014 (open-questions.md) — exports respect the selected report period **and** the currently applied filters (category, type, amount range); a filtered subset exports exactly that subset

#### FR-EXPORT-002 — PDF Export
The system shall export a report for a selected period as PDF (simple, shareable with an accountant). The PDF shall contain:

1. Report period
2. Total income
3. Total expenses
4. Net
5. Category breakdown
6. Transaction list for the selected scope

- Classification: MVP
- Source: feature-list.md — Export
- Decision: Q-013 (open-questions.md) — PDF content is optimized for human reading and accountant sharing

#### FR-EXPORT-003 — Excel/CSV Export
The system shall export a report as Excel/CSV for users who want raw data.

- **Excel** contains three sheets: **Sheet 1 — Summary** (selected period, income, expenses, net, category summary), **Sheet 2 — Transactions** (detailed records), **Sheet 3 — Categories** (category totals for the exported scope).
- **CSV** contains transaction-level data in a flat tabular structure suitable for import into other systems.
- Amounts are formatted as EGP (e.g., `1,250.50 ج.م`); exported numeric data remains machine-readable.

- Classification: MVP
- Source: feature-list.md — Export
- Decision: Q-012/Q-013 (open-questions.md)

#### FR-EXPORT-004 — Share Sheet
Upon confirmation, the system shall generate the file and open a share sheet (WhatsApp, email, save to device, etc.).

- Classification: MVP
- Source: user-flow-mobile.md — Section 4, step 3

### 5.10 Settings and Profile

#### FR-SETTINGS-001 — Edit Business Profile
The system shall allow the user to edit business name and business type in Settings.

- Classification: MVP
- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2

#### FR-SETTINGS-002 — Manage Categories
The Settings screen shall allow the user to manage categories (add/edit/delete custom ones; default categories hidden not deleted).

- Classification: MVP
- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2

#### FR-SETTINGS-003 — Enable Web Access
The Settings screen shall provide an "Enable Web Access" option to link an email address to the account for dashboard login. This is optional and not required to use the mobile app. The linked email is associated with the **existing authenticated Supabase user** — no second independent account is created for the email.

- Classification: MVP
- Source: user-flow-mobile.md — Section 5, step 2
- Decision: Q-016 (open-questions.md) — email identity maps back to the same business/account ownership

#### FR-SETTINGS-004 — Language Toggle
The Settings screen shall provide a language toggle (Arabic default / English).

- Classification: MVP
- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2

#### FR-SETTINGS-005 — Logout
The Settings screen shall provide a logout option.

- Classification: MVP
- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2

#### FR-SETTINGS-006 — Delete Account
The Settings screen shall provide a delete account option with confirmation and explanation of data loss.

- Classification: MVP
- Source: feature-list.md — Settings; user-flow-mobile.md — Section 5, step 2

### 5.11 Web Dashboard

#### 5.11.1 Web Login

#### FR-WEB-AUTH-001 — Web Login via Magic Link
The web dashboard shall allow login via email input and a "Send Magic Link" button; the user clicks the link in email and is redirected back to the dashboard, authenticated via Supabase.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 1, steps 1–2

#### FR-WEB-AUTH-002 — Unlinked Email Block (No Web Signup)
If the email isn't linked to any business account, the system shall show a message: "This email isn't linked to a business account. Enable web access from the mobile app first." There is no self-signup on web for MVP.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 1, step 3; Section 5 assumptions

#### FR-WEB-AUTH-003 — Web Session Persistence
The web session persists (stay logged in) until explicit logout.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 1, step 5

#### FR-WEB-AUTH-004 — Magic Link Expired Handling
If a magic link is expired or already used, the system shall show "Link expired" with a "Send new link" button.

- Classification: MVP
- Source: user-flow-dashboard.md — Edge Cases & Error States

#### 5.11.2 Dashboard Home

#### FR-WEB-DASH-001 — Web Dashboard Home Landing
The Dashboard Home shall be the landing screen after login.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 2, step 1

#### FR-WEB-DASH-002 — Web Summary Cards
The Dashboard Home shall show summary cards for Total Income, Total Expenses, and Net for the current month by default.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 2, step 2

#### FR-WEB-DASH-003 — Web Category Breakdown
The Dashboard Home shall show a category breakdown chart using the same underlying data as the mobile Reports tab.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 2, step 3

#### FR-WEB-DASH-004 — Recent Transactions
The Dashboard Home shall show the last 10 entries, each linking to full detail.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 2, step 4

#### FR-WEB-DASH-005 — Web Period Comparison
The Dashboard Home shall show a period comparison vs previous month (e.g., "+15% expenses vs last month").

- Classification: MVP
- Source: user-flow-dashboard.md — Section 2, step 5

#### FR-WEB-DASH-006 — Web Top Navigation
The dashboard shall have top navigation: Overview / Transactions / Reports / Categories / Settings.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 2, step 6

#### 5.11.3 Transactions Management

#### FR-WEB-TRANS-001 — Web Transactions Data Table
The web Transactions screen shall display a data table with sortable columns and pagination: date, type, vendor/customer, category, amount, receipt thumbnail.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 3, step 2

#### FR-WEB-TRANS-002 — Web Filters
The web Transactions screen shall provide a filter bar (date range, category, type, amount range) that mirrors the mobile app's filters for consistent behavior.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 3, step 3

#### FR-WEB-TRANS-003 — Web Search
The web Transactions screen shall support search by vendor/customer name.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 3, step 4
- Decision: Q-022 (open-questions.md) — matches only vendor/customer name for MVP

#### FR-WEB-TRANS-004 — Web Detail Panel
Clicking a row shall open a detail panel (side drawer or modal) showing all fields read-only by default, with a full-size receipt image viewer.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 3, step 5

#### FR-WEB-TRANS-005 — Web Edit
The web detail panel shall provide an "Edit" button opening an inline editable form; Save updates the same Supabase record the mobile app reads.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 3, step 5

#### FR-WEB-TRANS-006 — Web Delete
The web detail panel shall provide a "Delete" button with a confirmation dialog.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 3, step 5

#### 5.11.4 Reports

#### FR-WEB-REPORT-001 — Web Reports Period Selector
The web Reports screen shall provide the same unified period selector as Mobile:

```text
This Week
This Month
Last Month
Year-to-Date
Custom Range
```

- Classification: MVP
- Source: user-flow-dashboard.md — Section 4, step 2
- Decision: Q-011 (open-questions.md)

#### FR-WEB-REPORT-002 — Web Reports Summary and Breakdown
The web Reports screen shall show summary cards and a category breakdown using the same data model as mobile.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 4, step 3

#### FR-WEB-REPORT-003 — Web Export
The web Reports screen shall provide an Export button to choose PDF or Excel/CSV and download directly (no share sheet).

- Classification: MVP
- Source: user-flow-dashboard.md — Section 4, step 4

#### 5.11.5 Categories

#### FR-WEB-CATEGORY-001 — Web Category Table
The web Categories screen shall show a table of all categories (default + custom) with a usage count (how many transactions use each).

- Classification: MVP
- Source: user-flow-dashboard.md — Section 5, step 2

#### FR-WEB-CATEGORY-002 — Web Category Management
The web Categories screen shall allow adding, editing, and deleting custom categories, mirroring mobile Settings using the same underlying table.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 5, step 3

#### FR-WEB-CATEGORY-003 — Web Default Categories Hidden Not Deleted
On the web, default categories can be hidden but not deleted (same rule as mobile).

- Classification: MVP
- Source: user-flow-dashboard.md — Section 5, step 4

#### 5.11.6 Settings

#### FR-WEB-SETTINGS-001 — Web Business Profile
The web Settings screen shall allow editing business profile name and type, syncing with mobile.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 6, step 2

#### FR-WEB-SETTINGS-002 — Web Access Management
The web Settings screen shall allow viewing/unlinking the email identity connected to this account.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 6, step 3

#### FR-WEB-SETTINGS-003 — Web Logout
The web Settings screen shall provide a logout option.

- Classification: MVP
- Source: user-flow-dashboard.md — Section 6, step 4

---

## 6. User Flows

### 6.1 Mobile — Onboarding Flow (first-time user)

Source: user-flow-mobile.md — Section 1

1. Splash Screen → checks for active Supabase session.
   - Has session → Home Dashboard.
   - No session → Phone Entry.
2. Phone Entry → enter phone → "Send Code".
3. OTP Verification → enter 6-digit code → verified via Supabase Phone Auth.
   - Wrong code → inline error; resend after cooldown.
4. Business Setup (one-time, after first login): business name (text), business type (dropdown), Confirm → creates business profile → Home Dashboard.

### 6.2 Mobile — Core Loop: Add New Transaction

Source: user-flow-mobile.md — Section 2

Reachable in one tap from anywhere (FAB on Home).

1. Home → tap "+".
2. Type Selector → "Sale / Income" or "Purchase / Expense".
3. Capture Screen:
   - A: Camera → take photo.
   - B: Gallery → pick existing photo.
   - C: "Skip — enter manually" → empty form (bypasses AI).
4. Processing State (after photo):
   - Loading indicator while uploading + Gemini extraction.
   - Timeout/error → message + "Enter manually instead" button.
5. Review & Edit: pre-filled editable form; low-confidence fields flagged; edit any field; photo thumbnail (tappable full-size); category picker defaults to AI suggestion.
6. Confirm & Save: record written to Supabase; photo stored in Storage bucket linked to the record; success feedback; return to Home (updated totals).

### 6.3 Mobile — Browse & Manage Transactions

Source: user-flow-mobile.md — Section 3

1. Home → Transactions tab.
2. Transaction List: chronological, most recent first, grouped by date. Rows: thumbnail, vendor/customer, category, color-coded amount, date. Filter bar (date/category/type) + search.
3. Tap → Detail: read-only by default; Edit → Review & Edit form pre-filled; Delete → confirmation → removes record + image.

### 6.4 Mobile — Reports Flow

Source: user-flow-mobile.md — Section 4

1. Home → Reports tab.
2. Reports Screen: unified period selector (This Week / This Month / Last Month / Year-to-Date / Custom Range); summary cards (Income, Expenses, Net); category breakdown sorted by highest spend; comparison vs previous period.
3. Tap Export → Export Options: choose PDF or Excel/CSV; choose period (default = current); Confirm → file generated → share sheet (WhatsApp, email, save, etc.).

### 6.5 Mobile — Settings Flow

Source: user-flow-mobile.md — Section 5

1. Home → Settings.
2. Settings: business profile (name, type) editable; Manage Categories (add/edit/delete custom, defaults hidden not deleted); Enable Web Access (optional); Language toggle (Arabic default / English); Logout; Delete account (confirmation + data-loss explanation).

### 6.6 Web — Login Flow

Source: user-flow-dashboard.md — Section 1

1. Login page → email input → "Send Magic Link".
2. Email received → click link → redirected back to dashboard, authenticated.
3. If email not linked → blocked with message (no web self-signup).
4. Successful login → Dashboard Home.
5. Session persists until logout.

### 6.7 Web — Dashboard Home

Source: user-flow-dashboard.md — Section 2

Landing after login: total income / expenses / net summary cards (current month default); category breakdown chart (same data as mobile Reports); recent transactions (last 10); period comparison vs previous month; top nav Overview / Transactions / Reports / Categories / Settings.

### 6.8 Web — Transactions Management

Source: user-flow-dashboard.md — Section 3

1. Top nav → Transactions.
2. Sortable/paginated data table (date, type, vendor/customer, category, amount, thumbnail).
3. Filter bar (date range, category, type, amount range) + search by name.
4. Click row → detail panel (drawer/modal): read-only fields; full-size image viewer; Edit → inline editable form → Save changes same Supabase record; Delete → confirmation.

### 6.9 Web — Reports

Source: user-flow-dashboard.md — Section 4

Period selector (This Week / This Month / Last Month / Year-to-Date / Custom Range); summary cards + category breakdown; Export button → PDF or Excel/CSV → direct download, scoped to the period and current filters.

### 6.10 Web — Categories

Source: user-flow-dashboard.md — Section 5

Table of all categories (default + custom) with usage count; add/edit/delete custom (mirrors mobile); default categories hidden not deleted.

### 6.11 Web — Settings

Source: user-flow-dashboard.md — Section 6

Business profile (name, type) editable, syncs with mobile; Web Access (view/unlink email identity); Logout.

---

## 7. Edge Cases and Error Handling

### 7.1 Mobile Edge Cases (Source: user-flow-mobile.md — Edge Cases & Error States)

| Situation | Expected behavior | Classification |
|---|---|---|
| No internet connection during capture | Offline capture **is in MVP** (queue + sync, per Q-018 flipped): the receipt is captured and stored locally as a pending capture; AI processing/sync run when connectivity returns. A clear "waiting for connection" status is shown and retry is available. | MVP |
| AI returns low/no confidence on all fields | Treat as extraction failure → route to manual entry | MVP |
| User captures a non-receipt image | Gemini returns empty/near-empty → "Couldn't read this as a receipt, try again or enter manually" | MVP |
| Duplicate receipt (same photo/data twice) | Not required for MVP — Phase 2 nice-to-have (simple hash check) | POST-MVP |
| OTP not received | Resend after cooldown (60 seconds) + "having trouble?" support link | MVP |
| User deletes transaction by mistake | Confirmation dialog before delete only (no undo/trash in Phase 1) | MVP |
| Wrong OTP code | Inline error, allow resend after cooldown | MVP |

### 7.2 Web Edge Cases (Source: user-flow-dashboard.md — Edge Cases & Error States)

| Situation | Expected behavior | Classification |
|---|---|---|
| Email not yet linked to a business | Block login with clear explanatory message; no dashboard signup in MVP | MVP |
| Magic link expired/used | "Link expired" + "Send new link" button | MVP |
| New business with zero transactions | Empty state on Home/Transactions/Reports with an Arabic message (see Q-019 copy) rather than a blank/broken-looking screen | MVP |
| User edits on web while mobile open on same record | Not handled specially in MVP (last write wins); Phase 2 real-time sync consideration | POST-MVP |
| Web access unlinked while user logged in elsewhere | Session invalidated on next request (Supabase via RLS + auth checks) | MVP |

---

## 8. Non-Functional Requirements

#### NFR-LANG-001 — Primary Language Arabic (RTL)
The primary UI language shall be Arabic with right-to-left (RTL) layout throughout; English is secondary.

- Classification: MVP
- Source: feature-list.md — Non-Functional; AGENTS-NFR (noted)

#### NFR-PERF-001 — Extraction Performance
The AI extraction result shall return within a few seconds; the system shall show a clear loading state during processing and never a frozen screen.

- Classification: MVP
- Source: feature-list.md — Non-Functional (Performance); user-flow-mobile.md — Section 2, step 4

#### NFR-SEC-001 — Row Level Security
Row Level Security in Supabase shall ensure each business owner can only ever query (read/write) their own data.

- Classification: MVP
- Source: feature-list.md — Non-Functional (Security)

#### NFR-SEC-002 — Private Storage Bucket
Receipt images shall be stored in a private (non-public) storage bucket.

- Classification: MVP
- Source: feature-list.md — Non-Functional (Security)

#### NFR-DATA-001 — Data Trust / No Silent Save
AI-extracted data shall never be saved without user confirmation.

- Classification: MVP
- Source: feature-list.md — Non-Functional (Data trust); Review & Edit

#### NFR-LOWDEV-001 — Low-End Device Friendly
The app shall remain lightweight and avoid heavy animations, to work well on mid/low-spec Android devices.

- Classification: MVP
- Source: feature-list.md — Non-Functional (Low-end device friendly)

---

## 9. Requirements Traceability

### Classification Index

| Classification | Meaning |
|---|---|
| MVP | In-scope for Phase 1 MVP (feature-list.md Phase 1 + dashboard MVP companion scope) |
| POST-MVP | Phase 2 (feature-list.md Phase 2, or explicit "not for MVP / Phase 2" notes in flows) |
| FUTURE | Phase 3 / longer-term vision (feature-list.md Phase 3) |
| OUT-OF-SCOPE | Explicitly out of scope in feature-list.md |

### MVP Requirements Coverage by Capability Area

| Capability Area | Requirements | MVP Count |
|---|---|---|
| Authentication | FR-AUTH-001 … 007 | 7 |
| Business Onboarding | FR-ONBOARD-001 … 005 | 5 |
| Receipt Capture | FR-CAPTURE-001 … 007 | 7 |
| Offline Capture | FR-OFFLINE-001 … 008 | 8 |
| AI Data Extraction | FR-AI-001 … 009 | 9 |
| Review and Edit | FR-REVIEW-001 … 007 | 7 |
| Categories | FR-CATEGORY-001 … 005 | 5 |
| Transaction Management | FR-TRANS-001 … 013 | 13 |
| Dashboard and Reports | FR-DASH-001 … 007 | 7 |
| Export | FR-EXPORT-001 … 004 | 4 |
| Settings and Profile | FR-SETTINGS-001 … 006 | 6 |
| Web Login | FR-WEB-AUTH-001 … 004 | 4 |
| Web Dashboard Home | FR-WEB-DASH-001 … 006 | 6 |
| Web Transactions | FR-WEB-TRANS-001 … 006 | 6 |
| Web Reports | FR-WEB-REPORT-001 … 003 | 3 |
| Web Categories | FR-WEB-CATEGORY-001 … 003 | 3 |
| Web Settings | FR-WEB-SETTINGS-001 … 003 | 3 |
| Non-Functional | NFR-LANG-001, NFR-PERF-001, NFR-SEC-001, NFR-SEC-002, NFR-DATA-001, NFR-LOWDEV-001 | 6 |

**Total MVP functional + non-functional requirements: 109**

### Post-MVP / Future / Out-of-Scope Feature Index

| Feature | Classification | Source |
|---|---|---|
| ETA e-invoice / e-receipt integration | POST-MVP | feature-list.md — Phase 2 |
| Multi-user access per business | POST-MVP | feature-list.md — Phase 2 |
| Recurring transaction templates | POST-MVP | feature-list.md — Phase 2 |
| Low-stock / reorder suggestions | POST-MVP | feature-list.md — Phase 2 |
| Push notifications | POST-MVP | feature-list.md — Phase 2 |
| Duplicate receipt hash check | POST-MVP | user-flow-mobile.md — Edge Cases |
| Web "Add Transaction" (manual desktop entry) | POST-MVP | user-flow-dashboard.md — Section 3, step 6 |
| Web/mobile real-time sync (last-write-wins) | POST-MVP | user-flow-dashboard.md — Edge Cases |
| WhatsApp-based receipt submission | FUTURE | feature-list.md — Phase 3 |
| Multi-branch support | FUTURE | feature-list.md — Phase 3 |
| Loan/credit tracking | FUTURE | feature-list.md — Phase 3 |
| AI plain-language monthly summary | FUTURE | feature-list.md — Phase 3 |
| Full accounting / double-entry | OUT-OF-SCOPE | feature-list.md — Explicitly out of scope |
| Payroll management | OUT-OF-SCOPE | feature-list.md — Explicitly out of scope |
| Multi-currency support | OUT-OF-SCOPE | feature-list.md — Explicitly out of scope |
| Direct government tax filing/submission | OUT-OF-SCOPE (MVP); POST-MVP at earliest (pending legal review) | feature-list.md — Explicitly out of scope |
