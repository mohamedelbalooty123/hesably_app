# Report Contracts — Smart Invoice Assistant

Contracts for dashboard summaries, category breakdowns, period comparisons, and the unified report-period model used across Mobile and Web.

---

## 1. Report Period Model

Unified across Mobile and Web (Q-011, BR-REPORT-003):

| Period | Definition | Date Range |
|---|---|---|
| `this_week` | Current calendar week (Sunday–Saturday or Monday–Sunday per locale) | Start of current week → today |
| `this_month` | Current calendar month | 1st of current month → today |
| `last_month` | Previous calendar month | 1st of previous month → last day of previous month |
| `ytd` | Year-to-date | January 1 of current year → today |
| `custom` | User-defined range | `date_start` → `date_end` |

- Period is computed client-side; Supabase receives `date_start` and `date_end` as query parameters.
- Both clients use the same period definitions (BR-REPORT-003).

---

## 2. Home Summary (Mobile)

| Field | Value |
|---|---|
| **Client** | Flutter Mobile |
| **Path** | Direct Supabase → SELECT aggregate on `transactions` |
| **Period** | This month (current month) |
| **Output** | `{total_income, total_expense, net}` |
| **Display** | Large, glanceable numbers in EGP format (Q-012) |
| **RLS** | `business_id = current_business_id()` |
| **Index** | I1 (business_id, transaction_date) covers the date filter |
| **Requirements** | FR-DASH-001, Q-012 |

### Query Shape

```sql
SELECT
  SUM(amount) FILTER (WHERE type = 'income')  AS total_income,
  SUM(amount) FILTER (WHERE type = 'expense') AS total_expense
FROM transactions
WHERE business_id = <biz>
  AND transaction_date >= date_trunc('month', CURRENT_DATE)
  AND transaction_date <= CURRENT_DATE;
```

---

## 3. Home Category Breakdown (Mobile)

| Field | Value |
|---|---|
| **Client** | Flutter Mobile |
| **Path** | Direct Supabase → SELECT GROUP BY on `transactions` JOIN `categories` |
| **Period** | Current month |
| **Output** | Array of `{category_id, category_name, total_amount}` sorted by `total_amount DESC` |
| **Display** | Simple bar or list (FR-DASH-002) |
| **RLS** | `business_id = current_business_id()` |
| **Index** | I3 (business_id, category_id, transaction_date) |
| **Requirements** | FR-DASH-002 |

---

## 4. Home Period Comparison (Mobile)

| Field | Value |
|---|---|
| **Client** | Flutter Mobile |
| **Path** | Direct Supabase → SELECT × 2 (current month + previous month) |
| **Output** | `{current_income, current_expense, previous_income, previous_expense, income_change_pct, expense_change_pct}` |
| **Display** | "+15% expenses vs last month" (FR-DASH-003) |
| **Edge case** | Previous period has zero expenses → show "N/A" or "New" |
| **RLS** | `business_id = current_business_id()` |
| **Requirements** | FR-DASH-003, BR-REPORT-003 |

---

## 5. Reports Screen — Full Report

### 5.1 Summary Cards

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT aggregate on `transactions` |
| **Period** | User-selected (unified period selector) |
| **Filters** | Optional: category_id, type, amount range |
| **Output** | `{total_income, total_expense, net, transaction_count}` |
| **Display** | Summary cards in EGP format |
| **RLS** | `business_id = current_business_id()` |
| **Requirements** | FR-DASH-005, FR-WEB-DASH-002, FR-WEB-REPORT-002 |

### 5.2 Category Breakdown

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT GROUP BY on `transactions` JOIN `categories` |
| **Period** | User-selected + filters |
| **Output** | Array of `{category_id, category_name, total_amount, percentage}` sorted by `total_amount DESC` |
| **Display** | List or simple bar chart (FR-DASH-006, BR-REPORT-001) |
| **RLS** | `business_id = current_business_id()` |
| **Requirements** | FR-DASH-006, FR-WEB-REPORT-002, BR-REPORT-001/002 |

### 5.3 Period Comparison

| Field | Value |
|---|---|
| **Client** | Flutter Mobile, Next.js Dashboard |
| **Path** | Direct Supabase → SELECT × 2 (current period + immediately preceding period of same length) |
| **Output** | `{current_income, current_expense, previous_income, previous_expense, income_change_pct, expense_change_pct}` |
| **Display** | Comparison line (FR-DASH-007, FR-WEB-DASH-005) |
| **RLS** | `business_id = current_business_id()` |
| **Requirements** | FR-DASH-007, FR-WEB-DASH-005, BR-REPORT-003 |

---

## 6. Recent Transactions (Web Dashboard Home)

| Field | Value |
|---|---|
| **Client** | Next.js Dashboard |
| **Path** | Direct Supabase → SELECT on `transactions` JOIN `categories` |
| **Limit** | Last 10 entries (FR-WEB-DASH-004) |
| **Ordering** | `transaction_date DESC, created_at DESC` |
| **Output** | Array of transaction rows (same shape as list) |
| **RLS** | `business_id = current_business_id()` |
| **Requirements** | FR-WEB-DASH-004 |

---

## 7. Report Period Selector

| Field | Value |
|---|---|
| **Periods** | This Week, This Month, Last Month, Year-to-Date, Custom Range |
| **Mobile** | Tab-based selector on Reports screen |
| **Web** | Dropdown or segmented control on Reports screen; reflected in URL search params |
| **Default** | This Month |
| **Custom range** | Date picker for start/end dates |
| **URL sync (Web)** | Period and filters stored in URL search params for shareability |
| **Requirements** | FR-DASH-004, FR-WEB-REPORT-001, Q-011 |

---

## 8. EGP Display Format

| Field | Value |
|---|---|
| **Format** | `1,250.50 ج.م` — thousands separators, 2 decimal places, Arabic currency label |
| **Storage** | `numeric(14,2)` — always stored as numeric; formatting is client-side only |
| **Consistency** | Same format on Mobile and Web (Q-012, BR-REPORT-004) |
| **Calculations** | Always use numeric values, never formatted strings |

---

## 9. Empty States

| Scenario | Behavior |
|---|---|
| Zero transactions | Arabic empty state: "لا توجد معاملات بعد" with guidance (Q-019) |
| Zero in period | Show summary cards with zeros; no category breakdown |
| Web empty | Same Arabic copy; no "Add Transaction" CTA (creation is mobile-only) |

---

## 10. Performance

- Reports are computed live from transaction data; no cached/materialized views in MVP (backend-architecture §11)
- Solo-shop volumes are small (thousands of rows per year)
- Indexes I1, I2, I3 cover the primary report query patterns
- Client-side aggregation is acceptable for MVP; server-side is the query path

---

## 11. Traceability

| Report element | Requirement / Decision IDs |
|---|---|
| Home summary | FR-DASH-001, Q-012 |
| Category breakdown | FR-DASH-002/006, BR-REPORT-001/002 |
| Period comparison | FR-DASH-003/007, FR-WEB-DASH-005 |
| Unified period selector | FR-DASH-004, FR-WEB-REPORT-001, Q-011 |
| Summary cards (reports) | FR-DASH-005, FR-WEB-DASH-002, FR-WEB-REPORT-002 |
| EGP format | Q-012, BR-REPORT-004 |
| Empty states | Q-019 |
| Shared data model | BR-REPORT-002 |
