# Stitch Screen Map
> **Source of Truth**: Stitch Project `661013469764921318` — "Hesably — Smart Invoice Assistant"
> **Inspected**: 2026-09-18 via Stitch MCP `list_screens` / `get_project`
> **Visual Authority**: THE STITCH PROJECT IS THE ONLY VISUAL SOURCE OF TRUTH FOR THE HESABLY MOBILE UI.
> **Historical Warning**: `docs/mobile-design/` IS HISTORICAL/DEPRECATED AND MUST NOT OVERRIDE THE APPROVED STITCH DESIGN.

---

## Design System Tokens (from Stitch Project)

The current project's design theme (DESC: `designTheme` on `get_project`) declares:

| Token | Value |
|---|---|
| Color Mode | **Light** only (no dark in canvas) |
| Seed / Primary | `#0A7A3D` |
| Custom Color | `#0A7A3D` (brand green) |
| Background (canvas) | `#FAFAF8` |
| Roundness | 4dp base (Stitch setting); 8dp applied to buttons/cards per in-canvas "Kinetic Finance RTL" token sheet |
| Headline Font | Cairo (proxied by **Inter** in Stitch) |
| Body Font | Cairo (proxied by **Inter** in Stitch) |
| Direction | **RTL / Arabic-first** |
| Base spacing grid | 4dp |
| Screen margins | 16px |
| Touch target min | 48dp |
| Bottom nav height | 64dp |
| FAB | 56dp, brand-primary fill, white add icon |
| Bottom nav tabs | 4 (Home rightmost → Settings leftmost in RTL) |

> Font note: Cairo is bundled as TrueType in `apps/mobile/assets/fonts/`. Inter is Stitch's stand-in (*proxied*) for Cairo and must NOT be adopted. **Tajawal is dropped** — it no longer appears in the current Stitch project (only Cairo via Inter proxy).

> Design system instance `assets/badb0ff04f65483a997f1652b06563ab` ("Kinetic Finance RTL", 960×540) is the in-canvas token sheet. Primary stays `#0A7A3D` (with `onPrimary` `#FFFFFF`); the M3 tonal `#005F2D` from that sheet is superseded by both systems' stated button/FAB intent (solid `#0A7A3D` + white).

---

## Screen Inventory (from Stitch MCP)

Total canvas instances: **36**
- **33 UI implementation targets** (screen instances with HTML)
- **2 non-screen assets** (brand icon + ledger illustration)
- **1 design system instance** (`assets_badb0ff…`)

Primary screens by flow:

| # | Stitch Screen Title | Stitch Screen ID | Flutter Feature | Flutter Route | Primary State | Status |
|---|---|---|---|---|---|---|
| 1 | Splash Screen | `c91dad5d51d04f6db690703da6ac63af` | `app` | `/` | Auth initialization / loading | Approved / Not Implemented |
| 2 | Phone Entry Screen | `cd173b5262014762bb1caef88abf431f` | `auth` | `/login` | Unauthenticated / form idle | Approved / Not Implemented |
| 3 | OTP Verification Screen | `6bf42c7c77cd4b53943ddb39afa59dac` | `auth` | `/verify` | Awaiting OTP / resend countdown | Approved / Not Implemented |
| 4 | OTP Verification Screen (alt) | `168c9b6e876840d381a7cb50c91359f2` | `auth` | `/verify` | Awaiting OTP (alternate layout) | Approved / Not Implemented |
| 5 | Business Setup Screen — Refined | `62fb5278d18248109464ab53e55d007a` | `business_setup` | `/setup` | First-run onboarding | Approved / Not Implemented |
| 6 | Business Setup Form | `404ffa285bb94927bd38d133bbaf99e1` | `business_setup` | `/setup` | First-run onboarding (form) | Approved / Not Implemented |
| 7 | Home Dashboard — Financial Overview | `a70527bf571b43bc8a4e6b0afc4ca48a` | `home` | `/home` | Loaded with data | Approved / Not Implemented |
| 8 | Home Dashboard — Financial Overview (alt ×3) | `23336ac2860f42a9b0bae678fcf0491f`, `93b58b225fd8449b979d7a785935833c`, `f86023af5992420ba40bfb863cef1aac` | `home` | `/home` | Loaded (alternate layouts) | Approved / Not Implemented |
| 9 | Home Dashboard — Data State | `8a5ca89ea11f479daa716328554fadfa` | `home` | `/home` | Loaded (data) | Approved / Not Implemented |
| 10 | Home Screen — Empty State (×4) | `427962e23b0745bcaa5b05e0b8a08739`, `ac4b3ef488c74ec4b740f5b4d7a04c7e`, `085cf857150346d9ae03db8bae2a8e22`, `0813bbdb1ef94001bcfd16e472619a79` | `home` | `/home` | Empty state | Approved / Not Implemented |
| 11 | Home Dashboard — Offline Pending State (×2) | `f53448d2f93e4f56b5d74b5b355fd9ab`, `0d49f8d9eded44a5b22158c3e4a08b46` | `home` | `/home` | Offline pending queue | Approved / Not Implemented |
| 12 | Home Screen — Offline State | `5af8c6c838684a75b1c86960c6bb09b4` | `home` | `/home` | Offline (no backend) | Approved / Not Implemented |
| 13 | Transactions List — Populated State (×3) | `9c0b3ffafab54b50925b32c2f16fb3b1`, `d4e26ff680ee4e96a63e67cd7c8d0a78`, `4f7e934100f5408396c6c66cfd8c1313` | `transactions` | `/transactions` | Loaded with data | Approved / Not Implemented |
| 14 | Transactions List — Empty State (×2) | `e2924629ed0c438f80a34d7276b5fc8d`, `4c58e95ce8ad47889c7e4991681b73df` | `transactions` | `/transactions` | Empty state | Approved / Not Implemented |
| 15 | Transactions — Search Results Empty State | `fb5ccdad061448e8beda746bcccffba7` | `transactions` | `/transactions` | Search no-results | Approved / Not Implemented |
| 16 | Transaction Type Selection Screen (×4) | `ec48fa005cf84989b6c1ce543e546f99`, `cf51ad616133426f86c33747ee0b3a89`, `46af95d956154531ac1bbe323dde6174`, `6b9855f5e87b49f786bf5e38930f1be3` | `transactions` | `/transaction/type` | Type selector | Approved / Not Implemented |
| 17 | Transaction Detail — Confirmed State (×3) | `c0d2b2812db34fd0b1b4fca409e086a2`, `3566966955514fc499a6ede43595e3f2`, `7856adbc20aa47199ed28053dbc692db` | `transactions` | `/transaction/:id` | Detail loaded | Approved / Not Implemented |
| 18 | Receipt AI Processing Screen | `29f3b869e1a94beda5a59bd01994f2e3` | `receipt_capture` | `/capture` | AI processing in flight | Approved / Not Implemented |
| 19 | Review & Save Transaction — AI Draft State | `2e29b355f00b4112bf35aeb29678d847` | `ai_extraction` | `/review` | Populated, pending confirm | Approved / Not Implemented |

---

## Current Canvas Gaps (vs. `docs/mobile-design/` historical log)

The **current** Stitch project does NOT contain these screens that existed conceptually in the historical mobile-design docs:

- **Reports** screens (empty / loaded / export) — no visual in current canvas
- **Settings** screens (settings / web access)
- **Categories** management screens
- **Receipt viewer** (full-screen / modal) screens
- **Pending queue** standalone screen (offline states are expressed on Home instead)

**These flows are NOT dropped** — they are documented product features. Their implementation will follow the historical `docs/mobile-app/` architecture and existing API contracts until Stitch screens are added. Any future Stitch screen must be appended to this map with status `Approved / Not Implemented`.

---

## Non-UI Stitch Entries (Excluded from UI mapping)

| Title | Screen ID | Type | Note |
|---|---|---|---|
| Hesably Brand Icon | `381d9ec4d2af4d9096d7eb88ed312e9b` | 1024×1024 asset | Brand asset — reference for app icon only |
| Flat muted ledger receipt illustration | `8be0ad194e4541238f427277f08f1941` | 1024×1024 asset | Empty-state illustration reference |
| Kinetic Finance RTL (design system) | `assets_badb0ff04f65483a997f1652b06563ab` | 960×540 DESIGN_SYSTEM_INSTANCE | Token reference only |

> The **old** project `13492244755370590843` and its screen IDs are **stale and must not be referenced** for implementation.

---

## Navigation Bottom Bar

The approved design defines **4 tabs** in RTL order:
1. **الرئيسية** → `home` → `/home`
2. **المعاملات** → `transactions` → `/transactions`
3. **التقارير** → `reports` → `/reports`
4. **الإعدادات** → `settings` → `/settings`

Plus a **persistent FAB** (camera/capture) for quick receipt entry, not a tab.