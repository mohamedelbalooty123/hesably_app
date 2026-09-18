# Stitch Screen Map
> **Source of Truth**: Stitch Project `13492244755370590843` — "Full Application Design Review"
> **Inspected**: 2026-09-18 via Stitch MCP `list_screens`
> **Visual Authority**: THE NEW STITCH PROJECT IS THE ONLY VISUAL SOURCE OF TRUTH FOR THE HESABLY MOBILE UI.
> **Historical Warning**: `docs/mobile-design/` IS HISTORICAL/DEPRECATED AND MUST NOT OVERRIDE THE APPROVED STITCH DESIGN.

---

## Design System Tokens (from Stitch Project)

| Token | Value |
|---|---|
| Primary | `#004328` |
| Primary Container | `#0D5C3A` |
| Secondary | `#006D37` |
| Surface | `#FAF8FF` |
| Error | `#BA1A1A` |
| Headline Font | **Cairo** |
| Body Font | **Cairo** |
| Label Font | **Tajawal** |
| Reference Viewport | 390 × 852 dp |
| Roundness | 8dp base radius |
| Direction | **RTL / Arabic-first** |

---

## Screen Inventory (from Stitch MCP)

Total mobile screens identified: **35 screen instances** in Stitch canvas.
Primary named screens: **29 approved visual targets** (excluding uploaded docs, logo, and design system instances).

---

## Primary Screens

| SCR ID | Stitch Screen Title | Stitch Screen ID | Flutter Feature | Flutter Route | Flutter Page | Primary State | Related Overlays | Status |
|---|---|---|---|---|---|---|---|---|
| SCR-01 | شاشة البداية - حاسبلي (Splash) | `ef6d386b0afc43b394b0824dcdd5f255` | `app` | `/` | `SplashPage` | Auth initialization / loading | — | Approved / Not Implemented |
| SCR-02 | شاشة البداية والتحميل (Loading) | `d69f9e900dcf48d884c6f040351eb5ad` | `app` | `/` | `SplashPage` | Loading/bootstrapping | — | Approved / Not Implemented |
| SCR-03 | تسجيل الدخول برقم الهاتف (Phone Login) | `d4e0e71dcb4f4a6fb5fe9bfe63e2f6c5` | `auth` | `/login` | `LoginPage` | Unauthenticated / form idle | OTP sheet | Approved / Not Implemented |
| SCR-04 | تأكيد رمز التحقق OTP (OTP Verify) | `dd6b0d055b01401cb7a8dec45569d4ac` | `auth` | `/verify` | `OtpVerifyPage` | Awaiting OTP / resend countdown | — | Approved / Not Implemented |
| SCR-04b | إعداد النشاط التجاري (Business Setup) | `82469d81ee5f474a8bd9175deae5daa9` | `business_setup` | `/setup` | `BusinessSetupPage` | First-run onboarding | — | Approved / Not Implemented |
| SCR-05 | الرئيسية - لوحة التحكم Loaded (v1) | `41949ce1ad184b779cd02433d7fc09a5` | `home` | `/home` | `HomePage` | Loaded with data | FAB, OVR-01 | Approved / Not Implemented |
| SCR-05b | الرئيسية - لوحة التحكم Loaded (v2) | `46bf59097ad64302957a0e611162d5ef` | `home` | `/home` | `HomePage` | Loaded (alternate layout) | FAB, OVR-01 | Approved / Not Implemented |
| SCR-05c | SCR-05 — Home Empty | `d991b5dab7c2429689d459a29c0b015a` | `home` | `/home` | `HomePage` | Empty state | FAB | Approved / Not Implemented |
| SCR-06 | SCR-06 — Transactions Empty | `19d0d216c5024c1e87fd3f081d8613bd` | `transactions` | `/transactions` | `TransactionsPage` | Empty state | FAB | Approved / Not Implemented |
| SCR-06b | سجل المعاملات والتصفية Loaded (v1) | `e47a5d6b64bd4a268407649a6d460dc9` | `transactions` | `/transactions` | `TransactionsPage` | Loaded with data | OVR-01, OVR-03 | Approved / Not Implemented |
| SCR-06c | سجل المعاملات والتصفية Loaded (v2) | `6c5f644e5bd54fe19b8ca4d7a72ac7d2` | `transactions` | `/transactions` | `TransactionsPage` | Loaded with filters visible | OVR-01, OVR-03 | Approved / Not Implemented |
| SCR-06d | SCR-06 — Transactions Filtered | `9c4329ec137c48b2bde0a69e8c40ec12` | `transactions` | `/transactions` | `TransactionsPage` | Filtered active state | — | Approved / Not Implemented |
| SCR-07 | تفاصيل المعاملة (Transaction Detail v1) | `61c9e695e78646cfaf4da8f86ddd1ec3` | `transactions` | `/transaction/:id` | `TransactionDetailPage` | Detail loaded | SCR-17 receipt viewer | Approved / Not Implemented |
| SCR-07b | تفاصيل المعاملة (Transaction Detail v2) | `acd96bda3f5a4172ab5c419c6995f31b` | `transactions` | `/transaction/:id` | `TransactionDetailPage` | Detail alternate layout | SCR-17 | Approved / Not Implemented |
| SCR-08 | SCR-08 — Transaction Type | `49f75c36cecc4b0994c46aba4d2c68db` | `transactions` | `/transaction/type` | `TransactionTypePage` | Type selector | — | Approved / Not Implemented |
| SCR-09 | SCR-09 — Capture / AI Processing (v1) | `3effb99ba766475e922e26e56b3f5065` | `receipt_capture` | `/capture` | `CapturePage` | Camera + AI processing | Quality warning | Approved / Not Implemented |
| SCR-09b | SCR-09 — Capture / AI Processing (v2) | `29019306606144e78780a62daaaa94c9` | `receipt_capture` | `/capture` | `CapturePage` | AI processing overlay | OVR-08 | Approved / Not Implemented |
| SCR-10 | مراجعة وتأكيد الفاتورة (AI Review v1) | `ede7d274ae424fe9941045f8afbc19cc` | `ai_extraction` | `/review` | `AiReviewPage` | Populated, pending confirm | OVR-08 low-confidence | Approved / Not Implemented |
| SCR-10b | مراجعة وتأكيد الفاتورة (AI Review v2) | `5f665f30721a431b817ea896284eb956` | `ai_extraction` | `/review` | `AiReviewPage` | Alternate field layout | OVR-08 | Approved / Not Implemented |
| SCR-11 | SCR-11 — Reports Empty | `c048a347b1494b088205f91ca618b0b9` | `reports` | `/reports` | `ReportsPage` | Empty state | OVR-02, OVR-03 | Approved / Not Implemented |
| SCR-12a | التقارير المالية والتصدير (Reports Loaded v1) | `523c209b78424bb197b50eb9dce6845c` | `reports` | `/reports` | `ReportsPage` | Loaded with data | OVR-02, OVR-03 | Approved / Not Implemented |
| SCR-12b | التقارير المالية والتصدير (Reports Loaded v2) | `2bd055696f60426e8ee6764bd02642c5` | `reports` | `/reports` | `ReportsPage` | Loaded alternate layout | OVR-02, OVR-03 | Approved / Not Implemented |
| SCR-13 | SCR-13 — Category Management | `6ff26ecd24694ad39be161f1b9523579` | `categories` | `/categories` | `CategoriesPage` | List with defaults | OVR-04 delete | Approved / Not Implemented |
| SCR-14 | الفواتير المعلقة والمزامنة (Pending Queue) | `895b310835af43a0b7d4dcfa768b8745` | `receipt_capture` | `/pending` | `PendingQueuePage` | Offline pending + syncing | — | Approved / Not Implemented |
| SCR-15 | SCR-15 — Category Add / Rename | `75afc1e9e6394598890617db7f1ae683` | `categories` | `/categories/edit` | `CategoryEditPage` | Add/rename form | OVR-04 | Approved / Not Implemented |
| SCR-16 | SCR-16 — Web Access Enabled | `68944ac6e7c7484dad711530d1fc700c` | `settings` | `/settings/web-access` | `WebAccessPage` | Web access activated | — | Approved / Not Implemented |
| SCR-17a | SCR-17 — Receipt Viewer (mobile) | `8cb731df85ab4eba8e6fee9196227433` | `transactions` | `/receipt/:id` | `ReceiptViewerPage` | Full-screen receipt | — | Approved / Not Implemented |
| SCR-17b | SCR-17 — Receipt Viewer (overlay) | `c422e9d08ef044be8314c4f3ef509594` | `transactions` | — | `ReceiptViewerSheet` | Bottom sheet / modal | — | Approved / Not Implemented |
| SCR-18a | الإعدادات وإدارة الحساب (Settings v1) | `79a9361d60f14d4ca2426e4286e7be12` | `settings` | `/settings` | `SettingsPage` | Loaded | OVR-05, OVR-06 | Approved / Not Implemented |
| SCR-18b | الإعدادات وإدارة الحساب (Settings v2) | `3dd531e84c1c4d50aad2502c790c381e` | `settings` | `/settings` | `SettingsPage` | Alternate layout | OVR-05, OVR-06 | Approved / Not Implemented |

---

## Overlays / Dialogs / Sheets

| OVR ID | Stitch Screen Title | Stitch Screen ID | Type | Used By | Status |
|---|---|---|---|---|---|
| OVR-01 | OVR-01 — Category Picker | `f70310f7349d4a92bb2afd981c53a1d0` | Bottom Sheet | SCR-06 filters, SCR-10 review | Approved / Not Implemented |
| OVR-02 | OVR-02 — Export Options | `b09b6a2edb6547c398da9cf2066c783d` | Bottom Sheet | SCR-12 reports | Approved / Not Implemented |
| OVR-03 | OVR-03 — Date Range Picker | `89b506f080774d698c819dccd8384cdb` | Bottom Sheet | SCR-06 filters, SCR-12 reports | Approved / Not Implemented |
| OVR-04 | OVR-04 — Delete Confirmation | `ecdcb8b1cb724f23acb9e7496fa26800` | Dialog | SCR-13 categories, SCR-07 transaction | Approved / Not Implemented |
| OVR-05 | OVR-05 — Account Delete | `976f26c0ed184ef4bd8830bb51f91553` | Dialog | SCR-18 settings | Approved / Not Implemented |
| OVR-06 | OVR-06 — Logout Confirmation | `fc1dd9825d05420d9cb8e6c8df404c54` | Dialog | SCR-18 settings | Approved / Not Implemented |
| OVR-07 | OVR-07 — Unsaved Changes | `444f57ee2d874f38b56c340197750c69` | Dialog | SCR-10 review, SCR-04b setup | Approved / Not Implemented |
| OVR-08 | OVR-08 — AI Low-Confidence Advisory | `736e050c62b44d749953b6465427104a` | Inline / Advisory | SCR-09 capture, SCR-10 review | Approved / Not Implemented |

---

## Non-Screen Stitch Entries (Excluded from mapping)

These entries exist in the Stitch project as uploaded reference documents or assets, not visual screens:

| Title | Type | Note |
|---|---|---|
| `assumptions.md` | Uploaded markdown | Reference doc — ignore as design source |
| `open-questions.md` | Uploaded markdown | Reference doc — ignore as design source |
| `requirements.md` | Uploaded markdown | Reference doc — ignore as design source |
| `business-rules.md` | Uploaded markdown | Reference doc — ignore as design source |
| `acceptance-criteria.md` | Uploaded markdown | Reference doc — ignore as design source |
| `feature-list.md` | Uploaded markdown | Reference doc — ignore as design source |
| `user-flow-mobile.md` | Uploaded markdown | Reference doc — ignore as design source |
| `شعار حاسبلي` (Logo) | SVG Asset | Brand asset — use as reference for app icon only |
| Design System Instances × 2 | Canvas asset | Token reference only |

---

## Unresolved Mappings

None at this time. All 29 primary visual targets have been mapped to Flutter features and routes.

> If future Stitch screens are added, update this document immediately and mark new entries as `Approved / Not Implemented`.

---

## Navigation Bottom Bar

The approved design defines **4 tabs** in RTL order:
1. **الرئيسية** → `home` → `/home`
2. **المعاملات** → `transactions` → `/transactions`
3. **التقارير** → `reports` → `/reports`
4. **الإعدادات** → `settings` → `/settings`

Plus a **persistent FAB** (camera/capture) for quick receipt entry, not a tab.
