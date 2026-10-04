# Architecture Decision Records

Why this system is built the way it is: the decisions that were expensive to change,
assumptions that were made.

## Start here

[ADR-4](0004-apply-transfers-sequentially-with-per-transfer-rejection.md) defines
what applying a day's file means, and most of the rest serves it.
[ADR-3](0003-persist-accounts-with-a-mutable-balance-column.md) is the three tables
everything is written to.
[ADR-11](0011-make-transfers-uploads-idempotent.md) is the rule that keeps a day's
file from applying twice. [ADR-1](0001-represent-money-as-integer-cents.md) is the one
most likely to cause a correctness bug if ignored.

Before changing anything, two assumptions are worth knowing. ADR-4 takes a day's file
to be thousands of lines, so a run fits in one transaction; if that stops being true,
start there and expect to pay for it in ADR-11 and ADR-12 as well, and note that
[ADR-7](0007-accept-transfers-uploads-over-http.md)'s 8 MB cap is what keeps the
assumption honest. And `transfers` holds rejected lines alongside the movements that
applied, so every aggregate over it needs `WHERE outcome = 'applied'`;
[ADR-12](0012-record-every-line-outcome-on-transfers.md) argues that trade and
records the exit.

## Money and the rules

- [1. Represent money as integer cents](0001-represent-money-as-integer-cents.md)
- [2. Treat account numbers as opaque 16-digit strings](0002-treat-account-numbers-as-opaque-strings.md)
- [3. Persist accounts with a mutable balance column](0003-persist-accounts-with-a-mutable-balance-column.md)
- [4. Apply transfers sequentially with per-transfer rejection](0004-apply-transfers-sequentially-with-per-transfer-rejection.md)

## How the code is arranged

- [5. Keep transfer logic in service objects](0005-keep-transfer-logic-in-service-objects.md)
- [6. Parse CSV at an explicit boundary layer](0006-parse-csv-at-an-explicit-boundary-layer.md)

## Getting a file in

- [7. Accept the transfers CSV over HTTP, with its business date](0007-accept-transfers-uploads-over-http.md)
- [8. No login, no scoping](0008-one-company-no-login-no-scoping.md)
- [9. Load opening balances with a rake task](0009-load-opening-balances-with-a-rake-task.md)

## Applying a day's file

- [10. Process uploads in a background job, one at a time](0010-process-uploads-in-a-background-job.md)
- [11. Accept one completed upload per business date](0011-make-transfers-uploads-idempotent.md)
- [12. Record every line's outcome on the transfers table](0012-record-every-line-outcome-on-transfers.md)
