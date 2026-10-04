# 2. Treat account numbers as opaque 16-digit strings

## Status

Accepted — 2026-10-03

## Context

A 16-digit number could be stored as an integer or a string. Integers lose leading
zeros — `"0111234522226789".to_i.to_s` is a different account.

## Decision

Strings, validated as exactly 16 ASCII digits (`/\A\d{16}\z/`) when parsing, with a
unique index on the column. Never coerced to a number, never sorted as one.

Surrounding whitespace is stripped first, including what `String#strip` misses: a
non-breaking space, a zero-width space.

A number that fails the pattern makes its line unparseable, which fails the run
(ADR-6). That isn't a rejection — we keep that word for a well-formed transfer
refused by a rule (ADR-4).

## Consequences

- Leading zeros survive, so a truncated number can't misroute a transfer.
- `1111 2345 2222 6789` fails. Stripping non-digits would have accepted
  `1111-2345-2222-6789x` as well.
- The unique index is what makes the balances task safe to re-run: a second load
  naming an account we already hold is refused instead of quietly overwriting a
  balance (ADR-9).
- Correcting a mistyped number rewrites one row, because `transfers` references
  accounts by `id` (ADR-3).