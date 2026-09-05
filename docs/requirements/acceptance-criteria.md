# Acceptance Criteria

This document defines testable acceptance criteria for the MVP requirements. Each criterion describes **observable system behavior** and maps to a requirement ID from `requirements.md`. Criteria are written using Given / When / Then where possible and include both success and failure/edge cases described in the source documents.

---

## 1. Authentication

### AC-AUTH-001 — Phone Sign-up/Login
**Requirement:** FR-AUTH-001, FR-AUTH-002

**Given:**
A new user opens the app on mobile.

**When:**
They enter their phone number and send a code (no email/password option is available).

**Then:**
An OTP is sent to their phone, and they can verify to sign up/log in using only their phone number.

### AC-AUTH-002 — OTP Verification
**Requirement:** FR-AUTH-003

**Given:**
A user has requested a code for their phone number.

**When:**
They enter the correct 6-digit OTP.

**Then:**
They are successfully verified and authenticated.

### AC-AUTH-003 — Incorrect OTP Handling
**Requirement:** FR-AUTH-004

**Given:**
A user has entered an incorrect OTP code.

**When:**
They submit it.

**Then:**
An inline error is shown and they can resend the code after a cooldown.

### AC-AUTH-004 — OTP Resend and Support
**Requirement:** FR-AUTH-005

**Given:**
A user did not receive their OTP.

**When:**
The cooldown ends.

**Then:**
They can tap a resend button, and a "having trouble?" support link is available.

### AC-AUTH-005 — Session Persistence
**Requirement:** FR-AUTH-006

**Given:**
A user has previously logged in.

**When:**
They reopen the app.

**Then:**
They remain logged in (no re-authentication required).

### AC-AUTH-006 — Splash Routing by Session
**Requirement:** FR-AUTH-007

**Given:**
A user opens the app at the splash screen.

**When:**
The app checks for an active session.

**Then:**
A valid session routes to Home Dashboard; no session routes to Phone Entry.

---

## 2. Business Onboarding

### AC-ONBOARD-001 — Business Setup Shown After First Login
**Requirement:** FR-ONBOARD-001, FR-ONBOARD-005

**Given:**
A user has just completed their first successful login.

**When:**
They proceed past authentication.

**Then:**
A one-time Business Setup screen appears; after confirmation, a business profile is created and they are taken to the Home Dashboard.

### AC-ONBOARD-002 — Business Name and Type Entry
**Requirement:** FR-ONBOARD-002, FR-ONBOARD-003

**Given:**
A user is on the Business Setup screen.

**When:**
They enter a business name (text) and select a business type from Retail / Restaurant / Pharmacy / Service / Other.

**Then:**
Both values are accepted and used to create the business profile.

### AC-ONBOARD-003 — Default Currency EGP
**Requirement:** FR-ONBOARD-004

**Given:**
A user completes onboarding.

**When:**
A business profile is created.

**Then:**
The default currency is set to EGP.

### AC-ONBOARD-004 — Onboarding Not Repeated
**Requirement:** FR-ONBOARD-001

**Given:**
A user has already completed onboarding.

**When:**
They log in again later.

**Then:**
The Business Setup screen is not shown again (they go straight to Home Dashboard).

---

## 3. Receipt Capture

### AC-CAPTURE-001 — Add Transaction Reachable in One Tap
**Requirement:** FR-CAPTURE-001

**Given:**
The user is on any screen with the Add Transaction button.

**When:**
They tap the "+" (floating action) button.

**Then:**
The Add Transaction flow starts immediately (one tap from anywhere).

### AC-CAPTURE-002 — Transaction Type Selection
**Requirement:** FR-CAPTURE-002

**Given:**
A user has started adding a transaction.

**When:**
The Type Selector appears.

**Then:**
They can choose "Sale / Income" or "Purchase / Expense".

### AC-CAPTURE-003 — Camera Capture
**Requirement:** FR-CAPTURE-003

**Given:**
A user chooses to capture with the camera.

**When:**
They take a photo of a receipt.

**Then:**
The photo is used for processing.

### AC-CAPTURE-004 — Gallery Import
**Requirement:** FR-CAPTURE-004

**Given:**
A user chooses to pick an existing photo.

**When:**
They select a photo from the gallery.

**Then:**
The selected photo is used for processing.

### AC-CAPTURE-005 — Image Quality Warning
**Requirement:** FR-CAPTURE-005

**Given:**
A user is about to upload a receipt image.

**When:**
The image is clearly unusable (extremely dark, blank, or with no meaningful receipt content).

**Then:**
A REJECT outcome is returned, prompting the user to retake the image. Borderline images produce a WARNING that allows the user to continue; acceptable images PASS without prompt.

### AC-CAPTURE-006 — Manual Entry Without Photo
**Requirement:** FR-CAPTURE-007, FR-REVIEW-007

**Given:**
A user does not have a receipt (e.g., cash sale with no printed receipt).

**When:**
They choose "Skip — enter manually".

**Then:**
An empty entry form is shown and they can record the transaction without AI.

### AC-OFFLINE-001 — Capture Works Offline
**Requirement:** FR-OFFLINE-001, FR-OFFLINE-002

**Given:**
A user is on the capture screen with no internet connection.

**When:**
They capture a receipt (camera or gallery) and select the transaction type.

**Then:**
The receipt is captured and stored locally as a pending capture; no error is shown and no connectivity is required.

### AC-OFFLINE-002 — Pending List Shows Status
**Requirement:** FR-OFFLINE-003

**Given:**
A user has one or more unsynced pending captures.

**When:**
They open the Pending list.

**Then:**
Each pending capture is listed with a visible status (pending / syncing / failed), and the user can view or delete a pending capture before it syncs.

### AC-OFFLINE-003 — Deferred Sync on Reconnect
**Requirement:** FR-OFFLINE-004

**Given:**
A user has pending captures and connectivity returns.

**When:**
They tap "Sync now" (or the automatic retry triggers).

**Then:**
Pending captures upload, AI runs, and each proceeds through the review/confirm step; the status transitions pending → syncing → (ready for review) → synced.

### AC-OFFLINE-004 — Sync Does Not Duplicate
**Requirement:** FR-OFFLINE-005

**Given:**
A pending capture is already synced and the user triggers sync again (retry). 

**When:**
The previously-synced capture UUID is submitted again.

**Then:**
The server treats it as a no-op and no duplicate transaction/record is created.

### AC-OFFLINE-005 — Pending Is Never Auto-Confirmed
**Requirement:** FR-OFFLINE-008, NFR-DATA-001

**Given:**
A pending capture has been synced and AI has returned an extraction with confidence scores.

**When:**
The user reaches the review step.

**Then:**
The extracted data is presented for review/confirmation and is not persisted without the user's explicit confirmation (no offline or automatic bypass).

### AC-OFFLINE-006 — Pending Never Crosses Accounts
**Requirement:** FR-OFFLINE-006

**Given:**
A user with pending captures logs out (or the account is deleted/token expires/device is switched).

**When:**
A different account or identity accesses the device afterwards.

**Then:**
The pendings are purged or cryptographically bound to the original owner and are never visible to or syncable under the other account.

### AC-OFFLINE-007 — Offline Does Not Fabricate Capabilities
**Requirement:** FR-OFFLINE-007, BR-OFFLINE-008

**Given:**
A user is offline and views Home.

**When:**
Previously loaded data is shown.

**Then:**
The UI shows a read-only cached view and never implies cloud sync or a current/up-to-date status; offline never offers export, analytics, or cross-device access.

---

## 4. AI Extraction

### AC-AI-001 — Successful Extraction
**Requirement:** FR-AI-001, FR-AI-002

**Given:**
A user has captured a receipt image.

**When:**
The image is processed successfully by the AI.

**Then:**
The system displays the extracted fields (date, total amount, vendor/customer, line items if legible, suggested category) for user review before saving.

### AC-AI-002 — Confidence Flagging
**Requirement:** FR-AI-003, FR-AI-004

**Given:**
The AI returns confidence below 80% for one or more fields.

**When:**
The Review & Edit screen is shown.

**Then:**
The low-confidence fields are visually flagged (e.g., subtle highlight) prompting the user to double-check them; all fields remain editable.

### AC-AI-003 — Extraction Shows Loading State
**Requirement:** FR-AI-007, NFR-PERF-001

**Given:**
A user has captured a photo.

**When:**
The image is uploading and being processed.

**Then:**
A clear loading indicator is shown and the screen is never frozen.

### AC-AI-004 — Processing Timeout / Manual Fallback
**Requirement:** FR-AI-008

**Given:**
AI extraction fails or takes too long.

**When:**
The processing state ends in failure or does not produce a usable result within 15 seconds.

**Then:**
A message is shown with an "Enter manually instead" button (never a dead end).

### AC-AI-005 — Non-Receipt Image
**Requirement:** FR-AI-009

**Given:**
A user captures a non-receipt image (e.g., a random photo).

**When:**
The AI returns an empty/near-empty result.

**Then:**
A message is shown: "Couldn't read this as a receipt, try again or enter manually."

### AC-AI-006 — Low Confidence on All Fields Routes to Manual Entry
**Requirement:** FR-AI-006, FR-AI-005

**Given:**
The AI returns low/no confidence on all fields or missing required information.

**When:**
The overall extraction confidence is below 50% or required information is missing.

**Then:**
It is treated as extraction failure and the user is routed to manual entry, not forced to fix garbage data.

---

## 5. Review and Edit

### AC-REVIEW-001 — Pre-filled Editable Form
**Requirement:** FR-REVIEW-001, FR-REVIEW-003

**Given:**
AI has returned extracted data.

**When:**
The Review & Edit screen opens.

**Then:**
The extracted fields are pre-filled in an editable form and the user can edit any field.

### AC-REVIEW-002 — Confirmation Required Before Save
**Requirement:** FR-REVIEW-002, NFR-DATA-001, BR-AI-001

**Given:**
A user is on the Review & Edit screen with AI data.

**When:**
The user taps "Save".

**Then:**
The record is written to the database only after this explicit confirmation; no AI data is saved without the user confirming.

### AC-REVIEW-003 — Category Override
**Requirement:** FR-REVIEW-004, FR-CATEGORY-002

**Given:**
A transaction has a suggested category (AI suggestion).

**When:**
The user opens the category picker.

**Then:**
They can change the category from the suggestion to another value.

### AC-REVIEW-004 — Original Photo View
**Requirement:** FR-REVIEW-005, FR-REVIEW-006

**Given:**
A transaction has a captured photo.

**When:**
The user views it on the Review & Edit screen and taps the thumbnail.

**Then:**
The full-size original photo is shown, and the photo remains linked to the saved record.

### AC-REVIEW-005 — Save Stores Image and Returns Home
**Requirement:** FR-REVIEW-002 (mobile flow completion)

**Given:**
A user confirms a transaction with a photo.

**When:**
"Save" is tapped.

**Then:**
The record is written to Supabase, the photo is stored in the Storage bucket linked to the record, success feedback is shown, and the user returns to the Home Dashboard with updated totals.

---

## 6. Categories

### AC-CATEGORY-001 — Default Categories Provided
**Requirement:** FR-CATEGORY-001

**Given:**
A new business is set up.

**When:**
The user opens the category list.

**Then:**
The authoritative default categories are available (Sales, Purchases/Stock, Rent, Salaries, Utilities, Transport, Marketing, Maintenance, Taxes/Fees, Other).

### AC-CATEGORY-002 — Add Custom Category
**Requirement:** FR-CATEGORY-003

**Given:**
A user is managing categories in Settings.

**When:**
They add a custom category.

**Then:**
The new category becomes available for selection.

### AC-CATEGORY-003 — Edit/Delete Custom Category
**Requirement:** FR-CATEGORY-004

**Given:**
A user is managing categories in Settings.

**When:**
They edit or delete a custom category.

**Then:**
The change is applied to that custom category.

### AC-CATEGORY-004 — Default Category Cannot Be Deleted
**Requirement:** FR-CATEGORY-005, BR-CATEGORY-004

**Given:**
A user is managing categories.

**When:**
They attempt to delete a default category.

**Then:**
Deletion is prevented; the default category can only be hidden.

---

## 7. Transactions

### AC-TRANS-001 — Transaction List Displayed
**Requirement:** FR-TRANS-001, FR-TRANS-002, FR-TRANS-003

**Given:**
A user opens the Transactions tab.

**When:**
Recorded transactions exist.

**Then:**
They are shown chronologically (most recent first, grouped by date), each row showing thumbnail, vendor/customer, category, color-coded amount, and date.

### AC-TRANS-002 — Filter by Date Range
**Requirement:** FR-TRANS-004

**Given:**
A user is on the transaction list.

**When:**
They apply a date range filter.

**Then:**
Only transactions within the selected range are shown.

### AC-TRANS-003 — Filter by Category
**Requirement:** FR-TRANS-005

**Given:**
A user is on the transaction list.

**When:**
They apply a category filter.

**Then:**
Only transactions in the selected category are shown.

### AC-TRANS-004 — Filter by Type
**Requirement:** FR-TRANS-006

**Given:**
A user is on the transaction list.

**When:**
They filter by type (income/expense).

**Then:**
Only transactions of the selected type are shown.

### AC-TRANS-005 — Filter by Amount Range
**Requirement:** FR-TRANS-007

**Given:**
A user is on the transaction list.

**When:**
They apply an amount range filter.

**Then:**
Only transactions within the selected amount range are shown.

### AC-TRANS-006 — Search by Name
**Requirement:** FR-TRANS-008

**Given:**
A user is on the transaction list.

**When:**
They enter a vendor/customer name in the search field.

**Then:**
Only matching transactions are shown.

### AC-TRANS-007 — Transaction Detail View
**Requirement:** FR-TRANS-009, FR-TRANS-010

**Given:**
A user taps a transaction row.

**When:**
The detail view opens.

**Then:**
All fields are shown read-only by default along with the original full-size image.

### AC-TRANS-008 — Edit Past Entry
**Requirement:** FR-TRANS-011

**Given:**
A user is viewing a transaction detail.

**When:**
They tap "Edit".

**Then:**
The Review & Edit form reopens pre-filled with the saved values, and saving updates the record.

### AC-TRANS-009 — Delete Past Entry (with Confirmation)
**Requirement:** FR-TRANS-012, FR-TRANS-013, BR-TRANS-003

**Given:**
A user taps "Delete" on a transaction detail.

**When:**
They confirm the deletion in the confirmation dialog.

**Then:**
The record is removed along with its associated image.

### AC-TRANS-010 — Delete Cancel
**Requirement:** FR-TRANS-013, BR-TRANS-004

**Given:**
A user taps "Delete" on a transaction.

**When:**
They cancel the confirmation dialog.

**Then:**
The transaction is not deleted (confirmation dialog is the only safeguard and no undo/trash exists in the MVP).

---

## 8. Dashboard and Reports

### AC-DASH-001 — Home Summary
**Requirement:** FR-DASH-001

**Given:**
A user is on the Home Dashboard.

**When:**
They view the summary.

**Then:**
Total income, total expenses, and net for the current month are shown as large, glanceable numbers.

### AC-DASH-002 — Category Breakdown
**Requirement:** FR-DASH-002

**Given:**
A user is on the Home Dashboard.

**When:**
They view the breakdown.

**Then:**
Income/expenses are broken down by category (simple bar or list).

### AC-DASH-003 — Month-over-Month Comparison
**Requirement:** FR-DASH-003

**Given:**
A user is on the Home Dashboard.

**When:**
Prior-period data exists.

**Then:**
A month-over-month comparison is shown (e.g., "+15% expenses vs last month").

### AC-DASH-004 — Reports Period Selector
**Requirement:** FR-DASH-004

**Given:**
A user is on the Reports screen.

**When:**
They open the period selector.

**Then:**
They can choose from the unified set: This Week / This Month / Last Month / Year-to-Date / Custom Range.

### AC-DASH-005 — Reports Summary Cards
**Requirement:** FR-DASH-005

**Given:**
A user is on the Reports screen for a selected period.

**When:**
They view the report.

**Then:**
Summary cards show Total Income, Total Expenses, and Net for that period.

### AC-DASH-006 — Reports Category Breakdown Sorted by Spend
**Requirement:** FR-DASH-006, BR-REPORT-001

**Given:**
A user is on the Reports screen.

**When:**
The category breakdown is shown.

**Then:**
It is sorted by highest spend.

### AC-DASH-007 — Reports Comparison vs Previous Period
**Requirement:** FR-DASH-007

**Given:**
A user is on the Reports screen for a period.

**When:**
Prior-period data exists.

**Then:**
A comparison vs the previous period is shown (e.g., "+15% vs last month").

---

## 9. Export

### AC-EXPORT-001 — Export Options Sheet
**Requirement:** FR-EXPORT-001, BR-EXPORT-001

**Given:**
A user taps "Export" on the Reports screen.

**When:**
The Export Options sheet opens.

**Then:**
They can choose a format (PDF or Excel/CSV) and the period defaults to the currently selected one; the export is scoped to the selected period **and** any currently applied filters (category, type, amount range).

### AC-EXPORT-002 — PDF Export
**Requirement:** FR-EXPORT-002

**Given:**
A user selects PDF format for a period.

**When:**
They confirm the export.

**Then:**
A PDF report is generated for that period containing the report period, total income, total expenses, net, category breakdown, and transaction list for the selected scope.

### AC-EXPORT-003 — Excel/CSV Export
**Requirement:** FR-EXPORT-003

**Given:**
A user selects Excel/CSV format for a period.

**When:**
They confirm the export.

**Then:**
An Excel/CSV file with the raw data is generated (Excel: Summary, Transactions, and Categories sheets; CSV: flat transaction-level data).

### AC-EXPORT-004 — Share Sheet Opens
**Requirement:** FR-EXPORT-004

**Given:**
A user has generated an export.

**When:**
The file is ready.

**Then:**
A share sheet opens (WhatsApp, email, save to device, etc.).

---

## 10. Settings

### AC-SETTINGS-001 — Edit Business Profile
**Requirement:** FR-SETTINGS-001, FR-WEB-SETTINGS-001

**Given:**
A user opens Settings.

**When:**
They edit the business name or type and save.

**Then:**
The business profile is updated (and stays in sync across mobile and web).

### AC-SETTINGS-002 — Manage Categories
**Requirement:** FR-SETTINGS-002

**Given:**
A user opens Manage Categories in Settings.

**When:**
They add, edit, or delete a custom category, or hide a default category.

**Then:**
The change is applied (default categories cannot be deleted, only hidden).

### AC-SETTINGS-003 — Enable Web Access
**Requirement:** FR-SETTINGS-003

**Given:**
A user opens Settings.

**When:**
They choose "Enable Web Access" and link an email address.

**Then:**
An email is linked to the account enabling web login; this step is optional and not required to use the mobile app.

### AC-SETTINGS-004 — Language Toggle
**Requirement:** FR-SETTINGS-004

**Given:**
A user opens Settings.

**When:**
They toggle the language.

**Then:**
The UI switches between Arabic (default, RTL) and English.

### AC-SETTINGS-005 — Logout
**Requirement:** FR-SETTINGS-005

**Given:**
A user opens Settings.

**When:**
They tap Logout.

**Then:**
They are logged out and returned to the login flow.

### AC-SETTINGS-006 — Delete Account with Confirmation
**Requirement:** FR-SETTINGS-006

**Given:**
A user opens Settings.

**When:**
They choose Delete account.

**Then:**
A confirmation with an explanation of data loss is shown; after confirmation, the account is deleted.

---

## 11. Web Dashboard

### AC-WEB-AUTH-001 — Magic Link Login
**Requirement:** FR-WEB-AUTH-001

**Given:**
A user is on the web login page with a linked email.

**When:**
They enter their email and tap "Send Magic Link", then click the link in email.

**Then:**
They are redirected to the dashboard and authenticated.

### AC-WEB-AUTH-002 — Unlinked Email Blocked (No Web Signup)
**Requirement:** FR-WEB-AUTH-002, BR-WEB-003

**Given:**
A user enters an email not linked to any business account.

**When:**
They attempt to log in.

**Then:**
Login is blocked with the message "This email isn't linked to a business account. Enable web access from the mobile app first." (no self-signup on web).

### AC-WEB-AUTH-003 — Web Session Persists
**Requirement:** FR-WEB-AUTH-003

**Given:**
A user has logged in on the web.

**When:**
They revisit the dashboard later without logging out.

**Then:**
Their session persists (no re-login required).

### AC-WEB-AUTH-004 — Magic Link Expired
**Requirement:** FR-WEB-AUTH-004

**Given:**
A magic link is expired or already used.

**When:**
The user clicks it.

**Then:**
"Link expired" is shown with a "Send new link" button.

### AC-WEB-DASH-001 — Dashboard Home After Login
**Requirement:** FR-WEB-DASH-001

**Given:**
A user logs in on the web.

**When:**
Authentication succeeds.

**Then:**
They are directed to Dashboard Home (Overview).

### AC-WEB-DASH-002 — Web Summary Cards
**Requirement:** FR-WEB-DASH-002

**Given:**
A user is on Dashboard Home.

**When:**
They view the summary.

**Then:**
Total Income, Total Expenses, and Net for the current month are shown.

### AC-WEB-DASH-003 — Web Category Breakdown
**Requirement:** FR-WEB-DASH-003

**Given:**
A user is on Dashboard Home.

**When:**
The category breakdown is shown.

**Then:**
A category breakdown chart displays data consistent with the mobile Reports tab.

### AC-WEB-DASH-004 — Recent Transactions
**Requirement:** FR-WEB-DASH-004

**Given:**
A user is on Dashboard Home.

**When:**
Recent transactions exist.

**Then:**
The last 10 entries are shown, each linking to full detail.

### AC-WEB-DASH-005 — Web Period Comparison
**Requirement:** FR-WEB-DASH-005

**Given:**
A user is on Dashboard Home.

**When:**
Prior-month data exists.

**Then:**
A comparison vs the previous month is shown (e.g., "+15% expenses vs last month").

### AC-WEB-DASH-006 — Top Navigation
**Requirement:** FR-WEB-DASH-006

**Given:**
A user is on the dashboard.

**When:**
They look at the top navigation.

**Then:**
Links Overview / Transactions / Reports / Categories / Settings are available.

### AC-WEB-TRANS-001 — Web Data Table
**Requirement:** FR-WEB-TRANS-001

**Given:**
A user opens the Transactions page on the web.

**When:**
Transactions exist.

**Then:**
A sortable, paginated data table shows date, type, vendor/customer, category, amount, and receipt thumbnail.

### AC-WEB-TRANS-002 — Web Filters
**Requirement:** FR-WEB-TRANS-002

**Given:**
A user is on the web Transactions page.

**When:**
They apply date range, category, type, or amount range filters.

**Then:**
The table reflects the filters, consistent with the mobile app.

### AC-WEB-TRANS-003 — Web Search
**Requirement:** FR-WEB-TRANS-003

**Given:**
A user is on the web Transactions page.

**When:**
They search by vendor/customer name.

**Then:**
Only matching transactions are shown.

### AC-WEB-TRANS-004 — Web Detail Panel
**Requirement:** FR-WEB-TRANS-004

**Given:**
A user clicks a transaction row.

**When:**
The detail panel opens.

**Then:**
All fields are shown read-only by default with a full-size receipt image viewer.

### AC-WEB-TRANS-005 — Web Edit
**Requirement:** FR-WEB-TRANS-005, BR-TRANS-005

**Given:**
A user opens the web detail panel.

**When:**
They tap "Edit", change a field, and save.

**Then:**
The change updates the same Supabase record the mobile app reads.

### AC-WEB-TRANS-006 — Web Delete
**Requirement:** FR-WEB-TRANS-006

**Given:**
A user opens the web detail panel.

**When:**
They tap "Delete" and confirm in the confirmation dialog.

**Then:**
The record is deleted.

### AC-WEB-REPORT-001 — Web Reports Period Selector
**Requirement:** FR-WEB-REPORT-001

**Given:**
A user is on the web Reports screen.

**When:**
They open the period selector.

**Then:**
They can choose from the unified set shared with mobile: This Week / This Month / Last Month / Year-to-Date / Custom Range.

### AC-WEB-REPORT-002 — Web Reports Summary and Breakdown
**Requirement:** FR-WEB-REPORT-002

**Given:**
A user is on the web Reports screen for a selected period.

**When:**
They view the report.

**Then:**
Summary cards and a category breakdown display the same data model as mobile.

### AC-WEB-REPORT-003 — Web Export Download
**Requirement:** FR-WEB-REPORT-003

**Given:**
A user is on the web Reports screen.

**When:**
They tap Export and choose PDF or Excel/CSV.

**Then:**
The file downloads directly (no share sheet on web).

### AC-WEB-CATEGORY-001 — Web Category Table with Usage
**Requirement:** FR-WEB-CATEGORY-001, BR-CATEGORY-007

**Given:**
A user opens the Categories page on the web.

**When:**
The table is shown.

**Then:**
All categories (default + custom) are listed with a usage count per category.

### AC-WEB-CATEGORY-002 — Web Category Management
**Requirement:** FR-WEB-CATEGORY-002, BR-CATEGORY-006

**Given:**
A user is on the web Categories page.

**When:**
They add, edit, or delete a custom category.

**Then:**
The change reflects the same underlying table and rules as mobile Settings.

### AC-WEB-CATEGORY-003 — Web Default Category Cannot Be Deleted
**Requirement:** FR-WEB-CATEGORY-003, BR-CATEGORY-004

**Given:**
A user is on the web Categories page.

**When:**
They attempt to delete a default category.

**Then:**
Deletion is prevented; the default category can only be hidden (same rule as mobile).

### AC-WEB-SETTINGS-001 — Web Business Profile Editable
**Requirement:** FR-WEB-SETTINGS-001

**Given:**
A user is on the web Settings page.

**When:**
They edit the business name or type.

**Then:**
The change syncs with the mobile app.

### AC-WEB-SETTINGS-002 — Web Access View/Unlink
**Requirement:** FR-WEB-SETTINGS-002

**Given:**
A user is on the web Settings page.

**When:**
They view or unlink the email identity connected to the account.

**Then:**
The connected email is shown, and unlinking removes the web access link.

### AC-WEB-SETTINGS-003 — Web Logout
**Requirement:** FR-WEB-SETTINGS-003

**Given:**
A user is on the web Settings page.

**When:**
They tap Logout.

**Then:**
They are logged out of the dashboard.

### AC-WEB-EMPTY-001 — New Business Empty States
**Requirement:** FR-WEB-DASH-001, FR-WEB-TRANS-001, FR-WEB-REPORT-002

**Given:**
A business has zero transactions.

**When:**
The user opens Home, Transactions, or Reports.

**Then:**
An empty state is shown that explains the absence and offers a next action, rather than a blank/broken screen. Web empty state uses the Q-019 copy: "لا توجد معاملات بعد" with guidance "أضف أول معاملة من تطبيق الهاتف لبدء متابعة نشاطك التجاري."

---

## Traceability Summary

| Requirement Area | Requirement IDs | Acceptance Criteria IDs |
|---|---|---|
| Authentication | FR-AUTH-001…007 | AC-AUTH-001…006 |
| Business Onboarding | FR-ONBOARD-001…005 | AC-ONBOARD-001…004 |
| Receipt Capture | FR-CAPTURE-001…007 | AC-CAPTURE-001…006 |
| Offline Capture | FR-OFFLINE-001…008 | AC-OFFLINE-001…007 |
| AI Data Extraction | FR-AI-001…009 | AC-AI-001…006 |
| Review and Edit | FR-REVIEW-001…007 | AC-REVIEW-001…005 |
| Categories | FR-CATEGORY-001…005 | AC-CATEGORY-001…004 |
| Transactions | FR-TRANS-001…013 | AC-TRANS-001…010 |
| Dashboard and Reports | FR-DASH-001…007 | AC-DASH-001…007 |
| Export | FR-EXPORT-001…004 | AC-EXPORT-001…004 |
| Settings | FR-SETTINGS-001…006 | AC-SETTINGS-001…006 |
| Web Dashboard | FR-WEB-* | AC-WEB-* (incl. AC-WEB-EMPTY-001) |

**Total acceptance criteria: 91**

> Note: NFR items (e.g., NFR-SEC-001 row-level security, NFR-SEC-002 private bucket, NFR-DATA-001 no silent save) are cross-checked within relevant criteria (see AC-AI-001/002, AC-REVIEW-002, AC-WEB-AUTH-002) and are verified through the corresponding functional flows rather than as standalone user-visible behaviors.
