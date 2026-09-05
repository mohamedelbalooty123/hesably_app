# Screen Inventory — Smart Invoice Assistant (Mobile)

**Purpose:** every full-screen route (`SCR-xx`) and reusable overlay (`OVR-xx`) in MVP, with purpose, content, actions, entry/exit, and state notes. State depth lives in `ux-states.md`; connections in `navigation-map.md`.
**Label authority:** `information-architecture.md` §5.

---

## Screens (full-screen routes)

### SCR-01 Splash — شاشة البداية
| Field | Content |
|---|---|
| Purpose | Session check + brand moment (FR-AUTH-007) |
| Content | App mark; brief loading |
| Actions | None (auto-routes: Home or Phone Entry) |
| Entry | App cold open |
| Exit | Home (SCR-05) if session, else Phone Entry (SCR-02) |
| States | Loading (brief) → route; session-expired → Phone Entry |

### SCR-02 Phone Entry — أدخل رقم الهاتف (Login)
| Field | Content |
|---|---|
| Purpose | Phone-only sign-up/login (FR-AUTH-001/002, BR-AUTH-001) |
| Content | Phone input (intl format, `+20` default), "إرسال الكود" (Send code) |
| Actions | Send OTP → OTP (SCR-03) |
| Entry | Splash (no session), session expired, logout, account deleted |
| Exit | OTP (SCR-03) |
| States | Validation (missing/invalid number), network error → retry |

### SCR-03 OTP Verification — رمز التحقق
| Field | Content |
|---|---|
| Purpose | Verify 6-digit code (FR-AUTH-003) |
| Content | OTP input (6 digits), resend control with 60s cooldown, "تواجه مشكلة؟" support link (FR-AUTH-004/005, Q-001) |
| Actions | Verify → Home or Business Setup; Resend (after cooldown) |
| Entry | Phone Entry (SCR-02) |
| Exit | Business Setup (SCR-04) on first login, else Home (SCR-05) |
| States | Wrong code (inline), resend cooldown, network |

### SCR-04 Business Setup — بيانات النشاط التجاري (first-login only)
| Field | Content |
|---|---|
| Purpose | One-time business profile (FR-ONBOARD-001…005) |
| Content | Business name (text), business type picker (Retail / Restaurant / Pharmacy / Service / Other), currency note (EGP, fixed) |
| Actions | Confirm → creates business + seeds 10 default categories → Home |
| Entry | First successful OTP verification |
| Exit | Home (SCR-05) |
| States | Required-field validation; cannot skip |

### SCR-05 Home Dashboard — الرئيسية
| Field | Content |
|---|---|
| Purpose | Glanceable current-month summary + capture entry (FR-DASH-001…003) |
| Content | Summary cards: Total income, Total expenses, Net (EGP, current month); category breakdown (list or simple bar, sorted by spend); period comparison vs previous month ("+15% vs last month"); recent entries shortcut; **FAB** إضافة معاملة |
| Actions | FAB → Add flow (SCR-08); row/breakdown taps → Transactions/Reports; tab switch |
| Entry | Post-onboarding, tab selection |
| Exit | Add flow, other tabs |
| States | Loading (skeletons), empty (no transactions → empty state + FAB CTA), error (couldn't load → retry) |

### SCR-06 Transactions List — المعاملات
| Field | Content |
|---|---|
| Purpose | Full record, filterable and searchable (FR-TRANS-001…008) |
| Content | Filter bar (date range, category, type, amount range) + search by vendor/customer name (Q-022); grouped chronological list (most recent first, date-grouped); rows: thumbnail, party name, category, amount (color-coded income/expense), date (FR-TRANS-002/003) |
| Actions | Apply/clear filters; search (debounced); row tap → Detail; FAB remains accessible from Home only |
| Entry | Transactions tab |
| Exit | Detail (SCR-07) |
| States | Loading, empty (no transactions; with applied filters → "no matches" variant), search-no-results, error, offline |

### SCR-07 Transaction Detail — تفاصيل المعاملة
| Field | Content |
|---|---|
| Purpose | Full read-only record (FR-TRANS-009/010) |
| Content | Type, amount (EGP), date, party name (if any), category, line items (if any), receipt image (thumbnail → full-screen), entry source note ("تم الاستخراج الذكي" AI / manual), created/updated info |
| Actions | Edit → form (SCR-10); Delete → confirmation (OVR-04); receipt thumbnail → viewer (SCR-15) |
| Entry | Row tap in Transactions (SCR-06); recent-entry tap in Home |
| Exit | Transactions list (back), Edit form, Viewer (overlay) |
| States | Loading, error (record gone → return to list), offline (image may not load) |

### SCR-08 Transaction Type — نوع المعاملة (Add-flow step)
| Field | Content |
|---|---|
| Purpose | One deliberate choice before capture (FR-CAPTURE-002/006) |
| Content | Two large choices: مبيعات/إيرادات (income) and مشتريات/مصروفات (expense) |
| Actions | Pick type → Capture (SCR-09) or straight to Manual (SCR-10 via "إدخال يدوي") |
| Entry | Home FAB |
| Exit | Capture (SCR-09) or Manual form (SCR-10) |
| States | — (no async) |

### SCR-09 Capture — التقاط الفاتورة (Add-flow step)
| Field | Content |
|---|---|
| Purpose | Camera-first capture with gallery fallback + quality gating (FR-CAPTURE-003/004/005, Q-020); **offline = local pending capture** (Q-018 flipped, ADR-007) |
| Content | Camera viewfinder; "فتح من المعرض" (gallery) action; "إدخال يدوي" (manual skip); inline quality result (PASS / WARNING with continue / REJECT with retake guidance); AI processing state (visible 15s ceiling, Q-009); offline → "تم الحفظ محليًا — ستُعالج عند توفر الإنترنت" pending banner |
| Actions | Shoot/retake; pick gallery; continue on warning; manual skip; on processing: wait / timeout → manual; offline: keep as pending / retry when online |
| Entry | Type selected (SCR-08) |
| Exit | Processing → Review & Save (SCR-10) with prefill; manual → empty form (SCR-10); offline → Pending list ("waiting for connection"); back → type (SCR-08) |
| States | Camera permission denied, gallery unavailable, blurry/dark warning/reject, AI processing, AI failure/timeout/non-receipt, offline (local pending capture) |

### SCR-10 Transaction Form — Review & Save (مراجعة وحفظ)
| Field | Content |
|---|---|
| Purpose | Single form: AI pre-fill review, manual entry, and edit of existing entries (FR-REVIEW-001…007, FR-CAPTURE-007) |
| Content | Type (fixed from entry, not editable mid-flow), date, amount (EGP), vendor/customer (`party_name`, optional), category picker (defaults to AI suggestion), line items (optional), receipt thumbnail (AI path) → full-screen viewer; **low-confidence flags** (<80%) on flagged fields (FR-AI-003/004, Q-008) |
| Actions | Save (confirm — creates record + links image, if any); Back with unsaved content → discard confirmation (OVR-07) |
| Entry | Capture pre-fill, manual skip, or Edit from Detail |
| Exit | Save → success toast → return to origin (Home or Detail); cancel |
| States | Validation (amount > 0, required date/category), save-in-progress (row + image one logical commit), save error (retry), edit mode vs create mode, offline → save deferred as pending (req. restore on reconnect) |

---

### SCR-11 Reports — التقارير
| Field | Content |
|---|---|
| Purpose | Period-driven insights + export (FR-DASH-004…007) |
| Content | Period selector: This Week / This Month / Last Month / YTD / Custom (Q-011); summary: total income, total expenses, net; category breakdown (list + share bars); trend/steps across the period; **Export** button |
| Actions | Change period; Custom → date-range picker (OVR-03); Export → OVR-02 |
| Entry | Reports tab |
| Exit | Export sheet; back/tab switch |
| States | Loading (skeletons), empty (no data in period → explain + hint), error (retry), offline |

### SCR-12 Settings — الإعدادات
| Field | Content |
|---|---|
| Purpose | Account, business, and app settings (FR-SETTINGS-001…006) |
| Content | Groups: Business (name/type → SCR-13); Data (categories → SCR-14); Access (Web access → SCR-16); App (Language toggle); Safety (Logout → OVR-06, Delete Account → OVR-05) |
| Actions | Row taps to sub-pages; language applies immediately; destructive actions behind confirmations |
| Entry | Settings tab |
| Exit | Sub-pages; back/tab switch |
| States | Loading (profile), error |

### SCR-13 Business Profile — الملف التجاري
| Field | Content |
|---|---|
| Purpose | Edit business name/type (FR-SETTINGS-001) |
| Content | Name field, type picker, currency note (EGP — read-only, Q-012) |
| Actions | Save → success → back to Settings |
| Entry | Settings → Business row |
| Exit | Settings (back) |
| States | Validation, save-in-progress, save error |

### SCR-14 Manage Categories — إدارة التصنيفات
| Field | Content |
|---|---|
| Purpose | See + manage category list (FR-CATEGORY-001…005, Q-010) |
| Content | Defaults (10, hideable, not deletable/renameable — BR-CATEGORY-004) as toggles; customs (rename/delete when unused) in a separate group; "إضافة تصنيف" |
| Actions | Add/rename custom → SCR-15; hide/unhide default (toggle); delete unused custom → confirmation; unused drop-down when showing per-transaction |
| Entry | Settings → Data → Categories |
| Exit | Settings/Settings-group; back |
| States | Loading, empty (no customs — hint), error; delete blocked when category in use (inline error) |

### SCR-15 Category Form — تصنيف جديد / تعديل (modal or push)
| Field | Content |
|---|---|
| Purpose | Name a new custom category or rename one (FR-CATEGORY-002) |
| Content | Name field (+ Arabic-first entry, no emoji/duplicate), optional save |
| Actions | Save / Cancel |
| Entry | Manage Categories (SCR-14) |
| Exit | Back to SCR-14 list, refreshed |
| States | Validation (required, unique, reserved-name check) |

### SCR-16 Enable Web Access — تفعيل الدخول من الويب
| Field | Content |
|---|---|
| Purpose | Link an email identity so the dashboard can sign in (FR-SETTINGS-003, Q-016, web-access-contract §3) |
| Content | Info text, email input field, "إرسال رابط الدخول", success state ("تم إرسال الرابط — افتحه من بريدك"), error states |
| Actions | Send link; later "إلغاء الربط" (unlink) with confirmation |
| Entry | Settings → Access → Web access |
| Exit | Settings (back) |
| States | Loading (sending), success (link sent), error (invalid email / not found), unlink confirmation |

### SCR-17 Receipt Viewer — عرض صورة الفاتورة
| Field | Content |
|---|---|
| Purpose | Full-screen, read-only receipt image (storage-contracts §4) |
| Content | The image (from private `receipts` bucket via signed URL), pinch/zoom |
| Actions | Close |
| Entry | Detail (SCR-07) thumbnail; Review form (SCR-10) thumbnail |
| Exit | Close → previous screen |
| States | Loading, not-found/deleted, offline (can't load → message + retry) |

---

## Overlays (non-route surfaces)

### OVR-01 Category Picker — اختيار التصنيف
Bottom sheet used by SCR-10 (and filter in SCR-06 as a filter picker — same sheet, filter mode). Lists business categories: defaults then customs; searchable for long lists; shows AI suggestion badge. Selecting returns the label.

### OVR-02 Export Options — خيارات التصدير
Bottom sheet from SCR-11. Format choice (PDF / Excel / CSV); period row (defaults to current view — Q-014); "تصدير" action → client-side generation → share sheet (FR-EXPORT-004). Note: export always respects active period + applied filters.

### OVR-03 Date-Range Picker — اختيار الفترة المخصصة
Used by SCR-11 (Custom period) and OVR-02 (if a custom period is chosen inline). Start/end date selection; quick toggles (This week / month / last / YTD) + custom range; validation (start ≤ end, within accepted bounds).

### OVR-04 Delete Transaction — تأكيد الحذف
Confirmation dialog from SCR-07. Text restates the transaction identity ("حذف معاملة 'مشتريات — كشري' بقيمة 1,250 ج.م؟") + irreversibility note. Confirm → delete + refreshed list; cancel. (FR-TRANS-013, BR-TRANS-004.)

### OVR-05 Delete Account — تأكيد حذف الحساب
The most destructive surface: restates "سيتم حذف كل بياناتك نهائيًا" with the exact data scope (transactions, receipts, categories, web access), requires typed confirmation or a "حذف نهائي" action; calls the admin-scoped edge function (auth-contracts §2.5, FR-SETTINGS-005/006, security §…). Cancel stays.

### OVR-06 Logout — تأكيد تسجيل الخروج
Confirmation dialog ("سيتم تسجيل خروجك من هذا الجهاز") → sign out → Phone Entry. Destructive-ish; confirmable, not silent (FR-SETTINGS-005).

### OVR-07 Discard Review — تجاهل التعديلات الحالية
Guard when exiting the Review form (SCR-10) with unsaved/pre-filled content (or Capture with a just-captured photo). "سيفقد ما لم تحفظه" — Keep editing / Discard. Applies to back gesture, type-change, or any flow escape (FR-REVIEW-001, G3).

### OVR-08 Low-Confidence Flag → Advisory
Inline advisory tied to the flagged field in SCR-10 (not a modal): field shows a warning note telling the user to verify before save (FR-AI-004, Q-008).

---

## Summary
- **17 full-screen routes**, **8 overlays**, 4 destination tabs, 1 global FAB.
- Depth: ≤ 2 levels from any tab; add-flow is linear with guarded exits.
- Every destructive action (delete transaction, delete account, logout, exit-with-unsaved, unlink web) is confirmed.