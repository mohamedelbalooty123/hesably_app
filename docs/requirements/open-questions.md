# Requirements Decisions

## Purpose

This document contains product decisions that resolve previously open requirements questions before architecture and implementation. Each entry preserves the original question, why it matters, affected requirements, and source references, and adds the approved decision, rationale, expected product impact, and decision status. This preserves a complete audit trail from open question to closed decision.

## Decision Status

All questions in this document are resolved unless explicitly marked otherwise.

---

## 1. Authentication

### Q-001 — OTP Resend Cooldown Duration
**Status:** Resolved

**Original Question:**
What is the exact OTP resend cooldown duration? The mobile document suggests "e.g., 30s" but does not fix a value.

**Why it matters:**
Affects the resend-button behavior and messaging immediately after an OTP request; both cooldown length and behavior are user-visible.

**Decision:**
The OTP resend cooldown is **60 seconds**. This supersedes the "e.g., 30s" example in the mobile document and fixes the value.

**Product behavior:**
- Resend button is disabled for 60 seconds after an OTP request.
- Countdown is visible to the user.
- After 60 seconds, resend becomes available.

**Rationale:**
A one-minute cooldown provides a clear user experience for a non-technical audience and aligns with the intended OTP resend behavior.

**Product Impact:**
Fixes the resend cooldown for the OTP error/resend flow. Note: FR-AUTH-005 and BR-AUTH-003 currently state "(e.g., 30s)"; the next requirements refinement step should update them to 60 seconds.

**Affected Requirements:**
- FR-AUTH-004, FR-AUTH-005

**Source Reference:**
- user-flow-mobile.md — Section 1, step 3; Edge Cases (OTP not received)

---

### Q-002 — SMS Provider
**Status:** Resolved

**Original Question:**
Which SMS provider is used for delivering OTP codes? feature-list.md mentions "Supabase Phone Auth + SMS provider" without naming the provider.

**Why it matters:**
Determines delivery reliability, cost, and reachability in Egypt; affects OTP delivery times and the resend/support flow.

**Decision:**
Use **Supabase Phone Auth + Twilio** for OTP delivery. Twilio is the selected SMS provider and Supabase Phone Auth remains the authentication mechanism.

**Rationale:**
Twilio is the selected SMS provider for the project and Supabase Phone Auth remains the authentication mechanism. The choice addresses delivery reliability, cost, and reachability in Egypt.

**Product Impact:**
Names the SMS provider behind phone + OTP authentication, enabling the resend and "having trouble?" support flows to be built against the chosen channel.

**Affected Requirements:**
- FR-AUTH-001, FR-AUTH-003, FR-AUTH-005

**Source Reference:**
- feature-list.md — Authentication

---

## 2. Business and Account Model

### Q-003 — Session Expiry Policy
**Status:** Resolved

**Original Question:**
How long does a mobile session persist before it expires? feature-list.md and the flows say the user "stays logged in" and the session persists until logout, but no explicit timeout is defined.

**Why it matters:**
Determines security vs. convenience for a mobile-first, non-tech-savvy user; affects "stay logged in" behavior and re-authentication.

**Decision:**
Mobile sessions are **persistent until explicit logout**. There is no inactivity-based session timeout in the MVP.

**Product behavior:**
- User remains logged in between app launches.
- Session is refreshed through the authentication system.
- Explicit logout terminates the user's authenticated session.
- No custom inactivity timeout is introduced in the MVP.

**Rationale:**
The application is mobile-first and intended for frequent use by small business owners. Requiring repeated authentication would add unnecessary friction.

**Product Impact:**
Confirms the "stay logged in" behavior on mobile; no re-authentication between app opens unless the user logs out.

**Affected Requirements:**
- FR-AUTH-006, FR-AUTH-007

**Source Reference:**
- feature-list.md — Authentication
- user-flow-mobile.md — Section 1, step 1

---

### Q-004 — Web Login Method
**Status:** Resolved

**Original Question:**
Which web login method is used? The proposed approach is magic-link via an email linked from the mobile app. The document asks to flag an alternative approach (e.g., separate invite-only web login) before finalizing.

**Why it matters:**
This is a flagged open design decision that directly affects web login UX and the account-linking model.

**Decision:**
Use **Email Magic Link** for Web Dashboard authentication. The alternative separate invite-only web login is not adopted.

```text
Mobile App
   ↓
Enable Web Access
   ↓
Link / Verify Email
   ↓
Web Login
   ↓
Magic Link
   ↓
Dashboard
```

**Rules:**
- Web does not provide independent signup in MVP.
- The mobile application remains the source of account creation.
- Web access must first be enabled from the mobile application.

**Rationale:**
This provides a low-friction web login while preserving a single account/business ownership model.

**Product Impact:**
Confirms the proposed magic-link web login and rejects the separate invite-only web login alternative.

**Affected Requirements:**
- FR-WEB-AUTH-001, FR-WEB-AUTH-002, FR-SETTINGS-003

**Source Reference:**
- user-flow-dashboard.md — Section "Open design decision — Web login method"
- user-flow-mobile.md — Section 5, step 2

---

## 3. Transactions

### Q-005 — Manual Entry on Web in MVP
**Status:** Resolved

**Original Question:**
Is the web "Add Transaction" manual-entry button in scope for the MVP, or deferred to Phase 2? The document marks it optional/deferred.

**Why it matters:**
Determines whether the web dashboard can create transactions in the MVP or is view-only/edit-only.

**Decision:**
Manual "Add Transaction" from the Web Dashboard is **out of MVP**.

**MVP Web capabilities:**
Web supports:
- viewing transactions
- filtering
- searching
- editing transactions
- deleting transactions
- reports
- exports
- category management
- business settings

Web does **not** create new transactions in MVP.

**Rationale:**
Mobile remains the primary transaction-entry experience, while the dashboard acts as a companion management/reporting surface.

**Product Impact:**
Confirms the web dashboard is edit/manage-only and cannot create transactions in MVP; web manual entry remains a Phase 2 consideration.

**Affected Requirements:**
- FR-WEB-TRANS-001, FR-WEB-TRANS-005

**Source Reference:**
- user-flow-dashboard.md — Section 3, step 6

---

### Q-006 — Concurrent Edit Conflict Handling
**Status:** Resolved

**Original Question:**
How should concurrent edits to the same record from web and mobile be handled? The MVP uses "last write wins" with no special handling; real-time sync is a Phase 2 consideration.

**Why it matters:**
Determines acceptable MVP data behavior for a multi-device owner and whether Phase 2 must add sync/conflict resolution.

**Decision:**
Use **Last Write Wins** in MVP.

**Product behavior:**
If the same transaction is edited on Mobile and Web at approximately the same time, the latest successful write becomes the persisted value. No special conflict-resolution UI is required in MVP.

**Future:**
Real-time synchronization and conflict handling may be considered in Phase 2 if validated by actual usage.

**Rationale:**
Matches the MVP's stated last-write-wins behavior and keeps the MVP implementation simple; more complex synchronization is deferred pending real usage.

**Product Impact:**
Defines deterministic concurrency behavior for the multi-device owner in MVP; no conflict-resolution UI required.

**Affected Requirements:**
- FR-WEB-TRANS-005, BR-TRANS-006

**Source Reference:**
- user-flow-dashboard.md — Edge Cases & Error States

---

## 4. AI Extraction

### Q-007 — Which Gemini Model / Endpoint
**Status:** Resolved

**Original Question:**
Which Gemini model/version and endpoint is used for extraction? feature-list.md says "Gemini Vision API" only.

**Why it matters:**
Affects extraction quality, latency, cost, and the "few seconds" performance target.

**Decision:**
Use **Gemini 3.1 Flash-Lite** as the initial production model for receipt/invoice extraction.

**Architectural constraint:**
The model must be accessed through the server-side AI processing boundary. Do **not** expose the Gemini API key in Flutter.

**Rationale:**
The workload requires image understanding, structured extraction, low latency, cost efficiency, and high request volume potential. The selected model should therefore prioritize these characteristics.

**Important:**
This is a product-level model selection decision. Endpoint URLs, SDK configuration, and other implementation details are out of scope for this decision.

**Product Impact:**
Names the Gemini model used to extract receipt/invoice data; confirms the Gemini API key stays server-side and is never embedded in the Flutter app.

**Affected Requirements:**
- FR-AI-001, NFR-PERF-001

**Source Reference:**
- feature-list.md — AI Data Extraction; Stack — Non-Functional (Performance)

---

### Q-008 — Confidence Threshold Definition
**Status:** Resolved

**Original Question:**
How is a "low-confidence" field defined? feature-list.md allows "even a simple heuristic" for the confidence indicator, but no threshold is specified.

**Why it matters:**
Determines which fields get flagged for review and how extraction failure (low confidence on all fields) is decided.

**Decision:**
- **Field confidence < 80%** → flag field for user review.
- Treat extraction as **unsuccessful** when required information is missing **or** the overall extraction confidence is below **50%**.

**Product behavior:**
- Individual low-confidence fields are visually flagged.
- User remains able to edit every extracted field.
- If the extraction result is fundamentally unusable, route the user to manual entry.
- AI confidence never bypasses the user confirmation step.

**Rationale:**
Provides concrete thresholds for per-field flagging and for overall extraction failure, consistent with the "simple heuristic" allowance and the data-trust requirement.

**Product Impact:**
Determines exactly which fields are flagged for review and when a result is treated as unusable (routing to manual entry).

**Affected Requirements:**
- FR-AI-003, FR-AI-004, FR-AI-006

**Source Reference:**
- feature-list.md — AI Data Extraction

---

### Q-009 — What Counts as "Too Long" for Extraction Timeout
**Status:** Resolved

**Original Question:**
What timeout triggers the "extraction took too long" path? The flows require a timeout/error handling but do not define the threshold.

**Why it matters:**
Affects when a user sees the manual-entry fallback and the perceived responsiveness.

**Decision:**
Use **15 seconds** as the client-visible extraction timeout for MVP.

**Product behavior:**
If extraction has not produced a usable result within 15 seconds, show the extraction timeout message and offer "Enter manually instead". The user must never be trapped indefinitely in a loading state.

**Important:**
This is a user-experience timeout decision. It is distinct from infrastructure/network timeout configuration.

**Rationale:**
Sets a concrete, user-visible ceiling for the extraction loading state while preserving the "few seconds" performance target; the user always has a manual-entry escape.

**Product Impact:**
Defines the threshold at which the manual-entry fallback is offered, ensuring the loading state is never a dead end.

**Affected Requirements:**
- FR-AI-008, NFR-PERF-001

**Source Reference:**
- user-flow-mobile.md — Section 2, step 4

---

## 5. Categories

### Q-010 — Full List of Default Categories and Hiding Behavior
**Status:** Resolved

**Original Question:**
What is the complete, authoritative list of default categories? feature-list.md gives examples ("e.g., …") and user-flow-mobile.md says default categories "cannot be deleted, only hidden", but the exact list and how hiding works (visibility in pickers/filters/reports) is unspecified.

**Why it matters:**
Determines the taxonomy users see everywhere and how "hidden" default categories behave across the app.

**Decision:**
The default categories are:

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

**Default category rules:**
- Default categories are seeded for every business.
- Default categories cannot be permanently deleted.
- Users may hide a default category.
- Hidden categories remain valid for existing historical transactions.
- Hidden categories should not appear in normal category selection lists.
- Hidden categories should remain available when displaying historical transactions.
- Hidden categories should remain represented in reports when historical transactions use them.
- Hidden categories should remain available in filters when needed to access historical data.

**Custom categories:**
Users may create custom categories.

**Rationale:**
Provides the authoritative taxonomy relevant to small Egyptian retail/service businesses and clarifies exactly how hidden defaults behave in pickers, filters, reports, and history.

**Product Impact:**
Defines the complete category taxonomy and the hiding behavior used across the app (mobile and web).

**Affected Requirements:**
- FR-CATEGORY-001, FR-CATEGORY-005, FR-WEB-CATEGORY-003

**Source Reference:**
- feature-list.md — Categories
- user-flow-mobile.md — Section 5, step 2
- user-flow-dashboard.md — Section 5, step 4

---

## 6. Reports

### Q-011 — Cross-Platform Report Period Options
**Status:** Resolved

**Original Question:**
Mobile offers "This Week / This Month / Custom Range", while web offers "This Month / Last Month / Custom Range / Year-to-date". Should report periods be identical across platforms?

**Why it matters:**
Determines whether the explicit difference in period selectors between mobile and web is an intended product difference or an inconsistency to resolve.

**Decision:**
Use the **same report-period options on Mobile and Web**:

```text
This Week
This Month
Last Month
Year-to-Date
Custom Range
```

**Rationale:**
Using identical period semantics prevents inconsistencies between the mobile and dashboard experiences.

**Product Impact:**
Resolves the period-selector difference as an inconsistency. The unified set adds Last Month and Year-to-Date to mobile and This Week to web. Note: FR-DASH-004 and FR-WEB-REPORT-001 currently list the differing per-platform option sets; the next requirements refinement step should align them with the unified set.

**Affected Requirements:**
- FR-DASH-004, FR-WEB-REPORT-001

**Source Reference:**
- user-flow-mobile.md — Section 4, step 2
- user-flow-dashboard.md — Section 4, step 2

---

### Q-012 — Currency and Number Formatting
**Status:** Resolved

**Original Question:**
How are amounts and currency formatted for display in summaries, lists, and exports (e.g., decimals, Arabic numerals vs. Eastern Arabic numerals, EGP symbol placement)?

**Why it matters:**
Affects how monetary values render in Arabic (RTL) UI and exported PDF/CSV for accuracy and readability.

**Decision:**
MVP currency is **EGP only**.

**Display format:**
Use human-readable Egyptian Pound formatting with:
- thousands separators
- decimal precision when applicable
- currency label/symbol appropriate for Arabic UI

Recommended display example:

```text
1,250.50 ج.م
```

**Rules:**
- Financial calculations use numeric values, not formatted strings.
- Display formatting must be consistent across Mobile and Web.
- Exported numeric data should remain machine-readable where appropriate.
- Multi-currency is out of MVP scope.

**Rationale:**
Pins down a single consistent EGP display format for the Arabic (RTL) UI and exports, while keeping calculations numeric and multi-currency out of MVP scope.

**Product Impact:**
Defines how monetary values render across summaries, lists, and exports; confirms EGP-only for MVP.

**Affected Requirements:**
- FR-DASH-001, FR-WEB-DASH-002, FR-EXPORT-002, FR-EXPORT-003

**Source Reference:**
- feature-list.md — Authentication (default currency EGP); Dashboard & Reports (not detailed)

---

## 7. Export

### Q-013 — Export Report Content for Each Format
**Status:** Resolved

**Original Question:**
What precisely does the exported PDF and Excel/CSV contain (summary, category breakdown, transaction lines, date filters, etc.)? The documents define formats and the period, but not the exact content or structure.

**Why it matters:**
Determines whether the export satisfies the accountant use case and matches the user's chosen period/filters.

**Decision:**

**PDF** must contain:
1. Report period
2. Total income
3. Total expenses
4. Net
5. Category breakdown
6. Transaction list for the selected scope

The PDF is optimized for human reading and accountant sharing.

**Excel** should contain:

- **Sheet 1 — Summary**: selected period, income, expenses, net, category summary.
- **Sheet 2 — Transactions**: detailed transaction records.
- **Sheet 3 — Categories**: category totals for the exported scope.

**CSV** contains transaction-level data in a flat tabular structure suitable for import into other systems.

**Rationale:**
PDF is optimized for presentation/sharing, while Excel/CSV are optimized for analysis and raw data access.

**Product Impact:**
Defines the exact content and structure of each export format, satisfying the accountant use case.

**Affected Requirements:**
- FR-EXPORT-001, FR-EXPORT-002, FR-EXPORT-003, FR-WEB-REPORT-003

**Source Reference:**
- feature-list.md — Export
- user-flow-mobile.md — Section 4, step 3
- user-flow-dashboard.md — Section 4, step 4

---

### Q-014 — Export vs Current Filters
**Status:** Resolved

**Original Question:**
Does the exported report respect the currently applied filters (category, type, amount range) in addition to the period? The export "period defaults to the currently selected period", but filter propagation is unspecified.

**Why it matters:**
Determines whether exports reflect a filtered subset or the full period.

**Decision:**
Exports respect the **selected report period** plus the **currently applied filters**.

**Example:**
If the user selects:

```text
This Month
Category = Purchases
Type = Expense
```

the export contains only transactions matching that scope.

**Rationale:**
The exported file should reflect the dataset the user is currently analyzing.

**Product Impact:**
Defines that exports are scoped to both the period and the active filters, so a filtered subset exports exactly that subset.

**Affected Requirements:**
- FR-EXPORT-001, FR-EXPORT-002, FR-EXPORT-003

**Source Reference:**
- user-flow-mobile.md — Section 4, step 3

---

## 8. Web Access

### Q-015 — Web Access After Unlink
**Status:** Resolved

**Original Question:**
What happens to an already-signed-in web session when web access is unlinked? The dashboard notes the session should be invalidated on next request via RLS/auth, but the exact user experience is unspecified.

**Why it matters:**
Determines the unlink UX and consistency across devices.

**Decision:**
When Web Access is unlinked, existing web access becomes invalid.

**Expected behavior:**
On the next authenticated request:
- dashboard access is rejected
- user is returned to the login/access-disabled state
- user is informed that Web Access must be enabled again from the Mobile App

The existing authenticated web session does not need a special real-time disconnect mechanism in MVP.

**Rationale:**
Access is re-checked on the next authenticated request, so no real-time session termination is needed in MVP; this matches the RLS/auth-based invalidation approach.

**Product Impact:**
Defines the user experience after unlinking web access, consistent across devices.

**Affected Requirements:**
- FR-WEB-SETTINGS-002, BR-WEB-006

**Source Reference:**
- user-flow-dashboard.md — Section 6, step 3; Edge Cases

---

### Q-016 — Email Identity Linking Mechanics
**Status:** Resolved

**Original Question:**
How exactly is an email linked to a mobile (phone-auth) Supabase user when the owner enables web access? The mechanism is described conceptually, not fully specified.

**Why it matters:**
Determines the account-linking model and whether the magic-link login can reuse the existing Supabase user securely.

**Decision:**
The email address is linked to the existing authenticated Supabase user.

**User flow:**

```text
Mobile
 ↓
Authenticated user
 ↓
Enable Web Access
 ↓
Enter email
 ↓
Verify email
 ↓
Email becomes associated with the existing user
 ↓
Web Magic Link login
```

**Important rule:**
Do **not** create a second independent account for the email. The web identity must map back to the same business/account ownership.

**Rationale:**
Preserves a single account/business ownership model; the magic-link login reuses the existing Supabase user rather than creating a duplicate.

**Product Impact:**
Confirms the email is linked to the existing user (no second account), maintaining RLS isolation under the single-owner model.

**Affected Requirements:**
- FR-SETTINGS-003, FR-WEB-AUTH-001, FR-WEB-AUTH-002

**Source Reference:**
- user-flow-mobile.md — Section 5, step 2
- user-flow-dashboard.md — Section "Open design decision — Web login method"

---

## 9. Security

### Q-017 — Web Edit Create/Delete Permissions Scope
**Status:** Resolved

**Original Question:**
Does the web dashboard allow editing and deleting transactions in the MVP, and does this alter permissions relative to mobile? The dashboard details Edit and Delete for MVP, and notes a web "Add Transaction" may be deferred.

**Why it matters:**
Determines whether desktop edit/delete is intended in MVP and whether it changes how RLS/permissions are applied.

**Decision:**
For MVP:

```text
CREATE transaction → Mobile only
EDIT transaction → Mobile + Web
DELETE transaction → Mobile + Web
READ transaction → Mobile + Web
```

**Rationale:**
The dashboard is a management/reconciliation companion rather than a replacement for mobile transaction capture.

**Product Impact:**
Confirms web edit/delete in MVP while keeping transaction creation mobile-only; RLS applies the same owner-only isolation on both platforms.

**Affected Requirements:**
- FR-WEB-TRANS-005, FR-WEB-TRANS-006, BR-TRANS-005

**Source Reference:**
- user-flow-dashboard.md — Section 3, steps 5–6

---

## 10. UX / Product Decisions

### Q-018 — Offline Capture Handling (Phase 1 vs Phase 2)
**Status:** Resolved

**Original Question:**
When there is no internet during receipt capture, should the MVP queue locally ("will process when back online") or simply block capture with a clear message? The document explicitly leaves this as a Phase 1 vs Phase 2 scope decision.

**Why it matters:**
Determines MVP offline behavior, storage, and sync design; directly impacts real-world usability for shop owners with unreliable connectivity.

**Decision:**
Offline receipt capture is **out of MVP**.

**MVP behavior:**
When there is no network connection:
- do not queue receipt processing
- do not create an offline transaction pipeline
- display a clear message explaining that internet access is required
- allow the user to retry

**Future:**
Offline capture + synchronization may be introduced in Phase 2.

**Rationale:**
Offline queueing introduces synchronization, retries, conflict resolution, local persistence, and recovery complexity that is unnecessary for the initial validation of the product.

**Product Impact:**
Resolves the pending scope decision in favor of block-with-clear-message for MVP; offline capture remains a Phase 2 feature.

**Affected Requirements:**
- FR-CAPTURE-001 (capture), BR-MVP-004

**Source Reference:**
- user-flow-mobile.md — Edge Cases & Error States (No internet connection during capture)

---

### Q-019 — Empty State Copy and Design
**Status:** Resolved

**Original Question:**
What is the exact content and design of empty states for new businesses with zero transactions (Home, Transactions, Reports)? The dashboard suggests a message ("Add your first transaction from the mobile app") but no full spec.

**Why it matters:**
Determines the first-run experience and how a new user is guided to their first transaction.

**Decision:**
Use simple, action-oriented empty states.

**Mobile Home:**

```text
لا توجد معاملات بعد

ابدأ بتسجيل أول معاملة لنشاطك التجاري.
```

Primary CTA:

```text
إضافة معاملة
```

**Mobile Transactions:**

```text
لا توجد معاملات بعد

أضف أول عملية بيع أو شراء لبدء تسجيل نشاطك.
```

Primary CTA:

```text
إضافة معاملة
```

**Mobile Reports:**

```text
لا توجد بيانات كافية لعرض التقارير

أضف بعض المعاملات أولاً، وستظهر التقارير هنا.
```

**Web Dashboard:**

Use the same principle. Suggested copy:

```text
لا توجد معاملات بعد

أضف أول معاملة من تطبيق الهاتف لبدء متابعة نشاطك التجاري.
```

**Design principles:**
- never show an unexplained blank screen
- clearly explain why the state is empty
- provide a useful next action where appropriate
- keep copy short and Arabic-first

**Rationale:**
Guides the first-run experience for a new business with zero transactions, steering the user toward their first recorded transaction.

**Product Impact:**
Defines empty-state copy and design for Home, Transactions, and Reports on mobile and web, replacing blank/broken-looking screens.

**Affected Requirements:**
- FR-WEB-DASH-001, FR-WEB-TRANS-001, FR-WEB-REPORT-002

**Source Reference:**
- user-flow-dashboard.md — Edge Cases & Error States (New business with zero transactions)

---

### Q-020 — Image Quality Check Thresholds
**Status:** Resolved

**Original Question:**
What defines "blurry" or "too-dark" for the basic image quality check, and how aggressive is the retake prompt?

**Why it matters:**
Determines when users are warned and whether the check creates friction vs. too-lenient acceptance.

**Decision:**
Use an advisory quality-check model with three outcomes:

```text
PASS
WARNING
REJECT
```

**PASS:**
Image appears sufficiently usable for processing.

**WARNING:**
Image may be usable but has quality concerns such as:
- borderline darkness
- borderline blur
- poor framing

Allow the user to continue.

**REJECT:**
Image is clearly unusable, such as:
- extremely dark image
- effectively blank image
- image with no meaningful receipt content
- obviously unusable capture

Prompt the user to retake the image.

**Important:**
Do not use overly aggressive thresholds that reject potentially readable receipts. The image quality check is a user-assistance mechanism, not a strict guarantee that Gemini can read the receipt.

**Rationale:**
Balances friction against acceptance; the check advises the user (retake prompt on clear failures, continue on borderline) rather than enforcing a strict gate.

**Product Impact:**
Defines the image quality check behavior and the three outcome states for the capture flow.

**Affected Requirements:**
- FR-CAPTURE-005

**Source Reference:**
- feature-list.md — Receipt Capture

---

## 11. Technical Decisions That Affect Requirements

### Q-021 — Default vs Custom Category Rules
**Status:** Resolved

**Original Question:**
Is the mobile and web custom-category management fully in sync, and can a custom category be created that duplicates a hidden default? No guidance is given.

**Why it matters:**
Determines category integrity and whether hidden defaults and custom categories can overlap.

**Decision:**
Mobile and Web use the same category source of truth.

**Rules:**
- Categories are shared across platforms.
- Default categories are identifiable separately from custom categories.
- Default categories cannot be deleted.
- Default categories can be hidden.
- Custom categories can be created, edited, and deleted.
- A custom category cannot duplicate an existing default or custom category after normalization.
- Hidden defaults still exist for historical transactions.
- Category behavior must be consistent between Mobile and Web.

**Rationale:**
Keeps category management synchronized across platforms and prevents overlap or duplication that would compromise category integrity.

**Product Impact:**
Confirms full cross-platform category sync and adds a normalization rule so a custom category cannot duplicate any existing default or custom category.

**Affected Requirements:**
- FR-CATEGORY-003, FR-CATEGORY-004, FR-WEB-CATEGORY-002

**Source Reference:**
- feature-list.md — Categories
- user-flow-mobile.md — Section 5, step 2
- user-flow-dashboard.md — Section 5

---

### Q-022 — Transaction Search Scope
**Status:** Resolved

**Original Question:**
Is search limited to vendor/customer name only, or does it also search other fields (e.g., notes, category)? feature-list.md and both flows specify "search by vendor/customer name" without more.

**Why it matters:**
Determines the search index/behavior and what users can find.

**Decision:**
MVP transaction search is limited to **Vendor / Customer name**.

**Rules:**
Search does **not** include:
- notes
- categories
- arbitrary transaction fields
- full-text search
- OCR text

unless explicitly added in a future scope.

**Rationale:**
This preserves the behavior already defined by the product documentation and keeps MVP search simple.

**Product Impact:**
Confirms search matches only vendor/customer name on both mobile and web for MVP.

**Affected Requirements:**
- FR-TRANS-008, FR-WEB-TRANS-003

**Source Reference:**
- feature-list.md — Transaction List & Management
- user-flow-mobile.md — Section 3, step 2
- user-flow-dashboard.md — Section 3, step 4

---