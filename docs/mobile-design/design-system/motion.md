# Motion — Hesably Design System

**Purpose:** minimal, purposeful motion that confirms success and communicates state without taxing low-end Android hardware (NFR-LOWDEV-001). Motion is **never decorative**; it is **informational** (Principle 8).
**Sources:** `ux/ux-strategy.md` (low-end friendly note), `ux/ux-states.md` (skeletons), `ux/interaction-model.md` (loading, haptics), `accessibility.md`.

---

## 1. Motion philosophy

- **Purpose over polish:** every motion answers "what does this tell the user?" — if the answer is "nothing," remove it.
- **Low-end first:** 2D transforms and opacity only; no 3D transforms, no blur effects, no layered shadows with animation, no parallax, no physics-based spring animations.
- **User-initiated motion preferred:** a button press triggers a visual response; the system avoids autonomous "delightful" animations the user didn't ask for.
- **Respect prefers-reduced-motion:** if the OS setting is on, replace all transitions with instant cuts; keep only essential feedback (toast appear/disappear, skeleton pulse → stop).

---

## 2. Transition taxonomy

| Transition | Animation | Duration | Easing | Use |
|---|---|---|---|---|
| **Cut** | none | 0ms | — | content swap within the same surface (tab switch, filter apply) |
| **Fade** | opacity 0→1 | 200–300ms | ease-in-out | skeleton → loaded content; error → retry success |
| **Slide-up** (sheet) | translateY from bottom | 250–300ms | ease-out | bottom sheet (category picker OVR-01, export OVR-02) |
| **Slide-down** (sheet dismiss) | translateY to bottom | 200ms | ease-in | sheet close / backdrop tap |
| **Scale + fade** (dialog) | scale 0.95→1 + opacity | 200–250ms | ease-out | destructive confirm dialog (OVR-04/05/06/07) |
| **Toast appear** | translateY up + opacity | 200ms | ease-out | snackbar/toast enter |
| **Toast dismiss** | opacity out | 150ms | ease-in | snackbar auto-dismiss |
| **Haptic bump** | device vibration (5–15ms) | — | — | confirm only (see §4) |

**Anti-patterns:** spring physics; staggered list entrance (every row animating in sequence = 600ms+ on a 20-row list); a bouncing FAB; a full-screen cross-fade for a tab switch.

## 3. Content transitions

| Surface | Rule |
|---|---|
| Tab switch (bottom nav) | **Cut** — no cross-fade (instant recognition of new tab identity) |
| Screen push/pop (navigator) | Default OS push/pop (slide from right in RTL = slide from left in LTR); **no custom slide** needed |
| Filter apply (Transactions) | **Cut** — list content swaps instantly; a filter chip appears immediately |
| Skeleton → loaded content | **Fade in** the loaded content; skeleton fades out. Total ≤300ms. No skeleton shimmer. |
| Error → retry success | **Fade** the error out, **fade** the content in. No slide. |
| Scroll | native physics scroll only; no parallax headers, no sticky animated headers |
| Number counting (amount total) | **No counting animation** on low-end; the value appears in its final state. A brief 100ms fade if the number changes during a filter is acceptable. |
| AI processing spinner | thin indeterminate bar (200ms per cycle); no particle effects, no "thinking" animation |

## 4. Haptics (minimal, confirm-only)

Per interaction-model §2, haptics are restricted to **confirmation only**:

| Moment | Haptic |
|---|---|
| Save confirmed (SCR-10, SCR-13) | light bump (10–15ms) |
| Delete confirmed (OVR-04) | medium bump (15ms) |
| Account deletion complete | medium bump (15ms) |
| Language toggle switch applied | light bump (10ms) |
| Category added/renamed confirmed | light bump (10ms) |

**Never haptic on:** error, offline banner appear, AI processing, sheet open, tab switch, skeleton appear.

**Anti-patterns:** haptic on every tap; a heavy buzz for non-destructive actions; haptic as the only feedback (must always be paired with a visual change).

## 5. Skeleton motion

- **Pulse:** slow, 1.2s cycle, opacity oscillation between `surface-variant` and a slightly lighter shade. **No shimmer/sweep** (shimmer is a 2D translate that taxes low-end GPU).
- **Width variation:** skeleton blocks vary in width (70%, 85%, 100%) to mimic real content shape — this is a static layout choice, not a motion choice.
- **Appearance:** skeleton fades in (200ms) on first load; on refresh, the skeleton replaces the stale content with a 100ms cross-fade.

## 6. Progress indicators (in motion)

| Indicator | Motion |
|---|---|
| **Determinate progress bar** (save, sync, export) | 200ms per fill cycle, **LTR fill direction** even in RTL (renderer-fixed); width reflects %; no bounce at the end |
| **Indeterminate thin bar** (AI processing, initial load) | 600ms sweep left→right; **no full-screen indeterminate** (UX invariant) |
| **Per-row sync progress** | same determinate bar, narrower (2dp height); label + bar in same row |
| **Spinner (small)** | only inside an image-load placeholder or a button in-flight state; 24dp, single-color, 1s rotation; **never full-screen** |

**Anti-patterns:** a full-screen spinner blocking the entire view; an indeterminate progress bar that *looks* determinate (misleading); an animated progress that overshoots 100% and bounces back.

## 7. Transition timing budget

To stay low-end-safe:

- Any single transition ≤ **300ms**.
- No two transitions start simultaneously on the same surface (e.g., don't fade-in content while a sheet slides up — sequence them: sheet dismisses first, then content fades).
- Total animation frame budget on a low-end device: every transition must complete in ≤2 frames at 30fps (≤66ms per frame) → a 300ms transition is ~5 frames, which is acceptable. A 500ms transition is ~8+ frames and should be avoided.

## 8. Dark mode motion

- No special motion for dark-mode toggle; the color swap is instant (cut) — no cross-fade between light/dark (it's jarring and low-value).
- Skeleton pulse in dark mode uses the same timing (1.2s) but with dark-surface-appropriate opacity range.

## 9. Motion gate checklist

- [ ] Every transition ≤ 300ms.
- [ ] No 3D transforms, no blur animations, no parallax, no spring physics.
- [ ] Skeletons pulse slow (1.2s) with no shimmer.
- [ ] Haptics used only for confirmations (save, delete, toggle).
- [ ] No full-screen indeterminate spinner (use inline or processing card).
- [ ] Progress bar fill direction is LTR even in RTL.
- [ ] prefers-reduced-motion replaces all transitions with cuts.
- [ ] Two transitions never start simultaneously on the same surface.