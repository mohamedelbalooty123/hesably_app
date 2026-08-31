# Database Decisions — Smart Invoice Assistant

Decision records for the database layer. Numbering `ADR-DB-###` keeps them distinct from the architecture ADRs (`docs/architecture/decisions/ADR-###`).

## Catalogue

| # | Decision | Status | Summary |
|---|---|---|---|
| [ADR-DB-001](./ADR-DB-001-user-business-ownership.md) | User ↔ Business ownership | Accepted | 1:1 owner; no `profiles`/`membership` tables; tenant root `businesses` with UNIQUE `owner_id`; web access is metadata + server-side gate |
| [ADR-DB-002](./ADR-DB-002-transaction-model.md) | Transaction model | Accepted | single-currency `numeric(14,2)` ledger event; `type` income/expense; required category/amount/date; optional party; no double-entry, no inventory |
| [ADR-DB-003](./ADR-DB-003-category-model.md) | Category model & seeding | Accepted | seeded defaults via narrow SECURITY DEFINER AFTER-INSERT trigger; `name_key` normalize + UNIQUE; `type` `default`/`custom`; defaults undeletable/unrenameable; in-use custom delete blocked by RESTRICT |
| [ADR-DB-004](./ADR-DB-004-receipt-storage.md) | Receipt storage & upload order | Accepted | private bucket `receipts`; tenant-prefixed paths; 0..1 immutable records; row-first upload with rollback; 20 MB cap |
| [ADR-DB-005](./ADR-DB-005-deletion-strategy.md) | Deletion strategy | Accepted | no soft-delete; owner deletion is Edge-Function-scoped (service_role) + `ON DELETE CASCADE`; no owner DELETE on `businesses`; immutable tables have no UPDATE policy |

## Process

- Each ADR follows the Context / Decision / Consequences / Alternatives shape.
- Statuses: Proposed → Accepted → Deprecated / Superseded.
- ADNs are valid only in combination with the current requirements + architecture docs; re-evaluate if a resolved decision (Q-001…Q-022) changes.
- Related: `docs/architecture/decisions/README.md` (prior ADR-001…006).