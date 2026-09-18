# Interaction Model — Smart Invoice Assistant (Mobile)

**Purpose:** the behavioral contract for every tap, gesture, keyboard input, and system event — grounded in the mobile UX guidelines and the low/mid-spec Android target.
**Applies to:** all `SCR-xx` / `OVR-xx` surfaces.

---

## 1. Touch & layout baseline

| Rule | Spec | Rationale |
|---|---|---|
| Minimum touch target | **48×48dp** for all primary actions; tertiary/inline (toasts avoid tappability) may drop to 44dp but never below | Material guideline at Android's 48dp; 44pt iOS equivalent |
| Gap between interactive neighbors | ≥ **8dp** | Prevents adjacent-tap errors (guideline: 8px gap) |
| Position of critical actions | Bottom half of the screen; FAB bottom-right in RTL-agnostic terms → bottom-*start* edge flip; primary "Save"/"Confirm" on the **left** in RTL (mirror of LTR "right") | Single-handed thumb reach; RTL mirror |
| Safe areas / gestures | System back gesture and nav-bar respected; content avoids the bottom system inset | Android back = always functional (see §6) |

Haptics: **confirmations only** (save success, delete complete). No haptics on keystrokes or transient toasts (low-device battery; guideline: feedback, not noise).

---

## 2. Feedback & loading

| Condition | Behavior |
|---|---|
| Wait < ~400ms | No indicator (avoid flicker) |
| Wait ≥ ~400ms | **Skeleton** placeholders on content surfaces (list/Home/Reports); **inline progress** (determinate spinner + label) on action-initiated waits (save, verify, send-link) |
| AI processing | Dedicated progress view with the **15-second visible ceiling** and an always-present "أدخل يدويًا" escape (Q-009, FR-AI-007/008) |
| Action outcome | Success → transient success toast + destination refresh; Error → inline message near the triggerable control with **retry**, never a silent failure |
| Save in-flight | Save button disabled, shows "جارٍ الحفظ…", then success/error — no double-submit (FR-REVIEW, guideline: submit feedback energy) |

Skeletons over spinners on scrollable content: reduces perceived jank on mid devices (NFR-PERF-001, NFR-LOWDEV-001).

---

## 3. Forms & inputs

| Rule | Spec |
|---|---|
| Validation timing | Validate on commit (blur/submit); show errors **inline at the field**, not a single global banner (guideline: inline per-field). Field-level errors re-announced on submit |
| Required fields | Clearly marked; submit blocked with inline message; no silent submit |
| Amount input | Numeric-only keypad; EGP symbol and decimal handled by formatter; never rounds silently (Q-012) |
| Date input | Date picker with native Arabic calendar; defaults to today for new entries |
| Phone input | `+20` prefilled; whitespace/stripping handled at input time (auth-contracts §2.1) |
| OTP input | 6 digits, auto-advance, paste allowed; error state on wrong code with retry; resend cooldown **60s**, countdown visible (Q-001) |
| Long names/vendor | Text field, no regex restriction beyond cap; Arabic keyboard is default |
| Numeric formatting | `1,250.50 ج.م` everywhere (Q-012); amounts bold on read    surfaces |

Accessibility: every field has a visible label (not placeholder-only); errors are announced to screen readers; contrast ≥ WCAG AA for money figures and warnings.

---

## 4. Pickers & selection

| Surface | Behavior |
|---|---|
| Transaction type (SCR-08) | Two large cards; selection is immediate; no disabled state — a type choice is always required to proceed (FR-CAPTURE-002/006) |
| Category (OVR-01) | Bottom-sheet list from SCR-10: defaults group then customs; optional search; rows show name + (AI suggestion badge when suggested); selection collapses sheet and fills the form |
| Period selector (SCR-11) | Segmented control + "Custom Range" that opens OVR-03; selection re-renders the report immediately |
| Date range (OVR-03) | Start/end pickers; same-period validation (start ≤ end) |
| Business type (SCR-04/13) | Radio list (Retail / Restaurant / Pharmacy / Service / Other) — matches `business_types` domain (auth/business-contracts §2.2) |

---

## 5. Confirmations & destructive actions

| Action | Required confirmation | Untraceable? |
|---|---|---|
| Save from Review (AI or manual) | Implicit — the user pressed Save; nothing auto-persists (NFR-DATA-001) | No |
| **Delete transaction** | OVR-04 (names the record + value); no undo after (BR-TRANS-004) | Yes — dialog is the only guard |
| **Delete custom category** | Confirmation; blocked inline if still in use (FK reference → friendly error) | Yes |
| **Unlink web access** | Confirmation (BR-WEB-006) | Yes |
| **Logout** | OVR-06 confirmation | Yes |
| **Delete account** | OVR-05 (typed/scoped, most destructive) | Yes |
| Exit Review form with unsaved content | OVR-07 (Keep editing / Discard) | Yes |

**Guard principle (G7):** every destructive or data-losing action is a **two-step** action: tap → confirm with consequences stated → confirm/user action → done. "تأكيد" (confirmation) button carries the destructive color; "إلغاء" is always the escape.

---

## 6. Back & system navigation

Legacy from `navigation-map.md` §7, restated as rules:

| Gesture | Behavior |
|---|---|
| System back (gesture/button) | Always available; pops the correct stack level; on a tab root, exits the app (standard Android) |
| Back from Add flow (type chosen) | Returns to Type select, preserves type; back from Type select exits to origin tab |
| Back with unsaved Review content | OVR-07 guard, not silent discard |
| Back inside a bottom sheet | Dismisses the sheet only |
| Direction-flip | Under RTL, "back"/"previous" points **right**; icons mirror (chevron direction, `<` vs `>`) automatically |

---

## 7. RTL specifics

- Bidi isolation applied around numbers/money/phone (order stays LTR, labels RTL).
- Progress bars and skeletons fill **left→right** even in RTL (progress read direction is renderer-fixed).
- Sheet drag handles, close icons (`×`) — no directional ambiguity.
- Arabic numeric input vs Latin glyphs: **Latin digits** (`0123456789`) kept for amounts/phone to match backend `numeric(14,2)` checks (Q-012, auth-contracts §2.1); dates display per locale.

---

## 8. Offline & error interaction

| Case | UX |
|---|---|
| No network, app opens | Home still renders from cache if cached (read-only); banner "لا يوجد اتصال — البيانات قديمة" |
| Capture attempted offline | **Local capture proceeds**: image + type + (optional) metadata stored on-device as a pending capture, deferred sync + AI until connection returns (Q-018 flipped, ADR-007, FR-OFFLINE-001..008) |
| Any POST fails | Retry with preserved form content (never clear the form on error) |
| Image upload fails at save | Keep the record retriable; message explains the image didn't upload and can be retried (storage-contracts §4) |
| Search/filter debounce | 350ms debounce; results reflect applied criteria |

---

## 9. Performance-aware interaction (agreed with NFR-LOWDEV/PREF)

- **No heavy animations**; only micro-motion for feedback (progress, success checks) (NFR-LOWDEV-001).
- **List virtualization** for long Transactions lists (paging) instead of unbounded rendering.
- **Debounced search**, **compressed images** at capture (max dimension ~1600px, JPEG), skeletons over placeholders, `Viewport` hints for images.
- Everything is input-latency-first: reduces "app is slow → merchant is nervous" pressure.

---

## 10. Interaction invariants (acceptance-checkable)

1. Every destructive/data-losing action is ≥ 2 taps (tap → confirm).
2. No AI-originated data persists without a Save (NFR-DATA-001).
3. Every field error is inline, per-field, in Arabic (guideline + NFR-LANG-001).
4. No wait is presented without an indicator if ≥ 400ms; AI ceiling 15s with escape.
5. System back is never broken at any depth.