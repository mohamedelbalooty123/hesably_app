# UX States — Smart Invoice Assistant (Mobile)

**Purpose:** the complete state taxonomy for every surface — loading, empty, error, offline — plus the AI capture state machine and canonical Arabic/English copy for empty/error states.
**Screens:** per `screen-inventory.md`; overlays inherit the same state rules.

---

## 1. State taxonomy

Every screen can be in exactly one of these **primary states** at a time:

| State | Icon (concept) | Default copy anchor | When shown |
|---|---|---|---|
| **LOADING** | skeleton layout (no animated marquee) | — | Data fetch ≥ ~400ms |
| **CONTENT** | full data | — | Data available |
| **EMPTY** | simple illustration + message + action | "لا توجد معاملات بعد" (variant below) | No records for the scope |
| **NO-MATCHES** (list-only variant of EMPTY) | magnifier list | "لا توجد نتائج مطابقة للمعاملات المحددة" | Filters/search yield nothing |
| **ERROR** | broken-link icon + message + retry | "حدث خطأ في تحميل البيانات" | Fetch failed |
| **OFFLINE** | cloud-off icon + message | "لا يوجد اتصال بالإنترنت" | Network unavailable |
| **TRANSITIONAL** (per-flow) | progress w/ label | — | Multi-step flows (add, export, send-link) |

Sub-states (secondary, within CONTENT/ERROR only): **in-flight actions** (saving…, generating export…, sending link…), **validation** per-field, and **AI-flag** advisories (OVR-08).

---

## 2. AI capture state machine (Add flow)

The capture pipeline is the only machine-like flow. States and permitted transitions (no dead ends — G3):

```
IDLE (SCR-08 type chosen)
   │ choose camera/gallery/manual
   ▼
CAPTURED (image in memory) ──── quality check
   ├─ PASS ──────────────────────────────▶ PROCESSING
   ├─ WARNING (borderline) ── "متابعة على أي حال؟" ⟶ PROCESSING
   └─ REJECT ── guidance (“أعد التصوير…”) ⟶ CAPTURED (retake)  |  EXIT flow
PROCESSING (≤15s ceiling, FR-AI-007/008)
   ├─ SUCCESS ─▶ REVIEW (SCR-10). Fields <80% flagged (OVR-08); ≥50% but <100%, advisory; <50% overall → FAILURE
   ├─ FAILURE (structured) ── inline message ─▶ MANUAL (same form, empty) | RETRY
   ├─ TIMEOUT (>15s) ────────────────────▶ MANUAL | RETRY
   └─ NON-RECEIPT ── "ليست فاتورة" ──────▶ RETRY capture | MANUAL
REVIEW (SCR-10)
   ├─ SAVE ─▶ persisted (row+image) ─▶ SUCCESS toast ─▶ origin refreshed
   └─ EXIT with unsaved ─▶ OVR-07 (Keep editing / Discard)
```

**Offline (Q-018 flipped IN MVP, ADR-007):** when there is no connection, `CAPTURED` moves to a **device-local pending capture** instead of `PROCESSING` — AI is online-only. The pending-queue machine:

```
LOCAL_CAPTURED (image + type + optional metadata saved on-device)
   │  offline
   ▼
WAITING_FOR_NETWORK (in Pending list, "waiting for connection")
   │  manual "Sync now" and/or automatic on reconnect
   ▼
UPLOADING ─▶ PROCESSING_AI (re-enter the online machine at PROCESSING)
   │  FAILED (retryable) ─▶ WAITING_FOR_NETWORK
   ▼
READY_FOR_REVIEW ─▶ CONFIRMED (review/confirm)
   ├─ <80% confidence → REVIEW_REQUIRED flag
   └─ CONFIRMED ─▶ SYNCED (row + image persisted)
```

Pending captures are **device-local only**; they never survive account switch/logout (FR-OFFLINE-006), never sync to another account, and don't survive reinstall — surfaced honestly in the Pending list. AI never auto-persists (NFR-DATA-001).

Rules: PROCESSING is uninterruptible except the always-visible **manual escape**; every terminal failure state presents **retry** and/or **manual** as explicit actions (FR-AI-005/006/008/009, Q-008/Q-009).

---

## 3. Screen → state matrix

| Screen | LOADING | EMPTY | NO-MATCHES | ERROR | OFFLINE | Notes |
|---|---|---|---|---|---|---|
| SCR-01 Splash | brief route spinner | — | — | — | — | routes by session, never dead |
| SCR-02 Phone Entry | — | — | — | network error | message + retry | send-code wait = transitional |
| SCR-03 OTP | verify-in-flight | — | — | wrong code / expired | resend delayed | code errors inline |
| SCR-04 Business Setup | — | — | — | create error → retry | blocked | required fields |
| SCR-05 Home | skeleton cards | empty summary + FAB CTA | — | retry | cached read + banner | never black screen |
| SCR-06 Transactions | skeleton list | no-transactions empty | filtered no-match | retry | cached + banner | filter bar always visible |
| SCR-07 Detail | skeleton | (n/a — record-scoped) | — | "المعاملة غير موجودة" → back | image may not load | offline: text still readable |
| SCR-08 Type | — | — | — | — | — | static |
| SCR-09 Capture | camera init | — | — | permission / camera / gallery errors | local pending capture (Q-018 flipped) | quality rejects are guidance, not errors |
| SCR-10 Review & Save | prefill-in (AI) | — | — | save error → retry (form intact) | save deferred → pending (same form intact once online) | validation inline |
| SCR-11 Reports | skeleton | no-data-for-period | — | retry | cached + banner | period change re-enters LOADING |
| SCR-12 Settings | profile placeholder | — | — | retry | cached | static rows fine |
| SCR-13 Business Profile | — | — | — | save error | blocked | — |
| SCR-14 Categories | skeleton | no-customs hint | — | retry | — | defaults always listed |
| SCR-15 Category Form | — | — | — | save error | blocked | duplicate/reserved inline |
| SCR-16 Web Access | send-link in-flight | — | — | email/network error | blocked | success state after send |
| SCR-17 Receipt Viewer | image placeholder | — | — | "تعذر تحميل الصورة" + retry | image blocked | signed-URL refresh |

---

## 4. Canonical empty/error copy (Arabic primary, English secondary)

Used verbatim in states above (single source for translation).

| Context | Arabic | English (secondary) |
|---|---|---|
| Home, no transactions | لا توجد معاملات بعد — ابدأ بأول معاملة | No transactions yet — add your first one |
| Transactions, nothing at all | لا توجد معاملات بعد | No transactions yet |
| Transactions, filters → none | لا توجد نتائج مطابقة — جرّب تعديل الفلاتر | No matching results — try changing the filters |
| Search → none | لا توجد نتائج لبحث اسم «{name}» | No results for “{name}” |
| Reports, period has no data | لا توجد بيانات لهذه الفترة | No data for this period |
| Categories, no customs | لا توجد تصنيفات مخصصة — أضف واحدًا | No custom categories yet — add one |
| General load error | حدث خطأ في تحميل البيانات — إعادة المحاولة | Couldn’t load data — retry |
| General save error | حدث خطأ في الحفظ — راجع البيانات وأعد المحاولة | Couldn’t save — check and retry |
| Offline banner | لا يوجد اتصال بالإنترنت — تُعرض بيانات محفوظة | You’re offline — showing saved data |
| Capture offline → pending | تم الحفظ محليًا — ستُعالج عند توفر الإنترنت | Saved on this device — will process when you're back online |
| Pending sync | في انتظار الاتصال بالإنترنت | Waiting for connection |
| AI structured failure | لا يمكن قراءة بيانات الفاتورة بدقة — أدخلها يدويًا | Couldn’t read this receipt accurately — enter it manually |
| AI timeout | استغرق الاستخراج وقتًا طويلًا — أدخل البيانات يدويًا | Extraction took too long — enter manually |
| Non-receipt | يبدو أن الصورة ليست فاتورة — التقط صورة أوفى | This doesn’t look like a receipt — retake or enter manually |
| Receipt image not found | تعذر تحميل صورة الفاتورة | Couldn’t load the receipt image |
| Recording not found | المعاملة غير موجودة أو حُذفت | This transaction no longer exists |

---

## 5. State-transition rules (invariants)

1. **Every LOADING is bounded** — a 15s soft cap → error-with-retry (AI has its own 15s ceiling; data calls ≤ a few seconds).
2. **EMPTY always carries an action** (FR-DASH-… anchors at least: FAB or filter-clear), never a bare message.
3. **ERROR keeps the previous frame** when possible (cached/refresh-pattern) instead of replacing the screen with a blank error page.
4. **In-flight buttons are disabled + labeled** (no double submit) and always resolve to success or error.
5. **AI states never block manual entry** — the manual path is reachable from PROCESSING, FAILURE, TIMEOUT, and NON-RECEIPT.
6. **Offline captures are never lost silently** — a pending capture is always visible in a Pending/Captures list with a retry path ("Sync now"); account switch/logout purges it (FR-OFFLINE-006), surfaced in the list's copy.