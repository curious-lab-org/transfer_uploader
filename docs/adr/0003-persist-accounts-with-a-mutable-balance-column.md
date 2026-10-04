# 3. Persist accounts with a mutable balance column

## Status

Accepted — 2026-10-03

## Context

Balances survive between uploads and between days, so they live in the database. A
ledger is auditable and what a real bank does  but I don't want to over architect it
for simple use.

## Decision

Three tables.

```
accounts   number, balance_cents, opening_balance_cents
uploads    business_date, digest, state, error_message
transfers  upload_id, row_number, outcome,
           from_account_id, to_account_id, amount_cents, reason
```

`balance_cents` is the source of truth. `opening_balance_cents` is written once by the
balances task (ADR-9).

## Consequences

- `opening + SUM(amount_cents) WHERE outcome = 'applied'` should equal
  `balance_cents`, but nothing enforces it as we write, so it detects corruption
  rather than preventing it.
- `opening_balance_cents` has to exist from the first migration. Once a transfer
  overwrites a balance, the original survives only in a stored CSV.
