# Implementation Handoff — Hesably Flutter Mobile App

> **Date**: 2026-09-18
> **Phase**: App Foundation & Boot Sequence — COMPLETED
> **Produced by**: OpenCode (Foundation Phase)

---

## Visual Source Declarations

> **"THE STITCH PROJECT IS THE ONLY VISUAL SOURCE OF TRUTH FOR THE HESABLY MOBILE UI."**

> **"docs/mobile-design/ IS HISTORICAL/DEPRECATED AND MUST NOT OVERRIDE THE APPROVED STITCH DESIGN."**

> **"docs/mobile-app/ IS THE CURRENT FLUTTER IMPLEMENTATION ARCHITECTURE AUTHORITY."**

> **Current Stitch project**: `661013469764921318` — "Hesably — Smart Invoice Assistant" (old project `13492244755370590843` is STALE).

---

## 1. Flutter Foundation Status (post-foundation-phase)

| Item | Status | Notes |
|---|---|---|
| Flutter project initialized | ✅ Complete | `apps/mobile/` — package: `hesably` |
| `pubspec.yaml` configured | ✅ Complete | + `flutter_localizations`, `shared_preferences ^2.3.0`, `intl: any`, Cairo fonts |
| Boot sequence | ✅ Complete | `main.dart` → `bootstrap()` → env → DI → (Supabase) → `runApp` |
| Environment config | ✅ Complete | `AppEnvironment` — `--dart-define` wins, `.env` via `flutter_dotenv` fallback; `.env.example` present |
| DI / injectable | ✅ Complete | `getIt` + `injectable`, generated `injection.config.dart`, `SharedPreferences` pre-resolved |
| GoRouter shell | ✅ Complete | 4-tab `StatefulShellRoute.indexedStack` (Home/Tx/Reports/Settings) + placeholder screens |
| Theming | ✅ Complete | `AppTheme.light` — M3 from seed `#0A7A3D`, verified tokens copied over, Cairo text theme, 48dp controls, RTL-ready |
| Localization | ✅ Complete | `.arb` via `flutter_localizations` + `gen_l10n` — Arabic template, English secondary (see §2) |
| Cairo fonts | ✅ Complete | `assets/fonts/Cairo-{400,500,600,700}.ttf` bundled (Google Fonts static, valid TTFs) |
| Supabase initialization | ✅ Complete | Guarded — only when backend configured (`.env` or dart-define present) |
| Core scaffolding | ✅ Complete | `lib/core/` — `EgCurrency` (`1,250.50 ج.م`), error foundation (`AppFailure` + `mapError`), string extensions |
| Feature directories | ✅ Complete | `lib/features/{auth,home,transactions}/…` scaffolded with `.gitkeep` |
| Static analysis | ✅ 0 issues | `flutter analyze` — No issues found |
| Tests | ✅ 14 passing | env, theme, currency, error, app-shell widget tests |
| Build | ✅ Passes | `flutter build web --debug` — Built successfully |
| RTL `textDirection` | ✅ Complete | `locale: Locale('ar')` + `supportedLocales`; direction resolves from locale |

---

## 2. Localization Decision (resolved conflict)

Architecture doc `docs/architecture/mobile-architecture.md` §15 prescribes **easy_localization**; docs `docs/mobile-app/localization.md` + this task prescribe **flutter_localizations + .arb**.

**DECISION: `.arb` / gen_l10n** (Flutter first-party).

- The task spec (highest authority, user instruction) explicitly prescribes `.arb`.
- `.arb` integrates with `flutter gen-l10n`, `flutter_localizations`, and Material localizations without a third-party package.
- Divergence from the architecture doc is intentional and recorded here; `mobile-architecture.md` is NOT edited (historical). Update the architecture doc when the Architecture phase is revisited.

Setup: `l10n.yaml` (template `app_ar.arb`, class `AppLocalizations`, `nullable-getter: false`). Arabic-first; runtime toggle deferred to Settings feature. `intl: any` per Flutter gen_l10n guidance (resolves to 0.20.2).

---

## 3. Approved Design Tokens (from CURRENT Stitch project `661013469764921318`)

| Token | Value | Role |
|---|---|---|
| Primary | `#0A7A3D` | Main brand, interactive controls |
| On Primary | `#FFFFFF` | Text/icons on primary |
| Background (canvas) | `#FAFAF8` | Page background (reduces glare) |
| Surface | `#FFFFFF` | Cards, sheets |
| On Background / Surface | `#191C19` | Primary text |
| Outline | `#6F7A6E` | Secondary borders |
| Outline Variant | `#D0CFC8` | Default input borders, dividers |
| Secondary | `#5E5F59` | Neutral accents |
| Error | `#BA1A1A` | Destructive actions |
| Surface Container Low | `#F3F4EF` | Muted container surfaces |
| Surface Container | `#EDEEE9` | Raised container surfaces |
| Pending / Warning | `#F59E0B` (derived) | Low-confidence AI, pending sync ("Green for paid, Amber for pending") |
| Headline Font | **Cairo** (700/600) | Arabic financial numbers, headings |
| Body Font | **Cairo** (400) | Body copy |
| Label Font | **Cairo** (600/500) | Chips, labels — **Tajawal dropped** |
| RTL | **Always-on** | `locale: Locale('ar')` → RTL direction |
| Reference Viewport | 390 × 884 dp (Phone Entry 390 × 852) | Design baseline |
| Touch Target Min | 48 dp | All primary interactive controls |
| Roundness | 8 dp buttons/cards/inputs | Per Kinetic token sheet |

> **Token migration complete**: `#004328` / `#0D5C3A` / `#006D37` / `#FAF8FF` / Tajawal from the OLD project are obsolete — do NOT use. Stitch proxies Cairo with Inter strictly for rendering; the app bundles real Cairo.

---

## 4. Stitch Screen Mapping

Full mapping in: [`docs/mobile-app/stitch-screen-map.md`](./stitch-screen-map.md)

**Summary (current project `661013469764921318`):**
- Canvas instances: **36**
- UI implementation targets: **33** (screens with HTML)
- Non-UI assets: **2** (brand icon, ledger illustration)
- Design system instance: **1** (Kinetic Finance RTL token sheet)
- Covered flows: Splash, Phone Login, OTP, Business Setup, Home (loaded/empty/offline ×13), Transactions (list/type/detail/search ×14), Receipt AI Processing, Review & Save
- **Canvas gaps**: Reports, Settings, Categories, Receipt viewer, standalone Pending queue — documented product features, awaiting visuals

---

## 5. Implementation Sequence (post-foundation)

Foundation is **complete**. Remaining phases (unchanged, dependency-ordered):

| Phase | Feature | Key Screens | Depends On |
|---|---|---|---|
| 2 | **Authentication** | Splash, Phone Login, OTP Verify | Foundation ✅ |
| 3 | **Business Setup** | Business Setup (Refined + Form) | Auth (new user guard) |
| 4 | **Main Navigation Shell** | Bottom nav (already shelled in foundation) | Auth guard, Router ✅ |
| 5 | **Home** | Dashboard Loaded, Empty, Offline, Offline Pending | Navigation shell |
| 6 | **Receipt Capture (Online)** | SCR-09 Capture (Receipt AI Processing) | Camera plugin |
| 7 | **Offline Queue / Sync** | Home Offline Pending states | Capture, Local DB |
| 8 | **AI Extraction Edge Function** | (server-side, `extract-receipt`) | Supabase Edge Fn |
| 9 | **AI Review & Confirmation** | Review & Save — AI Draft State | AI Extraction |
| 10 | **Transactions** | List Populated/Empty/Search-empty, Type Selection, Detail | Home, Review |
| 11 | **Categories** | (no canvas yet) | Transactions |
| 12 | **Reports** | (no canvas yet) | Transactions |
| 13 | **Settings** | (no canvas yet) | Auth |

---

## 6. Resolved Blockers (former "Known Gaps")

| Former Gap | Resolution |
|---|---|
| Localization not configured | ✅ `.arb` + gen_l10n + `flutter_localizations` |
| Cairo / Tajawal fonts not registered | ✅ Cairo TTFs bundled; Tajawal dropped (not in current Stitch) |
| GoRouter not initialized | ✅ `StatefulShellRoute.indexedStack`, 4 tabs + placeholder pages |
| Supabase not initialized | ✅ Guarded `Supabase.initialize` in boot sequence |
| DI container not set up | ✅ `getIt`/`injectable` + generated config |
| Feature directories not scaffolded | ✅ `lib/features/` + `lib/core/` + `lib/app/` |
| RTL / Locale not set | ✅ `locale: Locale('ar')`, delegates, `supportedLocales` |
| Primary color seed mismatch | ✅ Resolved to `#0A7A3D` (current Stitch custom color) — old `#004328` CON-01 obsolete |
| `test/` missing | ✅ 14 tests (env, theme, currency, error, app shell) |
| `.env` template missing | ✅ `.env.example` created |

---

## 7. Open Decisions (previously "Known Conflicts" / required decisions)

| Decision | Status | Recommendation |
|---|---|---|
| D-01: Font loading | ✅ **Resolved** | Bundled `.ttf` assets (Cairo 400/500/600/700) — no `google_fonts` |
| D-04: Supabase env loading | ✅ **Resolved** | `--dart-define` (CI) + `.env` (local) via `AppEnvironment` |
| D-02: Local DB for offline | ⏳ Open (Phase 7) | `drift` or `hive` — defer |
| D-03: Camera approach | ⏳ Open (Phase 6) | `camera` (viewfinder UI) vs `image_picker` |
| D-05: Offline ID strategy | ⏳ Open (Phase 7) | UUID v4 client-generated (aligned with ADR-007) |
| CON-02: Font prescription | ✅ **Resolved** | Cairo for all roles; Tajawal dropped |

---

## 8. Validation Results

| Check | Result | Detail |
|---|---|---|
| `flutter pub get` | ✅ **Success** | intl 0.20.2, shared_preferences 2.3.x resolved |
| `dart run build_runner build` | ✅ **Success** | Generated `injection.config.dart` |
| `dart format lib test` | ✅ **Clean** | 16 files formatted |
| `flutter analyze` | ✅ **0 issues** | Clean pass |
| `flutter test` | ✅ **14 passed** | Foundation test suite |
| `flutter build web --debug` | ✅ **Success** | App compiles and boots |
| Secrets in code | ✅ **None** | Only `.env.example` placeholders; Gemini key stays server-side |
| Production features implemented | ✅ **No** | Only shell + placeholders in foundation scope |

---

## 9. Reusable Components — Foundation-Ready Scaffold

The following are planned to live in `lib/core/widgets/`. Not yet built (foundation scope excludes product UI):

`BottomNavShell` (in `app_router.dart`), `PrimaryButton`/`SecondaryButton`, `TransactionCard`, `CurrencyDisplay` (backed by `EgCurrency`), `EmptyStateWidget`, `LoadingStateWidget`, `ErrorStateWidget` (backed by `AppFailure`), `ConfidenceBadge`, `SyncStatusIndicator`, `ConfirmationDialog`, `CategoryPickerSheet`, `ExportOptionsSheet`, `DateRangePickerSheet`.

---

## 10. Testing Handoff

Foundation tests in place (`test/`):

| File | Covers |
|---|---|
| `test/config/app_environment_test.dart` | dart-define/.env precedence, `isBackendConfigured` |
| `test/theme/app_theme_test.dart` | Tokens, Cairo family, 48dp buttons, scaffold bg |
| `test/core/eg_currency_test.dart` | `1,250.50 ج.م` formatting, parse |
| `test/core/app_failure_test.dart` | `mapError` canonicalization |
| `test/app/app_smoke_test.dart` | Boot to shell, 4-tab navigation |

Feature-phase tests to add (from prior handoff §11): Auth/OTP, Business Setup gate, AI never auto-save, confidence thresholds, offline queue, sync state transitions, category deletion guard, transaction persistence, report date filtering, logout session clear.

---

## Handoff Status

```
FOUNDATION READY
```

**The foundation phase is complete and validated: the app boots, shells the 4-tab navigation, themes from verified Stitch tokens, localizes Arabic-first, and passes all checks.** Product features begin with Phase 2 (Authentication), scoped to the current Stitch canvas.