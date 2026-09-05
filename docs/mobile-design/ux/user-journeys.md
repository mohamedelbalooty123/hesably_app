# User Journeys — Smart Invoice Assistant (Mobile)

**Purpose:** end-to-end scenarios that validate the IA/navigation/strategy choices. Each journey lists steps, touchpoints (SCR/OVR), the target UX goal (G1–G7 from `ux-strategy.md`), and acceptance anchors.
**Conventions:** "→" is a user tap/gesture; screens per `screen-inventory.md`.

---

## J1 — First run: sign-up + first transaction

1. Install → open → Splash (SCR-01) → no session (FR-AUTH-007).
2. Phone Entry (SCR-02): enters `+20…` → "إرسال الكود" (FR-AUTH-001/002).
3. OTP (SCR-03): receives code, enters it, verify succeeds (FR-AUTH-003).
4. Business Setup (SCR-04): name + type → save (FR-ONBOARD-001…005).
5. Home (SCR-05): sees empty state + FAB.
6. FAB → Type (SCR-08) → choose expense → Capture (SCR-09) → snaps a receipt.
7. Quality check passes → AI processing (≤15s) → Review (SCR-10) pre-filled → adjusts amount → Save.
8. Success toast → Home now shows the entry and this month's summary.

**Goal:** G1 ✓ | **Acceptance anchors:** AC-AUTH, AC-ONBOARD, AC-CAPTURE, AC-REVIEW-00/01.

---

## J2 — Returning user records a quick income (persistent session)

1. Open app → Splash → Home directly (Q-003, FR-AUTH-006/007). No login.
2. FAB → إضافة معاملة → type "مبيعات" → snap → review → save.
3. Home summary updates instantly (refreshed after save).

**Goal:** G2, G5 | **Anchor:** AC-AUTH-006, AC-DASH.

---

## J3 — AI extraction: low confidence on amount

1. Capture → AI returns pre-filled form, **amount** confidence 73%.
2. SCR-10 shows the flagged field with OVR-08 advisory ("راجع المبلغ قبل الحفظ").
3. User verifies/corrects the amount → Save; confirmation persists the corrected value (FR-REVIEW-002, FR-AI-003/004, Q-008).

**Goal:** G3, G4 | **Anchor:** AC-AI-…, AC-CAPTURE-04/05 (review).

---

## J4 — AI extraction: failure → manual fallback

1. Capture → AI processing → structured failure (FR-AI-005/006) or >15s timeout (FR-AI-008).
2. SCR-09 shows inline error + "إدخال يدوي".
3. User taps manual → SCR-10 empty form → fills amount/date/category → Save.
4. No image attached (or optional attach) — record saves without receipt (transaction-contracts §1).

**Goal:** G3 | **Anchor:** AC-AI-…, AC-CAPTURE-…

---

## J5 — AI extraction: non-receipt image detected

1. User photographs a non-document (FR-AI-009).
2. SCR-09 shows "لا يمكن قراءة هذه الصورة كفاتورة…" → retake OR manual.
3. User retakes; capture flow continues normally.

**Goal:** G3 | **Anchor:** AC-AI-008/009, Q-015.

---

## J6 — Find & fix: locate an old expense and correct it

1. Transactions (SCR-06) → filter by category "مشتريات" + date range "last month" (FR-TRANS-004/005).
2. Search "محمود" (vendor name, Q-022) — debounced results (FR-TRANS-008).
3. Opens Detail (SCR-07) — read-only (FR-TRANS-010) → Edit → SCR-10 → changes amount → Save (FR-TRANS-011).
4. Returns to Detail refreshed; list retains its filters (navigation-map §4).

**Goal:** G5 | **Anchor:** AC-TRANS-…, AC-REVIEW-03/04.

---

## J7 — Delete a mistaken transaction

1. Detail (SCR-07) → Delete → OVR-04 describes the exact record.
2. Confirm → record removed (FR-TRANS-012/013) → list refreshed.
3. No undo/trash (BR-TRANS-004); the dialog is the safeguard.

**Goal:** G7 | **Anchor:** AC-TRANS-…

---

## J8 — Deeper: get this month's net at a glance

1. Home (SCR-05) shows income/expense/net cards for the current month (FR-DASH-001…003).
2. Taps the breakdown → Transactions with that month's date filter applied (context preserved).
3. Taps Reports tab → Reports (SCR-11).

**Goal:** G5 | **Anchor:** AC-DASH.

---

## J9 — Period report + export to the accountant

1. Reports (SCR-11) → chooses "Last Month" (Q-011) → view summaries + category breakdown (FR-DASH-004…007).
2. Taps Export (OVR-02) → PDF → share to WhatsApp/email (FR-EXPORT-004).
3. Export matches the visible period + filters (Q-014).

**Goal:** G5 | **Anchor:** AC-REPORT, AC-EXPORT-01/02.

---

## J10 — Custom period report

1. Reports → period selector → Custom → OVR-03 date-range picker → picks start/end.
2. Reports re-renders for the range; export (if any) honors it (FR-DASH-004…007, report-contracts §7).

**Goal:** G5 | **Anchor:** AC-REPORT-03/04.

---

## J11 — Trim categories (customs)

1. Settings (SCR-12) → Data → Categories (SCR-14).
2. Adds custom "نقل البضاعة" (SCR-15) — appears in picker (suggested by AI later).
3. Hides unused default "تسويق" (toggle) — no longer in new-selection lists, history intact (Q-010, BR-CATEGORY-004).
4. Deletes an unused custom → confirmation.

**Goal:** G5 | **Anchor:** AC-CATEGORY.

---

## J12 — Enable web access from the store

1. Settings → Access → Web access (SCR-16) → enters email "me@…" → "إرسال رابط الدخول" (FR-SETTINGS-003, Q-016).
2. Opens the email link from the same phone/laptop → dashboard signs in via magic link (web-access-contract §3).
3. Later revokes from the same screen (unlink → confirm) (BR-WEB-006).

**Goal:** G5 | **Anchor:** AC-SETTINGS-02, AC-WEB.

---

## J13 — No-internet moment outside the capture flow

1. User opens the app offline from an area with no cached state → Home shows graceful offline banner; cached summary still visible if available (offline capture remains out of scope, Q-018).
2. Tapping capture → clear "يلزم اتصال بالإنترنت" message + retry (offline is not a dead end for *stored* data; capture itself is blocked by design).

**Goal:** G3 | **Anchor:** AC-MISC (offline), Q-018.

---

## J14 — Account shutdown (logout / delete)

1. **Logout:** Settings → Safety → Logout (OVR-06) → confirm → Phone Entry (SCR-02). Next open requires a code again (session cleared).
2. **Delete account:** Settings → Safety → Delete Account (OVR-05) → typed/data-scope confirmation → admin delete via Edge Function (FR-SETTINGS-006) → Phone Entry → data gone by design.

**Goal:** G7 | **Anchor:** AC-SETTINGS-05/06, auth-contracts §2.5.

---

## Journey-to-screen coverage matrix

| Journey | Screens used | Goals |
|---|---|---|
| J1 | SCR-01,02,03,04,05,08,09,10 | G1,G2 |
| J2 | SCR-05,08,09,10 | G2,G5 |
| J3 | SCR-09,10; OVR-08 | G3,G4 |
| J4 | SCR-09,10 | G3 |
| J5 | SCR-09 | G3 |
| J6 | SCR-06,07,10 | G5 |
| J7 | SCR-07; OVR-04 | G7 |
| J8 | SCR-05,06,11 | G5 |
| J9 | SCR-11; OVR-02 | G5 |
| J10 | SCR-11; OVR-03 | G5 |
| J11 | SCR-12,13,14,15 | G5 |
| J12 | SCR-12,16 | G5 |
| J13 | SCR-05,09 (blocked) | G3 |
| J14 | SCR-12; OVR-05,06 | G7 |