# Export Contracts — Smart Invoice Assistant

Contracts for generating and delivering PDF and Excel/CSV export files. Generation is client-side from RLS-scoped data already fetched; no server-side export in MVP.

---

## 1. Export Model

```text
Reports screen (period + filters active)
  → User taps Export
    → Export Options sheet (choose format + confirm period)
      → Client generates file from RLS-scoped data
        → Mobile: share sheet / Web: direct download
```

---

## 2. Export Scope

| Field | Value |
|---|---|
| **Period** | Defaults to the currently selected report period (Q-014) |
| **Filters** | Respects currently applied filters: category, type, amount range (Q-014, BR-EXPORT-001) |
| **Data source** | Data already fetched via RLS-scoped queries; no additional server call |
| **Behavior** | A filtered subset exports exactly that subset |

---

## 3. PDF Export

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Generation** | Client-side (lightweight PDF library) |
| **Content** | 1. Report period, 2. Total income, 3. Total expenses, 4. Net, 5. Category breakdown, 6. Transaction list for the scope |
| **Currency** | EGP format (e.g., `1,250.50 ج.م`) (Q-013, BR-EXPORT-003) |
| **Delivery** | Mobile: share sheet (WhatsApp, email, save) (FR-EXPORT-004); Web: direct download (FR-WEB-REPORT-003) |
| **Language** | Arabic (RTL layout) as primary; matches the active UI language |
| **Optimization** | Optimized for human reading and accountant sharing (Q-013) |
| **Requirements** | FR-EXPORT-001/002/004, FR-WEB-REPORT-003, BR-EXPORT-001/002/003, Q-013, Q-014 |

---

## 4. Excel Export

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Generation** | Client-side (lightweight Excel library) |
| **Sheets** | **Sheet 1 — Summary**: period, income, expenses, net, category summary. **Sheet 2 — Transactions**: detailed records (date, type, vendor/customer, category, amount, notes). **Sheet 3 — Categories**: category totals for the exported scope. |
| **Currency** | EGP display format for human-readable cells; numeric values for machine-readable cells |
| **Delivery** | Mobile: share sheet; Web: direct download |
| **Requirements** | FR-EXPORT-001/003/004, FR-WEB-REPORT-003, BR-EXPORT-002, Q-013, Q-014 |

---

## 5. CSV Export

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Generation** | Client-side |
| **Content** | Flat transaction-level data: date, type, vendor/customer, category, amount, entry_source |
| **Format** | Standard CSV with headers; suitable for import into other systems |
| **Currency** | Numeric values (machine-readable); formatted header row |
| **Delivery** | Mobile: share sheet; Web: direct download |
| **Requirements** | FR-EXPORT-001/003/004, FR-WEB-REPORT-003, BR-EXPORT-002, Q-013 |

---

## 6. Export Options Sheet

| Field | Value |
|---|---|
| **Client** | Flutter Mobile |
| **Trigger** | Tap Export on Reports screen |
| **Options** | Format (PDF / Excel / CSV) + Period (default = current selection) |
| **Confirm** | Generate and deliver |
| **Requirements** | FR-EXPORT-001, FR-EXPORT-004 |

| Field | Value |
|---|---|
| **Client** | Next.js Dashboard |
| **Trigger** | Click Export on Reports screen |
| **Options** | Format (PDF / Excel / CSV); period = current selection (no change option on web) |
| **Confirm** | Generate and download |
| **Requirements** | FR-WEB-REPORT-003 |

---

## 7. Export Data Shape

### Transaction Row (for export)

| Column | Type | Notes |
|---|---|---|
| `transaction_date` | date | Formatted in display; raw in CSV |
| `type` | text | 'income' / 'expense' (localized label in PDF/Excel) |
| `party_name` | text | Vendor/customer name |
| `category_name` | text | Category display name |
| `amount` | numeric(14,2) | EGP formatted in PDF/Excel; raw in CSV |
| `entry_source` | text | 'manual' / 'ai' |

### Summary Block (for PDF/Excel)

| Field | Value |
|---|---|
| Report period | Start date — End date |
| Total income | EGP formatted |
| Total expenses | EGP formatted |
| Net | EGP formatted |
| Category breakdown | Category name → total amount (sorted by spend) |

---

## 8. Performance

- Client-side generation from already-fetched data; no additional server load
- PDF/Excel libraries should be lightweight for low-spec Android (NFR-LOWDEV-001)
- Generation is on-demand (only at export time); no pre-generation
- Server-side generation is a Phase 2 extension point for very large datasets

---

## 9. Traceability

| Export element | Requirement / Decision IDs |
|---|---|
| Export options + scope | FR-EXPORT-001, BR-EXPORT-001, Q-014 |
| PDF content | FR-EXPORT-002, BR-EXPORT-002, Q-013 |
| Excel content | FR-EXPORT-003, BR-EXPORT-002, Q-013 |
| CSV content | FR-EXPORT-003, BR-EXPORT-002, Q-013 |
| Share sheet (mobile) | FR-EXPORT-004 |
| Direct download (web) | FR-WEB-REPORT-003 |
| EGP currency format | Q-012, BR-EXPORT-003 |
| Period + filter scope | Q-014, BR-EXPORT-001 |
