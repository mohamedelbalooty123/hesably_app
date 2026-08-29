# Open Questions

This document collects all unanswered or ambiguous questions that must be resolved before implementation. These are questions the source documents do not fully answer. They are **not** resolved here; they remain open for product-owner/stakeholder decision.

---

## 1. Authentication

### Q-001 — OTP Resend Cooldown Duration
**Question:**
What is the exact OTP resend cooldown duration? The mobile document suggests "e.g., 30s" but does not fix a value.

**Why it matters:**
Affects the resend-button behavior and messaging immediately after an OTP request; both cooldown length and behavior are user-visible.

**Affected requirements:**
- FR-AUTH-004, FR-AUTH-005

**Source reference:**
- user-flow-mobile.md — Section 1, step 3; Edge Cases (OTP not received)

### Q-002 — SMS Provider
**Question:**
Which SMS provider is used for delivering OTP codes? feature-list.md mentions "Supabase Phone Auth + SMS provider" without naming the provider.

**Why it matters:**
Determines delivery reliability, cost, and reachability in Egypt; affects OTP delivery times and the resend/support flow.

**Affected requirements:**
- FR-AUTH-001, FR-AUTH-003, FR-AUTH-005

**Source reference:**
- feature-list.md — Authentication

---

## 2. Business and Account Model

### Q-003 — Session Expiry Policy
**Question:**
How long does a mobile session persist before it expires? feature-list.md and the flows say the user "stays logged in" and the session persists until logout, but no explicit timeout is defined.

**Why it matters:**
Determines security vs. convenience for a mobile-first, non-tech-savvy user; affects "stay logged in" behavior and re-authentication.

**Affected requirements:**
- FR-AUTH-006, FR-AUTH-007

**Source reference:**
- feature-list.md — Authentication
- user-flow-mobile.md — Section 1, step 1

### Q-004 — Web Login Method
**Question:**
Which web login method is used? The proposed approach is magic-link via an email linked from the mobile app. The document asks to flag an alternative approach (e.g., separate invite-only web login) before finalizing.

**Why it matters:**
This is a flagged open design decision that directly affects web login UX and the account-linking model.

**Affected requirements:**
- FR-WEB-AUTH-001, FR-WEB-AUTH-002, FR-SETTINGS-003

**Source reference:**
- user-flow-dashboard.md — Section "Open design decision — Web login method"
- user-flow-mobile.md — Section 5, step 2

---

## 3. Transactions

### Q-005 — Manual Entry on Web in MVP
**Question:**
Is the web "Add Transaction" manual-entry button in scope for the MVP, or deferred to Phase 2? The document marks it optional/deferred.

**Why it matters:**
Determines whether the web dashboard can create transactions in the MVP or is view-only/edit-only.

**Affected requirements:**
- FR-WEB-TRANS-001, FR-WEB-TRANS-005

**Source reference:**
- user-flow-dashboard.md — Section 3, step 6

### Q-006 — Concurrent Edit Conflict Handling
**Question:**
How should concurrent edits to the same record from web and mobile be handled? The MVP uses "last write wins" with no special handling; real-time sync is a Phase 2 consideration.

**Why it matters:**
Determines acceptable MVP data behavior for a multi-device owner and whether Phase 2 must add sync/conflict resolution.

**Affected requirements:**
- FR-WEB-TRANS-005, BR-TRANS-006

**Source reference:**
- user-flow-dashboard.md — Edge Cases & Error States

---

## 4. AI Extraction

### Q-007 — Which Gemini Model / Endpoint
**Question:**
Which Gemini model/version and endpoint is used for extraction? feature-list.md says "Gemini Vision API" only.

**Why it matters:**
Affects extraction quality, latency, cost, and the "few seconds" performance target.

**Affected requirements:**
- FR-AI-001, NFR-PERF-001

**Source reference:**
- feature-list.md — AI Data Extraction; Stack — Non-Functional (Performance)

### Q-008 — Confidence Threshold Definition
**Question:**
How is a "low-confidence" field defined? feature-list.md allows "even a simple heuristic" for the confidence indicator, but no threshold is specified.

**Why it matters:**
Determines which fields get flagged for review and how extraction failure (low confidence on all fields) is decided.

**Affected requirements:**
- FR-AI-003, FR-AI-004, FR-AI-006

**Source reference:**
- feature-list.md — AI Data Extraction

### Q-009 — What Counts as "Too Long" for Extraction Timeout
**Question:**
What timeout triggers the "extraction took too long" path? The flows require a timeout/error handling but do not define the threshold.

**Why it matters:**
Affects when a user sees the manual-entry fallback and the perceived responsiveness.

**Affected requirements:**
- FR-AI-008, NFR-PERF-001

**Source reference:**
- user-flow-mobile.md — Section 2, step 4

---

## 5. Categories

### Q-010 — Full List of Default Categories and Hiding Behavior
**Question:**
What is the complete, authoritative list of default categories? feature-list.md gives examples ("e.g., …") and user-flow-mobile.md says default categories "cannot be deleted, only hidden", but the exact list and how hiding works (visibility in pickers/filters/reports) is unspecified.

**Why it matters:**
Determines the taxonomy users see everywhere and how "hidden" default categories behave across the app.

**Affected requirements:**
- FR-CATEGORY-001, FR-CATEGORY-005, FR-WEB-CATEGORY-003

**Source reference:**
- feature-list.md — Categories
- user-flow-mobile.md — Section 5, step 2
- user-flow-dashboard.md — Section 5, step 4

---

## 6. Reports

### Q-011 — Cross-Platform Report Period Options
**Question:**
Mobile offers "This Week / This Month / Custom Range", while web offers "This Month / Last Month / Custom Range / Year-to-date". Should report periods be identical across platforms?

**Why it matters:**
Determines whether the explicit difference in period selectors between mobile and web is an intended product difference or an inconsistency to resolve.

**Affected requirements:**
- FR-DASH-004, FR-WEB-REPORT-001

**Source reference:**
- user-flow-mobile.md — Section 4, step 2
- user-flow-dashboard.md — Section 4, step 2

### Q-012 — Currency and Number Formatting
**Question:**
How are amounts and currency formatted for display in summaries, lists, and exports (e.g., decimals, Arabic numerals vs. Eastern Arabic numerals, EGP symbol placement)?

**Why it matters:**
Affects how monetary values render in Arabic (RTL) UI and exported PDF/CSV for accuracy and readability.

**Affected requirements:**
- FR-DASH-001, FR-WEB-DASH-002, FR-EXPORT-002, FR-EXPORT-003

**Source reference:**
- feature-list.md — Authentication (default currency EGP); Dashboard & Reports (not detailed)

---

## 7. Export

### Q-013 — Export Report Content for Each Format
**Question:**
What precisely does the exported PDF and Excel/CSV contain (summary, category breakdown, transaction lines, date filters, etc.)? The documents define formats and the period, but not the exact content or structure.

**Why it matters:**
Determines whether the export satisfies the accountant use case and matches the user's chosen period/filters.

**Affected requirements:**
- FR-EXPORT-001, FR-EXPORT-002, FR-EXPORT-003, FR-WEB-REPORT-003

**Source reference:**
- feature-list.md — Export
- user-flow-mobile.md — Section 4, step 3
- user-flow-dashboard.md — Section 4, step 4

### Q-014 — Export vs Current Filters
**Question:**
Does the exported report respect the currently applied filters (category, type, amount range) in addition to the period? The export "period defaults to the currently selected period", but filter propagation is unspecified.

**Why it matters:**
Determines whether exports reflect a filtered subset or the full period.

**Affected requirements:**
- FR-EXPORT-001, FR-EXPORT-002, FR-EXPORT-003

**Source reference:**
- user-flow-mobile.md — Section 4, step 3

---

## 8. Web Access

### Q-015 — Web Access After Unlink
**Question:**
What happens to an already-signed-in web session when web access is unlinked? The dashboard notes the session should be invalidated on next request via RLS/auth, but the exact user experience is unspecified.

**Why it matters:**
Determines the unlink UX and consistency across devices.

**Affected requirements:**
- FR-WEB-SETTINGS-002, BR-WEB-006

**Source reference:**
- user-flow-dashboard.md — Section 6, step 3; Edge Cases

### Q-016 — Email Identity Linking Mechanics
**Question:**
How exactly is an email linked to a mobile (phone-auth) Supabase user when the owner enables web access? The mechanism is described conceptually, not fully specified.

**Why it matters:**
Determines the account-linking model and whether the magic-link login can reuse the existing Supabase user securely.

**Affected requirements:**
- FR-SETTINGS-003, FR-WEB-AUTH-001, FR-WEB-AUTH-002

**Source reference:**
- user-flow-mobile.md — Section 5, step 2
- user-flow-dashboard.md — Section "Open design decision — Web login method"

---

## 9. Security

### Q-017 — Web Edit Create/Delete Permissions Scope
**Question:**
Does the web dashboard allow editing and deleting transactions in the MVP, and does this alter permissions relative to mobile? The dashboard details Edit and Delete for MVP, and notes a web "Add Transaction" may be deferred.

**Why it matters:**
Determines whether desktop edit/delete is intended in MVP and whether it changes how RLS/permissions are applied.

**Affected requirements:**
- FR-WEB-TRANS-005, FR-WEB-TRANS-006, BR-TRANS-005

**Source reference:**
- user-flow-dashboard.md — Section 3, steps 5–6

---

## 10. UX / Product Decisions

### Q-018 — Offline Capture Handling (Phase 1 vs Phase 2)
**Question:**
When there is no internet during receipt capture, should the MVP queue locally ("will process when back online") or simply block capture with a clear message? The document explicitly leaves this as a Phase 1 vs Phase 2 scope decision.

**Why it matters:**
Determines MVP offline behavior, storage, and sync design; directly impacts real-world usability for shop owners with unreliable connectivity.

**Affected requirements:**
- FR-CAPTURE-001 (capture), BR-MVP-004

**Source reference:**
- user-flow-mobile.md — Edge Cases & Error States (No internet connection during capture)

### Q-019 — Empty State Copy and Design
**Question:**
What is the exact content and design of empty states for new businesses with zero transactions (Home, Transactions, Reports)? The dashboard suggests a message ("Add your first transaction from the mobile app") but no full spec.

**Why it matters:**
Determines the first-run experience and how a new user is guided to their first transaction.

**Affected requirements:**
- FR-WEB-DASH-001, FR-WEB-TRANS-001, FR-WEB-REPORT-002

**Source reference:**
- user-flow-dashboard.md — Edge Cases & Error States (New business with zero transactions)

### Q-020 — Image Quality Check Thresholds
**Question:**
What defines "blurry" or "too-dark" for the basic image quality check, and how aggressive is the retake prompt?

**Why it matters:**
Determines when users are warned and whether the check creates friction vs. too-lenient acceptance.

**Affected requirements:**
- FR-CAPTURE-005

**Source reference:**
- feature-list.md — Receipt Capture

---

## 11. Technical Decisions That Affect Requirements

### Q-021 — Exact Default Categories Scope vs. Custom Categories
**Question:**
Is the mobile and web custom-category management fully in sync, and can a custom category be created that duplicates a hidden default? No guidance is given.

**Why it matters:**
Determines category integrity and whether hidden defaults and custom categories can overlap.

**Affected requirements:**
- FR-CATEGORY-003, FR-CATEGORY-004, FR-WEB-CATEGORY-002

**Source reference:**
- feature-list.md — Categories
- user-flow-mobile.md — Section 5, step 2
- user-flow-dashboard.md — Section 5

### Q-022 — Transaction Search Scope
**Question:**
Is search limited to vendor/customer name only, or does it also search other fields (e.g., notes, category)? feature-list.md and both flows specify "search by vendor/customer name" without more.

**Why it matters:**
Determines the search index/behavior and what users can find.

**Affected requirements:**
- FR-TRANS-008, FR-WEB-TRANS-003

**Source reference:**
- feature-list.md — Transaction List & Management
- user-flow-mobile.md — Section 3, step 2
- user-flow-dashboard.md — Section 3, step 4
