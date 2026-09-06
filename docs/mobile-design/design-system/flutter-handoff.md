# Flutter Handoff — Hesably Design System

**Purpose:** conceptual mapping from this design system to Flutter implementation — tokens → theme, components → widgets, RTL → framework features, state → pattern guidance. This is a **handoff reference**, not production code. The Flutter developer uses this alongside `tokens.md` and each design-system doc.
**Sources:** all design-system files; `docs/architecture/mobile-architecture.md` (if exists); NFR-LOWDEV-001, NFR-LANG-001.

---

## 1. Theme setup (Material 3 + custom tokens)

- **Framework:** Flutter with Material 3 (`useMaterial3: true`).
- **Theme:** `ThemeData` configured with a `ColorScheme` seeded from `brand-primary (#0A7A3D)` (Material 3 color generation). Override generated colors with exact tokens from `tokens.md` where needed (status colors, AI, offline, income/expense).
- **Text theme:** Google Fonts `Cairo` package (weights 400/500/600/700) loaded from assets. `TextTheme` maps: `displayLarge → type.display`, `headlineMedium → type.headline`, `titleMedium → type.title`, `bodyLarge → type.body`, `bodyMedium → type.body-strong` (weight 600), `labelLarge → type.label`, `bodySmall → type.caption`.
- **Dark theme:** separate `ColorScheme` using dark token values; the app toggles via `themeMode` (system/light/dark).
- **Token file:** `lib/theme/tokens.dart` — all token values as Dart `const`s; no magic hex strings scattered in widgets.

**Anti-patterns:** using `Theme.of(context).colorScheme.primary` for income/expense colors (they are separate tokens, not `primary`); hardcoding hex values in widget trees.

## 2. Component mapping (design system → Flutter widgets)

| Design system component | Flutter widget / approach |
|---|---|
| Text field (forms-controls.md §1) | `TextFormField` + `InputDecoration` (labelText, helperText, errorText, prefix/suffix icons); field border states via `OutlineInputBorder` with `focusedBorder`/`errorBorder` using token colors |
| Amount input (§3) | `TextFormField` + `TextInputType.numberWithOptions(decimal: true)` + custom `TextInputFormatter` for comma formatting + bidi isolation via `RichText` with `TextDirection.rtl` |
| OTP input (§7) | 6× `TextField` siblings in a `Row`; each `maxLength: 1`, `textInputType: TextInputType.number`; `FocusNode` chain for auto-advance; paste handled via clipboard listener |
| Dropdown / category select | `showModalBottomSheet` (Stitch overlay OVR-01); the trigger field is a `GestureDetector` wrapping an `InputDecoration`-styled container (not a native `DropdownButton`) — per forms-controls.md §5 |
| Radio group (§9) | `RadioGroup` + `RadioListTile` styled to 48dp row height; label right-aligned in RTL |
| Switch (§10) | `SwitchListTile` with `activeColor: brand-primary`, content-padding for 48dp row |
| Chips (filter, category, status) | `Chip` / `FilterChip` / `ActionChip` with custom `ChipThemeData`; AI suggestion chip uses `ai-container` background |
| Bottom nav | `NavigationBar` (Material 3) with 4 `NavigationDestination` items; `backgroundColor: surface`, `indicatorColor: brand-primary` for selected |
| FAB | `FloatingActionButton` (large, `backgroundColor: brand-primary`, `foregroundColor: text-on-primary`); `Positioned` at bottom-start (RTL-aware) |
| Bottom sheet | `showModalBottomSheet` with `shape: RoundedRectangleBorder(borderRadius: radius.lg)`; enter via slide-up transition (250ms) |
| Dialog | `showDialog` + `AlertDialog` with `shape: RoundedRectangleBorder(borderRadius: radius.lg)`; destructive button uses `color.status.error` background |
| Snackbar/toast | `ScaffoldMessenger.showSnackBar` with custom `SnackBarThemeData`; auto-dismiss 4s/10s; success = green container, error = red container |
| Empty state | custom `EmptyState` widget (illustration + title + subtitle + CTA(s)); centered in a `Center` inside the surface's body |
| Skeleton | custom `Skeleton` widget with `AnimatedOpacity` (1.2s pulse); `Container` blocks with `surface-variant` fill |
| Progress bar (determinate) | `LinearProgressIndicator` with `value`, `minHeight: 4dp`, `backgroundColor: surface-variant`, `valueColor: brand-primary`; `direction: Axis.horizontal` (LTR fill) |
| Progress spinner (small) | `CircularProgressIndicator` with `strokeWidth: 2`, `color: brand-primary`; only inside image-load placeholders and in-button loading |
| AI processing card | custom `AiProcessingCard` widget: `Row` with AI icon + text + countdown + manual-escape link; `AnimatedOpacity` for countdown pulse |
| Ledger list | `ListView.builder` with date-header sticky (`SliverPersistentHeader` or custom); row = `ListTile` with custom content |
| Detail sheet | `SingleChildScrollView` with `Column`; amount hero = `Text` with `type.headline`; receipt thumbnail = `GestureDetector` wrapping `ClipRRect` image |
| Category picker sheet | `ListView` inside `showModalBottomSheet`; rows are `RadioListTile` with optional indigo chip for AI suggestion |
| Filter chips bar | `SingleChildScrollView(horizontal)` of `FilterChip` widgets; active = filled `surface`, inactive = outline |
| Date range picker | `showDateRangePicker` (native) with locale set to Arabic; or custom bottom-sheet calendar if native doesn't support Saturday first-day |
| Provenance note (Detail) | `Text` with `type.caption`, `color.ai` for AI; `color.text-secondary` for manual |

## 3. RTL handling in Flutter

- **`Directionality` widget:** wrap the app in `Directionality(textDirection: TextDirection.rtl)` as the default; no per-screen override.
- **`matchTextDirection: true`** on directional `Icon` widgets (`Icon(Icons.arrow_back, matchTextDirection: true)`) to auto-mirror in RTL.
- **`Bidi` isolation:** wrap mixed-content text (amounts, dates with Latin) in `Bidi.isolate` spans or use `RichText` with explicit `TextDirection.ltr` for the Latin fragment inside `TextDirection.rtl` parent.
- **`EdgeInsetsDirectional`** instead of `EdgeInsets` for all directional padding (start/end, not left/right).
- **`Align` / `Positioned`** use `AlignmentDirectional` for FAB (bottom-start = bottom-left in RTL).
- **`ListView` scroll direction:** unchanged (RTL doesn't affect vertical scroll direction).
- **No `Transform` mirroring** — rely on `Directionality` and `matchTextDirection` only.

## 4. State management (pattern guidance, not prescriptive)

- The design system is stateless; it doesn't prescribe a state-management package (Provider, Riverpod, Bloc, etc.). But it defines what **states** each surface must handle (from `feedback-states.md` and `ux-states.md`):
  - `idle / loading / loaded / error / empty / offline / syncing` for data surfaces.
  - `idle / processing / success / failure / timeout / non-receipt` for AI capture.
  - `idle / pending / syncing / confirmed / failed` for offline sync.
- The Flutter developer chooses a state-management pattern that supports these states cleanly (Bloc is a natural fit for the state machines; Provider/Riverpod for simpler surfaces).
- **Key invariant:** every state is visible (no hidden loading); every error has a retry; every AI processing has a manual escape — these are design rules, not just code concerns.

## 5. Key packages (conceptual, not exhaustive)

| Need | Package |
|---|---|
| Fonts (Cairo) | `google_fonts` |
| HTTP / API | `dio` or `http` (per backend architecture) |
| Local storage (pending queue) | `hive` or `sqflite` (lightweight; no heavy DB) |
| Image handling (receipt capture) | `image_picker` |
| Camera (receipt capture) | `camera` (if needed beyond image_picker) |
| Permissions | `permission_handler` |
| Native calendar (date picker) | built-in `showDateRangePicker` with locale |
| Localization | `flutter_localizations` + `intl` + ARB files |
| Connectivity check | `connectivity_plus` |
| Sharing (export) | `share_plus` |

**Anti-patterns:** using a heavy state-management package for a simple screen; using `setState` for complex async state machines; using `shared_preferences` for structured data (pending queue).

## 6. Low-end Android constraints (NFR-LOWDEV-001)

- **No heavy animations:** no `AnimatedBuilder` with blur, no `BackdropFilter`, no `ShaderMask` animations, no `Transform` 3D.
- **Image handling:** downscale receipt images before display (max 800dp width for thumbnails); no full-resolution image in a list.
- **ListView:** use `ListView.builder` (lazy) for all lists; never build all rows at once.
- **Shadows:** minimal (elevation via border, not box-shadow — per `tokens.md` §5).
- **Font loading:** Cairo is a modest-sized font; preload in `main.dart` to avoid FOUC.
- **Memory:** dispose `FocusNode`, `AnimationController`, `ScrollController` properly; don't hold references to full-resolution images.

## 7. Localization setup

- `flutter_localizations` delegates + `AppLocalizations` generated from ARB files.
- Arabic is the primary locale; English is the secondary locale (toggle in Settings).
- `localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate]`.
- `supportedLocales: [Locale('ar'), Locale('en')]`.
- All user-facing strings go through `AppLocalizations.of(context).key` — **no hardcoded Arabic/English strings in widgets**.

## 8. Anti-pattern summary

| Anti-pattern | Why |
|---|---|
| Using `EdgeInsets.only(left: ...)` instead of `EdgeInsetsDirectional` | breaks in RTL |
| Forgetting `matchTextDirection` on directional icons | arrows point the wrong way in RTL |
| Hardcoding hex colors in widgets instead of using tokens | violates single-source-of-truth |
| Using `setState` for complex async state machines | leads to unhandled states (loading/error/offline) |
| Building all list rows at once (no `ListView.builder`) | memory blowup on low-end devices |
| Animating shadows/backdrop blur | violates NFR-LOWDEV-001 |
| Placeholder text as the only field label | violates interaction-model §3; inaccessible |
| Using `primary` color for income/expense | income/expense have their own tokens |