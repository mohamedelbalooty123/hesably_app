# Navigation Map — Smart Invoice Assistant (Mobile)

**Purpose:** the single reference for how screens connect, how the back stack behaves, and how routing guards sign-in/onboarding.
**Screen IDs:** `SCR-xx` from `screen-inventory.md`; overlays `OVR-xx` (non-route surfaces).

---

## 1. Global navigation shell

Four bottom-nav destinations + one global action (the Home FAB). **Tab identity is state, not stack:** switching tabs replaces the visible destination and never loses form state elsewhere (finished flows return to their origin tab).

```
Right edge (RTL start)                                    Left edge
   [ الرئيسية ]  [ المعاملات ]  [ التقارير ]  [ الإعدادات ]
      Home         Transactions   Reports       Settings
```

- Home (SCR-05) hosts the primary action button (**+ إضافة معاملة**, FAB).
- Transactions (SCR-06), Reports (SCR-11), Settings (SCR-12) are the other destinations.
- The FAB is the only global action; it is not part of the tab bar (trade-off recorded in `ux-strategy.md` §7).

---

## 2. Sign-in / onboarding routing (guard precedence)

```
App open → Splash (SCR-01)
   ├─ no session           → Phone Entry (SCR-02) → OTP (SCR-03)
   │                          └─ first login only → Business Setup (SCR-04) → Home (SCR-05)
   └─ has session          → Home (SCR-05)
   └─ session expired      → Phone Entry (SCR-02)   (FR-AUTH-007, Q-003)
```

Rules:
- Session check happens on every cold open of the app (FR-AUTH-007). Persistent session → straight Home (Q-003).
- First successful login (no `businesses` row) forces Business Setup once; returning users skip it (auth-contracts §2.3, FR-ONBOARD-001).
- Logout (SCR-12 → OVR-06) and account deletion (OVR-05) reset the stack to Phone Entry.
- Deep-link/web surface: none in MVP — the app owns the full flow.

---

## 3. Add-transaction flow (global task flow)

Entry is the Home FAB (one tap). The flow is **full-screen, finishes and returns to the origin tab** (Home by default).

```
Home FAB
  → SCR-08 Transaction Type: مبيعات/إيرادات OR مشتريات/مصروفات
  → SCR-09 Capture:
        • camera → photo → on-device quality check
              PASS → proceed | WARNING (borderline) → optional continue | REJECT → retake guidance (FR-CAPTURE-005, Q-020)
        • gallery → photo picked → same checks
        • "إدخال يدوي" (Enter manually) → skip AI → SCR-10 empty form (FR-CAPTURE-007)
        • OFFLINE (Q-018 flipped, ADR-007) → save locally as pending capture → Pending list ("waiting for connection"); sync now / auto-on-reconnect
  → (if photo) AI Processing state (in-flow) → 15s visible ceiling (Q-009)
        • success           → SCR-10 pre-filled; <80% fields flagged (Q-008)
        • structured failure → inline message + "Enter manually instead" (FR-AI-005/006)
        • timeout (>15s)     → inline message + "Enter manually instead" (FR-AI-008)
        • non-receipt        → "Couldn't read this as a receipt…" + retry / manual (FR-AI-009)
  → SCR-10 Review & Save:
        • Save → confirm-then-persist (row → image → receipt) → success toast → back to Home, refreshed
        • Save while offline → deferred as pending capture (device-local), restored on reconnect
        • Back with unsaved edits → OVR-07 discard confirmation
```

Back behavior:
- **Back** from Capture (SCR-09) → returns to type select (SCR-08) — preserves user's type choice.
- **Back** from Type select (SCR-08) → exits flow to origin tab; no data to lose.
- **Back** from Review & Save (SCR-10) with any edited/pre-filled values → **OVR-07** discard confirmation (avoid silent data loss of a just-captured receipt).

---

## 4. Browse → Detail → Edit / Delete

```
Transactions tab (SCR-06): filters + search + grouped chronological list
   → row tap → SCR-07 Transaction Detail (read-only default, FR-TRANS-010)
        • Edit → SCR-10 (same form, pre-filled from record) → Save → return to Detail refreshed
        • Delete → OVR-04 confirmation → list refreshed (FR-TRANS-012/013)
        • receipt thumbnail tap → SCR-15 full-screen Receipt Viewer (modal)
```

- Detail and Edit preserve **tab context**: after save, you return to the list with active filters intact (they are carried in the tab's state).
- Back from Detail → Transactions list. Edit is a push, not a replace (system back returns to the review form's parent, not the list).

---

## 5. Reports → Export

```
Reports tab (SCR-11): period selector (This Week / This Month / Last Month / Year-to-Date / Custom Range)
   → Export (OVR-02): format (PDF / Excel / CSV) + period (defaults to current selection, Q-014)
   → generate client-side → share sheet (FR-EXPORT-004)
   → Custom Range → OVR-03 date-range picker → Reports view re-renders
```

- Period and filter state is **view state**, shared with the web's URL-param equivalent conceptually (see report-contracts §7) — mobile keeps it in memory; no deep links.
- Export options sheet does not require a second period pick when the user already chose one (defaults to current).

---

## 6. Settings sub-navigation

```
Settings tab (SCR-12)
   → Business Profile (SCR-13) → Save → back to Settings
   → Manage Categories (SCR-14)
        • new / rename custom → SCR-15 (or sheet) → back to list
        • hide/unhide default → toggle directly in list
        • delete unused custom → OVR confirmation (FK RESTRICT friendly error if in use)
   → Enable Web Access (SCR-16) → email → link → confirmation state (FR-SETTINGS-003)
   → Language toggle (in Settings row, applies immediately)
   → Logout (OVR-06)
   → Delete Account (OVR-05) → confirmation with data-loss warning → admin delete → Phone Entry
```

---

## 7. Back-stack rules (uniform)

| Event | Behavior |
|---|---|
| System back on a tab destination | Exit app (standard Android behavior on the root of the stack) |
| System back in a pushed detail/sub-page | Pop to previous; preserve the source tab's filters/scroll |
| System back mid-capture-flow | Per §3: type choice preserved; unsaved review data guarded by OVR-07 |
| System back on a modal/Screen-full (Receipt Viewer, sheets) | Dismiss the overlay only |
| Home FAB while a flow is already open | Not reachable (flow is full-screen); FAB is only on Home |
| Push while a bottom sheet is open | Sheets block interaction; must be dismissed first |

Back handling must never break the platform back button (ux guideline — Navigation/Back Button). On Android this means the flow is a proper back-stack push, not `replace`.

---

## 8. Navigation invariants (acceptance-checkable)

1. Add is reachable in **one tap** from Home (G2).
2. Every capture pipeline outcome reaches a **new user action** (G3) — no state is terminal without an action.
3. No toast "saved" precedes the user's own confirm (G4).
4. All four tab labels + FAB + type labels match the labeling table in `information-architecture.md` §5.
5. Returning-user cold open lands on Home (Q-003); session expiry routes to Phone Entry.