# AI Patterns — Hesably Design System

**Purpose:** a reusable visual language for AI functionality that makes AI feel **assistive, never authoritative** — and that unmistakably distinguishes **AI draft/suggestion** from **user-confirmed financial data**. This is the visual expression of the AI trust invariant (NFR-DATA-001, BR-CONFIRM-001, Q-008).
**Sources:** `ux/ux-states.md` §2 (AI state machine), `ux/screen-inventory.md` (SCR-09/10, OVR-08), `ux/user-journeys.md` (J3/J4/J5), `ux/interaction-model.md` §2, `feature-list.md` (§3 AI extraction), `change-management/offline-mvp-change-impact.md` (§6 offline AI).

---

## 1. Core visual stance

**AI is always a draft until the user confirms.** The system's visual grammar makes this legible:

- AI-affiliated elements carry **indigo** (`color.ai` / `color.ai-container`) — a color used *only* for AI. Confirmed financial data uses the normal authoritative ink (`text-primary`, primary/success statuses) with **no AI color**, no dashed border, no sparkle.
- **Dashed outline + AI glyph** annotate "this was AI-produced and not yet reviewed/confirmed."
- **Confirmed data looks like ordinary data** — the goal is that the *moment* a value is confirmed it becomes plain, authoritative ink. No "permanently-tagged" AI styling lingers on confirmed records (provenance is a separate, subtle note on Detail).
- Never use a "robot in charge" metaphor or anything implying the machine decides.

**Trust distinction checklist (designers must pass this on every AI surface):**

| Element | AI draft / suggestion | User-confirmed data |
|---|---|---|
| Ink | AI-container fill / indigo dashes | `text-primary` standard, solid |
| Border | dashed, `color.ai` | solid, component default |
| Marker | `auto_awesome` 16–18dp + label | none |
| Behavior | editable, flagged if low-confidence | immutable unless editing |
| Copy | "اقتراح","تم الاستخراج الذكي مقترح" | exact record, no qualifier |

---

## 2. AI processing view (SCR-09, in-flow)

- **Anatomy:** compact card on the capture screen: AI glyph (indigo) + label **"جارٍ استخراج البيانات…"** + thin indeterminate progress + **15-second visible ceiling** countdown ("وقت أقصاه 15 ثانية") + always-visible escape link **"إدخال يدوي"**.
- **States (all from `ux-states.md` machine):**
  - `PROCESSING` (≤15s; uninterruptible except manual escape by spec).
  - `TIMEOUT (≥15s)` → inline message "استغرق الاستخراج وقتًا طويلًا — أدخل البيانات يدويًا" + button **"إدخال يدوي"** (and optional "إعادة المحاولة" only if technically sound; the spec's guaranteed path is manual — navigation-map §3).
  - `FAILURE (structured)` → inline message "لا يمكن قراءة بيانات الفاتورة بدقة — أدخلها يدويًا" + **"إدخال يدوي"** (retry optional).
  - `NON-RECEIPT` → "يبدو أن الصورة ليست فاتورة — التقط صورة أوفى" + actions **retake** / **manual**.
- **Rules:** every terminal state has a next action (G3); processing never blocks manual entry; the escape is present from the first frame of processing, not only after the ceiling.
- **Anti-patterns:** a bare spinner with no ceiling; hiding the manual escape until timeout; a "processing…" state that looks like a success.

## 3. AI extraction result — the Review & Save form (SCR-10)

- **Provenance chip** at the top of the form (AI path): `auto_awesome` + **"تم الاستخراج الذكي"** in an `color.ai-container` chip, with caption "راجع البيانات ثم احفظ — لن يُحفظ شيء قبل تأكيدك".
- **Pre-filled fields** display extracted values; each is **editable** and behaves like a normal form field, but AI-sourced fields show a **discreet AI mark** (dashed border on the field or small sparkle next to the label) that disappears/changes once the user edits the field — indicating the user has taken ownership.
- **The form's primary CTA is** "احفظ" (**Save**). Nothing auto-saves; there is no "apply AI" button and no timer.
- **Anti-patterns:** a green "confirmed"-style checkmark on an unedited AI field; a Save disabled until all fields verified (user must be able to save after fixing only what matters); pre-marking AI fields as final.

## 4. Confidence system

Thresholds (from `ux-strategy.md` G4 / `user-journeys.md` J3): **≥80% unflagged · <80% flagged for review · <50% = field treated as failure (overall <50% → failure)**.

- **Field-level confidence:**
  - `≥80% (high)`: no flag; the field is visually normal AI-draft (dashed mark only). Optionally a quiet "دقة عالية" (`color.status.success` text chip) at `<100%`.
  - `50–79% (advisory)`: **OVR-08 inline advisory** under the field: `warning_amber` 16dp + `type.caption` warning text "راجع {حقل} قبل الحفظ" + the field keeps its dashed AI mark. Add a subtle warning tint to the field container. The user edits → mark clears.
  - `<50% (low)`: treated as *not confidently read*. For a **whole-result** score <50% → **route to manual** (not "save anyway"); for a **single field** <50% → advisory + the field is highlighted so the user must address it (empty value with "لم يُقرأ هذا الحقل بوضوح — أدخله يدويًا").
- **Confidence display (where a % is shown):** a small caption `73%` in Latin digits next to the low-confidence flag / in the provenance chip; **never** a large dial/gauge that visually ranks AI output near authoritative. Percent read LTR (`73%`), inside bidi isolation.
- **Anti-patterns:** a big confidence ring; confidence styled like a success/progress; a "100% confident" claim without source verification.

## 5. AI suggestion markers

- **Category** (OVR-01): the AI-suggested category row carries an indigo **"اقتراح AI"** chip (`color.ai-container`), the user may pick another; selecting any category collapses the sheet (no "confirm suggestion" step).
- **Any suggested value** (vendor name, date, items): follows §3 field marks (dashed + sparkle). No suggestion is "sticky" — editing it clears the AI mark.
- **Anti-patterns:** suggestion footnotes that read like errors; auto-locking the suggested value.

## 6. AI provenance on saved data (Detail SCR-07)

- A saved record has a **subtle, permanent** provenance note ("تم الاستخراج الذكي — راجعه عند الحفظ") in `color.ai` at `type.caption`, **inside the Detail, not as a confirmation visual**. It does not make confirmed data look AI-authoritative — it's a breadcrumb for trust ("this value came from the image; the owner verified it").
- Manual-entry records show **"إدخال يدوي"** provenance (neutral `text-secondary`).
- **Anti-patterns:** a provenance chip that makes confirmed data look draft; provenance on list rows (too noisy — keep it to Detail).

## 7. AI warning / info treatments

- **AI info note** (`color.ai`/info glyph): contextual help, e.g., "الجودة أقل من المثالية — تحقق من الأرقام" on a borderline extraction.
- **AI failure** uses error status + error copy + retry/manual — identical to any other error surface (no special "AI-error" styling beyond the standard error treatment; the source is AI, the presentation is a normal retryable error).
- **Anti-patterns:** inventing a new "AI error" color; dressing AI failures as success.

## 8. Offline + AI interaction (deferred)

- Offline captured pending → when online, upload happens, **then** AI extraction **re-enters the standard PROCESSING → REVIEW** machine (ux-states §2). The user always reviews; the AI output never auto-saves (BR-OFFLINE-004, FR-OFFLINE-008).
- **Visual rule:** a pending capture that has not yet been AI-processed carries an **offline/pending** marker (see `offline-patterns.md`), *not* an AI marker — the user must not believe "my pending item was already AI-read." Once sync begins, the standard AI processing view appears.
- **Anti-patterns:** showing an AI confidence flag on a local-only pending capture; implying the pending item was already extracted.

## 9. Inclusive "AI" naming and copy

- Use plain Arabic: "استخراج ذكي", "اقتراح", "راجع وحفظ". Avoid the translation of "confidence" as a noun in user copy — frame as "راجع {الحقل} قبل الحفظ".
- The AI **icon** (`auto_awesome`) is reserved (see `iconography.md` §3.4) and carries a `Semantics` label ("ذكاء اصطناعي" / "AI").
- **Anti-patterns:** "Gemini", "model", "confidence score", "extraction success rate" as user-facing strings (persona: plain words only).

---

## 10. AI visual rules — consolidated checklist (design gate)

- [ ] Every AI element uses `color.ai`/`ai-container` or a dash, never primary/success **unless** it's the user's confirm action.
- [ ] No AI value is presented without an explicit user confirm path (Save).
- [ ] Low-confidence fields (<80%) carry OVR-08 advisory; whole <50% → manual.
- [ ] Processing state ≤15s visible ceiling + manual escape from frame one.
- [ ] Pending/offline items carry pending markers, not AI markers.
- [ ] Provenance exists on Detail but never re-drafts confirmed data.
- [ ] Copy stays plain Arabic; % stays Latin-digit LTR.
- [ ] No "robot-authority", no AI>human visual ranking.