# Implementation Handoff — Hesably Flutter Mobile App

> **Date**: 2026-09-18
> **Phase**: Initial Implementation Handoff
> **Produced by**: Antigravity (Implementation Readiness Audit)

---

## Visual Source Declarations

> **"THE NEW STITCH PROJECT IS THE ONLY VISUAL SOURCE OF TRUTH FOR THE HESABLY MOBILE UI."**

> **"docs/mobile-design/ IS HISTORICAL/DEPRECATED AND MUST NOT OVERRIDE THE APPROVED STITCH DESIGN."**

> **"docs/mobile-app/ IS THE CURRENT FLUTTER IMPLEMENTATION ARCHITECTURE AUTHORITY."**

---

## 1. Current Flutter Foundation Status

| Item | Status | Notes |
|---|---|---|
| Flutter project initialized | ✅ Complete | `apps/mobile/` — package: `hesably`, bundle: `com.hesably` |
| `pubspec.yaml` configured | ✅ Complete | Core dependencies added |
| `main.dart` foundation | ✅ Complete | `HesablyApp` + `MaterialApp` with M3 seed `#0A7A3D` |
| Dependency resolution | ✅ Clean | `flutter pub get` resolves with no errors |
| Static analysis | ✅ 0 issues | `flutter analyze` — No issues found |
| Test directory | ⚠️ Missing | `test/` not created; no test runner available yet |
| Directory structure | ⚠️ Partial | `lib/` contains only `main.dart` — `app/`, `core/`, `features/` not yet scaffolded as real dirs |
| `.env` file | ⚠️ Missing | `flutter_dotenv` is a declared dependency but no `.env` file exists |
| Localization setup | ❌ Not done | `flutter_localizations` not in `pubspec.yaml`; no `.arb` files |
| Cairo / Tajawal fonts | ❌ Not done | `pubspec.yaml` has no font declarations; Google Fonts dependency not added |
| GoRouter setup | ❌ Not done | `go_router` declared but no router file exists |
| Supabase initialization | ❌ Not done | `supabase_flutter` declared but no init call in `main.dart` |
| DI/injectable setup | ❌ Not done | `get_it`/`injectable` declared but no DI setup exists |
| Feature directories | ❌ Not done | `lib/features/` does not exist yet |
| RTL `textDirection` | ❌ Not done | `MaterialApp` does not declare `locale` or `Directionality` |

---

## 2. Architecture Summary

The project follows a **Feature-First Clean Architecture** with the following layer contract:

```
Presentation (Cubit / Widget)
    ↓  calls
Domain (UseCase / Entity / Repository Interface)
    ↓  implemented by
Data (DataSource / RepositoryImpl / Model)
    ↓  delegates to
External (Supabase / Local DB / Storage)
```

Each feature lives at: `lib/features/<feature_name>/{data,domain,presentation}/`

Shared infrastructure lives at: `lib/core/`

App-level bootstrap lives at: `lib/app/`

### Critical Architecture Rules
1. **Supabase calls** are only allowed inside `DataSource` classes — never in widgets or domain.
2. **State** is managed via `flutter_bloc` Cubit (preferred) or Bloc for complex event streams.
3. **Navigation** uses `go_router` with centralized route guards in `lib/app/router/`.
4. **DI** uses `get_it` + `injectable`. No manual `new` for services.
5. **Errors** are mapped to `Failure` sealed classes; domain returns `Either<Failure, T>` via `fpdart`.
6. **Secrets** use `--dart-define` or `.env` via `flutter_dotenv`. Gemini API key MUST NOT exist in the Flutter client.
7. **UI strings** use `.arb` files via `flutter_localizations` — no hardcoded Arabic strings in widgets.
8. **Colors** are accessed only via `Theme.of(context).colorScheme.*` — never raw hex values in widgets.

---

## 3. Approved Design System Tokens (from Stitch)

| Token | Value | Role |
|---|---|---|
| Primary | `#004328` | Main brand, interactive controls |
| Primary Container | `#0D5C3A` | App bar, FAB |
| Secondary | `#006D37` | Positive cash flow, verified state |
| Error | `#BA1A1A` | Destructive actions only |
| Surface | `#FAF8FF` | Canvas / page background |
| AI / Warning | `#F59E0B` (Tertiary) | Low-confidence AI fields, pending sync |
| Headline Font | **Cairo** | All financial numbers, Arabic headings |
| Label Font | **Tajawal** | Chips, status tags, compact labels |
| RTL | **Always-on** | `textDirection: TextDirection.rtl` |
| Reference Viewport | 390 × 852 dp | Design baseline |
| Touch Target Min | 48 dp | All primary interactive controls |

> **Note on primary color**: Stitch uses `#004328` as `primary` and `#0D5C3A` as `primary-container`. The current `main.dart` uses `#0A7A3D` as the seed. This needs to be updated to match the approved Stitch token exactly during the app foundation task.

---

## 4. Stitch Screen Mapping

Full mapping is in: [`docs/mobile-app/stitch-screen-map.md`](./stitch-screen-map.md)

**Summary:**
- **Stitch Project**: `13492244755370590843` — "Full Application Design Review"
- **Total screens in Stitch canvas**: 35 screen instances
- **Primary visual screens mapped**: 30 (primary screens + overlays)
- **Overlays/dialogs/sheets mapped**: 8 (OVR-01 through OVR-08)
- **Non-screen reference entries excluded**: 9 (uploaded docs + logo + design system assets)
- **Unresolved mappings**: **0**

---

## 5. Implementation Sequence

Dependency-ordered sequence for the next phase. Do NOT begin until this handoff is accepted.

| Phase | Feature | Key Screens | Depends On |
|---|---|---|---|
| 1 | **App Foundation** | — | Nothing — must be first |
| 2 | **Authentication** | SCR-01/02 Splash, SCR-03 Login, SCR-04 OTP Verify | Foundation |
| 3 | **Business Setup** | SCR-04b Business Setup | Auth (new user guard) |
| 4 | **Main Navigation Shell** | Bottom nav (Home/Tx/Reports/Settings) | Auth guard, Router |
| 5 | **Home** | SCR-05 Loaded, SCR-05c Empty | Navigation shell |
| 6 | **Receipt Capture (Online)** | SCR-09 Capture | Camera plugin, Foundation |
| 7 | **Offline Queue / Sync** | SCR-14 Pending Queue | Capture, Local DB |
| 8 | **AI Extraction Edge Function** | (server-side) | Supabase Edge Fn |
| 9 | **AI Review & Confirmation** | SCR-10 Review, OVR-08 Low-Confidence | AI Extraction |
| 10 | **Transactions** | SCR-06 List/Empty/Filtered, SCR-07 Detail, SCR-08 Type | Home, Review |
| 11 | **Categories** | SCR-13 Management, SCR-15 Add/Rename, OVR-01 Picker | Transactions |
| 12 | **Reports** | SCR-11 Empty, SCR-12 Loaded, OVR-02 Export, OVR-03 Date Range | Transactions |
| 13 | **Settings** | SCR-16 Web Access, SCR-18 Settings, OVR-05/06 dialogs | Auth |
| 14 | **Receipt Viewer** | SCR-17 Viewer | Transactions |
| 15 | **Final Hardening** | All OVR dialogs, RTL validation, a11y, perf | Everything |

---

## 6. Known Gaps (Found During Audit)

### Foundation Gaps (Must be resolved before feature work)

| Gap | Severity | Description |
|---|---|---|
| **Localization not configured** | 🔴 Blocker | `flutter_localizations` not in `pubspec.yaml`. Arabic-first app requires `.arb` files and `MaterialApp` locale config before any string can be written correctly. |
| **Cairo / Tajawal fonts not registered** | 🔴 Blocker | `pubspec.yaml` has no `fonts:` section. The approved design mandates Cairo for body/headline and Tajawal for labels. Can use `google_fonts` package or bundled assets. |
| **GoRouter not initialized** | 🔴 Blocker | Package declared but no router file or `MaterialApp.router` wrapper exists. |
| **Supabase not initialized** | 🔴 Blocker | Package declared but no `Supabase.initialize()` call in `main()`. Requires `.env` or `--dart-define` for URL and anon key. |
| **DI container not set up** | 🔴 Blocker | `get_it` + `injectable` declared but no `configureDependencies()` call and no `@module`/`@injectable` annotated classes. |
| **Feature directories not scaffolded** | 🔴 Blocker | `lib/features/`, `lib/core/`, `lib/app/` do not exist yet. |
| **RTL / Locale not set on MaterialApp** | 🔴 Blocker | `MaterialApp` lacks `locale: Locale('ar')` and `supportedLocales`/`localizationsDelegates`. |
| **Primary color seed mismatch** | 🟡 Minor | `main.dart` uses `#0A7A3D`; Stitch DESIGN.md specifies `#004328` as primary and `#0D5C3A` as primary-container. Update theme seed during foundation task. |
| **test/ directory missing** | 🟡 Minor | No test directory or widget_test.dart. Required for CI. |
| **.env file not created** | 🟡 Minor | `flutter_dotenv` is a dependency but no `.env` example or template exists. |

### Non-Blocking Observations

| Item | Note |
|---|---|
| `pubspec.yaml` description | Still reads "A new Flutter project." — update to "Hesably — AI-powered bookkeeping for Egyptian merchants." |
| `flutter_lints` v5 | v6 is available. Non-breaking upgrade acceptable at any time. |
| 38 packages with newer versions | Acceptable. Run `flutter pub outdated` before each release. |
| Offline local DB package | `offline-sync.md` mentions Hive or SQLite. Neither is in `pubspec.yaml` yet. Decision needed before Phase 7. |
| Camera plugin | Not in `pubspec.yaml`. Required for Phase 6. `camera` or `image_picker` package decision needed. |
| `google_fonts` or bundled fonts | Decision needed: bundle Cairo/Tajawal as assets or use `google_fonts` package. |

---

## 7. Known Conflicts

| Conflict ID | Description | Source A | Source B | Resolution |
|---|---|---|---|---|
| CON-01 | Primary color value | `main.dart` uses `#0A7A3D` as seed | Stitch DESIGN.md: primary `#004328`, primary-container `#0D5C3A` | **Use Stitch values.** Update `main.dart` during foundation task. |
| CON-02 | Font prescription | `docs/mobile-app/theming.md` says "Cairo font" | Stitch design system also uses **Tajawal** for labels | **Not a conflict** — use Cairo for all body/headline and Tajawal for label role. |

---

## 8. Required Decisions Before Feature Implementation

The following decisions must be made before each respective phase begins:

| Decision | Required By | Options | Recommendation |
|---|---|---|---|
| **D-01: Font loading strategy** | Phase 1 Foundation | `google_fonts` package vs bundled `.ttf` assets | Bundled assets — avoids network dependency, critical for low-end Android |
| **D-02: Local DB for offline** | Phase 7 Offline | `hive_flutter`, `sqflite`, `drift` | `drift` (type-safe, query-friendly for complex pending queue) or `hive` (lightweight) |
| **D-03: Camera approach** | Phase 6 Capture | `camera` (full control) vs `image_picker` (simpler) | `camera` for the approved viewfinder UI design |
| **D-04: Supabase env loading** | Phase 1 Foundation | `--dart-define` at build time vs `flutter_dotenv` `.env` file | `--dart-define` for CI/CD; `.env` for local dev (already have `flutter_dotenv` dep) |
| **D-05: Offline local ID strategy** | Phase 7 Offline | UUID v4 client-generated | UUID v4 — already aligned with ADR-007 |
| **D-06: `google_fonts` version** | Phase 1 Foundation | Latest compatible version | Add to `pubspec.yaml` during foundation task |

---

## 9. Validation Results

| Check | Result | Detail |
|---|---|---|
| `flutter analyze` | ✅ **0 issues** | Ran at 2026-09-18, clean pass |
| `flutter pub get` | ✅ **Success** | All 38 declared packages resolved |
| `flutter test` | ⚠️ **Skipped** | `test/` directory not found — no tests written yet |
| Dependency conflicts | ✅ **None** | No incompatible constraints |
| `pubspec.yaml` syntax | ✅ **Valid** | Parsed correctly by pub |
| Git status | ✅ **Clean** | 3 commits on `chore/mobile-scaffolding` |
| Stitch project accessible | ✅ **Yes** | Project `13492244755370590843` inspected via Stitch MCP |
| Historical docs used as design source | ✅ **No** | `docs/mobile-design/` accessed only to confirm deprecation status |
| Production features implemented | ✅ **No** | Only placeholder page in `main.dart` |
| Secrets in code | ✅ **None** | No API keys or tokens found in any committed file |

---

## 10. Reusable Components — Pre-Identified

The following shared components will be needed across multiple screens. They should be built once in `lib/core/widgets/` or `lib/app/widgets/` and NOT duplicated inside features:

| Component | Used By | Priority |
|---|---|---|
| `HesablyAppBar` | All primary screens | Foundation |
| `BottomNavShell` | Home, Transactions, Reports, Settings | Phase 4 |
| `PrimaryButton` / `SecondaryButton` | Auth, Setup, Review, Settings | Phase 2 |
| `TransactionCard` | Home (recent), Transactions list | Phase 5/10 |
| `CurrencyDisplay` | Home summary, Transaction detail, Reports | Phase 5 |
| `DateRangeDisplay` | Transaction list, Reports | Phase 10/12 |
| `EmptyStateWidget` | Home, Transactions, Reports, Categories | Phase 5 |
| `LoadingStateWidget` | All data-driven screens | Foundation |
| `ErrorStateWidget` | All data-driven screens | Foundation |
| `ConfidenceBadge` | SCR-10 AI Review, SCR-07 detail | Phase 9 |
| `SyncStatusIndicator` | SCR-14 Pending, Home | Phase 7 |
| `ConfirmationDialog` | OVR-04, OVR-05, OVR-06, OVR-07 | Phase 10 |
| `CategoryPickerSheet` | OVR-01 | Phase 11 |
| `ExportOptionsSheet` | OVR-02 | Phase 12 |
| `DateRangePickerSheet` | OVR-03 | Phase 10/12 |

---

## 11. Testing Handoff

No tests are written yet. The following critical flows MUST have test coverage as they are implemented:

| Flow | Test Type | Reason |
|---|---|---|
| `Auth / OTP` | Unit + Widget | Business-critical: wrong OTP handling = lock-out |
| `Business Setup` | Unit | First-run gate; must not be bypassable |
| `AI Review — never auto-save` | Unit (UseCase) | Core product contract violation risk |
| `AI confidence thresholds` | Unit | 80% / 50% rules are product requirements |
| `Offline capture → pending queue` | Unit + Integration | Core MVP feature |
| `Sync state transitions` | Unit | OFFLINE ≠ ERROR ≠ PENDING ≠ SYNCING |
| `Category deletion guard` | Unit | Default categories must never be deleteable |
| `Transaction persistence` | Unit + Widget | Double-save / duplicate risk |
| `Report date filtering` | Unit | Export respects active filters |
| `Logout session clear` | Unit | Security requirement |

---

## Handoff Status

```
IMPLEMENTATION READY WITH ISSUES
```

**The foundation compiles cleanly, analysis passes, and the Stitch design is fully mapped.**

**However, 7 blocking foundation gaps must be resolved before any feature implementation begins:**
1. Localization not configured
2. Cairo / Tajawal fonts not registered
3. GoRouter not initialized
4. Supabase not initialized
5. DI container not set up
6. Feature directory structure not scaffolded
7. RTL / Locale not set on MaterialApp

**These gaps should be addressed in the next task: "App Foundation & Boot Sequence."**
