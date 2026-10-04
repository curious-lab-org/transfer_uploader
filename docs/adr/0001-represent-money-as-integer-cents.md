# 1. Represent money as integer cents

## Status

Accepted — 2026-10-03

## Context

The central rule compares a balance against zero: a transfer is rejected if it would
take the source below $0. Floats do not work as expected. Subtract `0.10` from
`0.30` three times and you get `-2.8e-17`, so an account emptied to zero comes out
holding a negative balance. Postgres `numeric` would be exact, but it accepts `0.001`
and we do not want sub cents.

## Decision

All money is an `Integer` of cents, in `bigint` columns named `*_cents`. `t.integer`
caps at $21.4m, which one corporate balance can exceed.

The parser matches `/\A\d{1,13}(\.\d{1,2})?\z/` before converting, because
`BigDecimal` accepts `1e3`, `5_00.00` and `500.` happily (ADR-6). So `500.100` fails
for its third decimal place, nothing is rounded, and an absurd amount fails the run
cleanly instead of hitting a Postgres range error part-way through.

Every amount is AUD by assumption. We don't store a currency.

## Consequences

- The `>= 0` check can't drift, and the parser is the only place a money bug can
  hide.
- `1e3`, `1,000.00` and three decimals all fail. Nothing is inferred from an
  ambiguous amount while money is moving.
- A USD file would apply as AUD with nothing to catch it. A second currency means a
  schema change.
- No sub-cent, so interest or FX would need a different scale.
