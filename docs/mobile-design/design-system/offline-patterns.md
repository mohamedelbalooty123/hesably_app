# Offline Patterns — Hesably Design System

**Purpose:** visual + interaction rules for offline capture with deferred sync (MVP-scope only: **capture + sync**, per Q-018 flipped and ADR-007). Offline AI, upload, reports, and cross-device sync stay online-only.
**Sources:** `change-management/offline-mvp-change-impact.md` (§1 scope, §7 ADR-007), `change-management/post-change-consistency-matrix.md`, `feature-list.md` (§4 offline), `ux/ux-states.md` (OFFLINE/PENDING/SYNCING states), `feedback-states.md` (§ statuses), `ux/screen-inventory.md` (SCR-01/05 Home, FAB).

---

## 1. Scope guard (what offline means visually)

- **In scope:** camera/gallery capture with no internet → local pending → **deferred sync** (upload + AI) when online; pending queue always visible with a retry path; pending never auto-confirmed.
- **Out of scope visuals:** do NOT design offline reports, offline search-over-remote, offline AI processing, or an offline-export flow. If a surface can't work offline, use the standard offline treatment (banner + locked action with "يتطلب اتصالًا"), never a fake local copy.

## 2. Offline persistence banner

Anatomy per `feedback-states.md` §5 banners.

| Aspect | Spec |
|---|---|
| Position | top of surface under the app bar (Home/Transactions/Reports); never over the FAB |
| Content | `cloud_off` + "لا يوجد اتصال بالإنترنت — تُعرض البيانات المحفوظة فقط" |
| Behavior | persistent while offline; **no sync claim** (BR-OFFLINE-003) |
| Reading | `text-on-surface` on `color.offline` container (slate) — reserved; see `color-system.md` |
| Edge | appears on surfaces where the user might expect live data; does **not** appear inside the capture flow (there it's the local-save path, not an error) |

**Anti-patterns:** an offline banner styled like an error; an offline banner that offers a "retry" that pings a dead network continuously; claiming "قيد المزامنة" while actually offline.

## 3. Pending queue

- **Entry + count:** Home shows a **pending row/entry point**: chip `pending_actions` + "بانتظار المزامنة" + count badge (`text-on-primary` filled circle 18-20dp). Tapping opens the **Pending list** (surface within Transactions region or a dedicated section, per change-analysis entry).
- **Row anatomy:** receipt thumbnail, date/capture-time, "بانتظار الاتصال" (`color.pending` chip — violet), and a **retry** action for failed rows.
- **Persistence:** the queue survives app restarts *by design* — a capture lost silently is the #1 forbidden outcome (state invariant #6).
- **Anti-patterns:** pending rows that look like ordinary transactions (they are NOT in the ledger yet); an automatically clearing queue without user action.

## 4. Capture flow while offline

- Entering the **FAB (capture)** while offline: **no error dialog**. The flow continues (local capture is the point of the MVP offline scope). A quiet offline hint chip ("ستُحفظ محليًا وتُزامن لاحقًا") shows in the capture screen so the user knows there's no AI now.
- After capture (no AI while offline): **Review screen (SCR-10) still appears for local-only save** — the user edits and confirms locally; the record is **stored with pending status** (BR-OFFLINE offline save is allowed — user explicitly confirmed local values). Show a `color.pending` chip **"بانتظار المزامنة (لن يُرسل للإنترنت الآن)"** on that confirmation screen.
- Confirmed-while-offline is **not** "synced/confirmed online status" — the Pending chip remains until an actual successful sync.
- **Anti-patterns:** a "save offline" modal interrupting the capture; claiming "تم الحفظ والمزامنة" on a local-only save; hiding the local save behind a "you'll lose it" warning that suggests dropping the capture.

## 5. Sync behavior (deferred, online moment)

- When connectivity returns: the queue syncs **per-row**, not one big blocking job. Each pending row shows its own state inline:
  - `PENDING` → `SYNCING` (blue `sync` + "جارٍ المزامنة…") → `CONFIRMED` (success toast; row leaves the pending surface) or `FAILED` (error chip + **retry**).
- **Per-row failure is non-blocking:** one failed row never blocks the rest.
- After upload, AI processing re-enters the standard **PROCESSING → REVIEW** machine (see `ai-patterns.md` §8): the synced item appears in the AI-process queue, user reviews and confirms → only then does it reach the ledger. **Result: user "local confirm" is for local bookkeeping trust; the AI review is for the extraction; both doors must open.** (BR-OFFLINE-004).
- **Anti-patterns:** a single giant "sync all" spinner over the queue; a sync whose failure marks the local record as deleted; AI output auto-applied to a synced pending record.

## 6. Failed sync / retry

- Failed rows: `sync_problem` + "فشلت المزامنة — أعد المحاولة" + **retry** button per row; a **"إعادة المحاولة الكل"** secondary action available at queue level.
- Failure keeps the local data (never destructive to local value). Dark-on-dark edge covered (see motion/color guidance).
- **Anti-patterns:** distinguishing "sync failed" from "network down" by color only (both are retryable → both carry retry).

## 7. Surfaces that require online (locked states)

| Surface | Offline visual | Action |
|---|---|---|
| AI processing (new capture) | not reachable (see §4) | offline hint chip |
| Reports (remote data) | offline banner; data is already cached **read-only**; report generation (export) disabled with tooltip "التصدير يتطلب اتصالًا" | Re-enable on reconnect |
| Export / share | disabled + note "التصدير يتطلب اتصالًا" (FR-OFFLINE-008-adjacent) | retry on reconnect |
| Web access settings | "يُرسل عند توفر اتصال" (deferred send, no false success) | re-send on reconnect |
| Search over remote records | works on cached data only; no infinite spinner | banner + "النتائج تُعرض من المحفوظ فقط" |

**Anti-patterns:** a disabled state with no explanation; a "coming soon when online" that hides the standard offline banner; silent empty search results while offline.

## 8. Cross-device note

- Offline capture never implies cross-device availability (out of MVP scope — ADR-007). The **web dashboard** may show the pending marker on records not yet sync-confirmed (consistency matrix status per change-management). Design guides the mobile markers first; dashboard companions reuse the same chips/tokens.

## 9. Offline/sync token usage recap

Use `color.offline` (slate) for *network absence*, `color.pending` (violet) for *waiting*, `color.syncing` (blue) for *in flight*, success/error for terminal outcomes. Never use offline/pending colors to describe an AI state (ai-patterns §8) and never swap them for status colors.

## 10. Consolidated checklist (design gate)

- [ ] Every offline capture reaches the visible Pending queue with a retry path.
- [ ] No sync/confirm claim until a real online sync succeeds.
- [ ] 15s/blocking semantics never apply offline; AI states re-enter the standard machine on reconnect.
- [ ] One failed row doesn't block the queue.
- [ ] Online-only surfaces are disabled with explanation, not faked.
- [ ] Offline ≠ error visuals; offline = its own quiet slate language.