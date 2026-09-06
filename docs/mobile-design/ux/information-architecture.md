# Information Architecture — Smart Invoice Assistant (Mobile)

**Scope:** content model, top-level areas, organization schemes, labeling (Arabic primary / English secondary), hierarchy, RTL order.
**Screens referenced:** `SCR-xx` / `OVR-xx` IDs from `screen-inventory.md`.

---

## 1. Content model (what the UX is built around)

One business, one user (ASM-003). All content is business-scoped; the UI never surfaces another tenant's data (NFR-SEC-001).

| Entity | User-facing concept | Notes |
|---|---|---|
| Business | "نشاطي التجاري" / My business | Name + type; currency fixed to EGP (Q-012). Created in onboarding (SCR-04). |
| Category | "تصنيف" / Category | 10 defaults + custom; defaults hideable but not deletable/renamable (Q-010, BR-CATEGORY-004). |
| Transaction | "معاملة" / Transaction | Income (مبيعات/إيرادات) or Expense (مشتريات/مصروفات); amount, date, party name, category. Nothing more in MVP. |
| Transaction item | "بند" / Line item | Optional detail beneath a transaction (description + amount); never the primary mental model. |
| Receipt | "صورة الفاتورة" / Receipt image | Attached image shown in review + detail; read-only after save. |
| AI extraction | (invisible to user) | Provenance snapshot for AI-originated entries; never a user-facing model. |
| Pending capture (offline) | "في انتظار الاتصال" / Waiting for connection | Device-local capture awaiting sync (Q-018 flipped, ADR-007); visible in a **Pending list** (not in Transactions until confirmed+synced); device-only, cleared on logout (FR-OFFLINE-006). |

**User-facing truth:** *I have a business → it has categories → I record income and expenses into it → I look at reports.*

---

## 2. Top-level areas (the four destinations)

| Area | Arabic | English | User question it answers |
|---|---|---|---|
| Home Dashboard | الرئيسية | Home | "كيف حال نشاطي الشهر ده؟" — current month's income / expenses / net + breakdown |
| Transactions | المعاملات | Transactions | "إيه اللي سجلته؟" — the full record, filterable and searchable |
| Reports | التقارير | Reports | "إيه الوضع على مدار فترة أختارها؟" — any unified period, deep breakdown, export |
| Settings | الإعدادات | Settings | "إزاي أظبط الحاجات دي؟" — profile, categories, web access, language |

Plus a **global task flow** that is not an area: **Add Transaction** (إضافة معاملة), reached from a floating action button on Home (FR-CAPTURE-001, G2).

---

## 3. Organization scheme

- **Transactions: chronological, grouped by date**, most recent first (FR-TRANS-002). Primary access path is time.
- **Home: one fixed period** (current month) to guarantee a glanceable answer (FR-DASH-001).
- **Reports: period-driven** — the unified selector This Week / This Month / Last Month / Year-to-Date / Custom Range (Q-011) is the organizing axis.
- **Categories: alphabetical (per backend order) within two groups** — defaults first, then custom (category-contracts §3).
- **Settings: grouped by concern** — Account/Business, Data (categories), Access (web), Language, and Safety (logout / delete).

No "via-selector" departments, tabs-inside-tabs, or sectioned nav beyond this. Depth stays ≤ 2 levels from a tab.

---

## 4. Hierarchy (depth analysis)

```
Tab level (bottom nav)                 Flows (≥1 level deep)
─────────────────────                  ─────────────────────
Home (SCR-05) ─── FAB ───▶ Add flow: Type (SCR-08) → Capture (SCR-09) → Review & Save (SCR-10) → done
                                   └── Manual entry: straight to Review & Save (SCR-10)
                                   └── Offline (Q-018 flipped): capture saved as pending → Pending list ("waiting for connection") → sync → Resume in Review & Save (SCR-10)
Transactions (SCR-06) ─▶ Detail (SCR-07) ─▶ Edit → Review & Save (SCR-10); Delete → confirm (OVR-04)
Reports (SCR-11) ─ Export (OVR-02); Custom Range → date picker (OVR-03)
Settings (SCR-12) ─▶ Business Profile (SCR-13) | Categories (SCR-14 → SCR-15) | Web Access (SCR-16)
```

- The Add flow and the view/edit flow are **linear, finish-and-return**; the back gesture returns to the starting tab, discarding progress with a confirmation when unsaved edits exist (OVR-07).
- Detail and Settings sub-pages are **push**; the four tab destinations are **replace** (tab identity is a state, not a stack entry).

---

## 5. Labeling system (Arabic primary, English secondary)

Authoritative labels below. They are UI copy anchors; visual tokens come later.

| Element | Arabic (primary) | English (secondary) |
|---|---|---|
| Home tab | الرئيسية | Home |
| Transactions tab | المعاملات | Transactions |
| Reports tab | التقارير | Reports |
| Settings tab | الإعدادات | Settings |
| Add transaction (FAB) | إضافة معاملة | Add transaction |
| Transaction type — income | مبيعات / إيرادات | Sale / Income |
| Transaction type — expense | مشتريات / مصروفات | Purchase / Expense |
| Amount | المبلغ | Amount |
| Date | التاريخ | Date |
| Vendor / customer (party) | المورّد / العميل | Vendor / customer |
| Category | التصنيف | Category |
| Receipt / photo | صورة الفاتورة | Receipt |
| Total income | إجمالي الإيرادات | Total income |
| Total expenses | إجمالي المصروفات | Total expenses |
| Net | صافي الربح (الفرق) | Net |
| This month | هذا الشهر | This month |
| Last month | الشهر الماضي | Last month |
| This week | هذا الأسبوع | This week |
| Year to date | منذ بداية السنة | Year to date |
| Custom range | فترة مخصصة | Custom range |
| Export | تصدير | Export |
| Save | حفظ | Save |
| Cancel | إلغاء | Cancel |
| Delete | حذف | Delete |
| Confirm | تأكيد | Confirm |
| Try again | إعادة المحاولة | Try again |
| Enter manually | إدخال يدوي | Enter manually |
| Business name | اسم النشاط | Business name |
| Business type | نوع النشاط | Business type |
| Manage categories | إدارة التصنيفات | Manage categories |
| Enable web access | تفعيل الدخول من الويب | Enable web access |

**Naming rules**
1. Money always shows the EGP format `1,250.50 ج.م` — never a bare number and never a conflicting currency (Q-012).
2. Income/expense type names exactly match the stored values' Arabic labels (مبيعات/مشتريات…) so AI suggestions and pickers use the same strings (category-contracts §2).
3. Avoid translated technical terms: use "صورة" (photo) not "مرفق", "احفظ" (save) not "أكّد"، except where "تأكيد" is a confirmation-dialog action.
4. Direction-dependent terms ("next", "back") are mirrored under RTL automatically (see `interaction-model.md`).

---

## 6. Default categories (labels — authoritative)

Seeded automatically at onboarding (Q-010). Hidden defaults remain valid for history/filters but leave new-selection lists (BR-CATEGORY-004).

| Arabic | English |
|---|---|
| مبيعات | Sales |
| مشتريات | Purchases / Stock |
| إيجار | Rent |
| مرتبات | Salaries |
| فواتير | Utilities |
| نقل | Transport |
| تسويق | Marketing |
| صيانة | Maintenance |
| ضرائب ورسوم | Taxes / Fees |
| أخرى | Other |

---

## 7. RTL ordering rules

- **Reading order** is right-to-left: the first item of any horizontal or tab-like list renders on the **right**.
- **Bottom navigation order** therefore reads, left to right, as: Settings ← Reports ← Transactions ← Home (i.e., Home appears at the right edge, thumb-friendly in RTL for right-handed use).
- **Back/forward** semantics flip under RTL: "previous step" points right, "next step" points left (mandatory mirror, not hard-coded LTR arrows).
- Dates, amounts, and phone numbers keep their **LTR numeric glyph order** inside RTL labels (bidi isolation around values).
- Z-order and stacking (bottom sheets, dialogs) are direction-agnostic.

---

## 8. Where AI lives in the IA

AI is **inside the Add flow, not an area.** Its place in the mental model:

```
تصنيف بصورته → استخراج (AI) → مراجعة → تأكيد → حفظ
               surfaces on Review & Save (SCR-10)
```

- AI produces a **pre-filled review form**; the user owns the final words (FR-REVIEW-001…004, NFR-DATA-001).
- If AI fails silently/timeouts, the form still exists as **manual entry** — the IA never creates a separate "AI mode". Same form, two entry sources (manual/ai) per `transaction-contracts.md` §1.
- AI suggests a category that maps to the business's own category list (category-contracts §2, FR-CATEGORY-002).