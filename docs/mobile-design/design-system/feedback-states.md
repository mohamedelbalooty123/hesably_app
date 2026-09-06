# Feedback & States — Hesably Design System

**Purpose:** one unified status language across the app + the feedback-mechanism choices and the empty-state/loading systems. A given state looks and behaves identically everywhere (Principle 7).
**Sources:** `ux/ux-states.md` (taxonomy, copy), `ux/interaction-model.md` §2/§5, `components.md` (feedback components), `offline-patterns.md`, `ai-patterns.md`.

---

## 1. Unified status language

A **status** = icon + semantic color + label (badge/chip) + supporting text (optional) + interaction (retry / dismiss / none). No status is defined by color alone.

| Status | Icon | Color | Label style | Supporting text rule | Interaction |
|---|---|---|---|---|---|
| **success** | `check_circle` | `color.status.success` | success chip / toast | brief confirm | none (auto-dismiss toast) |
| **warning** | `warning_amber` | `color.status.warning` | warning chip / advisory | explains risk ("قد لا تُقرأ بدقة") | continue-or-retake (capture) |
| **error** | `error_outline` | `color.status.error` | error chip / inline | states the problem + fix | **retry** always |
| **info** | `info_outline` | `color.status.info` | info chip / neutral note | neutral explanation | optional dismiss |
| **pending** | `pending_actions`/`cloud_queue` | `color.pending` (violet) | pending chip | "في انتظار الاتصال…" | none (row action: sync) |
| **processing** | `hourglass_top`/`sync` | `color.syncing` (blue) | inline progress + label | "جارٍ المعالجة…" | none (uninterruptible except AI manual escape) |
| **syncing** | `sync` | `color.syncing` | syncing chip | "جارٍ المزامنة…" | none |
| **offline** | `cloud_off` | `color.offline` (slate) | persistent banner | "لا يوجد اتصال — تُعرض بيانات محفوظة" | manual refresh/none |
| **failed** | `sync_problem` | `color.status.error` | failed chip | "فشلت المزامنة" | **retry** |
| **retry** | `refresh` | `color.primary` | button/text link | before/after message | triggers retry |
| **review-required** | `rule`/`fact_check` | `color.review-required` (warning) | per-field advisory | "راجع المبلغ قبل الحفظ" | user edits the field |
| **confirmed** | `check_circle` (done) | `color.status.success` | success toast + refresh | — | none |
| **synced** | `cloud_done` | `color.status.success` | synced chip | "تمت المزامنة" | none |

**Cohesion rule:** the same status token set is the single source for chips, banners, toasts, inline notes, and dialogs. A "success synced" and a "success saved" share the same glyph/color family — the text differentiates.

**Reserved mapping:** `color.ai` belongs to AI surfaces only; `color.offline`/`color.pending`/`color.syncing` to offline/sync surfaces only. Status colors on data (income/expense) follow `financial-ui.md` — a transaction's **type** is not a **status**.

---

## 2. Feedback mechanism selection (least disruptive that works)

Ranked from least to most disruptive — choose the **lowest** that communicates:

1. **Inline (field-level)** — validation, low-confidence flag, per-field failure.
2. **Snackbar (transient)** — success outcomes, transient status (auto-dismiss 4s success / 10s important).
3. **Banner (persistent)** — persistent states (offline, web-access pending), dismissible.
4. **Dialog** — destructive/data-losing confirmations, the most important interruption (auto-dismiss never).
5. **Full-screen state** — ERROR/EMPTY/OFFLINE only when the surface can't render content; keep the previous frame where possible (state invariant #3).

| Situation | Mechanism |
|---|---|
| Field invalid | inline error (1) |
| AI low-confidence on a field | inline advisory (OVR-08) (1) |
| Save succeeded | snackbar (2) |
| Link sent (web access) | snackbar/inline success state (2) |
| Offline | persistent banner (3) |
| Delete confirm | dialog (4) |
| Account delete | dialog with typed confirm (4) |
| Load error with cached frame | banner + inline retry (3) |
| Load error, no frame | ERROR state (5) |

---

## 3. Inline errors

- Per-field, Arabic, actionable ("أدخل مبلغًا أكبر من صفر"). Appear on commit (blur/submit) + re-announced on resubmit.
- Never a single global banner for a field issue.
- An invalid field gets error border + message; the Send/Save still enabled? **No** — submit is blocked with inline message (no silent pass), per interaction-model §3.

## 4. Snackbar

- Auto-dismiss 4s (success) / 10s (important). Only for transient outcomes, never for validation or as error-notification on a live page.
- Appears above bottom nav / keyboard; success snackbar only after the user's own confirm (G4).

## 5. Banners

- Persistent offline banner on cached Home/Transactions/Reports: message + (no) action; never claims sync (BR-OFFLINE-003).
- Pending web-access banner ("تم إرسال الرابط — افتحه من بريدك") on SCR-16 success.
- Position: below app bar on the surface; not below content; must not obscure the FAB.

## 6. Dialogs

- Destructive + data-losing only (OVR-04/05/06/07). One affirmative; escape always.
- Confirm button is destructive-filled; states consequence; delete-account requires typed-match or explicit "حذف نهائي" (FR-SETTINGS-006).
- Never auto-dismiss; never two destructive buttons.

## 7. Empty states (reusable)

Copy anchors per `ux-states.md` §4; anatomy per `components.md` §Empty State. Table of empty-state surfaces + CTA:

| Surface | Icon dir | Title (anchor) | Supporting | Primary CTA | Secondary |
|---|---|---|---|---|---|
| Home, first time | flat ledger illustration (muted) | "ابدأ بأول معاملة" | "التقط صورة فاتورة أو أدخلها يدويًا" | FAB + hint | — |
| Transactions, none | ledger | "لا توجد معاملات بعد" | plain | "إضافة معاملة" (navigates via FAB) | "إدخال يدوي" |
| Transactions, filtered/none | magnifier | "لا توجد نتائج مطابقة — جرّب تعديل الفلاتر" | — | "مسح الفلاتر" | — |
| Search, none | magnifier list | "لا توجد نتائج لبحث اسم «{name}»" | — | "مسح البحث" | — |
| Reports, empty period | bar-chart soft | "لا توجد بيانات لهذه الفترة" | "غيّر الفترة وجرّب مجددًا" | "تغيير الفترة" | — |
| Categories, no customs | tag-plus | "لا توجد تصنيفات مخصصة — أضف واحدًا" | — | "إضافة تصنيف" | — |
| Pending, none | cloud-queue check | "لا توجد معاملات بانتظار المزامنة" | — | (auto-sync note) | — |
| Web access, not enabled | link | "فعّل الدخول من الويب" | step guidance | "إرسال رابط الدخول" | — |

- **Rules:** every empty state has an action (state invariant #2); illustrations stay muted/line-art, ≤120dp, `surface-variant`/`border` tones — they frame, never shout.
- **Anti-patterns:** illustration-first empty states hiding the CTA; confusing a no-matches empty with a no-data empty (different copy + different action); an empty state that looks like an error.

## 8. Loading system

| Wait | Pattern |
|---|---|
| < ~400ms | nothing (avoid flicker) |
| ≥ ~400ms, content surface (list/Home/Reports/Categories) | **skeleton** placeholders mirroring layout |
| Action-initiated (save/verify/send-link/export) | **inline determinate progress** + label ("جارٍ الحفظ…") |
| AI processing (≤15s) | dedicated processing card + ceiling + manual escape (see `ai-patterns.md`) |
| Image load (receipt viewer/thumb) | image placeholder + spinner (small) |
| Sync | per-pending-row inline progress (see `offline-patterns.md`) |

- **Blocking: avoid** full-screen spinners. A blocking modal is used only where the flow is genuinely uninterruptible (rare — e.g., account delete in-flight), and even then the system back must remain safe.
- Skeletons never shimmer wildly (slow pulse, 1.2s), no marquee sweeps.
- Every LOADING is bounded (state invariant #1): data calls ≤ few seconds → error-with-retry; AI 15s ceiling.
- Progress bars fill LTR even in RTL (renderer-fixed), per interaction-model §7.

**Anti-patterns:** permanent skeletons; spinners over content lists; a blocking overlay for a 500ms action; infinite AI waiting without the ceiling.

---

## 9. State invariants (from `ux-states.md`, restated for design)

1. Every LOADING bounded → error-with-retry.
2. EMPTY always carries an action.
3. ERROR keeps the previous frame where possible (cached/refresh).
4. In-flight buttons disabled + labeled; resolve to success or error.
5. AI states never block manual entry.
6. Offline captures are never lost silently (always in the Pending list with a retry path).